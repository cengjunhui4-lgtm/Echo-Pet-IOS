import Foundation

enum EchoBackendConfiguration {
    static var localStubBaseURL: URL {
        URL(string: "http://127.0.0.1:8000")!
    }

    static var defaultBaseURL: URL {
        if let rawValue = ProcessInfo.processInfo.environment["ECHOPET_BACKEND_BASE_URL"],
           let url = URL(string: rawValue) {
            return url
        }

        return localStubBaseURL
    }
}

protocol EchoURLSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: EchoURLSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}

enum EchoHTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum EchoAPIEndpoint: Equatable {
    case login
    case logout
    case me
    case pets
    case createPet
    case pet(UUID)
    case updatePet(UUID)
    case deletePet(UUID)
    case petMemories(UUID)
    case createMemory(UUID)
    case memory(UUID)
    case memoryMedia(UUID)
    case lifePrint(UUID)
    case generateLifePrint(UUID)
    case timeline(UUID)
    case createTimelineEvent(UUID)
    case timelineEvent(UUID)
    case capsules(UUID)
    case generateCapsule(UUID)
    case capsule(UUID)
    case companionMessages(UUID)
    case companionChat(UUID)
    case exportPetData(UUID)
    case deleteMe

    static let basePath = "/v1"

    var method: EchoHTTPMethod {
        switch self {
        case .login, .logout, .createPet, .createMemory, .memoryMedia, .generateLifePrint,
             .createTimelineEvent, .generateCapsule, .companionChat, .exportPetData:
            return .post
        case .updatePet, .memory, .timelineEvent, .capsule:
            return .put
        case .deletePet, .deleteMe:
            return .delete
        case .me, .pets, .pet, .petMemories, .lifePrint, .timeline, .capsules,
             .companionMessages:
            return .get
        }
    }

    var path: String {
        switch self {
        case .login:
            return "\(Self.basePath)/auth/login"
        case .logout:
            return "\(Self.basePath)/auth/logout"
        case .me, .deleteMe:
            return "\(Self.basePath)/me"
        case .pets, .createPet:
            return "\(Self.basePath)/pets"
        case .pet(let petID), .updatePet(let petID), .deletePet(let petID):
            return "\(Self.basePath)/pets/\(petID.uuidString)"
        case .petMemories(let petID), .createMemory(let petID):
            return "\(Self.basePath)/pets/\(petID.uuidString)/memories"
        case .memory(let memoryID):
            return "\(Self.basePath)/memories/\(memoryID.uuidString)"
        case .memoryMedia(let memoryID):
            return "\(Self.basePath)/memories/\(memoryID.uuidString)/media"
        case .lifePrint(let petID):
            return "\(Self.basePath)/pets/\(petID.uuidString)/lifeprint"
        case .generateLifePrint(let petID):
            return "\(Self.basePath)/pets/\(petID.uuidString)/lifeprint/generate"
        case .timeline(let petID), .createTimelineEvent(let petID):
            return "\(Self.basePath)/pets/\(petID.uuidString)/timeline"
        case .timelineEvent(let timelineID):
            return "\(Self.basePath)/timeline/\(timelineID.uuidString)"
        case .capsules(let petID):
            return "\(Self.basePath)/pets/\(petID.uuidString)/capsules"
        case .generateCapsule(let petID):
            return "\(Self.basePath)/pets/\(petID.uuidString)/capsules/generate"
        case .capsule(let capsuleID):
            return "\(Self.basePath)/capsules/\(capsuleID.uuidString)"
        case .companionMessages(let petID):
            return "\(Self.basePath)/pets/\(petID.uuidString)/companion/messages"
        case .companionChat(let petID):
            return "\(Self.basePath)/pets/\(petID.uuidString)/companion/chat"
        case .exportPetData(let petID):
            return "\(Self.basePath)/pets/\(petID.uuidString)/export"
        }
    }

    static func contractExamples(
        petID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        memoryID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        timelineID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        capsuleID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    ) -> [EchoAPIEndpoint] {
        [
            .login,
            .logout,
            .me,
            .pets,
            .createPet,
            .pet(petID),
            .updatePet(petID),
            .deletePet(petID),
            .petMemories(petID),
            .createMemory(petID),
            .memory(memoryID),
            .memoryMedia(memoryID),
            .lifePrint(petID),
            .generateLifePrint(petID),
            .timeline(petID),
            .createTimelineEvent(petID),
            .timelineEvent(timelineID),
            .capsules(petID),
            .generateCapsule(petID),
            .capsule(capsuleID),
            .companionMessages(petID),
            .companionChat(petID),
            .exportPetData(petID),
            .deleteMe
        ]
    }
}

struct EchoAPIEnvelope<Payload: Codable>: Codable {
    var data: Payload?
    var error: EchoAPIErrorPayload?
    var requestID: String?

    enum CodingKeys: String, CodingKey {
        case data
        case error
        case requestID = "requestId"
    }
}

struct EchoAPIErrorPayload: Error, Equatable, Codable {
    var code: String
    var message: String
}

struct AuthLoginRequest: Equatable, Codable {
    var provider: String
    var identityToken: String?
    var email: String?
}

struct AuthTokenResponse: Equatable, Codable {
    var accessToken: String
    var refreshToken: String
    var userID: String

    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case userID = "userId"
    }
}

struct RelationshipContext: Equatable, Codable {
    var userRole: String
    var petRole: String
}

struct CompanionChatRequest: Equatable, Codable {
    var message: String
    var relationship: RelationshipContext
    var context: CompanionContextPayload?

    init(
        message: String,
        relationship: RelationshipContext,
        context: CompanionContextPayload? = nil
    ) {
        self.message = message
        self.relationship = relationship
        self.context = context
    }
}

struct CompanionChatResponse: Equatable, Codable {
    var messageID: String
    var reply: String
    var isAIGenerated: Bool
    var sourceMemoryIDs: [String]
    var modelVersion: String

    enum CodingKeys: String, CodingKey {
        case messageID = "messageId"
        case reply
        case isAIGenerated = "isAiGenerated"
        case sourceMemoryIDs = "sourceMemoryIds"
        case modelVersion
    }
}

struct DataExportResponse: Equatable, Codable {
    var exportID: String
    var status: String

    enum CodingKeys: String, CodingKey {
        case exportID = "exportId"
        case status
    }
}

struct MediaUploadIntent: Equatable, Codable {
    var uploadURL: URL?
    var storageKey: String
    var expiresAt: Date?
}

enum EchoAPIClientError: LocalizedError, Equatable {
    case invalidBaseURL
    case backendNotConnected(EchoAPIEndpoint)
    case invalidHTTPResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Echo Pet backend base URL is invalid."
        case .backendNotConnected(let endpoint):
            return "Echo Pet backend is not connected yet: \(endpoint.path)"
        case .invalidHTTPResponse:
            return "Echo Pet backend returned an invalid HTTP response."
        case .httpStatus(let statusCode):
            return "Echo Pet backend returned HTTP \(statusCode)."
        }
    }
}

protocol EchoAPIClient {
    var baseURL: URL { get }
    var bearerToken: String? { get }

    func makeURLRequest(for endpoint: EchoAPIEndpoint) throws -> URLRequest
    func makeURLRequest<Body: Encodable>(for endpoint: EchoAPIEndpoint, body: Body) throws -> URLRequest

    func login(_ request: AuthLoginRequest) async throws -> AuthTokenResponse
    func logout() async throws
    func me() async throws -> UserProfileResponse
    func listPets() async throws -> [PetProfile]
    func createPet(_ pet: PetProfile) async throws -> PetProfile
    func getPet(_ petID: UUID) async throws -> PetProfile
    func updatePet(_ pet: PetProfile) async throws -> PetProfile
    func deletePet(_ petID: UUID) async throws
    func listMemories(petID: UUID) async throws -> [Memory]
    func createMemory(petID: UUID, memory: Memory) async throws -> Memory
    func updateMemory(_ memory: Memory) async throws -> Memory
    func deleteMemory(_ memoryID: UUID) async throws
    func createMediaUploadIntent(memoryID: UUID, asset: MediaAsset) async throws -> MediaUploadIntent
    func getLifePrint(petID: UUID) async throws -> LifePrint
    func generateLifePrint(petID: UUID) async throws -> LifePrint
    func listTimeline(petID: UUID) async throws -> [TimelineEvent]
    func createTimelineEvent(petID: UUID, event: TimelineEvent) async throws -> TimelineEvent
    func updateTimelineEvent(_ event: TimelineEvent) async throws -> TimelineEvent
    func deleteTimelineEvent(_ timelineID: UUID) async throws
    func listCapsules(petID: UUID) async throws -> [MemoryCapsule]
    func generateCapsule(petID: UUID) async throws -> MemoryCapsule
    func getCapsule(_ capsuleID: UUID) async throws -> MemoryCapsule
    func updateCapsule(_ capsule: MemoryCapsule) async throws -> MemoryCapsule
    func deleteCapsule(_ capsuleID: UUID) async throws
    func listCompanionMessages(petID: UUID) async throws -> [ChatMessage]
    func companionChat(petID: UUID, request: CompanionChatRequest) async throws -> CompanionChatResponse
    func exportPetData(petID: UUID) async throws -> DataExportResponse
    func deleteMe() async throws
}

struct UserProfileResponse: Equatable, Codable {
    var userID: String
    var displayName: String?
    var email: String?

    enum CodingKeys: String, CodingKey {
        case userID = "userId"
        case displayName
        case email
    }
}

class EchoAPIStubClient: EchoAPIClient {
    let baseURL: URL
    let bearerToken: String?

    init(
        baseURL: URL = URL(string: "https://api.echo.pet")!,
        bearerToken: String? = nil
    ) {
        self.baseURL = baseURL
        self.bearerToken = bearerToken
    }

    func makeURLRequest(for endpoint: EchoAPIEndpoint) throws -> URLRequest {
        try makeURLRequest(for: endpoint, bodyData: nil)
    }

    func makeURLRequest<Body: Encodable>(for endpoint: EchoAPIEndpoint, body: Body) throws -> URLRequest {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try makeURLRequest(for: endpoint, bodyData: encoder.encode(body))
    }

    func login(_ request: AuthLoginRequest) async throws -> AuthTokenResponse {
        throw EchoAPIClientError.backendNotConnected(.login)
    }

    func logout() async throws {
        throw EchoAPIClientError.backendNotConnected(.logout)
    }

    func me() async throws -> UserProfileResponse {
        throw EchoAPIClientError.backendNotConnected(.me)
    }

    func listPets() async throws -> [PetProfile] {
        throw EchoAPIClientError.backendNotConnected(.pets)
    }

    func createPet(_ pet: PetProfile) async throws -> PetProfile {
        throw EchoAPIClientError.backendNotConnected(.createPet)
    }

    func getPet(_ petID: UUID) async throws -> PetProfile {
        throw EchoAPIClientError.backendNotConnected(.pet(petID))
    }

    func updatePet(_ pet: PetProfile) async throws -> PetProfile {
        throw EchoAPIClientError.backendNotConnected(.updatePet(pet.id))
    }

    func deletePet(_ petID: UUID) async throws {
        throw EchoAPIClientError.backendNotConnected(.deletePet(petID))
    }

    func listMemories(petID: UUID) async throws -> [Memory] {
        throw EchoAPIClientError.backendNotConnected(.petMemories(petID))
    }

    func createMemory(petID: UUID, memory: Memory) async throws -> Memory {
        throw EchoAPIClientError.backendNotConnected(.createMemory(petID))
    }

    func updateMemory(_ memory: Memory) async throws -> Memory {
        throw EchoAPIClientError.backendNotConnected(.memory(memory.id))
    }

    func deleteMemory(_ memoryID: UUID) async throws {
        throw EchoAPIClientError.backendNotConnected(.memory(memoryID))
    }

    func createMediaUploadIntent(memoryID: UUID, asset: MediaAsset) async throws -> MediaUploadIntent {
        throw EchoAPIClientError.backendNotConnected(.memoryMedia(memoryID))
    }

    func getLifePrint(petID: UUID) async throws -> LifePrint {
        throw EchoAPIClientError.backendNotConnected(.lifePrint(petID))
    }

    func generateLifePrint(petID: UUID) async throws -> LifePrint {
        throw EchoAPIClientError.backendNotConnected(.generateLifePrint(petID))
    }

    func listTimeline(petID: UUID) async throws -> [TimelineEvent] {
        throw EchoAPIClientError.backendNotConnected(.timeline(petID))
    }

    func createTimelineEvent(petID: UUID, event: TimelineEvent) async throws -> TimelineEvent {
        throw EchoAPIClientError.backendNotConnected(.createTimelineEvent(petID))
    }

    func updateTimelineEvent(_ event: TimelineEvent) async throws -> TimelineEvent {
        throw EchoAPIClientError.backendNotConnected(.timelineEvent(event.id))
    }

    func deleteTimelineEvent(_ timelineID: UUID) async throws {
        throw EchoAPIClientError.backendNotConnected(.timelineEvent(timelineID))
    }

    func listCapsules(petID: UUID) async throws -> [MemoryCapsule] {
        throw EchoAPIClientError.backendNotConnected(.capsules(petID))
    }

    func generateCapsule(petID: UUID) async throws -> MemoryCapsule {
        throw EchoAPIClientError.backendNotConnected(.generateCapsule(petID))
    }

    func getCapsule(_ capsuleID: UUID) async throws -> MemoryCapsule {
        throw EchoAPIClientError.backendNotConnected(.capsule(capsuleID))
    }

    func updateCapsule(_ capsule: MemoryCapsule) async throws -> MemoryCapsule {
        throw EchoAPIClientError.backendNotConnected(.capsule(capsule.id))
    }

    func deleteCapsule(_ capsuleID: UUID) async throws {
        throw EchoAPIClientError.backendNotConnected(.capsule(capsuleID))
    }

    func listCompanionMessages(petID: UUID) async throws -> [ChatMessage] {
        throw EchoAPIClientError.backendNotConnected(.companionMessages(petID))
    }

    func companionChat(petID: UUID, request: CompanionChatRequest) async throws -> CompanionChatResponse {
        throw EchoAPIClientError.backendNotConnected(.companionChat(petID))
    }

    func exportPetData(petID: UUID) async throws -> DataExportResponse {
        throw EchoAPIClientError.backendNotConnected(.exportPetData(petID))
    }

    func deleteMe() async throws {
        throw EchoAPIClientError.backendNotConnected(.deleteMe)
    }

    private func makeURLRequest(for endpoint: EchoAPIEndpoint, bodyData: Data?) throws -> URLRequest {
        let trimmedPath = endpoint.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = baseURL.appendingPathComponent(trimmedPath)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }

        if let bodyData {
            request.httpBody = bodyData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}

final class EchoAPIHTTPClient: EchoAPIStubClient {
    private let urlSession: EchoURLSession

    init(
        baseURL: URL = EchoBackendConfiguration.defaultBaseURL,
        bearerToken: String? = nil,
        urlSession: EchoURLSession = URLSession.shared
    ) {
        self.urlSession = urlSession
        super.init(baseURL: baseURL, bearerToken: bearerToken)
    }

    override func companionChat(petID: UUID, request: CompanionChatRequest) async throws -> CompanionChatResponse {
        let urlRequest = try makeURLRequest(for: .companionChat(petID), body: request)
        let (data, response) = try await urlSession.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EchoAPIClientError.invalidHTTPResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw EchoAPIClientError.httpStatus(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CompanionChatResponse.self, from: data)
    }
}
