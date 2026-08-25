import Foundation

protocol EchoRepository {
    func loadState() -> EchoAppState
    func saveState(_ state: EchoAppState)
    func syncState(_ state: EchoAppState) async throws
    func clearState()
    func loadDemoState(language: AppLanguage) -> EchoAppState
    func loadStarterMessages(petName: String, language: AppLanguage) -> [ChatMessage]
    func makeGeneratedCapsule(petName: String) -> MemoryCapsule
}

final class LocalEchoRepository: EchoRepository {
    private let dataService: DemoDataService
    private let store: LocalDataStore
    private let cloudSync: EchoCloudSyncing?

    init(
        dataService: DemoDataService = .shared,
        store: LocalDataStore = .shared,
        cloudSync: EchoCloudSyncing? = EchoCloudSyncService.shared
    ) {
        self.dataService = dataService
        self.store = store
        self.cloudSync = cloudSync
    }

    func loadState() -> EchoAppState {
        store.load()
    }

    func saveState(_ state: EchoAppState) {
        store.save(state)
    }

    func syncState(_ state: EchoAppState) async throws {
        try await cloudSync?.syncState(state, allowAnonymous: true)
    }

    func clearState() {
        store.clear()
    }

    func loadDemoState(language: AppLanguage) -> EchoAppState {
        dataService.loadDemoState(language: language)
    }

    func loadStarterMessages(petName: String, language: AppLanguage) -> [ChatMessage] {
        dataService.loadStarterMessages(petName: petName, language: language)
    }

    func makeGeneratedCapsule(petName: String) -> MemoryCapsule {
        dataService.makeGeneratedCapsule(petName: petName)
    }
}
