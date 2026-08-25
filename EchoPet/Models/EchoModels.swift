import Foundation

enum EchoAIContent {
    static let companionDisclaimer = L10n.text(.companionAIDisclaimer, language: .zhHans)

    static func companionDisclaimer(language: AppLanguage) -> String {
        L10n.text(.companionAIDisclaimer, language: language)
    }

    static func normalizeCompanionReply(_ text: String, language: AppLanguage = .zhHans) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let disclaimer = companionDisclaimer(language: language)

        guard !trimmed.isEmpty else {
            return disclaimer
        }

        guard !trimmed.contains(disclaimer) else {
            return trimmed
        }

        return "\(trimmed)\n\(disclaimer)"
    }
}

struct PetProfile: Identifiable, Equatable, Codable {
    var id: UUID
    var name: String
    var species: String?
    var breed: String
    var age: String
    var birthDate: Date?
    var status: String?
    var relationshipLabel: String?
    var avatarAssetID: String?
    var personality: String
    var mbti: String
    var favoriteThings: [String]
    var habits: [String]
    var createdAt: Date?
    var updatedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        species: String? = nil,
        breed: String,
        age: String,
        birthDate: Date? = nil,
        status: String? = nil,
        relationshipLabel: String? = nil,
        avatarAssetID: String? = nil,
        personality: String,
        mbti: String,
        favoriteThings: [String],
        habits: [String],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.breed = breed
        self.age = age
        self.birthDate = birthDate
        self.status = status
        self.relationshipLabel = relationshipLabel
        self.avatarAssetID = avatarAssetID
        self.personality = personality
        self.mbti = mbti
        self.favoriteThings = favoriteThings
        self.habits = habits
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum AccountProvider: String, Equatable, Codable {
    case localPreview
    case supabaseAnonymous
    case email
}

struct AccountSession: Identifiable, Equatable, Codable {
    var id: String { userID }
    var userID: String
    var displayName: String
    var email: String?
    var provider: AccountProvider
    var isLocalOnly: Bool
    var createdAt: Date

    init(
        userID: String = "local-preview-user",
        displayName: String,
        email: String? = nil,
        provider: AccountProvider = .localPreview,
        isLocalOnly: Bool = true,
        createdAt: Date = Date()
    ) {
        self.userID = userID
        self.displayName = displayName
        self.email = email
        self.provider = provider
        self.isLocalOnly = isLocalOnly
        self.createdAt = createdAt
    }
}

enum SyncConnectionState: String, Equatable, Codable {
    case localOnly
    case readyForBackend
}

enum SyncDomain: String, Equatable, Codable, CaseIterable {
    case account
    case petProfile
    case memoryFiles
    case lifePrint
    case timeline
    case memoryCapsules
    case companion
}

struct SyncReadinessSummary: Equatable, Codable {
    var state: SyncConnectionState
    var queuedChangeCount: Int
    var activeDomains: [SyncDomain]
}

enum AICompanionTone: String, Equatable, Codable, CaseIterable {
    case gentleCompanion
}

enum CompanionConnectionState: String, Equatable, Codable {
    case localOnly
    case backendConnected
    case backendUnavailable
}

struct AICompanionSettings: Equatable, Codable {
    var allowsMemoryContext: Bool
    var tone: AICompanionTone
    var updatedAt: Date

    static let `default` = AICompanionSettings()

    init(
        allowsMemoryContext: Bool = true,
        tone: AICompanionTone = .gentleCompanion,
        updatedAt: Date = Date()
    ) {
        self.allowsMemoryContext = allowsMemoryContext
        self.tone = tone
        self.updatedAt = updatedAt
    }
}

struct CompanionPetContext: Equatable, Codable {
    var id: UUID
    var name: String
    var species: String?
    var breed: String
    var age: String
    var status: String?
    var relationshipLabel: String?
    var personality: String
    var mbti: String
    var favoriteThings: [String]
    var habits: [String]

    enum CodingKeys: String, CodingKey {
        case id = "petId"
        case name
        case species
        case breed
        case age
        case status
        case relationshipLabel
        case personality
        case mbti
        case favoriteThings
        case habits
    }
}

struct CompanionLifePrintContext: Equatable, Codable {
    var summary: String
    var updatedAt: Date
    var personalityTraits: [String]
    var favoriteThings: [String]
    var habits: [String]
    var sourceMemoryIDs: [UUID]
    var isAIGenerated: Bool

    enum CodingKeys: String, CodingKey {
        case summary
        case updatedAt
        case personalityTraits
        case favoriteThings
        case habits
        case sourceMemoryIDs = "sourceMemoryIds"
        case isAIGenerated = "isAiGenerated"
    }
}

struct CompanionTimelineMemoryContext: Equatable, Codable {
    var id: UUID
    var petID: UUID?
    var memoryID: UUID?
    var date: Date
    var title: String
    var story: String
    var category: String?
    var mediaAssetCount: Int
    var sourceMemoryIDs: [UUID]

    enum CodingKeys: String, CodingKey {
        case id = "timelineId"
        case petID = "petId"
        case memoryID = "memoryId"
        case date
        case title
        case story
        case category
        case mediaAssetCount
        case sourceMemoryIDs = "sourceMemoryIds"
    }
}

struct CompanionDailyTaskContext: Equatable, Codable {
    var id: UUID
    var petID: UUID?
    var title: String
    var note: String
    var dueAt: Date?
    var date: Date
    var template: DailyCareTaskTemplate
    var isCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case id = "taskId"
        case petID = "petId"
        case title
        case note
        case dueAt
        case date
        case template
        case isCompleted
    }
}

struct CompanionMessageContext: Equatable, Codable {
    var id: UUID
    var role: String
    var text: String
    var timestamp: Date
    var isAIGenerated: Bool
    var sourceMemoryIDs: [UUID]

    enum CodingKeys: String, CodingKey {
        case id = "messageId"
        case role
        case text
        case timestamp
        case isAIGenerated = "isAiGenerated"
        case sourceMemoryIDs = "sourceMemoryIds"
    }
}

struct CompanionPrivacyContext: Equatable, Codable {
    var allowsMemoryContext: Bool
    var usesPetProfile: Bool
    var usesLifePrint: Bool
    var usesTimeline: Bool
    var usesDailyTasks: Bool
    var usesChatHistory: Bool
}

struct CompanionContextPayload: Equatable, Codable {
    var languageCode: String
    var tone: AICompanionTone
    var generatedAt: Date
    var pet: CompanionPetContext
    var lifePrint: CompanionLifePrintContext?
    var timelineMemories: [CompanionTimelineMemoryContext]
    var dailyTasks: [CompanionDailyTaskContext]
    var recentMessages: [CompanionMessageContext]
    var privacy: CompanionPrivacyContext
}

enum DailyCareTaskTemplate: String, Equatable, Codable, CaseIterable {
    case feeding
    case walk
    case grooming
    case play
    case cleaning
    case medicine
    case photo
    case custom
}

struct DailyCareTask: Identifiable, Equatable, Codable {
    var id: UUID
    var petID: UUID?
    var title: String
    var note: String
    var dueAt: Date?
    var date: Date
    var template: DailyCareTaskTemplate
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        petID: UUID? = nil,
        title: String,
        note: String = "",
        dueAt: Date? = nil,
        date: Date = Date(),
        template: DailyCareTaskTemplate = .custom,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.petID = petID
        self.title = title
        self.note = note
        self.dueAt = dueAt
        self.date = date
        self.template = template
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum MemoryKind: String, Equatable, Codable, CaseIterable {
    case text
    case photo
    case video
    case audio
    case mixed
}

struct MediaAsset: Identifiable, Equatable, Codable {
    var id: UUID
    var kind: MemoryKind
    var localIdentifier: String?
    var remoteURL: URL?
    var storageKey: String?
    var caption: String?

    init(
        id: UUID = UUID(),
        kind: MemoryKind,
        localIdentifier: String? = nil,
        remoteURL: URL? = nil,
        storageKey: String? = nil,
        caption: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.localIdentifier = localIdentifier
        self.remoteURL = remoteURL
        self.storageKey = storageKey
        self.caption = caption
    }
}

enum BackgroundDisplayMode: String, Equatable, Codable, CaseIterable, Identifiable {
    case fixed
    case random
    case dailyRandom
    case gentleCycle

    var id: String { rawValue }
}

struct BackgroundAlbumPhoto: Identifiable, Equatable, Codable {
    var id: UUID
    var asset: MediaAsset
    var isIncludedInRotation: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        asset: MediaAsset,
        isIncludedInRotation: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.asset = asset
        self.isIncludedInRotation = isIncludedInRotation
        self.createdAt = createdAt
    }
}

struct BackgroundAlbumSettings: Equatable, Codable {
    var photos: [BackgroundAlbumPhoto]
    var selectedPhotoID: UUID?
    var displayMode: BackgroundDisplayMode
    var blurRadius: Double
    var updatedAt: Date

    static let empty = BackgroundAlbumSettings()

    init(
        photos: [BackgroundAlbumPhoto] = [],
        selectedPhotoID: UUID? = nil,
        displayMode: BackgroundDisplayMode = .fixed,
        blurRadius: Double = 18,
        updatedAt: Date = Date()
    ) {
        self.photos = photos
        self.selectedPhotoID = selectedPhotoID
        self.displayMode = displayMode
        self.blurRadius = min(max(blurRadius, 0), 32)
        self.updatedAt = updatedAt
    }
}

struct Memory: Identifiable, Equatable, Codable {
    var id: UUID
    var petID: UUID?
    var title: String
    var body: String
    var occurredAt: Date
    var kind: MemoryKind
    var mediaAssets: [MediaAsset]
    var tags: [String]
    var emotionTags: [String]
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        petID: UUID? = nil,
        title: String,
        body: String,
        occurredAt: Date,
        kind: MemoryKind = .text,
        mediaAssets: [MediaAsset] = [],
        tags: [String] = [],
        emotionTags: [String] = [],
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.petID = petID
        self.title = title
        self.body = body
        self.occurredAt = occurredAt
        self.kind = kind
        self.mediaAssets = mediaAssets
        self.tags = tags
        self.emotionTags = emotionTags
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct TimelineEvent: Identifiable, Equatable, Codable {
    var id: UUID
    var petID: UUID?
    var memoryID: UUID?
    var date: Date
    var title: String
    var story: String
    var imageSystemName: String
    var mediaAssets: [MediaAsset]
    var category: String?
    var sourceMemoryIDs: [UUID]?

    init(
        id: UUID = UUID(),
        petID: UUID? = nil,
        memoryID: UUID? = nil,
        date: Date,
        title: String,
        story: String,
        imageSystemName: String,
        mediaAssets: [MediaAsset] = [],
        category: String? = nil,
        sourceMemoryIDs: [UUID]? = nil
    ) {
        self.id = id
        self.petID = petID
        self.memoryID = memoryID
        self.date = date
        self.title = title
        self.story = story
        self.imageSystemName = imageSystemName
        self.mediaAssets = mediaAssets
        self.category = category
        self.sourceMemoryIDs = sourceMemoryIDs
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case petID
        case memoryID
        case date
        case title
        case story
        case imageSystemName
        case mediaAssets
        case category
        case sourceMemoryIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        petID = try container.decodeIfPresent(UUID.self, forKey: .petID)
        memoryID = try container.decodeIfPresent(UUID.self, forKey: .memoryID)
        date = try container.decode(Date.self, forKey: .date)
        title = try container.decode(String.self, forKey: .title)
        story = try container.decode(String.self, forKey: .story)
        imageSystemName = try container.decode(String.self, forKey: .imageSystemName)
        mediaAssets = try container.decodeIfPresent([MediaAsset].self, forKey: .mediaAssets) ?? []
        category = try container.decodeIfPresent(String.self, forKey: .category)
        sourceMemoryIDs = try container.decodeIfPresent([UUID].self, forKey: .sourceMemoryIDs)
    }
}

typealias TimelineMemory = TimelineEvent

struct ChatMessage: Identifiable, Equatable, Codable {
    var id: UUID
    var text: String
    var isUser: Bool
    var timestamp: Date
    var isAIGenerated: Bool?
    var sourceMemoryIDs: [UUID]?

    init(
        id: UUID = UUID(),
        text: String,
        isUser: Bool,
        timestamp: Date,
        isAIGenerated: Bool? = nil,
        sourceMemoryIDs: [UUID]? = nil
    ) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
        self.isAIGenerated = isAIGenerated
        self.sourceMemoryIDs = sourceMemoryIDs
    }
}

struct MemoryCapsule: Identifiable, Equatable, Codable {
    var id: UUID
    var petID: UUID?
    var title: String
    var dateLabel: String
    var body: String
    var accentSystemName: String
    var theme: String?
    var sourceMemoryIDs: [UUID]?
    var isAIGenerated: Bool?
    var createdAt: Date?

    init(
        id: UUID = UUID(),
        petID: UUID? = nil,
        title: String,
        dateLabel: String,
        body: String,
        accentSystemName: String,
        theme: String? = nil,
        sourceMemoryIDs: [UUID]? = nil,
        isAIGenerated: Bool? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.petID = petID
        self.title = title
        self.dateLabel = dateLabel
        self.body = body
        self.accentSystemName = accentSystemName
        self.theme = theme
        self.sourceMemoryIDs = sourceMemoryIDs
        self.isAIGenerated = isAIGenerated
        self.createdAt = createdAt
    }
}

struct LifePrint: Equatable, Codable {
    var id: UUID?
    var petID: UUID?
    var summary: String
    var updatedAt: Date
    var personalityTraits: [String]?
    var favoriteThings: [String]?
    var habits: [String]?
    var sourceMemoryIDs: [UUID]?
    var isAIGenerated: Bool?

    init(
        id: UUID? = nil,
        petID: UUID? = nil,
        summary: String,
        updatedAt: Date,
        personalityTraits: [String]? = nil,
        favoriteThings: [String]? = nil,
        habits: [String]? = nil,
        sourceMemoryIDs: [UUID]? = nil,
        isAIGenerated: Bool? = nil
    ) {
        self.id = id
        self.petID = petID
        self.summary = summary
        self.updatedAt = updatedAt
        self.personalityTraits = personalityTraits
        self.favoriteThings = favoriteThings
        self.habits = habits
        self.sourceMemoryIDs = sourceMemoryIDs
        self.isAIGenerated = isAIGenerated
    }
}

typealias LifePrintRecord = LifePrint
