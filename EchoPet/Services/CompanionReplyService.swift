import Foundation

protocol CompanionBackendClient {
    func companionChat(petID: UUID, request: CompanionChatRequest) async throws -> CompanionChatResponse
}

extension EchoAPIStubClient: CompanionBackendClient {}

enum CompanionReplySource: Equatable {
    case backend
    case localOnly
    case backendUnavailable
}

struct CompanionReplyResult: Equatable {
    var response: CompanionChatResponse
    var source: CompanionReplySource
}

struct AIContextBuilder {
    var maxTimelineMemories = 8
    var maxDailyTasks = 12
    var maxRecentMessages = 10

    func build(
        pet: PetProfile,
        lifePrint: LifePrintRecord?,
        timeline: [TimelineMemory],
        dailyTasks: [DailyCareTask],
        messages: [ChatMessage],
        settings: AICompanionSettings,
        language: AppLanguage = .zhHans,
        now: Date = Date()
    ) -> CompanionContextPayload? {
        guard settings.allowsMemoryContext else {
            return nil
        }

        return CompanionContextPayload(
            languageCode: language.localeIdentifier,
            tone: settings.tone,
            generatedAt: now,
            pet: CompanionPetContext(
                id: pet.id,
                name: pet.name,
                species: pet.species,
                breed: pet.breed,
                age: pet.age,
                status: pet.status,
                relationshipLabel: pet.relationshipLabel,
                personality: pet.personality,
                mbti: pet.mbti,
                favoriteThings: pet.favoriteThings,
                habits: pet.habits
            ),
            lifePrint: lifePrint.map(makeLifePrintContext),
            timelineMemories: timeline
                .sorted { $0.date > $1.date }
                .prefix(maxTimelineMemories)
                .map(makeTimelineMemoryContext),
            dailyTasks: dailyTasks
                .sorted { $0.updatedAt > $1.updatedAt }
                .prefix(maxDailyTasks)
                .map(makeDailyTaskContext),
            recentMessages: messages
                .suffix(maxRecentMessages)
                .map(makeMessageContext),
            privacy: CompanionPrivacyContext(
                allowsMemoryContext: true,
                usesPetProfile: true,
                usesLifePrint: lifePrint != nil,
                usesTimeline: !timeline.isEmpty,
                usesDailyTasks: !dailyTasks.isEmpty,
                usesChatHistory: !messages.isEmpty
            )
        )
    }

    func relationshipContext(for pet: PetProfile, language: AppLanguage) -> RelationshipContext {
        let userRole = pet.relationshipLabel ?? (language == .zhHans ? "主人" : "owner")
        let petRole = pet.species ?? (language == .zhHans ? "宠物" : "pet")
        return RelationshipContext(userRole: userRole, petRole: petRole)
    }

    private func makeLifePrintContext(_ lifePrint: LifePrintRecord) -> CompanionLifePrintContext {
        CompanionLifePrintContext(
            summary: lifePrint.summary,
            updatedAt: lifePrint.updatedAt,
            personalityTraits: lifePrint.personalityTraits ?? [],
            favoriteThings: lifePrint.favoriteThings ?? [],
            habits: lifePrint.habits ?? [],
            sourceMemoryIDs: lifePrint.sourceMemoryIDs ?? [],
            isAIGenerated: lifePrint.isAIGenerated ?? false
        )
    }

    private func makeTimelineMemoryContext(_ memory: TimelineMemory) -> CompanionTimelineMemoryContext {
        CompanionTimelineMemoryContext(
            id: memory.id,
            petID: memory.petID,
            memoryID: memory.memoryID,
            date: memory.date,
            title: memory.title,
            story: memory.story,
            category: memory.category,
            mediaAssetCount: memory.mediaAssets.count,
            sourceMemoryIDs: memory.sourceMemoryIDs ?? memory.memoryID.map { [$0] } ?? []
        )
    }

    private func makeDailyTaskContext(_ task: DailyCareTask) -> CompanionDailyTaskContext {
        CompanionDailyTaskContext(
            id: task.id,
            petID: task.petID,
            title: task.title,
            note: task.note,
            dueAt: task.dueAt,
            date: task.date,
            template: task.template,
            isCompleted: task.isCompleted
        )
    }

    private func makeMessageContext(_ message: ChatMessage) -> CompanionMessageContext {
        CompanionMessageContext(
            id: message.id,
            role: message.isUser ? "user" : "assistant",
            text: message.text,
            timestamp: message.timestamp,
            isAIGenerated: message.isAIGenerated ?? false,
            sourceMemoryIDs: message.sourceMemoryIDs ?? []
        )
    }
}

struct CompanionReplyService {
    static let localModelVersion = "local-companion-context-stub-v1"
    private let backendClient: CompanionBackendClient?
    private let localResponseDelayNanoseconds: UInt64

    init(
        backendClient: CompanionBackendClient? = CompanionReplyService.defaultBackendClient(),
        localResponseDelayNanoseconds: UInt64 = 450_000_000
    ) {
        self.backendClient = backendClient
        self.localResponseDelayNanoseconds = localResponseDelayNanoseconds
    }

    private static func defaultBackendClient() -> CompanionBackendClient? {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return nil
        }

        if let rawValue = ProcessInfo.processInfo.environment["ECHOPET_BACKEND_BASE_URL"],
           let url = URL(string: rawValue) {
            return EchoAPIHTTPClient(baseURL: url)
        }

        return EchoSupabaseCompanionClient()
    }

    func reply(to message: String, petName: String, language: AppLanguage = .zhHans) async throws -> String {
        let request = CompanionChatRequest(
            message: message,
            relationship: RelationshipContext(
                userRole: language == .zhHans ? "主人" : "owner",
                petRole: language == .zhHans ? "宠物" : "pet"
            )
        )
        return try await reply(request: request, petName: petName, language: language).reply
    }

    func reply(
        request: CompanionChatRequest,
        petID: UUID,
        petName: String,
        language: AppLanguage = .zhHans
    ) async throws -> CompanionReplyResult {
        if let backendClient {
            do {
                return CompanionReplyResult(
                    response: try await backendClient.companionChat(petID: petID, request: request),
                    source: .backend
                )
            } catch {
#if DEBUG
                print("Echo Pet Companion backend failed: \(error)")
#endif
                return CompanionReplyResult(
                    response: try await localReply(request: request, petName: petName, language: language),
                    source: .backendUnavailable
                )
            }
        }

        return CompanionReplyResult(
            response: try await localReply(request: request, petName: petName, language: language),
            source: .localOnly
        )
    }

    func reply(
        request: CompanionChatRequest,
        petName: String,
        language: AppLanguage = .zhHans
    ) async throws -> CompanionChatResponse {
        try await localReply(request: request, petName: petName, language: language)
    }

    private func localReply(
        request: CompanionChatRequest,
        petName: String,
        language: AppLanguage
    ) async throws -> CompanionChatResponse {
        if localResponseDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: localResponseDelayNanoseconds)
        }

        let text = request.message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let reply = makeLocalReply(for: text, request: request, petName: petName, language: language)
        let sourceMemoryIDs = request.context?.timelineMemories
            .flatMap(\.sourceMemoryIDs)
            .map(\.uuidString) ?? []

        return CompanionChatResponse(
            messageID: UUID().uuidString,
            reply: EchoAIContent.normalizeCompanionReply(reply, language: language),
            isAIGenerated: true,
            sourceMemoryIDs: Array(sourceMemoryIDs.prefix(6)),
            modelVersion: Self.localModelVersion
        )
    }

    private func makeLocalReply(
        for text: String,
        request: CompanionChatRequest,
        petName: String,
        language: AppLanguage
    ) -> String {
        guard let context = request.context else {
            return makeFallbackReply(for: text, petName: petName, language: language)
        }

        let personality = context.lifePrint?.personalityTraits.first
            ?? context.pet.personality
        let latestMemory = context.timelineMemories.first
        let nextTask = context.dailyTasks.first { !$0.isCompleted }
        let completedTask = context.dailyTasks.first { $0.isCompleted }

        if text.contains("miss") || text.contains("想") {
            return localizedContextReply(
                language: language,
                zh: "如果用 \(context.pet.name) 的记忆口吻轻轻回应：我会带着「\(personality)」的样子靠近你。\(memoryLine(latestMemory, language: language))这些被你保存下来的小事，会让我更像你熟悉的那个我。",
                en: "If I answer through \(context.pet.name)'s saved memories, I would stay close with that \(personality) feeling. \(memoryLine(latestMemory, language: language)) The small moments you kept help me sound closer to the companion you remember."
            )
        }

        if text.contains("thank") || text.contains("谢谢") {
            return localizedContextReply(
                language: language,
                zh: "我也把这份照顾记在 \(context.pet.name) 的档案里了。\(taskLine(completedTask ?? nextTask, language: language))谢谢你还愿意把这些日常慢慢留下来。",
                en: "I saved that care into \(context.pet.name)'s companion archive. \(taskLine(completedTask ?? nextTask, language: language)) Thank you for still keeping these ordinary moments with care."
            )
        }

        return localizedContextReply(
            language: language,
            zh: "我记下了。现在我会参考 \(context.pet.name) 的宠物资料、LifePrint、时间线和今日陪伴计划来回应你。\(taskLine(nextTask ?? completedTask, language: language))这会让每次对话更贴近它真实留下来的习惯。",
            en: "I have saved that. I will now answer with \(context.pet.name)'s profile, LifePrint, Timeline, and today's care plan in mind. \(taskLine(nextTask ?? completedTask, language: language)) That makes each reply closer to the habits already recorded."
        )
    }

    private func makeFallbackReply(for text: String, petName: String, language: AppLanguage) -> String {
        if text.contains("miss") || text.contains("想") {
            return L10n.text(.companionReplyMissing, language: language, petName)
        }

        if text.contains("thank") || text.contains("谢谢") {
            return L10n.text(.companionReplyThanks, language: language, petName)
        }

        return L10n.text(.companionReplyDefault, language: language)
    }

    private func memoryLine(_ memory: CompanionTimelineMemoryContext?, language: AppLanguage) -> String {
        guard let memory else {
            return language == .zhHans
                ? "等你继续记录新的时间线后，我会更懂那些具体的想念。"
                : "As you keep adding Timeline memories, I will understand the specific shape of that missing more clearly."
        }

        return language == .zhHans
            ? "我还记得「\(memory.title)」：\(memory.story)"
            : "I still remember \"\(memory.title)\": \(memory.story)"
    }

    private func taskLine(_ task: CompanionDailyTaskContext?, language: AppLanguage) -> String {
        guard let task else {
            return language == .zhHans
                ? "今天还没有新的陪伴计划，但一件很小的事也可以成为记忆。"
                : "There is no care plan yet today, but even one small act can become a memory."
        }

        let status = task.isCompleted
            ? (language == .zhHans ? "已经完成" : "already done")
            : (language == .zhHans ? "还在等待" : "still waiting")

        return language == .zhHans
            ? "今天的「\(task.title)」\(status)，这也是我理解你们关系的一部分。"
            : "Today's \"\(task.title)\" is \(status), and that is part of how I understand your bond."
    }

    private func localizedContextReply(language: AppLanguage, zh: String, en: String) -> String {
        switch language {
        case .zhHans:
            return zh
        case .en:
            return en
        }
    }
}
