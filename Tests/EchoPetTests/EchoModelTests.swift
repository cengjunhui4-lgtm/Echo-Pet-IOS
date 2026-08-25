import Foundation
import XCTest
@testable import EchoPet

final class EchoModelTests: XCTestCase {
    func testCompanionDisclaimerIsAppendedOnce() {
        let reply = EchoAIContent.normalizeCompanionReply("我记住这段散步了。")

        XCTAssertTrue(reply.hasSuffix(EchoAIContent.companionDisclaimer))
        XCTAssertEqual(reply.components(separatedBy: EchoAIContent.companionDisclaimer).count, 2)

        let normalizedAgain = EchoAIContent.normalizeCompanionReply(reply)
        XCTAssertEqual(normalizedAgain, reply)
    }

    func testLocalizationTableReturnsChineseAndEnglishCopy() {
        XCTAssertEqual(L10n.text(.tabHome, language: .zhHans), "首页")
        XCTAssertEqual(L10n.text(.tabHome, language: .en), "Home")
        XCTAssertEqual(L10n.text(.commonEdit, language: .zhHans), "编辑")
        XCTAssertEqual(L10n.text(.commonEdit, language: .en), "Edit")
        XCTAssertEqual(L10n.text(.settingsLanguageTitle, language: .zhHans), "语言")
        XCTAssertEqual(L10n.text(.settingsLanguageTitle, language: .en), "Language")
        XCTAssertEqual(L10n.text(.profileAccountCreateLocal, language: .zhHans), "创建本地账号档案")
        XCTAssertEqual(L10n.text(.profileSyncReadyStatus, language: .en), "Ready for backend sync")
        XCTAssertEqual(L10n.text(.homeDailyTasksTitle, language: .zhHans), "今日陪伴计划")
        XCTAssertEqual(L10n.text(.dailyTaskTemplatePhoto, language: .en), "Photo")
        XCTAssertEqual(L10n.text(.profileAccountStats, language: .en, 1, 2, 3), "Pets 1 · Timeline 2 · Capsules 3")
        XCTAssertEqual(L10n.text(.timelineFormPhotoMaxReached, language: .zhHans), "已达到 9 张照片上限。删除一张后可以继续添加。")
        XCTAssertEqual(L10n.text(.timelineFormPhotoImportFailedMessage, language: .en, 2), "2 photos could not be imported. Try again or choose different photos.")
        XCTAssertEqual(L10n.text(.backgroundAlbumModeGentleCycle, language: .zhHans), "柔和轮换")
        XCTAssertEqual(L10n.text(.backgroundAlbumModeGentleCycle, language: .en), "Gentle Cycle")
        XCTAssertEqual(L10n.text(.settingsAIMemoryToggleTitle, language: .zhHans), "允许 AI 使用宠物记忆")
        XCTAssertEqual(L10n.text(.settingsAIToneCurrent, language: .en), "Default tone: gentle companion")
    }

    @MainActor
    func testLocalizationManagerPersistsSelectedLanguage() {
        let suiteName = "EchoPet.LocalizationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let manager = LocalizationManager(defaults: defaults)
        XCTAssertEqual(manager.language, .zhHans)

        manager.setLanguage(.en)

        let reloadedManager = LocalizationManager(defaults: defaults)
        XCTAssertEqual(reloadedManager.language, .en)
        XCTAssertEqual(reloadedManager.text(.settingsTitle), "Settings")
    }

    func testCompanionReplyUsesSelectedEnglishCopyAndDisclaimer() async throws {
        let service = CompanionReplyService()

        let reply = try await service.reply(to: "I miss Momo", petName: "Momo", language: .en)

        XCTAssertTrue(reply.contains("Momo"))
        XCTAssertTrue(reply.contains(EchoAIContent.companionDisclaimer(language: .en)))
        XCTAssertFalse(reply.contains(EchoAIContent.companionDisclaimer(language: .zhHans)))
    }

    func testSharedMemoryModelRoundTripsThroughJSON() throws {
        let petID = UUID()
        let occurredAt = Date(timeIntervalSince1970: 1_710_000_000)
        let createdAt = Date(timeIntervalSince1970: 1_710_000_100)
        let memory = Memory(
            petID: petID,
            title: "第一次回家",
            body: "它慢慢走进来，然后选中了那块软地毯。",
            occurredAt: occurredAt,
            kind: .photo,
            mediaAssets: [
                MediaAsset(kind: .photo, storageKey: "pets/\(petID.uuidString)/home.jpg")
            ],
            tags: ["home", "first-day"],
            emotionTags: ["calm"],
            isFavorite: true,
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(memory)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Memory.self, from: data)

        XCTAssertEqual(decoded, memory)
        XCTAssertEqual(decoded.mediaAssets.first?.storageKey, "pets/\(petID.uuidString)/home.jpg")
    }

    func testDailyCareTaskModelRoundTripsThroughJSON() throws {
        let dueAt = Date(timeIntervalSince1970: 1_780_000_000)
        let task = DailyCareTask(
            petID: UUID(),
            title: "Refresh water",
            note: "Clean the bowl too.",
            dueAt: dueAt,
            date: dueAt,
            template: .feeding,
            isCompleted: true,
            createdAt: dueAt,
            updatedAt: dueAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(task)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DailyCareTask.self, from: data)

        XCTAssertEqual(decoded, task)
        XCTAssertEqual(decoded.template, .feeding)
        XCTAssertTrue(decoded.isCompleted)
    }

    func testBackgroundAlbumSettingsRoundTripsThroughJSON() throws {
        let photoID = UUID()
        let asset = MediaAsset(kind: .photo, storageKey: "Media/background.jpg")
        let photo = BackgroundAlbumPhoto(
            id: photoID,
            asset: asset,
            isIncludedInRotation: true,
            createdAt: Date(timeIntervalSince1970: 1_780_000_000)
        )
        let settings = BackgroundAlbumSettings(
            photos: [photo],
            selectedPhotoID: photoID,
            displayMode: .gentleCycle,
            blurRadius: 14,
            updatedAt: Date(timeIntervalSince1970: 1_780_000_100)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(settings)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(BackgroundAlbumSettings.self, from: data)

        XCTAssertEqual(decoded, settings)
        XCTAssertEqual(decoded.displayMode, .gentleCycle)
        XCTAssertEqual(decoded.photos.first?.asset.storageKey, "Media/background.jpg")
    }

    func testAICompanionSettingsRoundTripsThroughJSON() throws {
        let settings = AICompanionSettings(
            allowsMemoryContext: false,
            tone: .gentleCompanion,
            updatedAt: Date(timeIntervalSince1970: 1_780_000_000)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(settings)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AICompanionSettings.self, from: data)

        XCTAssertEqual(decoded, settings)
        XCTAssertFalse(decoded.allowsMemoryContext)
        XCTAssertEqual(decoded.tone, .gentleCompanion)
    }

    func testTimelineEventDecodesLegacyJSONWithoutMediaAssets() throws {
        let id = UUID()
        let json = """
        {
          "id": "\(id.uuidString)",
          "date": "2024-03-12T00:00:00Z",
          "title": "Quiet Morning",
          "story": "A calm morning by the window.",
          "imageSystemName": "sun.max.fill"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let event = try decoder.decode(TimelineEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.id, id)
        XCTAssertEqual(event.title, "Quiet Morning")
        XCTAssertTrue(event.mediaAssets.isEmpty)
    }
}
