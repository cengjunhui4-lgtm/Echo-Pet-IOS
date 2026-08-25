import Foundation
import UIKit
import XCTest
@testable import EchoPet

final class LocalDataStoreTests: XCTestCase {
    private var temporaryRoot: URL!
    private var defaults: UserDefaults!
    private var defaultsSuiteName: String!

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("EchoPetTests-\(UUID().uuidString)", isDirectory: true)
        defaultsSuiteName = "EchoPetTests-\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuiteName))
    }

    override func tearDownWithError() throws {
        if let temporaryRoot {
            try? FileManager.default.removeItem(at: temporaryRoot)
        }
        defaults.removePersistentDomain(forName: defaultsSuiteName)
        temporaryRoot = nil
        defaults = nil
        defaultsSuiteName = nil
        try super.tearDownWithError()
    }

    func testSaveLoadAndClearJSONState() throws {
        let store = makeStore()
        let pet = PetProfile(
            name: "Lucky",
            species: "Dog",
            breed: "Shiba",
            age: "5",
            status: "alive",
            relationshipLabel: "owner",
            personality: "安静、敏感",
            mbti: "ISFP",
            favoriteThings: ["晒太阳"],
            habits: ["等在门口"]
        )
        let state = EchoAppState(
            pet: pet,
            dailyTasks: [
                DailyCareTask(
                    petID: pet.id,
                    title: "换水",
                    note: "清洗水碗",
                    dueAt: Date(timeIntervalSince1970: 1_700_010_000),
                    date: Date(timeIntervalSince1970: 1_700_000_000),
                    template: .feeding
                )
            ],
            backgroundAlbum: BackgroundAlbumSettings(
                photos: [
                    BackgroundAlbumPhoto(
                        asset: MediaAsset(kind: .photo, storageKey: "Media/background.jpg")
                    )
                ],
                displayMode: .dailyRandom,
                blurRadius: 12
            ),
            timeline: [
                TimelineEvent(
                    petID: pet.id,
                    date: Date(timeIntervalSince1970: 1_700_000_000),
                    title: "第一次回家",
                    story: "它慢慢靠近。",
                    imageSystemName: "house.fill"
                )
            ],
            messages: [
                ChatMessage(text: "你好", isUser: true, timestamp: Date())
            ],
            capsules: [],
            lifePrint: LifePrint(summary: "Lucky 喜欢安静陪伴。", updatedAt: Date(), isAIGenerated: true),
            aiCompanionSettings: AICompanionSettings(allowsMemoryContext: false)
        )

        store.save(state)

        let loaded = store.load()
        XCTAssertEqual(loaded.pet?.name, "Lucky")
        XCTAssertEqual(loaded.dailyTasks.count, 1)
        XCTAssertEqual(loaded.dailyTasks.first?.template, .feeding)
        XCTAssertEqual(loaded.backgroundAlbum.photos.count, 1)
        XCTAssertEqual(loaded.backgroundAlbum.displayMode, .dailyRandom)
        XCTAssertEqual(loaded.backgroundAlbum.blurRadius, 12)
        XCTAssertEqual(loaded.timeline.count, 1)
        XCTAssertEqual(loaded.messages.count, 1)
        XCTAssertEqual(loaded.lifePrint?.isAIGenerated, true)
        XCTAssertFalse(loaded.aiCompanionSettings.allowsMemoryContext)

        store.clear()
        let cleared = store.load()
        XCTAssertNil(cleared.pet)
        XCTAssertTrue(cleared.dailyTasks.isEmpty)
        XCTAssertTrue(cleared.backgroundAlbum.photos.isEmpty)
        XCTAssertTrue(cleared.timeline.isEmpty)
        XCTAssertTrue(cleared.messages.isEmpty)
        XCTAssertTrue(cleared.aiCompanionSettings.allowsMemoryContext)
    }

    func testLoadLegacyJSONStateWithoutAccountSession() throws {
        let store = makeStore()
        try FileManager.default.createDirectory(
            at: store.databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let legacyJSON = """
        {
          "pet": null,
          "timeline": [],
          "messages": [],
          "capsules": [],
          "lifePrint": null
        }
        """
        try Data(legacyJSON.utf8).write(to: store.databaseURL)

        let loaded = store.load()

        XCTAssertNil(loaded.accountSession)
        XCTAssertNil(loaded.pet)
        XCTAssertTrue(loaded.dailyTasks.isEmpty)
        XCTAssertTrue(loaded.backgroundAlbum.photos.isEmpty)
        XCTAssertTrue(loaded.timeline.isEmpty)
        XCTAssertTrue(loaded.aiCompanionSettings.allowsMemoryContext)
    }

    func testLocalMediaStoreSavesAndDeletesPhotoAsset() throws {
        let mediaStore = LocalMediaStore(
            fileManager: .default,
            baseDirectoryURL: temporaryRoot
        )
        let data = try XCTUnwrap(makeTestImageData())

        let asset = try mediaStore.savePhotoData(data)
        let fileURL = try XCTUnwrap(mediaStore.fileURL(for: asset))

        XCTAssertEqual(asset.kind, .photo)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        mediaStore.delete(asset)

        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    private func makeStore() -> LocalDataStore {
        LocalDataStore(
            fileManager: .default,
            legacyDefaults: defaults,
            baseDirectoryURL: temporaryRoot
        )
    }

    private func makeTestImageData() -> Data? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        let image = renderer.image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        return image.pngData()
    }
}
