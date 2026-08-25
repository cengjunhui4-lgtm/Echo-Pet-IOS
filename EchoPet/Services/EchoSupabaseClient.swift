import Foundation
import Security

enum EchoSupabaseConfiguration {
    static let projectURL = URL(string: "https://lhcllwbwtbpztbzdduep.supabase.co")!
    static let publishableKey = "sb_publishable_YyqGpTFG50EuIYRsciZOxw_bO0Ua7ck"
}

protocol EchoSessionStorage {
    func load() -> Data?
    func save(_ data: Data)
    func delete()
}

final class EchoKeychainSessionStorage: EchoSessionStorage {
    private let service: String
    private let account: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.echopet.mvp",
         account: String = "supabase.session") {
        self.service = service
        self.account = account
    }

    func load() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            return nil
        }
        return result as? Data
    }

    func save(_ data: Data) {
        delete()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

final class EchoUserDefaultsSessionStorage: EchoSessionStorage {
    private let userDefaults: UserDefaults
    private let key: String

    init(userDefaults: UserDefaults, key: String) {
        self.userDefaults = userDefaults
        self.key = key
    }

    func load() -> Data? {
        userDefaults.data(forKey: key)
    }

    func save(_ data: Data) {
        userDefaults.set(data, forKey: key)
    }

    func delete() {
        userDefaults.removeObject(forKey: key)
    }
}

struct SupabaseSession: Equatable, Codable {
    var userID: String
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date
    var provider: AccountProvider
    var displayName: String?
    var email: String?

    var isValidForRequest: Bool {
        expiresAt.timeIntervalSinceNow > 90
    }

    var accountSession: AccountSession {
        AccountSession(
            userID: userID,
            displayName: displayName ?? defaultDisplayName,
            email: email,
            provider: provider,
            isLocalOnly: false
        )
    }

    private var defaultDisplayName: String {
        switch provider {
        case .email:
            return email ?? "Email"
        case .supabaseAnonymous:
            return "Guest"
        case .localPreview:
            return "Local"
        }
    }
}

struct EmailPasswordAuthRequest {
    var email: String
    var password: String
}

enum EchoSupabaseAuthError: Error, Equatable {
    case emailConfirmationRequired
}

final class EchoSupabaseAuthService {
    static let shared = EchoSupabaseAuthService()

    private let api: EchoSupabaseAPI
    private let storage: EchoSessionStorage

    init(
        api: EchoSupabaseAPI = EchoSupabaseAPI(),
        userDefaults: UserDefaults? = nil,
        sessionStorageKey: String = "com.echopet.supabase.session"
    ) {
        self.api = api
        if let userDefaults {
            self.storage = EchoUserDefaultsSessionStorage(userDefaults: userDefaults, key: sessionStorageKey)
        } else {
            self.storage = EchoKeychainSessionStorage(account: sessionStorageKey)
        }
    }

    func storedSession() -> SupabaseSession? {
        guard let data = storage.load() else {
            return nil
        }

        return try? JSONDecoder().decode(SupabaseSession.self, from: data)
    }

    func authenticatedSession(allowAnonymous: Bool = true) async throws -> SupabaseSession {
        if let session = storedSession(), session.isValidForRequest {
            return session
        }

        if let refreshToken = storedSession()?.refreshToken,
           let refreshed = try? await refreshSession(refreshToken: refreshToken) {
            storeSession(refreshed)
            return refreshed
        }

        guard allowAnonymous else {
            throw EchoAPIClientError.backendNotConnected(.login)
        }

        return try await signInAnonymously()
    }

    func signInAnonymously() async throws -> SupabaseSession {
        storage.delete()
        let response = try await api.sendJSON(
            path: "auth/v1/signup",
            method: "POST",
            body: EmptyJSONBody(),
            responseType: SupabaseAuthResponse.self
        )
        guard response.hasSession else {
            throw EchoAPIClientError.backendNotConnected(.login)
        }
        let session = response.session(provider: .supabaseAnonymous, displayName: "Guest", email: nil)
        storeSession(session)
        return session
    }

    func signInWithEmail(_ request: EmailPasswordAuthRequest) async throws -> SupabaseSession {
        storage.delete()
        let response = try await api.sendJSON(
            path: "auth/v1/token?grant_type=password",
            method: "POST",
            body: SupabaseEmailPasswordRequest(
                email: request.email,
                password: request.password
            ),
            responseType: SupabaseAuthResponse.self
        )
        guard response.hasSession else {
            throw EchoAPIClientError.backendNotConnected(.login)
        }
        let session = response.session(
            provider: .email,
            displayName: request.email,
            email: request.email
        )
        storeSession(session)
        return session
    }

    func signUpWithEmail(_ request: EmailPasswordAuthRequest) async throws -> SupabaseSession {
        storage.delete()
        let response = try await api.sendJSON(
            path: "auth/v1/signup",
            method: "POST",
            body: SupabaseEmailPasswordRequest(
                email: request.email,
                password: request.password
            ),
            responseType: SupabaseAuthResponse.self
        )
        guard response.hasSession else {
            throw EchoSupabaseAuthError.emailConfirmationRequired
        }
        let session = response.session(
            provider: .email,
            displayName: request.email,
            email: request.email
        )
        storeSession(session)
        return session
    }

    func verifyEmailSignupOTP(email: String, token: String) async throws -> SupabaseSession {
        storage.delete()
        let response = try await api.sendJSON(
            path: "auth/v1/verify",
            method: "POST",
            body: SupabaseOTPVerificationRequest(
                email: email,
                token: token,
                type: "signup"
            ),
            responseType: SupabaseAuthResponse.self
        )
        guard response.hasSession else {
            throw EchoAPIClientError.backendNotConnected(.login)
        }
        let session = response.session(
            provider: .email,
            displayName: email,
            email: email
        )
        storeSession(session)
        return session
    }

    func resetPassword(forEmail email: String) async throws {
        try await api.sendJSONWithoutResponse(
            path: "auth/v1/recover",
            method: "POST",
            body: SupabasePasswordRecoveryRequest(email: email)
        )
    }

    func resetPasswordWithOTP(email: String, token: String, newPassword: String) async throws {
        let response = try await api.sendJSON(
            path: "auth/v1/verify",
            method: "POST",
            body: SupabaseOTPVerificationRequest(
                email: email,
                token: token,
                type: "recovery"
            ),
            responseType: SupabaseAuthResponse.self
        )
        guard let accessToken = response.accessToken, !accessToken.isEmpty else {
            throw EchoAPIClientError.backendNotConnected(.login)
        }

        try await api.sendJSONWithoutResponse(
            path: "auth/v1/user",
            method: "PUT",
            accessToken: accessToken,
            body: SupabaseUpdatePasswordRequest(password: newPassword)
        )

        storage.delete()
    }

    func signOut() {
        storage.delete()
    }

    func deleteAccount() async throws {
        let session = try await authenticatedSession(allowAnonymous: false)
        _ = try await api.sendJSON(
            path: "functions/v1/delete-account",
            method: "POST",
            accessToken: session.accessToken,
            body: EmptyJSONBody(),
            responseType: SupabaseDeleteAccountResponse.self
        )
        signOut()
    }

    func updatePassword(accessToken: String, newPassword: String) async throws {
        try await api.sendJSONWithoutResponse(
            path: "auth/v1/user",
            method: "PUT",
            accessToken: accessToken,
            body: SupabaseUpdatePasswordRequest(password: newPassword)
        )
    }

    private func refreshSession(refreshToken: String) async throws -> SupabaseSession {
        let response = try await api.sendJSON(
            path: "auth/v1/token?grant_type=refresh_token",
            method: "POST",
            body: SupabaseRefreshTokenRequest(refreshToken: refreshToken),
            responseType: SupabaseAuthResponse.self
        )
        let stored = storedSession()
        return response.session(
            provider: stored?.provider ?? .supabaseAnonymous,
            displayName: stored?.displayName,
            email: stored?.email
        )
    }

    private func storeSession(_ session: SupabaseSession) {
        guard let data = try? JSONEncoder().encode(session) else {
            return
        }

        storage.save(data)
    }
}

protocol EchoCloudSyncing {
    func syncState(_ state: EchoAppState, allowAnonymous: Bool) async throws
}

final class EchoCloudSyncService: EchoCloudSyncing {
    static let shared = EchoCloudSyncService()

    private let authService: EchoSupabaseAuthService
    private let api: EchoSupabaseAPI

    init(
        authService: EchoSupabaseAuthService = .shared,
        api: EchoSupabaseAPI = EchoSupabaseAPI()
    ) {
        self.authService = authService
        self.api = api
    }

    func syncState(_ state: EchoAppState, allowAnonymous: Bool = true) async throws {
        guard let pet = state.pet else {
            return
        }

        let session = try await authService.authenticatedSession(allowAnonymous: allowAnonymous)

        try await upsert(
            table: "pets",
            records: [
                SupabasePetRecord(
                    id: pet.id.uuidString,
                    ownerID: session.userID,
                    name: pet.name,
                    species: pet.species ?? "pet",
                    breed: pet.breed,
                    relationshipLabel: pet.relationshipLabel ?? "owner and pet",
                    personalityNotes: pet.personality,
                    favoriteThings: pet.favoriteThings,
                    habits: pet.habits,
                    aiMemoryEnabled: state.aiCompanionSettings.allowsMemoryContext
                )
            ],
            accessToken: session.accessToken
        )

        try await upsert(
            table: "timeline_events",
            records: state.timeline.map {
                SupabaseTimelineEventRecord(
                    id: $0.id.uuidString,
                    petID: pet.id.uuidString,
                    ownerID: session.userID,
                    title: $0.title,
                    story: $0.story,
                    happenedAt: Self.timestamp($0.date),
                    mood: nil,
                    emotionTags: [],
                    behaviorTags: $0.category.map { [$0] } ?? [],
                    importance: 3,
                    sourceKind: "memory",
                    aiSummary: $0.story
                )
            },
            accessToken: session.accessToken
        )

        try await upsert(
            table: "daily_tasks",
            records: state.dailyTasks.map {
                SupabaseDailyTaskRecord(
                    id: $0.id.uuidString,
                    petID: pet.id.uuidString,
                    ownerID: session.userID,
                    title: $0.title,
                    note: $0.note,
                    dueOn: Self.day($0.date),
                    dueAt: Self.time($0.dueAt),
                    templateKey: $0.template.rawValue,
                    isCompleted: $0.isCompleted
                )
            },
            accessToken: session.accessToken
        )

        if let lifePrint = state.lifePrint {
            try await upsert(
                table: "lifeprints",
                records: [
                    SupabaseLifePrintRecord(
                        id: pet.id.uuidString,
                        petID: pet.id.uuidString,
                        ownerID: session.userID,
                        summary: lifePrint.summary,
                        personalityTraits: lifePrint.personalityTraits ?? [],
                        favoriteThings: lifePrint.favoriteThings ?? [],
                        habits: lifePrint.habits ?? [],
                        relationshipPatterns: [pet.relationshipLabel].compactMap { $0 },
                        sourceTimelineEventIDs: state.timeline.map { $0.id.uuidString },
                        sourceDailyTaskIDs: state.dailyTasks.map { $0.id.uuidString },
                        aiModel: "deepseek-v4-flash",
                        aiMode: "context-sync",
                        isCurrent: true,
                        generatedAt: Self.timestamp(lifePrint.updatedAt)
                    )
                ],
                accessToken: session.accessToken
            )
        }
    }

    private func upsert<Record: Encodable>(
        table: String,
        records: [Record],
        accessToken: String
    ) async throws {
        guard !records.isEmpty else {
            return
        }

        try await api.sendJSONWithoutResponse(
            path: "rest/v1/\(table)?on_conflict=id",
            method: "POST",
            accessToken: accessToken,
            preferHeader: "resolution=merge-duplicates,return=minimal",
            body: records
        )
    }

    private static func timestamp(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func day(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func time(_ date: Date?) -> String? {
        guard let date else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

final class EchoSupabaseCompanionClient: CompanionBackendClient {
    private let authService: EchoSupabaseAuthService
    private let api: EchoSupabaseAPI

    init(
        authService: EchoSupabaseAuthService = .shared,
        api: EchoSupabaseAPI = EchoSupabaseAPI()
    ) {
        self.authService = authService
        self.api = api
    }

    func companionChat(petID: UUID, request: CompanionChatRequest) async throws -> CompanionChatResponse {
        let session = try await authService.authenticatedSession()
        let functionRequest = SupabaseCompanionFunctionRequest(
            petID: petID.uuidString,
            message: request.message,
            languageCode: request.context?.languageCode ?? "zh_Hans",
            relationship: request.relationship,
            settings: SupabaseCompanionFunctionSettings(
                memoryEnabled: request.context?.privacy.allowsMemoryContext ?? true,
                tone: request.context?.tone.rawValue ?? AICompanionTone.gentleCompanion.rawValue
            )
        )

        return try await api.sendJSON(
            path: "functions/v1/companion-chat",
            method: "POST",
            accessToken: session.accessToken,
            body: functionRequest,
            responseType: CompanionChatResponse.self
        )
    }
}

final class EchoSupabaseAPI {
    let projectURL: URL
    let publishableKey: String
    let urlSession: EchoURLSession

    init(
        projectURL: URL = EchoSupabaseConfiguration.projectURL,
        publishableKey: String = EchoSupabaseConfiguration.publishableKey,
        urlSession: EchoURLSession = URLSession.shared
    ) {
        self.projectURL = projectURL
        self.publishableKey = publishableKey
        self.urlSession = urlSession
    }

    func sendJSON<Body: Encodable, ResponseBody: Decodable>(
        path: String,
        method: String,
        accessToken: String? = nil,
        preferHeader: String? = nil,
        body: Body,
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody {
        let data = try await sendJSONData(
            path: path,
            method: method,
            accessToken: accessToken,
            preferHeader: preferHeader,
            body: body
        )
        return try JSONDecoder().decode(ResponseBody.self, from: data)
    }

    func sendJSONWithoutResponse<Body: Encodable>(
        path: String,
        method: String,
        accessToken: String? = nil,
        preferHeader: String? = nil,
        body: Body
    ) async throws {
        _ = try await sendJSONData(
            path: path,
            method: method,
            accessToken: accessToken,
            preferHeader: preferHeader,
            body: body
        )
    }

    private func sendJSONData<Body: Encodable>(
        path: String,
        method: String,
        accessToken: String?,
        preferHeader: String?,
        body: Body
    ) async throws -> Data {
        var request = URLRequest(url: makeURL(path: path))
        request.httpMethod = method
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let preferHeader {
            request.setValue(preferHeader, forHTTPHeaderField: "Prefer")
        }

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EchoAPIClientError.invalidHTTPResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
#if DEBUG
            let details = String(data: data, encoding: .utf8) ?? ""
            print("Echo Supabase request failed: \(request.url?.absoluteString ?? "") status=\(httpResponse.statusCode) body=\(details)")
#endif
            throw EchoAPIClientError.httpStatus(httpResponse.statusCode)
        }

        return data
    }

    private func makeURL(path: String) -> URL {
        var components = URLComponents(url: projectURL, resolvingAgainstBaseURL: false)!
        let pathParts = path.split(separator: "?", maxSplits: 1).map(String.init)
        components.path = "/" + pathParts[0].trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if pathParts.count > 1 {
            components.percentEncodedQuery = pathParts[1]
        }

        return components.url!
    }
}

private struct EmptyJSONBody: Encodable {}

private struct SupabaseEmailPasswordRequest: Encodable {
    var email: String
    var password: String
}

private struct SupabasePasswordRecoveryRequest: Encodable {
    var email: String
}

private struct SupabaseOTPVerificationRequest: Encodable {
    var email: String
    var token: String
    var type: String
}

private struct SupabaseUpdatePasswordRequest: Encodable {
    var password: String
}

private struct SupabaseRefreshTokenRequest: Encodable {
    var refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

private struct SupabaseAuthResponse: Decodable {
    var accessToken: String?
    var refreshToken: String?
    var expiresIn: Int?
    var expiresAt: Int?
    var user: SupabaseAuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case user
        case id
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decodeIfPresent(String.self, forKey: .accessToken)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        expiresIn = try container.decodeIfPresent(Int.self, forKey: .expiresIn)
        expiresAt = try container.decodeIfPresent(Int.self, forKey: .expiresAt)

        if let wrappedUser = try container.decodeIfPresent(SupabaseAuthUser.self, forKey: .user) {
            user = wrappedUser
        } else {
            user = SupabaseAuthUser(id: try container.decode(String.self, forKey: .id))
        }
    }

    var hasSession: Bool {
        accessToken?.isEmpty == false
    }

    func session(provider: AccountProvider, displayName: String?, email: String?) -> SupabaseSession {
        let fallbackExpiry = Date().addingTimeInterval(TimeInterval(expiresIn ?? 3600))
        let expiry = expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? fallbackExpiry
        return SupabaseSession(
            userID: user.id,
            accessToken: accessToken ?? "",
            refreshToken: refreshToken,
            expiresAt: expiry,
            provider: provider,
            displayName: displayName,
            email: email
        )
    }
}

private struct SupabaseAuthUser: Decodable {
    var id: String
}

private struct SupabaseDeleteAccountResponse: Decodable {
    var deleted: Bool
}

private struct SupabaseCompanionFunctionRequest: Encodable {
    var petID: String
    var message: String
    var languageCode: String
    var relationship: RelationshipContext
    var settings: SupabaseCompanionFunctionSettings

    enum CodingKeys: String, CodingKey {
        case petID = "petId"
        case message
        case languageCode
        case relationship
        case settings
    }
}

private struct SupabaseCompanionFunctionSettings: Encodable {
    var memoryEnabled: Bool
    var tone: String
}

private struct SupabasePetRecord: Encodable {
    var id: String
    var ownerID: String
    var name: String
    var species: String
    var breed: String?
    var relationshipLabel: String
    var personalityNotes: String?
    var favoriteThings: [String]
    var habits: [String]
    var aiMemoryEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case species
        case breed
        case relationshipLabel = "relationship_label"
        case personalityNotes = "personality_notes"
        case favoriteThings = "favorite_things"
        case habits
        case aiMemoryEnabled = "ai_memory_enabled"
    }
}

private struct SupabaseTimelineEventRecord: Encodable {
    var id: String
    var petID: String
    var ownerID: String
    var title: String
    var story: String
    var happenedAt: String
    var mood: String?
    var emotionTags: [String]
    var behaviorTags: [String]
    var importance: Int
    var sourceKind: String
    var aiSummary: String?

    enum CodingKeys: String, CodingKey {
        case id
        case petID = "pet_id"
        case ownerID = "owner_id"
        case title
        case story
        case happenedAt = "happened_at"
        case mood
        case emotionTags = "emotion_tags"
        case behaviorTags = "behavior_tags"
        case importance
        case sourceKind = "source_kind"
        case aiSummary = "ai_summary"
    }
}

private struct SupabaseDailyTaskRecord: Encodable {
    var id: String
    var petID: String
    var ownerID: String
    var title: String
    var note: String
    var dueOn: String
    var dueAt: String?
    var templateKey: String
    var isCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case petID = "pet_id"
        case ownerID = "owner_id"
        case title
        case note
        case dueOn = "due_on"
        case dueAt = "due_at"
        case templateKey = "template_key"
        case isCompleted = "is_completed"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(petID, forKey: .petID)
        try container.encode(ownerID, forKey: .ownerID)
        try container.encode(title, forKey: .title)
        try container.encode(note, forKey: .note)
        try container.encode(dueOn, forKey: .dueOn)
        try container.encode(templateKey, forKey: .templateKey)
        try container.encode(isCompleted, forKey: .isCompleted)

        if let dueAt {
            try container.encode(dueAt, forKey: .dueAt)
        } else {
            try container.encodeNil(forKey: .dueAt)
        }
    }
}

private struct SupabaseLifePrintRecord: Encodable {
    var id: String
    var petID: String
    var ownerID: String
    var summary: String
    var personalityTraits: [String]
    var favoriteThings: [String]
    var habits: [String]
    var relationshipPatterns: [String]
    var sourceTimelineEventIDs: [String]
    var sourceDailyTaskIDs: [String]
    var aiModel: String
    var aiMode: String
    var isCurrent: Bool
    var generatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case petID = "pet_id"
        case ownerID = "owner_id"
        case summary
        case personalityTraits = "personality_traits"
        case favoriteThings = "favorite_things"
        case habits
        case relationshipPatterns = "relationship_patterns"
        case sourceTimelineEventIDs = "source_timeline_event_ids"
        case sourceDailyTaskIDs = "source_daily_task_ids"
        case aiModel = "ai_model"
        case aiMode = "ai_mode"
        case isCurrent = "is_current"
        case generatedAt = "generated_at"
    }
}
