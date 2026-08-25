import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct EchoAppState: Codable {
    var accountSession: AccountSession? = nil
    var pet: PetProfile?
    var dailyTasks: [DailyCareTask]
    var backgroundAlbum: BackgroundAlbumSettings
    var timeline: [TimelineMemory]
    var messages: [ChatMessage]
    var capsules: [MemoryCapsule]
    var lifePrint: LifePrintRecord?
    var aiCompanionSettings: AICompanionSettings

    static let empty = EchoAppState(
        accountSession: nil,
        pet: nil,
        dailyTasks: [],
        backgroundAlbum: .empty,
        timeline: [],
        messages: [],
        capsules: [],
        lifePrint: nil,
        aiCompanionSettings: .default
    )

    init(
        accountSession: AccountSession? = nil,
        pet: PetProfile? = nil,
        dailyTasks: [DailyCareTask] = [],
        backgroundAlbum: BackgroundAlbumSettings = .empty,
        timeline: [TimelineMemory],
        messages: [ChatMessage],
        capsules: [MemoryCapsule],
        lifePrint: LifePrintRecord?,
        aiCompanionSettings: AICompanionSettings = .default
    ) {
        self.accountSession = accountSession
        self.pet = pet
        self.dailyTasks = dailyTasks
        self.backgroundAlbum = backgroundAlbum
        self.timeline = timeline
        self.messages = messages
        self.capsules = capsules
        self.lifePrint = lifePrint
        self.aiCompanionSettings = aiCompanionSettings
    }

    private enum CodingKeys: String, CodingKey {
        case accountSession
        case pet
        case dailyTasks
        case backgroundAlbum
        case timeline
        case messages
        case capsules
        case lifePrint
        case aiCompanionSettings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountSession = try container.decodeIfPresent(AccountSession.self, forKey: .accountSession)
        pet = try container.decodeIfPresent(PetProfile.self, forKey: .pet)
        dailyTasks = try container.decodeIfPresent([DailyCareTask].self, forKey: .dailyTasks) ?? []
        backgroundAlbum = try container.decodeIfPresent(BackgroundAlbumSettings.self, forKey: .backgroundAlbum) ?? .empty
        timeline = try container.decodeIfPresent([TimelineMemory].self, forKey: .timeline) ?? []
        messages = try container.decodeIfPresent([ChatMessage].self, forKey: .messages) ?? []
        capsules = try container.decodeIfPresent([MemoryCapsule].self, forKey: .capsules) ?? []
        lifePrint = try container.decodeIfPresent(LifePrintRecord.self, forKey: .lifePrint)
        aiCompanionSettings = try container.decodeIfPresent(AICompanionSettings.self, forKey: .aiCompanionSettings) ?? .default
    }
}

final class LocalDataStore {
    static let shared = LocalDataStore()

    private let fileManager: FileManager
    private let legacyDefaults: UserDefaults
    private let baseDirectoryURL: URL?
    private let legacyKey = "echoPet.appState.v1"
    private let databaseFileName = "echo_pet_db.json"
    private let directoryName = "EchoPet"

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let legacyDecoder = JSONDecoder()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    init(
        fileManager: FileManager = .default,
        legacyDefaults: UserDefaults = .standard,
        baseDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.legacyDefaults = legacyDefaults
        self.baseDirectoryURL = baseDirectoryURL
    }

    var databaseURL: URL {
        databaseDirectoryURL.appendingPathComponent(databaseFileName)
    }

    func load() -> EchoAppState {
        if fileManager.fileExists(atPath: databaseURL.path) {
            return loadFromJSONDatabase()
        }

        if let migrated = loadLegacyDefaultsState() {
            save(migrated)
            legacyDefaults.removeObject(forKey: legacyKey)
            return migrated
        }

        save(.empty)
        return .empty
    }

    func save(_ state: EchoAppState) {
        do {
            try createDatabaseDirectoryIfNeeded()
            let data = try encoder.encode(state)
            try data.write(to: databaseURL, options: [.atomic])
        } catch {
            assertionFailure("Failed to save EchoPet JSON database: \(error.localizedDescription)")
        }
    }

    func clear() {
        if fileManager.fileExists(atPath: databaseURL.path) {
            try? fileManager.removeItem(at: databaseURL)
        }
        legacyDefaults.removeObject(forKey: legacyKey)
        save(.empty)
    }

    private var databaseDirectoryURL: URL {
        if let baseDirectoryURL {
            return baseDirectoryURL.appendingPathComponent(directoryName, isDirectory: true)
        }

        let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return supportURL.appendingPathComponent(directoryName, isDirectory: true)
    }

    private func loadFromJSONDatabase() -> EchoAppState {
        do {
            let data = try Data(contentsOf: databaseURL)
            return try decoder.decode(EchoAppState.self, from: data)
        } catch {
            moveInvalidDatabaseAside()
            return .empty
        }
    }

    private func loadLegacyDefaultsState() -> EchoAppState? {
        guard let data = legacyDefaults.data(forKey: legacyKey) else {
            return nil
        }

        return try? legacyDecoder.decode(EchoAppState.self, from: data)
    }

    private func createDatabaseDirectoryIfNeeded() throws {
        try fileManager.createDirectory(
            at: databaseDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    private func moveInvalidDatabaseAside() {
        let backupURL = databaseURL.deletingPathExtension().appendingPathExtension("invalid.json")
        try? fileManager.removeItem(at: backupURL)
        try? fileManager.moveItem(at: databaseURL, to: backupURL)
    }
}

enum LocalMediaStoreError: Error {
    case invalidImageData
}

final class LocalMediaStore {
    static let shared = LocalMediaStore()

    private let fileManager: FileManager
    private let baseDirectoryURL: URL?
    private let directoryName = "EchoPet"
    private let mediaDirectoryName = "Media"

    init(
        fileManager: FileManager = .default,
        baseDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.baseDirectoryURL = baseDirectoryURL
    }

    func savePhotoData(_ data: Data) throws -> MediaAsset {
        try createMediaDirectoryIfNeeded()
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = mediaDirectoryURL.appendingPathComponent(fileName)

#if canImport(UIKit)
        guard
            let image = UIImage(data: data),
            let jpegData = image.jpegData(compressionQuality: 0.86)
        else {
            throw LocalMediaStoreError.invalidImageData
        }
        try jpegData.write(to: fileURL, options: [.atomic])
#else
        try data.write(to: fileURL, options: [.atomic])
#endif

        return MediaAsset(
            kind: .photo,
            storageKey: "\(mediaDirectoryName)/\(fileName)"
        )
    }

    func fileURL(for asset: MediaAsset) -> URL? {
        guard let storageKey = asset.storageKey else {
            return nil
        }

        let fileName = storageKey
            .components(separatedBy: "/")
            .last ?? storageKey

        return mediaDirectoryURL.appendingPathComponent(fileName)
    }

    func delete(_ asset: MediaAsset) {
        guard let fileURL = fileURL(for: asset) else {
            return
        }

        try? fileManager.removeItem(at: fileURL)
    }

    func delete(_ assets: [MediaAsset]) {
        assets.forEach(delete)
    }

    private var mediaDirectoryURL: URL {
        if let baseDirectoryURL {
            return baseDirectoryURL
                .appendingPathComponent(directoryName, isDirectory: true)
                .appendingPathComponent(mediaDirectoryName, isDirectory: true)
        }

        let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return supportURL
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent(mediaDirectoryName, isDirectory: true)
    }

    private func createMediaDirectoryIfNeeded() throws {
        try fileManager.createDirectory(
            at: mediaDirectoryURL,
            withIntermediateDirectories: true
        )
    }
}
