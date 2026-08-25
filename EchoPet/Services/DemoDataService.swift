import Foundation
import UIKit

final class DemoDataService {
    static let shared = DemoDataService()

    private init() {}

    func loadDemoState(language: AppLanguage = .zhHans) -> EchoAppState {
        let pet = loadPetProfile(language: language)
        let timeline = loadTimelineMemories(petID: pet.id, language: language)
        let sourceMemoryIDs = timeline.compactMap(\.memoryID)

        return EchoAppState(
            accountSession: AccountSession(
                displayName: L10n.text(.profileAccountLocalDisplayName, language: language)
            ),
            pet: pet,
            dailyTasks: loadDailyTasks(petID: pet.id, language: language),
            backgroundAlbum: loadBackgroundAlbum(language: language),
            timeline: timeline,
            messages: loadStarterMessages(petName: pet.name, language: language),
            capsules: loadMemoryCapsules(petID: pet.id, sourceMemoryIDs: sourceMemoryIDs, language: language),
            lifePrint: loadLifePrint(pet: pet, sourceMemoryIDs: sourceMemoryIDs, language: language)
        )
    }

    func loadPetProfile(language: AppLanguage = .en) -> PetProfile {
        switch language {
        case .zhHans:
            return PetProfile(
                name: "豆包",
                species: "猫",
                breed: "狸花猫",
                age: "4 岁",
                status: "陪伴中",
                relationshipLabel: "家人",
                personality: "亲人、安静、好奇",
                mbti: "温柔观察型",
                favoriteThings: ["窗边晒太阳", "羽毛逗猫棒", "纸箱"],
                habits: ["早晨蹭手", "听到钥匙声就跑来", "睡前趴在沙发边"],
                createdAt: makeDate(year: 2022, month: 4, day: 8),
                updatedAt: Date()
            )
        case .en:
            return PetProfile(
                name: "Momo",
                species: "Dog",
                breed: "Golden Retriever",
                age: "7 years",
                status: "remembered",
                relationshipLabel: "family",
                personality: "Gentle, curious, always close",
                mbti: "Warm observer",
                favoriteThings: ["Sunny window", "Blue ball", "Evening walks"],
                habits: ["Waits by the door", "Sleeps beside the sofa", "Tilts head when called"],
                createdAt: makeDate(year: 2019, month: 5, day: 18),
                updatedAt: Date()
            )
        }
    }

    func loadTimelineMemories(petID: UUID? = nil, language: AppLanguage = .en) -> [TimelineMemory] {
        switch language {
        case .zhHans:
            return [
                TimelineMemory(
                    petID: petID,
                    memoryID: UUID(),
                    date: makeDate(year: 2022, month: 4, day: 8),
                    title: "第一次回家",
                    story: "豆包先躲在纸箱后面，过了很久才慢慢靠近你的手。",
                    imageSystemName: "house.fill",
                    mediaAssets: makeDemoPhotoAssets(seed: 1, count: 2),
                    category: "first-day"
                ),
                TimelineMemory(
                    petID: petID,
                    memoryID: UUID(),
                    date: makeDate(year: 2023, month: 10, day: 2),
                    title: "学会等钥匙声",
                    story: "每次门口传来钥匙声，豆包都会从沙发边跑过来，像在确认你真的回来了。",
                    imageSystemName: "key.fill",
                    category: "daily-ritual"
                ),
                TimelineMemory(
                    petID: petID,
                    memoryID: UUID(),
                    date: makeDate(year: 2026, month: 3, day: 12),
                    title: "窗边的安静早晨",
                    story: "阳光落在窗台上，豆包趴在那里睡着，尾巴偶尔轻轻动一下。",
                    imageSystemName: "sun.max.fill",
                    mediaAssets: makeDemoPhotoAssets(seed: 3, count: 3),
                    category: "quiet-moment"
                )
            ]
        case .en:
            return [
                TimelineMemory(
                    petID: petID,
                    memoryID: UUID(),
                    date: makeDate(year: 2019, month: 5, day: 18),
                    title: "First Day Home",
                    story: "Momo walked in slowly, then chose the soft rug as the safest place.",
                    imageSystemName: "house.fill",
                    mediaAssets: makeDemoPhotoAssets(seed: 11, count: 2),
                    category: "first-day"
                ),
                TimelineMemory(
                    petID: petID,
                    memoryID: UUID(),
                    date: makeDate(year: 2021, month: 9, day: 2),
                    title: "The Blue Ball",
                    story: "A simple blue ball became the one thing Momo carried into every room.",
                    imageSystemName: "circle.fill",
                    category: "favorite-thing"
                ),
                TimelineMemory(
                    petID: petID,
                    memoryID: UUID(),
                    date: makeDate(year: 2024, month: 3, day: 12),
                    title: "Quiet Morning",
                    story: "A calm morning by the window, full of light and familiar breathing.",
                    imageSystemName: "sun.max.fill",
                    mediaAssets: makeDemoPhotoAssets(seed: 13, count: 3),
                    category: "quiet-moment"
                )
            ]
        }
    }

    func loadMemoryCapsules(petID: UUID? = nil, sourceMemoryIDs: [UUID]? = nil, language: AppLanguage = .en) -> [MemoryCapsule] {
        switch language {
        case .zhHans:
            return [
                MemoryCapsule(
                    petID: petID,
                    title: "窗边早晨",
                    dateLabel: "3 月 12 日",
                    body: "那天早晨很安静。豆包在窗边睡着，你没有叫醒它，只是把那束光和它一起保存了下来。",
                    accentSystemName: "sun.max.fill",
                    theme: "quiet-morning",
                    sourceMemoryIDs: sourceMemoryIDs,
                    isAIGenerated: true,
                    createdAt: Date()
                )
            ]
        case .en:
            return [
                MemoryCapsule(
                    petID: petID,
                    title: "A Morning Momo Loved",
                    dateLabel: "March 12",
                    body: "Light came through the window, and Momo stayed close without asking for anything.",
                    accentSystemName: "sun.max.fill",
                    theme: "quiet-morning",
                    sourceMemoryIDs: sourceMemoryIDs,
                    isAIGenerated: true,
                    createdAt: Date()
                )
            ]
        }
    }

    func loadDailyTasks(petID: UUID? = nil, language: AppLanguage = .zhHans) -> [DailyCareTask] {
        switch language {
        case .zhHans:
            return [
                DailyCareTask(
                    petID: petID,
                    title: "换一碗新鲜水",
                    note: "顺手清洗水碗。",
                    dueAt: makeTimeToday(hour: 9, minute: 30),
                    template: .feeding
                ),
                DailyCareTask(
                    petID: petID,
                    title: "陪豆包玩 10 分钟",
                    note: "羽毛逗猫棒或纸球都可以。",
                    dueAt: makeTimeToday(hour: 20, minute: 0),
                    template: .play
                ),
                DailyCareTask(
                    petID: petID,
                    title: "拍一张今日照片",
                    note: "",
                    template: .photo,
                    isCompleted: true
                )
            ]
        case .en:
            return [
                DailyCareTask(
                    petID: petID,
                    title: "Refresh water bowl",
                    note: "Rinse the bowl while changing water.",
                    dueAt: makeTimeToday(hour: 9, minute: 30),
                    template: .feeding
                ),
                DailyCareTask(
                    petID: petID,
                    title: "Spend 10 minutes together",
                    note: "A ball, a brush, or quiet sitting nearby all counts.",
                    dueAt: makeTimeToday(hour: 20, minute: 0),
                    template: .play
                ),
                DailyCareTask(
                    petID: petID,
                    title: "Take one photo today",
                    note: "",
                    template: .photo,
                    isCompleted: true
                )
            ]
        }
    }

    func loadBackgroundAlbum(language: AppLanguage = .zhHans) -> BackgroundAlbumSettings {
        let photos = makeDemoPhotoAssets(seed: language == .zhHans ? 31 : 41, count: 3)
            .map { BackgroundAlbumPhoto(asset: $0) }

        return BackgroundAlbumSettings(
            photos: photos,
            selectedPhotoID: photos.first?.id,
            displayMode: .gentleCycle,
            blurRadius: 16
        )
    }

    func loadStarterMessages(petName: String, language: AppLanguage = .zhHans) -> [ChatMessage] {
        [
            ChatMessage(
                text: EchoAIContent.normalizeCompanionReply(
                    L10n.text(.companionStarterMessage, language: language, petName),
                    language: language
                ),
                isUser: false,
                timestamp: Date(),
                isAIGenerated: true
            )
        ]
    }

    func makeGeneratedCapsule(petName: String) -> MemoryCapsule {
        MemoryCapsule(
            title: "\(petName)'s Gentle Memory",
            dateLabel: "Today",
            body: "Some companionship stays in small routines: a glance, a step, a quiet place beside you.",
            accentSystemName: "heart.fill",
            theme: "gentle-memory",
            isAIGenerated: true,
            createdAt: Date()
        )
    }

    private func loadLifePrint(pet: PetProfile, sourceMemoryIDs: [UUID], language: AppLanguage) -> LifePrintRecord {
        let summary: String
        switch language {
        case .zhHans:
            summary = "\(pet.name) 的 LifePrint 来自日常里那些反复出现的小习惯：靠近、等待、晒太阳，以及在熟悉声音响起时第一时间回应。"
        case .en:
            summary = "\(pet.name)'s LifePrint is shaped by gentle routines: staying close, waiting at the door, loving sunlight, and answering familiar sounds."
        }

        return LifePrintRecord(
            summary: summary,
            updatedAt: Date(),
            personalityTraits: [pet.personality],
            favoriteThings: pet.favoriteThings,
            habits: pet.habits,
            sourceMemoryIDs: sourceMemoryIDs.isEmpty ? nil : sourceMemoryIDs,
            isAIGenerated: true
        )
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private func makeTimeToday(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: now
        ) ?? now
    }

    private func makeDemoPhotoAssets(seed: Int, count: Int) -> [MediaAsset] {
        (0..<count).compactMap { index in
            guard let data = makeDemoPhotoData(seed: seed + index) else {
                return nil
            }

            return try? LocalMediaStore.shared.savePhotoData(data)
        }
    }

    private func makeDemoPhotoData(seed: Int) -> Data? {
        let size = CGSize(width: 900, height: 680)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let colors: [UIColor] = [
                UIColor(red: 1.00, green: 0.79, blue: 0.45, alpha: 1.0),
                UIColor(red: 0.96, green: 0.62, blue: 0.43, alpha: 1.0),
                UIColor(red: 0.49, green: 0.66, blue: 0.50, alpha: 1.0),
                UIColor(red: 0.53, green: 0.45, blue: 0.38, alpha: 1.0),
                UIColor(red: 0.98, green: 0.88, blue: 0.73, alpha: 1.0)
            ]
            let base = colors[seed % colors.count]
            let accent = colors[(seed + 2) % colors.count]

            base.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            accent.withAlphaComponent(0.42).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 540, y: -70, width: 300, height: 300))
            context.cgContext.fillEllipse(in: CGRect(x: -80, y: 430, width: 260, height: 260))

            UIColor.white.withAlphaComponent(0.55).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 330, y: 210, width: 210, height: 170))
            context.cgContext.fillEllipse(in: CGRect(x: 265, y: 155, width: 82, height: 92))
            context.cgContext.fillEllipse(in: CGRect(x: 382, y: 130, width: 86, height: 100))
            context.cgContext.fillEllipse(in: CGRect(x: 504, y: 155, width: 82, height: 92))
        }

        return image.jpegData(compressionQuality: 0.86)
    }
}
