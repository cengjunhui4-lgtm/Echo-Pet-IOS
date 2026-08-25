import Foundation
import UIKit
import XCTest
@testable import EchoPet

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testSavingFirstPetProfileCreatesStarterMessageAndPersists() {
        let repository = InMemoryEchoRepository()
        let viewModel = HomeViewModel(repository: repository)
        let profile = PetProfile(
            name: "Lucky",
            species: "Dog",
            breed: "Mixed",
            age: "6",
            personality: "温柔、好奇",
            mbti: "ENFP",
            favoriteThings: ["蓝色球"],
            habits: ["等门"]
        )

        viewModel.savePetProfile(profile)

        XCTAssertEqual(viewModel.pet?.name, "Lucky")
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.isAIGenerated, true)
        XCTAssertTrue(viewModel.messages.first?.text.contains(EchoAIContent.companionDisclaimer) == true)
        XCTAssertEqual(repository.lastSavedState?.pet?.name, "Lucky")
    }

    func testDeletingPetProfileClearsOwnedLocalState() {
        let pet = PetProfile(
            name: "Momo",
            breed: "Golden Retriever",
            age: "7",
            personality: "安静",
            mbti: "ISFP",
            favoriteThings: [],
            habits: []
        )
        let repository = InMemoryEchoRepository(
            state: EchoAppState(
                pet: pet,
                timeline: [
                    TimelineEvent(date: Date(), title: "回家", story: "很安静。", imageSystemName: "house.fill")
                ],
                messages: [
                    ChatMessage(text: "你好", isUser: true, timestamp: Date())
                ],
                capsules: [
                    MemoryCapsule(title: "早晨", dateLabel: "今天", body: "阳光很好。", accentSystemName: "sun.max.fill")
                ],
                lifePrint: LifePrint(summary: "Momo 喜欢陪伴。", updatedAt: Date())
            )
        )
        let viewModel = HomeViewModel(repository: repository)

        viewModel.deletePetProfileAndContent()

        XCTAssertNil(viewModel.pet)
        XCTAssertTrue(viewModel.dailyTasks.isEmpty)
        XCTAssertTrue(viewModel.timeline.isEmpty)
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertTrue(viewModel.capsules.isEmpty)
        XCTAssertNil(viewModel.lifePrint)
        XCTAssertTrue(repository.didClearState)
    }

    func testGenerateLifePrintUsesSelectedEnglishCopy() async {
        let pet = PetProfile(
            name: "Momo",
            breed: "Golden Retriever",
            age: "7",
            personality: "gentle",
            mbti: "ISFP",
            favoriteThings: ["sunny window"],
            habits: ["waits by the door"]
        )
        let repository = InMemoryEchoRepository(
            state: EchoAppState(
                pet: pet,
                timeline: [
                    TimelineEvent(date: Date(), title: "Quiet Morning", story: "Sunlight stayed near.", imageSystemName: "sun.max.fill")
                ],
                messages: [],
                capsules: [],
                lifePrint: nil
            )
        )
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.generateLifePrint(language: .en)

        XCTAssertTrue(viewModel.lifePrint?.summary.contains("Momo is a gentle companion.") == true)
        XCTAssertTrue(viewModel.lifePrint?.summary.contains("Quiet Morning") == true)
    }

    func testLoadingDemoDataReplacesDirtyStateAndPersistsSelectedLanguageSeed() {
        let repository = InMemoryEchoRepository(
            state: EchoAppState(
                pet: PetProfile(
                    name: "1",
                    breed: "1",
                    age: "1",
                    personality: "1",
                    mbti: "1",
                    favoriteThings: [],
                    habits: []
                ),
                timeline: [],
                messages: [],
                capsules: [],
                lifePrint: nil
            )
        )
        let viewModel = HomeViewModel(repository: repository)

        viewModel.loadDemoData(language: .en)

        XCTAssertEqual(viewModel.pet?.name, "Momo")
        XCTAssertEqual(viewModel.dailyTasks.count, 3)
        XCTAssertEqual(viewModel.timeline.count, 1)
        XCTAssertEqual(viewModel.capsules.count, 1)
        XCTAssertNotNil(viewModel.lifePrint)
        XCTAssertTrue(viewModel.messages.first?.text.contains(EchoAIContent.companionDisclaimer(language: .en)) == true)
        XCTAssertEqual(repository.lastSavedState?.pet?.name, "Momo")
    }

    func testLocalAccountSessionCanBeCreatedAndSignedOut() {
        let repository = InMemoryEchoRepository()
        let viewModel = HomeViewModel(repository: repository)

        viewModel.createLocalAccountSession(language: .en)

        XCTAssertEqual(viewModel.accountSession?.displayName, "Local Account Archive")
        XCTAssertEqual(viewModel.syncReadiness.state, .readyForBackend)
        XCTAssertEqual(repository.lastSavedState?.accountSession?.provider, .localPreview)

        viewModel.signOutAccount()

        XCTAssertNil(viewModel.accountSession)
        XCTAssertEqual(viewModel.syncReadiness.state, .localOnly)
        XCTAssertNil(repository.lastSavedState?.accountSession)
    }

    func testSyncReadinessSummarizesLocalBackendBoundaries() {
        let pet = PetProfile(
            name: "Momo",
            breed: "Golden Retriever",
            age: "7",
            personality: "gentle",
            mbti: "ISFP",
            favoriteThings: [],
            habits: []
        )
        let repository = InMemoryEchoRepository(
            state: EchoAppState(
                accountSession: AccountSession(displayName: "Local Account Archive"),
                pet: pet,
                timeline: [
                    TimelineEvent(
                        petID: pet.id,
                        date: Date(timeIntervalSince1970: 1),
                        title: "Morning",
                        story: "Soft light.",
                        imageSystemName: "sun.max.fill",
                        mediaAssets: [
                            MediaAsset(kind: .photo, storageKey: "Media/a.jpg"),
                            MediaAsset(kind: .photo, storageKey: "Media/b.jpg")
                        ]
                    )
                ],
                messages: [
                    ChatMessage(text: "hello", isUser: true, timestamp: Date(timeIntervalSince1970: 1))
                ],
                capsules: [
                    MemoryCapsule(title: "Capsule", dateLabel: "Today", body: "Body", accentSystemName: "heart.fill")
                ],
                lifePrint: LifePrint(summary: "Summary", updatedAt: Date(timeIntervalSince1970: 1))
            )
        )
        let viewModel = HomeViewModel(repository: repository)

        let readiness = viewModel.syncReadiness

        XCTAssertEqual(readiness.state, .readyForBackend)
        XCTAssertEqual(readiness.queuedChangeCount, 8)
        XCTAssertEqual(
            readiness.activeDomains,
            [.account, .petProfile, .memoryFiles, .lifePrint, .timeline, .memoryCapsules, .companion]
        )
    }

    func testDailyTaskPlanCanBeAddedCompletedEditedAndDeleted() {
        let pet = PetProfile(
            name: "Momo",
            breed: "Golden Retriever",
            age: "7",
            personality: "gentle",
            mbti: "ISFP",
            favoriteThings: [],
            habits: []
        )
        let repository = InMemoryEchoRepository(
            state: EchoAppState(
                pet: pet,
                timeline: [],
                messages: [],
                capsules: [],
                lifePrint: nil
            )
        )
        let viewModel = HomeViewModel(repository: repository)
        let dueAt = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())

        viewModel.saveDailyTask(
            DailyCareTask(
                title: "Play together",
                note: "Use the blue ball.",
                dueAt: dueAt,
                template: .play
            )
        )

        let savedTask = viewModel.todaysDailyTasks[0]
        XCTAssertEqual(savedTask.petID, pet.id)
        XCTAssertEqual(savedTask.title, "Play together")
        XCTAssertEqual(savedTask.template, .play)
        XCTAssertEqual(repository.lastSavedState?.dailyTasks.count, 1)

        viewModel.toggleDailyTaskCompletion(savedTask)

        let completedTask = viewModel.todaysDailyTasks[0]
        XCTAssertTrue(completedTask.isCompleted)
        XCTAssertEqual(viewModel.completedTodayTaskCount, 1)

        viewModel.saveDailyTask(
            DailyCareTask(
                id: completedTask.id,
                petID: completedTask.petID,
                title: "Brush gently",
                note: "Keep it short.",
                dueAt: completedTask.dueAt,
                date: completedTask.date,
                template: .grooming,
                isCompleted: completedTask.isCompleted,
                createdAt: completedTask.createdAt
            )
        )

        let editedTask = viewModel.todaysDailyTasks[0]
        XCTAssertEqual(editedTask.title, "Brush gently")
        XCTAssertEqual(editedTask.note, "Keep it short.")
        XCTAssertEqual(editedTask.template, .grooming)

        viewModel.deleteDailyTask(editedTask)

        XCTAssertTrue(viewModel.todaysDailyTasks.isEmpty)
        XCTAssertTrue(repository.lastSavedState?.dailyTasks.isEmpty == true)
    }

    func testDailyPetGreetingIsStableForTheSameDateAndIncludesPetName() {
        let pet = PetProfile(
            name: "豆包",
            breed: "狸花猫",
            age: "4 岁",
            personality: "亲人",
            mbti: "温柔观察型",
            favoriteThings: [],
            habits: []
        )
        let repository = InMemoryEchoRepository(
            state: EchoAppState(
                pet: pet,
                timeline: [],
                messages: [],
                capsules: [],
                lifePrint: nil
            )
        )
        let viewModel = HomeViewModel(repository: repository)
        let date = Date(timeIntervalSince1970: 1_786_080_000)

        let firstGreeting = viewModel.dailyPetGreeting(language: .zhHans, date: date)
        let secondGreeting = viewModel.dailyPetGreeting(language: .zhHans, date: date)

        XCTAssertEqual(firstGreeting, secondGreeting)
        XCTAssertTrue(firstGreeting.contains("豆包"))
    }

    func testAIContextBuilderIncludesPetLifePrintTimelineDailyTasksAndChatHistory() throws {
        let pet = PetProfile(
            name: "豆包",
            species: "猫",
            breed: "狸花猫",
            age: "4 岁",
            relationshipLabel: "家人",
            personality: "亲人、安静、好奇",
            mbti: "温柔观察型",
            favoriteThings: ["窗边晒太阳"],
            habits: ["听到钥匙声就跑来"]
        )
        let memoryID = UUID()
        let messageID = UUID()
        let context = try XCTUnwrap(
            AIContextBuilder().build(
                pet: pet,
                lifePrint: LifePrint(
                    summary: "豆包喜欢安静陪伴。",
                    updatedAt: Date(timeIntervalSince1970: 2),
                    personalityTraits: ["亲人"],
                    favoriteThings: ["窗边晒太阳"],
                    habits: ["等钥匙声"],
                    sourceMemoryIDs: [memoryID],
                    isAIGenerated: true
                ),
                timeline: [
                    TimelineEvent(
                        petID: pet.id,
                        memoryID: memoryID,
                        date: Date(timeIntervalSince1970: 1),
                        title: "第一次回家",
                        story: "豆包慢慢靠近你的手。",
                        imageSystemName: "house.fill",
                        mediaAssets: [
                            MediaAsset(kind: .photo, storageKey: "Media/home.jpg")
                        ]
                    )
                ],
                dailyTasks: [
                    DailyCareTask(petID: pet.id, title: "换水", note: "清洗水碗", template: .feeding)
                ],
                messages: [
                    ChatMessage(id: messageID, text: "我想你", isUser: true, timestamp: Date(timeIntervalSince1970: 3))
                ],
                settings: .default,
                now: Date(timeIntervalSince1970: 4)
            )
        )

        XCTAssertEqual(context.pet.name, "豆包")
        XCTAssertEqual(context.lifePrint?.personalityTraits, ["亲人"])
        XCTAssertEqual(context.timelineMemories.first?.title, "第一次回家")
        XCTAssertEqual(context.timelineMemories.first?.mediaAssetCount, 1)
        XCTAssertEqual(context.timelineMemories.first?.sourceMemoryIDs, [memoryID])
        XCTAssertEqual(context.dailyTasks.first?.title, "换水")
        XCTAssertEqual(context.recentMessages.first?.id, messageID)
        XCTAssertTrue(context.privacy.usesPetProfile)
        XCTAssertTrue(context.privacy.usesLifePrint)
        XCTAssertTrue(context.privacy.usesTimeline)
        XCTAssertTrue(context.privacy.usesDailyTasks)
        XCTAssertTrue(context.privacy.usesChatHistory)
    }

    func testAIContextBuilderReturnsNilWhenMemoryUsageIsDisabled() {
        let pet = PetProfile(
            name: "Momo",
            breed: "Golden Retriever",
            age: "7",
            personality: "gentle",
            mbti: "Warm observer",
            favoriteThings: [],
            habits: []
        )

        let context = AIContextBuilder().build(
            pet: pet,
            lifePrint: nil,
            timeline: [],
            dailyTasks: [],
            messages: [],
            settings: AICompanionSettings(allowsMemoryContext: false),
            language: .en
        )

        XCTAssertNil(context)
    }

    func testAICompanionMemorySettingCanBeDisabledAndPersisted() {
        let repository = InMemoryEchoRepository()
        let viewModel = HomeViewModel(repository: repository)

        viewModel.setAICompanionMemoryContextEnabled(false)

        XCTAssertFalse(viewModel.aiCompanionSettings.allowsMemoryContext)
        XCTAssertFalse(repository.lastSavedState?.aiCompanionSettings.allowsMemoryContext ?? true)

        viewModel.setAICompanionMemoryContextEnabled(true)

        XCTAssertTrue(viewModel.aiCompanionSettings.allowsMemoryContext)
        XCTAssertTrue(repository.lastSavedState?.aiCompanionSettings.allowsMemoryContext == true)
    }

    func testSendingCompanionMessageUsesMemoryContextWhenAllowed() async {
        let pet = PetProfile(
            name: "豆包",
            species: "猫",
            breed: "狸花猫",
            age: "4 岁",
            relationshipLabel: "家人",
            personality: "亲人、安静、好奇",
            mbti: "温柔观察型",
            favoriteThings: ["窗边晒太阳"],
            habits: ["听到钥匙声就跑来"]
        )
        let memoryID = UUID()
        let repository = InMemoryEchoRepository(
            state: EchoAppState(
                pet: pet,
                dailyTasks: [
                    DailyCareTask(petID: pet.id, title: "换一碗新鲜水", template: .feeding)
                ],
                timeline: [
                    TimelineEvent(
                        petID: pet.id,
                        memoryID: memoryID,
                        date: Date(timeIntervalSince1970: 1),
                        title: "第一次回家",
                        story: "豆包慢慢靠近你的手。",
                        imageSystemName: "house.fill"
                    )
                ],
                messages: [
                    ChatMessage(text: "欢迎回来", isUser: false, timestamp: Date(timeIntervalSince1970: 1), isAIGenerated: true)
                ],
                capsules: [],
                lifePrint: LifePrint(
                    summary: "豆包喜欢安静陪伴。",
                    updatedAt: Date(timeIntervalSince1970: 1),
                    personalityTraits: ["亲人、安静"]
                )
            )
        )
        let viewModel = HomeViewModel(repository: repository)

        viewModel.draftMessage = "我有点想豆包"
        await viewModel.sendDraftMessage(language: .zhHans)

        let aiMessage = viewModel.messages.last
        XCTAssertEqual(viewModel.messages.count, 3)
        XCTAssertEqual(viewModel.messages[1].text, "我有点想豆包")
        XCTAssertTrue(aiMessage?.text.contains("第一次回家") == true)
        XCTAssertTrue(aiMessage?.text.contains(EchoAIContent.companionDisclaimer(language: .zhHans)) == true)
        XCTAssertEqual(aiMessage?.sourceMemoryIDs, [memoryID])
    }

    func testSendingCompanionMessageUsesBackendWhenAvailable() async {
        let pet = PetProfile(
            name: "豆包",
            species: "猫",
            breed: "狸花猫",
            age: "4 岁",
            relationshipLabel: "家人",
            personality: "亲人、安静、好奇",
            mbti: "温柔观察型",
            favoriteThings: ["窗边晒太阳"],
            habits: ["听到钥匙声就跑来"]
        )
        let memoryID = UUID()
        let backendClient = CapturingCompanionBackendClient(
            response: CompanionChatResponse(
                messageID: "backend-reply",
                reply: "后端已经读到豆包的记忆：第一次回家。",
                isAIGenerated: true,
                sourceMemoryIDs: [memoryID.uuidString],
                modelVersion: "deepseek-v4-flash-stub-v1"
            )
        )
        let repository = InMemoryEchoRepository(
            state: EchoAppState(
                pet: pet,
                dailyTasks: [
                    DailyCareTask(petID: pet.id, title: "换水", template: .feeding)
                ],
                timeline: [
                    TimelineEvent(
                        petID: pet.id,
                        memoryID: memoryID,
                        date: Date(timeIntervalSince1970: 1),
                        title: "第一次回家",
                        story: "豆包慢慢靠近你的手。",
                        imageSystemName: "house.fill"
                    )
                ],
                messages: [],
                capsules: [],
                lifePrint: LifePrint(summary: "豆包喜欢安静陪伴。", updatedAt: Date(timeIntervalSince1970: 1))
            )
        )
        let viewModel = HomeViewModel(
            repository: repository,
            companionService: CompanionReplyService(
                backendClient: backendClient,
                localResponseDelayNanoseconds: 0
            )
        )

        viewModel.draftMessage = "我有点想豆包"
        await viewModel.sendDraftMessage(language: .zhHans)

        XCTAssertEqual(viewModel.companionConnectionState, .backendConnected)
        XCTAssertEqual(backendClient.capturedPetID, pet.id)
        XCTAssertEqual(backendClient.capturedRequest?.context?.pet.name, "豆包")
        XCTAssertEqual(backendClient.capturedRequest?.context?.timelineMemories.first?.memoryID, memoryID)
        XCTAssertTrue(viewModel.messages.last?.text.contains("后端已经读到豆包的记忆") == true)
        XCTAssertTrue(viewModel.messages.last?.text.contains(EchoAIContent.companionDisclaimer(language: .zhHans)) == true)
        XCTAssertEqual(viewModel.messages.last?.sourceMemoryIDs, [memoryID])
    }

    func testSendingCompanionMessageFallsBackWhenBackendIsUnavailable() async {
        let pet = PetProfile(
            name: "豆包",
            breed: "狸花猫",
            age: "4 岁",
            personality: "亲人、安静",
            mbti: "温柔观察型",
            favoriteThings: [],
            habits: []
        )
        let repository = InMemoryEchoRepository(
            state: EchoAppState(
                pet: pet,
                timeline: [],
                messages: [],
                capsules: [],
                lifePrint: nil
            )
        )
        let viewModel = HomeViewModel(
            repository: repository,
            companionService: CompanionReplyService(
                backendClient: FailingCompanionBackendClient(),
                localResponseDelayNanoseconds: 0
            )
        )

        viewModel.draftMessage = "谢谢你"
        await viewModel.sendDraftMessage(language: .zhHans)

        XCTAssertEqual(viewModel.companionConnectionState, .backendUnavailable)
        XCTAssertTrue(viewModel.messages.last?.text.contains(EchoAIContent.companionDisclaimer(language: .zhHans)) == true)
    }

    func testBackgroundAlbumCanImportSelectCycleAndDeleteLocalPhotos() throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("EchoPetBackgroundMediaTests-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: temporaryRoot)
        }

        let mediaStore = LocalMediaStore(
            fileManager: .default,
            baseDirectoryURL: temporaryRoot
        )
        let repository = InMemoryEchoRepository()
        let viewModel = HomeViewModel(repository: repository, mediaStore: mediaStore)
        let data = try XCTUnwrap(makeTestImageData())

        let firstPhoto = try viewModel.importBackgroundPhotoData(data)
        XCTAssertEqual(viewModel.backgroundAlbum.selectedPhotoID, firstPhoto.id)
        XCTAssertEqual(viewModel.activeBackgroundPhoto()?.id, firstPhoto.id)

        let secondPhoto = try viewModel.importBackgroundPhotoData(data)
        let firstURL = try XCTUnwrap(mediaStore.fileURL(for: firstPhoto.asset))
        let secondURL = try XCTUnwrap(mediaStore.fileURL(for: secondPhoto.asset))

        XCTAssertTrue(FileManager.default.fileExists(atPath: firstURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondURL.path))
        XCTAssertEqual(viewModel.backgroundAlbum.photos.count, 2)
        XCTAssertEqual(viewModel.backgroundAlbum.selectedPhotoID, secondPhoto.id)
        XCTAssertEqual(viewModel.activeBackgroundPhoto()?.id, secondPhoto.id)

        viewModel.setFixedBackgroundPhoto(firstPhoto)
        viewModel.setBackgroundDisplayMode(.gentleCycle)

        XCTAssertEqual(viewModel.activeBackgroundPhoto(cycleIndex: 0)?.id, firstPhoto.id)
        XCTAssertEqual(viewModel.activeBackgroundPhoto(cycleIndex: 1)?.id, secondPhoto.id)

        viewModel.setFixedBackgroundPhoto(secondPhoto)
        viewModel.setBackgroundBlurRadius(40)
        viewModel.setBackgroundPhotoRotation(firstPhoto, isIncluded: false)

        XCTAssertEqual(viewModel.backgroundAlbum.displayMode, .fixed)
        XCTAssertEqual(viewModel.activeBackgroundPhoto()?.id, secondPhoto.id)
        XCTAssertEqual(viewModel.backgroundAlbum.blurRadius, 32)
        XCTAssertFalse(viewModel.backgroundAlbum.photos.first?.isIncludedInRotation == true)

        viewModel.deleteBackgroundPhoto(secondPhoto)

        XCTAssertFalse(FileManager.default.fileExists(atPath: secondURL.path))
        XCTAssertEqual(viewModel.backgroundAlbum.selectedPhotoID, firstPhoto.id)

        viewModel.resetBackgroundAlbum()

        XCTAssertFalse(FileManager.default.fileExists(atPath: firstURL.path))
        XCTAssertTrue(viewModel.backgroundAlbum.photos.isEmpty)
        XCTAssertTrue(repository.lastSavedState?.backgroundAlbum.photos.isEmpty == true)
    }

    func testActiveBackgroundSkipsMissingSelectedPhotoFile() throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("EchoPetMissingBackgroundMediaTests-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: temporaryRoot)
        }

        let mediaStore = LocalMediaStore(
            fileManager: .default,
            baseDirectoryURL: temporaryRoot
        )
        let data = try XCTUnwrap(makeTestImageData())
        let availableAsset = try mediaStore.savePhotoData(data)
        let missingPhoto = BackgroundAlbumPhoto(
            asset: MediaAsset(kind: .photo, storageKey: "Media/missing-background.jpg")
        )
        let availablePhoto = BackgroundAlbumPhoto(asset: availableAsset)
        let repository = InMemoryEchoRepository(
            state: EchoAppState(
                backgroundAlbum: BackgroundAlbumSettings(
                    photos: [missingPhoto, availablePhoto],
                    selectedPhotoID: missingPhoto.id,
                    displayMode: .fixed,
                    blurRadius: 10
                ),
                timeline: [],
                messages: [],
                capsules: [],
                lifePrint: nil
            )
        )
        let viewModel = HomeViewModel(repository: repository, mediaStore: mediaStore)

        XCTAssertEqual(viewModel.activeBackgroundPhoto()?.id, availablePhoto.id)
    }

    func testEditingTimelineMemoryDeletesRemovedPhotoFiles() throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("EchoPetTimelineMediaTests-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: temporaryRoot)
        }

        let mediaStore = LocalMediaStore(
            fileManager: .default,
            baseDirectoryURL: temporaryRoot
        )
        let data = try XCTUnwrap(makeTestImageData())
        let retainedAsset = try mediaStore.savePhotoData(data)
        let removedAsset = try mediaStore.savePhotoData(data)
        let retainedURL = try XCTUnwrap(mediaStore.fileURL(for: retainedAsset))
        let removedURL = try XCTUnwrap(mediaStore.fileURL(for: removedAsset))
        let memoryID = UUID()
        let memory = TimelineEvent(
            id: memoryID,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            title: "Morning",
            story: "Soft light by the window.",
            imageSystemName: "sun.max.fill",
            mediaAssets: [retainedAsset, removedAsset]
        )
        let repository = InMemoryEchoRepository(
            state: EchoAppState(
                pet: nil,
                timeline: [memory],
                messages: [],
                capsules: [],
                lifePrint: nil
            )
        )
        let viewModel = HomeViewModel(repository: repository, mediaStore: mediaStore)

        let updatedMemory = TimelineEvent(
            id: memoryID,
            date: memory.date,
            title: memory.title,
            story: memory.story,
            imageSystemName: memory.imageSystemName,
            mediaAssets: [retainedAsset]
        )
        viewModel.saveTimelineMemory(updatedMemory)

        XCTAssertTrue(FileManager.default.fileExists(atPath: retainedURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: removedURL.path))
        XCTAssertEqual(repository.lastSavedState?.timeline.first?.mediaAssets, [retainedAsset])
    }
}

private final class CapturingCompanionBackendClient: CompanionBackendClient {
    let response: CompanionChatResponse
    private(set) var capturedPetID: UUID?
    private(set) var capturedRequest: CompanionChatRequest?

    init(response: CompanionChatResponse) {
        self.response = response
    }

    func companionChat(petID: UUID, request: CompanionChatRequest) async throws -> CompanionChatResponse {
        capturedPetID = petID
        capturedRequest = request
        return response
    }
}

private struct FailingCompanionBackendClient: CompanionBackendClient {
    func companionChat(petID: UUID, request: CompanionChatRequest) async throws -> CompanionChatResponse {
        throw EchoAPIClientError.backendNotConnected(.companionChat(petID))
    }
}

private final class InMemoryEchoRepository: EchoRepository {
    private var state: EchoAppState
    private(set) var lastSavedState: EchoAppState?
    private(set) var didClearState = false

    init(state: EchoAppState = .empty) {
        self.state = state
    }

    func loadState() -> EchoAppState {
        state
    }

    func saveState(_ state: EchoAppState) {
        self.state = state
        lastSavedState = state
    }

    func syncState(_ state: EchoAppState) async throws {}

    func clearState() {
        state = .empty
        didClearState = true
    }

    func loadDemoState(language: AppLanguage) -> EchoAppState {
        let pet = PetProfile(
            name: language == .en ? "Momo" : "豆包",
            breed: language == .en ? "Golden Retriever" : "狸花猫",
            age: language == .en ? "7 years" : "4 岁",
            personality: language == .en ? "Gentle" : "亲人",
            mbti: language == .en ? "Warm observer" : "温柔观察型",
            favoriteThings: [],
            habits: []
        )

        return EchoAppState(
            pet: pet,
            dailyTasks: [
                DailyCareTask(title: language == .en ? "Refresh water" : "换水", template: .feeding),
                DailyCareTask(title: language == .en ? "Play together" : "陪玩", template: .play),
                DailyCareTask(title: language == .en ? "Take a photo" : "拍照", template: .photo, isCompleted: true)
            ],
            timeline: [
                TimelineEvent(date: Date(timeIntervalSince1970: 1), title: language == .en ? "First Day Home" : "第一次回家", story: "story", imageSystemName: "house.fill")
            ],
            messages: loadStarterMessages(petName: pet.name, language: language),
            capsules: [
                MemoryCapsule(title: language == .en ? "Demo Capsule" : "演示胶囊", dateLabel: "Today", body: "body", accentSystemName: "heart.fill")
            ],
            lifePrint: LifePrint(summary: language == .en ? "Demo LifePrint" : "演示生命印记", updatedAt: Date(timeIntervalSince1970: 1))
        )
    }

    func loadStarterMessages(petName: String, language: AppLanguage) -> [ChatMessage] {
        [
            ChatMessage(
                text: EchoAIContent.normalizeCompanionReply(
                    L10n.text(.companionStarterMessage, language: language, petName),
                    language: language
                ),
                isUser: false,
                timestamp: Date(timeIntervalSince1970: 1),
                isAIGenerated: true
            )
        ]
    }

    func makeGeneratedCapsule(petName: String) -> MemoryCapsule {
        MemoryCapsule(
            title: "\(petName) 的测试胶囊",
            dateLabel: "今天",
            body: "用于测试。",
            accentSystemName: "heart.fill"
        )
    }
}

private func makeTestImageData() -> Data? {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
    let image = renderer.image { context in
        UIColor.systemTeal.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
    }
    return image.pngData()
}
