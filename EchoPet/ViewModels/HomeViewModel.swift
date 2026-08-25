import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var accountSession: AccountSession?
    @Published private(set) var pet: PetProfile?
    @Published private(set) var dailyTasks: [DailyCareTask]
    @Published private(set) var backgroundAlbum: BackgroundAlbumSettings
    @Published private(set) var timeline: [TimelineMemory]
    @Published var messages: [ChatMessage]
    @Published private(set) var capsules: [MemoryCapsule]
    @Published private(set) var lifePrint: LifePrintRecord?
    @Published private(set) var aiCompanionSettings: AICompanionSettings
    @Published private(set) var companionConnectionState: CompanionConnectionState = .localOnly
    @Published var draftMessage = ""
    @Published private(set) var isSendingMessage = false
    @Published private(set) var isGeneratingLifePrint = false
    @Published private(set) var isSigningInAccount = false
    @Published private(set) var isSyncingToCloud = false
    @Published private(set) var isDeletingAccountData = false
    @Published var messageError: String?
    @Published var lifePrintError: String?
    @Published var accountError: String?
    @Published var accountMessage: String?
    @Published var dataDeletionError: String?

    private let repository: EchoRepository
    private let companionService: CompanionReplyService
    private let aiContextBuilder: AIContextBuilder
    private let mediaStore: LocalMediaStore
    private let authService: EchoSupabaseAuthService
    private var lastFailedMessage: String?

    init(
        repository: EchoRepository = LocalEchoRepository(),
        companionService: CompanionReplyService = CompanionReplyService(),
        aiContextBuilder: AIContextBuilder = AIContextBuilder(),
        mediaStore: LocalMediaStore = .shared,
        authService: EchoSupabaseAuthService = .shared
    ) {
        let state = repository.loadState()
        self.repository = repository
        self.companionService = companionService
        self.aiContextBuilder = aiContextBuilder
        self.mediaStore = mediaStore
        self.authService = authService
        accountSession = state.accountSession
        pet = state.pet
        dailyTasks = state.dailyTasks
        backgroundAlbum = state.backgroundAlbum
        timeline = state.timeline
        messages = state.messages
        capsules = state.capsules
        lifePrint = state.lifePrint
        aiCompanionSettings = state.aiCompanionSettings

        if accountSession == nil, let cloudSession = authService.storedSession() {
            accountSession = cloudSession.accountSession
        }
    }

    var hasPetProfile: Bool {
        pet != nil
    }

    var hasAccountSession: Bool {
        accountSession != nil
    }

    var todaysDailyTasks: [DailyCareTask] {
        let today = Date()
        let currentPetID = pet?.id
        return dailyTasks
            .filter { task in
                Calendar.current.isDate(task.date, inSameDayAs: today)
                    && (task.petID == nil || task.petID == currentPetID)
            }
            .sorted(by: sortDailyTasks)
    }

    var todayTaskCount: Int {
        todaysDailyTasks.count
    }

    var completedTodayTaskCount: Int {
        todaysDailyTasks.filter(\.isCompleted).count
    }

    func dailyPetGreeting(language: AppLanguage = .zhHans, date: Date = Date()) -> String {
        guard let pet else {
            return L10n.text(.homeDailyMoodFallback, language: language)
        }

        let keys: [L10n.Key] = [
            .homeDailyMoodMessage1,
            .homeDailyMoodMessage2,
            .homeDailyMoodMessage3,
            .homeDailyMoodMessage4,
            .homeDailyMoodMessage5
        ]
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let nameSeed = pet.name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let index = abs(day + nameSeed) % keys.count
        return L10n.text(keys[index], language: language, pet.name)
    }

    var syncReadiness: SyncReadinessSummary {
        var domains: [SyncDomain] = []
        var queuedChangeCount = 0

        if accountSession != nil {
            domains.append(.account)
            queuedChangeCount += 1
        }

        if pet != nil {
            domains.append(.petProfile)
            queuedChangeCount += 1
        }

        let mediaAssetCount = timeline.flatMap(\.mediaAssets).count
        if mediaAssetCount > 0 {
            domains.append(.memoryFiles)
            queuedChangeCount += mediaAssetCount
        }

        if lifePrint != nil {
            domains.append(.lifePrint)
            queuedChangeCount += 1
        }

        if !timeline.isEmpty {
            domains.append(.timeline)
            queuedChangeCount += timeline.count
        }

        if !capsules.isEmpty {
            domains.append(.memoryCapsules)
            queuedChangeCount += capsules.count
        }

        if !messages.isEmpty {
            domains.append(.companion)
            queuedChangeCount += messages.count
        }

        return SyncReadinessSummary(
            state: accountSession == nil ? .localOnly : .readyForBackend,
            queuedChangeCount: queuedChangeCount,
            activeDomains: domains
        )
    }

    func createLocalAccountSession(language: AppLanguage = .zhHans) {
        accountSession = AccountSession(
            displayName: L10n.text(.profileAccountLocalDisplayName, language: language)
        )
        saveState()
    }

    func continueAsGuest(language: AppLanguage = .zhHans) async {
        isSigningInAccount = true
        accountError = nil

        do {
            let session = try await authService.signInAnonymously()
            accountSession = session.accountSession
            saveState()
            await syncCurrentState()
        } catch {
            accountError = L10n.text(.profileAccountSignInFailed, language: language)
        }

        isSigningInAccount = false
    }

    func signInWithEmail(
        email: String,
        password: String,
        language: AppLanguage = .zhHans
    ) async {
        isSigningInAccount = true
        accountError = nil
        accountMessage = nil

        do {
            let session = try await authService.signInWithEmail(
                EmailPasswordAuthRequest(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )
            )
            accountSession = session.accountSession
            saveState()
            await syncCurrentState()
        } catch {
            accountError = L10n.text(.profileAccountSignInFailed, language: language)
        }

        isSigningInAccount = false
    }

    @discardableResult
    func signUpWithEmail(
        email: String,
        password: String,
        language: AppLanguage = .zhHans
    ) async -> Bool {
        isSigningInAccount = true
        accountError = nil
        accountMessage = nil
        defer {
            isSigningInAccount = false
        }

        do {
            let session = try await authService.signUpWithEmail(
                EmailPasswordAuthRequest(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )
            )
            accountSession = session.accountSession
            saveState()
            await syncCurrentState()
            return true
        } catch EchoSupabaseAuthError.emailConfirmationRequired {
            accountMessage = L10n.text(.profileAccountEmailConfirmationRequired, language: language)
            return true
        } catch {
            accountError = L10n.text(.profileAccountSignUpFailed, language: language)
            return false
        }
    }

    func verifyEmailSignupCode(
        email: String,
        code: String,
        language: AppLanguage = .zhHans
    ) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@"), !trimmedCode.isEmpty else {
            accountError = L10n.text(.profileAccountVerificationCodeRequired, language: language)
            return
        }

        isSigningInAccount = true
        accountError = nil
        accountMessage = nil

        do {
            let session = try await authService.verifyEmailSignupOTP(
                email: trimmedEmail,
                token: trimmedCode
            )
            accountSession = session.accountSession
            accountMessage = L10n.text(.profileAccountVerificationSuccess, language: language)
            saveState()
            await syncCurrentState()
        } catch {
            accountError = L10n.text(.profileAccountVerificationFailed, language: language)
        }

        isSigningInAccount = false
    }

    func resetPassword(email: String, language: AppLanguage = .zhHans) async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@") else {
            accountError = L10n.text(.profileAccountEmailHint, language: language)
            return
        }

        isSigningInAccount = true
        accountError = nil
        accountMessage = nil

        do {
            try await authService.resetPassword(forEmail: trimmed)
            accountMessage = L10n.text(.profileAccountResetSent, language: language)
        } catch {
            accountError = L10n.text(.profileAccountResetFailed, language: language)
        }

        isSigningInAccount = false
    }

    func completePasswordReset(
        email: String,
        code: String,
        newPassword: String,
        language: AppLanguage = .zhHans
    ) async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@"), !trimmedCode.isEmpty else {
            accountError = L10n.text(.profileAccountResetCodeRequired, language: language)
            return false
        }

        isSigningInAccount = true
        accountError = nil
        accountMessage = nil

        do {
            try await authService.resetPasswordWithOTP(
                email: trimmedEmail,
                token: trimmedCode,
                newPassword: newPassword
            )
            authService.signOut()
            accountSession = nil
            accountMessage = L10n.text(.passwordResetSuccess, language: language)
            isSigningInAccount = false
            return true
        } catch {
            accountError = L10n.text(.passwordResetFailed, language: language)
            isSigningInAccount = false
            return false
        }
    }

    func updatePassword(
        accessToken: String,
        newPassword: String,
        language: AppLanguage = .zhHans
    ) async -> Bool {
        accountError = nil
        accountMessage = nil

        do {
            try await authService.updatePassword(
                accessToken: accessToken,
                newPassword: newPassword
            )
            authService.signOut()
            accountSession = nil
            accountMessage = L10n.text(.passwordResetSuccess, language: language)
            return true
        } catch {
            accountError = L10n.text(.passwordResetFailed, language: language)
            return false
        }
    }

    func signOutAccount() {
        authService.signOut()
        accountSession = nil
        saveState()
    }

#if DEBUG
    func clearAccountForDebugPreview() {
        authService.signOut()
        accountSession = nil
        repository.saveState(currentState())
    }
#endif

    func setAICompanionMemoryContextEnabled(_ isEnabled: Bool) {
        var nextSettings = aiCompanionSettings
        nextSettings.allowsMemoryContext = isEnabled
        nextSettings.updatedAt = Date()
        aiCompanionSettings = nextSettings
        saveState()
    }

    func saveDailyTask(_ task: DailyCareTask) {
        var nextTask = task
        nextTask.petID = task.petID ?? pet?.id
        nextTask.updatedAt = Date()

        if let index = dailyTasks.firstIndex(where: { $0.id == task.id }) {
            dailyTasks[index] = nextTask
        } else {
            dailyTasks.append(nextTask)
        }

        dailyTasks.sort(by: sortDailyTasks)
        saveState()
    }

    func toggleDailyTaskCompletion(_ task: DailyCareTask) {
        guard let index = dailyTasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        dailyTasks[index].isCompleted.toggle()
        dailyTasks[index].updatedAt = Date()
        dailyTasks.sort(by: sortDailyTasks)
        saveState()
    }

    func deleteDailyTask(_ task: DailyCareTask) {
        dailyTasks.removeAll { $0.id == task.id }
        saveState()
    }

    @discardableResult
    func importBackgroundPhotoData(_ data: Data, activate: Bool = true) throws -> BackgroundAlbumPhoto {
        let asset = try mediaStore.savePhotoData(data)
        let photo = BackgroundAlbumPhoto(asset: asset)
        var nextAlbum = backgroundAlbum
        nextAlbum.photos.append(photo)

        if activate {
            nextAlbum.selectedPhotoID = photo.id
            nextAlbum.displayMode = .fixed
            nextAlbum.blurRadius = min(nextAlbum.blurRadius, 10)
        } else if nextAlbum.selectedPhotoID == nil {
            nextAlbum.selectedPhotoID = photo.id
        }

        saveBackgroundAlbum(nextAlbum)
        return photo
    }

    func setBackgroundDisplayMode(_ mode: BackgroundDisplayMode) {
        var nextAlbum = backgroundAlbum
        nextAlbum.displayMode = mode
        saveBackgroundAlbum(nextAlbum)
    }

    func setBackgroundBlurRadius(_ radius: Double) {
        var nextAlbum = backgroundAlbum
        nextAlbum.blurRadius = min(max(radius, 0), 32)
        saveBackgroundAlbum(nextAlbum)
    }

    func setFixedBackgroundPhoto(_ photo: BackgroundAlbumPhoto) {
        guard backgroundAlbum.photos.contains(where: { $0.id == photo.id }) else {
            return
        }

        var nextAlbum = backgroundAlbum
        nextAlbum.selectedPhotoID = photo.id
        nextAlbum.displayMode = .fixed
        nextAlbum.blurRadius = min(nextAlbum.blurRadius, 10)
        saveBackgroundAlbum(nextAlbum)
    }

    func setBackgroundPhotoRotation(_ photo: BackgroundAlbumPhoto, isIncluded: Bool) {
        var nextAlbum = backgroundAlbum
        guard let index = nextAlbum.photos.firstIndex(where: { $0.id == photo.id }) else {
            return
        }

        nextAlbum.photos[index].isIncludedInRotation = isIncluded
        saveBackgroundAlbum(nextAlbum)
    }

    func deleteBackgroundPhoto(_ photo: BackgroundAlbumPhoto) {
        var nextAlbum = backgroundAlbum
        guard let index = nextAlbum.photos.firstIndex(where: { $0.id == photo.id }) else {
            return
        }

        let removedPhoto = nextAlbum.photos.remove(at: index)
        mediaStore.delete(removedPhoto.asset)

        if nextAlbum.selectedPhotoID == removedPhoto.id {
            nextAlbum.selectedPhotoID = nextAlbum.photos.first?.id
        }

        if nextAlbum.photos.isEmpty {
            saveBackgroundAlbum(.empty)
        } else {
            saveBackgroundAlbum(nextAlbum)
        }
    }

    func resetBackgroundAlbum() {
        mediaStore.delete(backgroundAlbum.photos.map(\.asset))
        saveBackgroundAlbum(.empty)
    }

    func backgroundFileURL(for asset: MediaAsset) -> URL? {
        mediaStore.fileURL(for: asset)
    }

    func activeBackgroundPhoto(
        cycleIndex: Int = 0,
        sessionSeed: Int = 0,
        date: Date = Date()
    ) -> BackgroundAlbumPhoto? {
        let allPhotos = backgroundAlbum.photos.filter(isBackgroundPhotoAvailable)
        guard !allPhotos.isEmpty else {
            return nil
        }

        let rotationPhotos = allPhotos.filter(\.isIncludedInRotation)
        let candidates = rotationPhotos.isEmpty ? allPhotos : rotationPhotos

        switch backgroundAlbum.displayMode {
        case .fixed:
            return selectedBackgroundPhoto(in: allPhotos) ?? allPhotos.first
        case .random:
            return candidates[positiveModulo(sessionSeed, candidates.count)]
        case .dailyRandom:
            let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
            let albumSeed = candidates
                .map { $0.id.uuidString }
                .joined()
                .unicodeScalars
                .reduce(0) { $0 + Int($1.value) }
            return candidates[positiveModulo(day + albumSeed, candidates.count)]
        case .gentleCycle:
            let startIndex = selectedBackgroundPhoto(in: candidates)
                .flatMap { selected in candidates.firstIndex(where: { $0.id == selected.id }) } ?? 0
            return candidates[positiveModulo(startIndex + cycleIndex, candidates.count)]
        }
    }

    func savePetProfile(_ profile: PetProfile, language: AppLanguage = .zhHans) {
        let isFirstProfile = pet == nil
        var nextProfile = profile
        nextProfile.createdAt = profile.createdAt ?? Date()
        nextProfile.updatedAt = Date()
        pet = nextProfile

        if isFirstProfile && messages.isEmpty {
            messages = repository.loadStarterMessages(petName: nextProfile.name, language: language)
        }

        saveState()
    }

    func deletePetProfileAndContent() {
        mediaStore.delete(timeline.flatMap(\.mediaAssets))
        mediaStore.delete(backgroundAlbum.photos.map(\.asset))
        authService.signOut()
        accountSession = nil
        pet = nil
        dailyTasks = []
        backgroundAlbum = .empty
        timeline = []
        capsules = []
        messages = []
        lifePrint = nil
        aiCompanionSettings = .default
        companionConnectionState = .localOnly
        draftMessage = ""
        messageError = nil
        lifePrintError = nil
        lastFailedMessage = nil
        repository.clearState()
    }

    func deleteAccountAndContent(language: AppLanguage = .zhHans) async {
        isDeletingAccountData = true
        dataDeletionError = nil

        do {
            if accountSession?.isLocalOnly == false {
                try await authService.deleteAccount()
            }
            deletePetProfileAndContent()
        } catch {
            dataDeletionError = L10n.text(.settingsDataDeleteFailed, language: language)
        }

        isDeletingAccountData = false
    }

    func loadDemoData(language: AppLanguage = .zhHans, syncToCloud: Bool = true) {
        mediaStore.delete(timeline.flatMap(\.mediaAssets))
        mediaStore.delete(backgroundAlbum.photos.map(\.asset))
        let state = repository.loadDemoState(language: language)
        accountSession = state.accountSession
        pet = state.pet
        dailyTasks = state.dailyTasks
        backgroundAlbum = state.backgroundAlbum
        timeline = state.timeline
        messages = state.messages
        capsules = state.capsules
        lifePrint = state.lifePrint
        aiCompanionSettings = state.aiCompanionSettings
        companionConnectionState = .localOnly
        draftMessage = ""
        messageError = nil
        lifePrintError = nil
        lastFailedMessage = nil
        if syncToCloud {
            saveState()
        } else {
            repository.saveState(currentState())
        }
    }

    func saveTimelineMemory(_ memory: TimelineMemory) {
        if let index = timeline.firstIndex(where: { $0.id == memory.id }) {
            deleteRemovedMediaAssets(from: timeline[index], to: memory)
            timeline[index] = memory
        } else {
            timeline.append(memory)
        }

        timeline.sort { $0.date < $1.date }
        lifePrint = nil
        saveState()
    }

    func deleteTimelineMemory(_ memory: TimelineMemory) {
        timeline.removeAll { $0.id == memory.id }
        mediaStore.delete(memory.mediaAssets)
        lifePrint = nil
        saveState()
    }

    func saveMemoryCapsule(_ capsule: MemoryCapsule) {
        if let index = capsules.firstIndex(where: { $0.id == capsule.id }) {
            capsules[index] = capsule
        } else {
            capsules.insert(capsule, at: 0)
        }

        saveState()
    }

    func deleteMemoryCapsule(_ capsule: MemoryCapsule) {
        capsules.removeAll { $0.id == capsule.id }
        saveState()
    }

    func generateLifePrint(language: AppLanguage = .zhHans) async {
        guard let pet else {
            lifePrintError = L10n.text(.lifePrintErrorNoPet, language: language)
            return
        }

        isGeneratingLifePrint = true
        lifePrintError = nil

        do {
            try await Task.sleep(nanoseconds: 500_000_000)
            let sourceMemoryIDs = timeline.compactMap { $0.memoryID }
            lifePrint = LifePrintRecord(
                summary: makeLifePrintSummary(for: pet, language: language),
                updatedAt: Date(),
                personalityTraits: [pet.personality],
                favoriteThings: pet.favoriteThings,
                habits: pet.habits,
                sourceMemoryIDs: sourceMemoryIDs.isEmpty ? nil : sourceMemoryIDs,
                isAIGenerated: true
            )
            saveState()
        } catch {
            lifePrintError = L10n.text(.lifePrintErrorInterrupted, language: language)
        }

        isGeneratingLifePrint = false
    }

    func sendDraftMessage(language: AppLanguage = .zhHans) async {
        let text = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        draftMessage = ""
        await sendMessage(text, appendUserMessage: true, language: language)
    }

    func retryLastFailedMessage(language: AppLanguage = .zhHans) async {
        guard let lastFailedMessage else { return }
        await sendMessage(lastFailedMessage, appendUserMessage: false, language: language)
    }

    func clearMessages(language: AppLanguage = .zhHans) {
        messages = []
        if let pet {
            messages = repository.loadStarterMessages(petName: pet.name, language: language)
        }
        messageError = nil
        lastFailedMessage = nil
        saveState()
    }

    private func sendMessage(_ text: String, appendUserMessage: Bool, language: AppLanguage) async {
        guard !isSendingMessage else { return }
        guard let pet else {
            messageError = L10n.text(.companionErrorNoPet, language: language)
            return
        }

        let previousMessages = messages

        if appendUserMessage {
            messages.append(ChatMessage(text: text, isUser: true, timestamp: Date()))
        }

        isSendingMessage = true
        messageError = nil
        saveState()

        do {
            let request = CompanionChatRequest(
                message: text,
                relationship: aiContextBuilder.relationshipContext(for: pet, language: language),
                context: aiContextBuilder.build(
                    pet: pet,
                    lifePrint: lifePrint,
                    timeline: timeline,
                    dailyTasks: dailyTasks,
                    messages: previousMessages,
                    settings: aiCompanionSettings,
                    language: language
                )
            )
            await syncCurrentState()
            let result = try await companionService.reply(
                request: request,
                petID: pet.id,
                petName: pet.name,
                language: language
            )
            companionConnectionState = connectionState(for: result.source)
            let reply = EchoAIContent.normalizeCompanionReply(
                result.response.reply,
                language: language
            )
            messages.append(
                ChatMessage(
                    text: reply,
                    isUser: false,
                    timestamp: Date(),
                    isAIGenerated: result.response.isAIGenerated,
                    sourceMemoryIDs: result.response.sourceMemoryIDs.compactMap { UUID(uuidString: $0) }
                )
            )
            lastFailedMessage = nil
        } catch {
            messageError = L10n.text(.companionErrorSendFailed, language: language)
            lastFailedMessage = text
        }

        isSendingMessage = false
        saveState()
    }

    private func makeLifePrintSummary(for pet: PetProfile, language: AppLanguage) -> String {
        let memoryLine: String
        if let latest = timeline.last {
            memoryLine = L10n.text(.lifePrintSummaryLatestMemory, language: language, latest.title, pet.name)
        } else {
            memoryLine = L10n.text(.lifePrintSummaryNoMemory, language: language)
        }

        let listSeparator = language == .zhHans ? "、" : ", "
        let favorites = pet.favoriteThings.isEmpty
            ? L10n.text(.lifePrintSummaryDefaultFavorites, language: language)
            : pet.favoriteThings.joined(separator: listSeparator)
        let habits = pet.habits.isEmpty
            ? L10n.text(.lifePrintSummaryDefaultHabits, language: language)
            : pet.habits.joined(separator: listSeparator)

        return L10n.text(.lifePrintSummaryWithMemory, language: language, pet.name, pet.personality, favorites, habits, memoryLine)
    }

    private func sortDailyTasks(_ lhs: DailyCareTask, _ rhs: DailyCareTask) -> Bool {
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted
        }

        switch (lhs.dueAt, rhs.dueAt) {
        case let (left?, right?):
            if left != right {
                return left < right
            }
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            break
        }

        return lhs.createdAt < rhs.createdAt
    }

    private func saveState() {
        let state = currentState()
        repository.saveState(state)

        Task {
            try? await repository.syncState(state)
            await refreshAccountSessionFromCloudIfNeeded()
        }
    }

    private func currentState() -> EchoAppState {
        EchoAppState(
            accountSession: accountSession,
            pet: pet,
            dailyTasks: dailyTasks,
            backgroundAlbum: backgroundAlbum,
            timeline: timeline,
            messages: messages,
            capsules: capsules,
            lifePrint: lifePrint,
            aiCompanionSettings: aiCompanionSettings
        )
    }

    private func syncCurrentState() async {
        isSyncingToCloud = true
        try? await repository.syncState(currentState())
        await refreshAccountSessionFromCloudIfNeeded()
        isSyncingToCloud = false
    }

    private func refreshAccountSessionFromCloudIfNeeded() async {
        guard accountSession == nil || accountSession?.provider == .localPreview else {
            return
        }

        guard let cloudSession = authService.storedSession() else {
            return
        }

        accountSession = cloudSession.accountSession
        repository.saveState(currentState())
    }

    private func saveBackgroundAlbum(_ album: BackgroundAlbumSettings) {
        var nextAlbum = album
        nextAlbum.updatedAt = Date()
        backgroundAlbum = nextAlbum
        saveState()
    }

    private func selectedBackgroundPhoto(in photos: [BackgroundAlbumPhoto]) -> BackgroundAlbumPhoto? {
        guard let selectedPhotoID = backgroundAlbum.selectedPhotoID else {
            return nil
        }

        return photos.first { $0.id == selectedPhotoID }
    }

    private func isBackgroundPhotoAvailable(_ photo: BackgroundAlbumPhoto) -> Bool {
        guard let fileURL = mediaStore.fileURL(for: photo.asset) else {
            return false
        }

        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    private func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        guard divisor > 0 else {
            return 0
        }

        return ((value % divisor) + divisor) % divisor
    }

    private func connectionState(for source: CompanionReplySource) -> CompanionConnectionState {
        switch source {
        case .backend:
            return .backendConnected
        case .localOnly:
            return .localOnly
        case .backendUnavailable:
            return .backendUnavailable
        }
    }

    private func deleteRemovedMediaAssets(from oldMemory: TimelineMemory, to newMemory: TimelineMemory) {
        let retainedAssetIDs = Set(newMemory.mediaAssets.map(\.id))
        let removedAssets = oldMemory.mediaAssets.filter { !retainedAssetIDs.contains($0.id) }
        mediaStore.delete(removedAssets)
    }
}
