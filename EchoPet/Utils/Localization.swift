import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case zhHans
    case en

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .zhHans:
            return "zh_Hans"
        case .en:
            return "en"
        }
    }

    var displayName: String {
        switch self {
        case .zhHans:
            return "中文"
        case .en:
            return "English"
        }
    }
}

@MainActor
final class LocalizationManager: ObservableObject {
    private static let storageKey = "echoPet.appLanguage"
    private let defaults: UserDefaults

    @Published private(set) var language: AppLanguage

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Self.storageKey)
        self.language = AppLanguage(rawValue: stored ?? "") ?? .zhHans
    }

    func setLanguage(_ language: AppLanguage) {
        self.language = language
        defaults.set(language.rawValue, forKey: Self.storageKey)
    }

    func text(_ key: L10n.Key, _ arguments: CVarArg...) -> String {
        L10n.text(key, language: language, arguments)
    }
}

enum L10n {
    enum Key: String, CaseIterable {
        case tabHome, tabTimeline, tabLifePrint, tabCompanion, tabProfile
        case commonCancel, commonSave, commonDelete, commonEdit, commonClear, commonOK, commonDone, commonNotRecorded
        case brandIntroTitle, brandIntroMessage, brandIntroStart
        case onboardingTitle, onboardingMessage, onboardingCreatePet
        case onboardingStep1Title, onboardingStep1Subtitle, onboardingStep2Title, onboardingStep2Subtitle, onboardingStep3Title, onboardingStep3Subtitle
        case accountGateTitle, accountGateMessage, accountGateEmailTitle, accountGateEmailPlaceholder, accountGatePasswordPlaceholder, accountGateSignIn, accountGateSignUp, accountGateContinueGuest, accountGateForgotPassword, accountGateResetSent, accountGateSigningIn, accountGateAuthHint
        case homeTitle, homeSubtitle, homePetProfile, homeEditPetProfile, homeCreatePetEmptyTitle, homeCreatePetEmptyMessage, homeCreatePetEmptyAction
        case homeTileTimelineTitle, homeTileTimelineSubtitle, homeTileLifePrintTitle, homeTileLifePrintSubtitle, homeTileCompanionTitle, homeTileCompanionSubtitle, homeTileCapsuleTitle, homeTileCapsuleSubtitle
        case homeLatestMemory, homeNoMemoryTitle, homeNoMemoryMessage, homeNoMemoryAction, homeSettings
        case backgroundAlbumTitle, backgroundAlbumSubtitle, backgroundAlbumAddPhotos, backgroundAlbumPhotoCount, backgroundAlbumEmptyTitle, backgroundAlbumEmptyMessage
        case backgroundAlbumModeTitle, backgroundAlbumModeFixed, backgroundAlbumModeRandom, backgroundAlbumModeDailyRandom, backgroundAlbumModeGentleCycle
        case backgroundAlbumBlurTitle, backgroundAlbumBlurValue, backgroundAlbumSetFixed, backgroundAlbumIncludeInRotation, backgroundAlbumRemovePhoto
        case backgroundAlbumRestoreDefault, backgroundAlbumImporting, backgroundAlbumImportFailedTitle, backgroundAlbumImportFailedMessage, backgroundAlbumCurrentBackground, backgroundAlbumAccessibility
        case homeDailyMoodTitle, homeDailyMoodFallback, homeDailyMoodMessage1, homeDailyMoodMessage2, homeDailyMoodMessage3, homeDailyMoodMessage4, homeDailyMoodMessage5
        case homeDailyTasksTitle, homeDailyTasksSubtitle, homeDailyTasksProgress, homeDailyTasksAllDone, homeDailyTasksEmptyTitle, homeDailyTasksEmptyMessage, homeDailyTaskAdd
        case homeDailyTasksCollapse, homeDailyTasksExpand, homeDailyTasksMove
        case homeDailyTaskNoTime, homeDailyTaskCompleted, homeDailyTaskPending, homeDailyTaskCompleteAccessibility, homeDailyTaskReopenAccessibility
        case dailyTaskFormTitleCreate, dailyTaskFormTitleEdit, dailyTaskFormSectionTemplate, dailyTaskFormSectionDetails, dailyTaskFormFieldTitle, dailyTaskFormFieldNote, dailyTaskFormUseTime, dailyTaskFormFieldTime
        case dailyTaskTemplateFeeding, dailyTaskTemplateWalk, dailyTaskTemplateGrooming, dailyTaskTemplatePlay, dailyTaskTemplateCleaning, dailyTaskTemplateMedicine, dailyTaskTemplatePhoto, dailyTaskTemplateCustom
        case timelineTitle, timelineSubtitleNoPet, timelineSubtitlePet, timelineNoPetTitle, timelineNoPetMessage, timelineEmptyTitle, timelineEmptyMessage, timelineAdd, timelineEdit
        case timelineDeleteAccessibility, timelineEditAccessibility, timelineDeleteDialog
        case timelineFormTitleCreate, timelineFormTitleEdit, timelineFormSectionMemory, timelineFormFieldTitle, timelineFormFieldDate, timelineFormFieldStory, timelineFormSectionIcon
        case timelineFormIconHome, timelineFormIconDaily, timelineFormIconLove, timelineFormIconPaw, timelineFormIconToy, timelineFormIconNature
        case timelineFormSectionPhotos, timelineFormAddPhotos, timelineFormPhotoCount, timelineFormPhotoLimit, timelineFormDeletePhoto
        case timelineFormPhotoEmptyHint, timelineFormPhotoImporting, timelineFormPhotoMaxReached
        case timelineFormPhotoImportFailedTitle, timelineFormPhotoImportFailedMessage
        case timelineFormDiscardDialog, timelineFormDiscardChanges, timelineFormKeepEditing, timelinePhotoCountBadge
        case lifePrintTitle, lifePrintSubtitle, lifePrintNoPetTitle, lifePrintNoPetMessage, lifePrintResultTitle, lifePrintStatusNotGenerated, lifePrintStatusUpdatedAt
        case lifePrintStatusGenerating, lifePrintStatusEmpty, lifePrintGenerateAccessibility, lifePrintRegenerateAccessibility
        case lifePrintRowName, lifePrintRowBreed, lifePrintRowAge, lifePrintRowPersonality, lifePrintGroupFavoriteThings, lifePrintGroupHabits
        case lifePrintErrorNoPet, lifePrintErrorInterrupted, lifePrintSummaryWithMemory, lifePrintSummaryNoMemory, lifePrintSummaryLatestMemory, lifePrintSummaryDefaultFavorites, lifePrintSummaryDefaultHabits
        case capsuleTitle, capsuleSubtitle, capsuleNoPetTitle, capsuleNoPetMessage, capsuleEmptyTitle, capsuleEmptyMessage, capsuleCreate, capsuleEdit
        case capsuleDeleteAccessibility, capsuleEditAccessibility, capsuleDeleteDialog
        case capsuleFormSectionContent, capsuleFormFieldTitle, capsuleFormFieldDateLabel, capsuleFormFieldBody, capsuleFormSectionIcon
        case capsuleFormIconMorning, capsuleFormIconMissing, capsuleFormIconPrecious, capsuleFormIconText, capsuleFormIconNight, capsuleFormIconGift
        case companionTitle, companionNoPetSubtitle, companionNoPetTitle, companionNoPetMessage, companionResponding, companionInputPlaceholder
        case companionSendAccessibility, companionAIStamp, companionAIDisclaimer, companionUserAccessibility, companionEchoAccessibility
        case companionConnectionBackend, companionConnectionLocal, companionConnectionFallback
        case companionErrorNoPet, companionErrorSendFailed, companionReplyMissing, companionReplyThanks, companionReplyDefault, companionStarterMessage
        case profileTitle, profileSubtitle, profileAccountTitle, profileAccountMessage, profileAccountStats, profilePetTitle, profilePetEmpty, profilePetCreate, profilePetEdit
        case profileAccountLocalDisplayName, profileAccountSignedIn, profileAccountLocalOnlyBadge, profileAccountCreateLocal, profileAccountSignOut, profileAccountSignOutDialog, profileAccountBackendPending
        case profileAccountEmailBadge, profileAccountGuestBadge, profileAccountContinueGuest, profileAccountSigningIn, profileAccountSignInFailed, profileAccountSignUpFailed, profileAccountEmailConfirmationRequired, profileAccountVerificationAlertTitle, profileAccountVerificationAlertMessage, profileAccountResetFailed, profileAccountCloudMessage
        case profileAccountEmailTitle, profileAccountEmailPlaceholder, profileAccountPasswordPlaceholder, profileAccountEmailSignIn, profileAccountEmailSignUp, profileAccountEmailHint, profileAccountAuthHint, profileAccountForgotPassword, profileAccountResetSent
        case profileAccountVerificationCodeTitle, profileAccountVerificationCodePlaceholder, profileAccountVerificationCodeSubmit, profileAccountVerificationCodeRequired, profileAccountVerificationSuccess, profileAccountVerificationFailed
        case profileAccountResetCodeTitle, profileAccountResetCodeMessage, profileAccountResetCodePlaceholder, profileAccountResetCodeSubmit, profileAccountResetCodeRequired
        case profilePrivacyTitle, profilePrivacyMessage1, profilePrivacyMessage2, profilePermissionsTitle, profileSettingsTitle, profileSettingsSubtitle
        case profileSyncTitle, profileSyncMessage, profileSyncLocalOnlyStatus, profileSyncReadyStatus, profileSyncQueuedChanges, profileSyncDomains
        case profileSyncDomainAccount, profileSyncDomainPetProfile, profileSyncDomainMemoryFiles, profileSyncDomainLifePrint, profileSyncDomainTimeline, profileSyncDomainMemoryCapsules, profileSyncDomainCompanion
        case settingsTitle, settingsSubtitle, settingsLanguageTitle, settingsLanguageMessage, settingsLanguagePicker
        case settingsPrivacyTitle, settingsPrivacyMessage1, settingsPrivacyMessage2, settingsViewFullPolicy, settingsTermsTitle, settingsTermsMessage1, settingsTermsMessage2, settingsViewFullTerms
        case settingsPrivacyIntro, settingsPrivacyCollectedTitle, settingsPrivacyCollectedBody, settingsPrivacyUseTitle, settingsPrivacyUseBody, settingsPrivacyAIThirdPartyTitle, settingsPrivacyAIThirdPartyBody
        case settingsPrivacyRetentionTitle, settingsPrivacyRetentionBody, settingsPrivacyDeletionTitle, settingsPrivacyDeletionBody, settingsPrivacyContactTitle, settingsPrivacyContactBody
        case settingsTermsIntro, settingsTermsServiceTitle, settingsTermsServiceBody, settingsTermsNoAdviceTitle, settingsTermsNoAdviceBody, settingsTermsUserContentTitle, settingsTermsUserContentBody
        case settingsTermsAIContentTitle, settingsTermsAIContentBody, settingsTermsDeletionTitle, settingsTermsDeletionBody
        case settingsDataTitle, settingsDataClearChat, settingsDataDeleteAll, settingsDataDeleteCloud, settingsDataDeleteInProgress, settingsDataDeleteFailed, settingsDataCloudMessage, settingsDataLoadDemo, settingsDataDemoMessage
        case settingsAITitle, settingsAIMessage, settingsAIMemoryToggleTitle, settingsAIMemoryToggleMessage, settingsAIToneCurrent, settingsVersionTitle, settingsVersionName, settingsVersionStage
        case settingsClearChatDialog, settingsDeleteAllDialog, settingsDeleteCloudDialog, settingsLoadDemoDialog
        case passwordResetTitle, passwordResetMessage, passwordResetNewPassword, passwordResetConfirmPassword, passwordResetSubmit, passwordResetSuccess, passwordResetFailed, passwordResetTooShort, passwordResetMismatch
        case profileFormTitleCreate, profileFormTitleEdit, profileFormSectionAvatar, profileFormAvatarChoose, profileFormAvatarChange, profileFormAvatarRemove
        case profileFormSectionBasic, profileFormFieldName, profileFormFieldBreed, profileFormFieldAge
        case profileFormFieldPersonality, profileFormFieldMBTI, profileFormSectionLife, profileFormFieldFavoriteThings, profileFormFieldHabits
        case profileFormDefaultBreed, profileFormDefaultAge, profileFormDefaultMBTI
        case permissionPhotosTitle, permissionPhotosPurpose, permissionCameraTitle, permissionCameraPurpose, permissionMicrophoneTitle, permissionMicrophonePurpose
        case permissionStatusNotDetermined, permissionStatusAuthorized, permissionStatusDenied, permissionStatusLimited, permissionStatusRestricted, permissionStatusUnavailable
    }

    static func text(_ key: Key, language: AppLanguage, _ arguments: CVarArg...) -> String {
        text(key, language: language, arguments)
    }

    static func text(_ key: Key, language: AppLanguage, _ arguments: [CVarArg]) -> String {
        let format = table[language]?[key] ?? table[.zhHans]?[key] ?? key.rawValue
        guard !arguments.isEmpty else {
            return format
        }
        return String(format: format, locale: Locale(identifier: language.localeIdentifier), arguments: arguments)
    }

    private static let table: [AppLanguage: [Key: String]] = [
        .zhHans: [
            .tabHome: "首页", .tabTimeline: "时间线", .tabLifePrint: "生命印记", .tabCompanion: "陪伴", .tabProfile: "我的",
            .commonCancel: "取消", .commonSave: "保存", .commonDelete: "删除", .commonEdit: "编辑", .commonClear: "清空", .commonOK: "知道了", .commonDone: "完成", .commonNotRecorded: "尚未记录",
            .brandIntroTitle: "Echo Pet",
            .brandIntroMessage: "把和它的陪伴，温柔地记录下来。",
            .brandIntroStart: "开始",
            .onboardingTitle: "为它建立第一份生命档案",
            .onboardingMessage: "从名字、性格和一个小习惯开始，Echo Pet 会把后续记忆整理成时间线、生命印记、记忆胶囊和陪伴对话。",
            .onboardingCreatePet: "创建宠物资料",
            .onboardingStep1Title: "创建宠物资料", .onboardingStep1Subtitle: "记录它是谁，以及你们是什么关系。",
            .onboardingStep2Title: "添加第一条记忆", .onboardingStep2Subtitle: "写下一次回家、一次散步，或一个安静的日常。",
            .onboardingStep3Title: "形成陪伴档案", .onboardingStep3Subtitle: "逐步生成 LifePrint、Timeline、Memory Capsule 和 Companion 上下文。",
            .accountGateTitle: "保存你的陪伴档案",
            .accountGateMessage: "登录邮箱账号后，档案可以在不同设备间同步；选择游客模式也能立即开始体验。",
            .accountGateEmailTitle: "邮箱",
            .accountGateEmailPlaceholder: "邮箱地址",
            .accountGatePasswordPlaceholder: "密码（至少 6 位）",
            .accountGateSignIn: "登录",
            .accountGateSignUp: "创建账号",
            .accountGateContinueGuest: "游客模式继续",
            .accountGateForgotPassword: "忘记密码？",
            .accountGateAuthHint: "请输入有效邮箱地址和至少 6 位密码",
            .accountGateResetSent: "重置邮件已发送，请查收收件箱。",
            .accountGateSigningIn: "正在处理…",
            .homeTitle: "Echo Pet", .homeSubtitle: "把陪伴继续记录下来", .homePetProfile: "宠物档案", .homeEditPetProfile: "编辑宠物档案",
            .homeCreatePetEmptyTitle: "先创建宠物档案",
            .homeCreatePetEmptyMessage: "记录名字、性格和生活习惯后，成长时间线、生命印记和陪伴对话才会有真实上下文。",
            .homeCreatePetEmptyAction: "创建宠物档案",
            .homeTileTimelineTitle: "成长时间线", .homeTileTimelineSubtitle: "记录节点",
            .homeTileLifePrintTitle: "生命印记", .homeTileLifePrintSubtitle: "生成摘要",
            .homeTileCompanionTitle: "Echo 陪伴", .homeTileCompanionSubtitle: "继续对话",
            .homeTileCapsuleTitle: "记忆胶囊", .homeTileCapsuleSubtitle: "保存片段",
            .homeLatestMemory: "最近记忆", .homeNoMemoryTitle: "还没有成长记忆",
            .homeNoMemoryMessage: "从一次回家、一次散步或一个安静早晨开始，写下第一条时间线。",
            .homeNoMemoryAction: "添加第一条记忆", .homeSettings: "设置",
            .backgroundAlbumTitle: "背景相册",
            .backgroundAlbumSubtitle: "保存喜欢的照片，并把它们变成所有页面的柔和背景。",
            .backgroundAlbumAddPhotos: "添加背景照片",
            .backgroundAlbumPhotoCount: "已保存 %d 张背景照片",
            .backgroundAlbumEmptyTitle: "还没有背景照片",
            .backgroundAlbumEmptyMessage: "添加一张照片后，可以设为固定背景；添加多张后，可以随机、每日随机或柔和轮换。",
            .backgroundAlbumModeTitle: "背景方式",
            .backgroundAlbumModeFixed: "固定一张",
            .backgroundAlbumModeRandom: "每次随机",
            .backgroundAlbumModeDailyRandom: "每日随机",
            .backgroundAlbumModeGentleCycle: "柔和轮换",
            .backgroundAlbumBlurTitle: "背景虚化",
            .backgroundAlbumBlurValue: "%d",
            .backgroundAlbumSetFixed: "设为固定背景",
            .backgroundAlbumIncludeInRotation: "参与背景轮换",
            .backgroundAlbumRemovePhoto: "删除背景照片",
            .backgroundAlbumRestoreDefault: "恢复默认背景",
            .backgroundAlbumImporting: "正在导入背景照片",
            .backgroundAlbumImportFailedTitle: "部分背景照片未能导入",
            .backgroundAlbumImportFailedMessage: "%d 张照片没有成功导入，请重试或选择其他照片。",
            .backgroundAlbumCurrentBackground: "背景照片",
            .backgroundAlbumAccessibility: "打开背景相册",
            .homeDailyMoodTitle: "今日心情",
            .homeDailyMoodFallback: "今天也可以从一个小小的陪伴计划开始。",
            .homeDailyMoodMessage1: "%@ 今天像晒过太阳的小毯子，也想确认你有没有好好吃饭。",
            .homeDailyMoodMessage2: "%@ 今天有点想被你叫名字，也希望你忙完后能慢慢休息。",
            .homeDailyMoodMessage3: "%@ 今天的心情很软，像在门口等你回头看一眼。",
            .homeDailyMoodMessage4: "%@ 今天想把安静分给你一点，也提醒你别忘了喝水。",
            .homeDailyMoodMessage5: "%@ 今天有一点想你，如果可以，留十分钟给彼此就很好。",
            .homeDailyTasksTitle: "今日陪伴计划",
            .homeDailyTasksSubtitle: "把今天想为它做的小事安排下来。",
            .homeDailyTasksProgress: "已完成 %d / %d",
            .homeDailyTasksAllDone: "今天的陪伴计划已完成",
            .homeDailyTasksEmptyTitle: "今天还没有计划",
            .homeDailyTasksEmptyMessage: "可以从喂食、陪玩、梳毛或拍一张照片开始。",
            .homeDailyTaskAdd: "添加任务",
            .homeDailyTasksCollapse: "折叠今日陪伴计划",
            .homeDailyTasksExpand: "展开今日陪伴计划",
            .homeDailyTasksMove: "拖动今日陪伴计划",
            .homeDailyTaskNoTime: "今天",
            .homeDailyTaskCompleted: "已完成",
            .homeDailyTaskPending: "待完成",
            .homeDailyTaskCompleteAccessibility: "完成任务，%@",
            .homeDailyTaskReopenAccessibility: "重新打开任务，%@",
            .dailyTaskFormTitleCreate: "添加今日任务",
            .dailyTaskFormTitleEdit: "编辑今日任务",
            .dailyTaskFormSectionTemplate: "任务模板",
            .dailyTaskFormSectionDetails: "任务内容",
            .dailyTaskFormFieldTitle: "任务名称",
            .dailyTaskFormFieldNote: "备注，可选",
            .dailyTaskFormUseTime: "设置提醒时间",
            .dailyTaskFormFieldTime: "时间",
            .dailyTaskTemplateFeeding: "喂食/饮水",
            .dailyTaskTemplateWalk: "散步",
            .dailyTaskTemplateGrooming: "梳毛",
            .dailyTaskTemplatePlay: "陪玩",
            .dailyTaskTemplateCleaning: "清洁",
            .dailyTaskTemplateMedicine: "用药",
            .dailyTaskTemplatePhoto: "拍照记录",
            .dailyTaskTemplateCustom: "自定义",
            .timelineTitle: "成长时间线", .timelineSubtitleNoPet: "先创建宠物档案，再记录成长故事", .timelineSubtitlePet: "%@ 的成长故事",
            .timelineNoPetTitle: "需要先创建宠物档案", .timelineNoPetMessage: "时间线会围绕宠物档案保存成长节点。请回到首页创建档案。",
            .timelineEmptyTitle: "还没有成长节点", .timelineEmptyMessage: "添加第一次回家、一次散步或一个安静日常，让 LifePrint 有真实材料。",
            .timelineAdd: "添加成长记忆", .timelineEdit: "编辑成长记忆", .timelineDeleteAccessibility: "删除成长记忆", .timelineEditAccessibility: "编辑成长记忆",
            .timelineDeleteDialog: "删除这条成长记忆？", .timelineFormTitleCreate: "添加成长记忆", .timelineFormTitleEdit: "编辑成长记忆",
            .timelineFormSectionMemory: "记忆内容", .timelineFormFieldTitle: "标题", .timelineFormFieldDate: "日期", .timelineFormFieldStory: "写下这段故事",
            .timelineFormSectionIcon: "图标", .timelineFormIconHome: "第一次回家", .timelineFormIconDaily: "日常时刻",
            .timelineFormIconLove: "亲密陪伴", .timelineFormIconPaw: "成长足迹", .timelineFormIconToy: "玩具", .timelineFormIconNature: "自然",
            .timelineFormSectionPhotos: "照片", .timelineFormAddPhotos: "添加照片", .timelineFormPhotoCount: "%d / %d 张照片",
            .timelineFormPhotoLimit: "一次记录最多保存 9 张照片。", .timelineFormDeletePhoto: "删除照片",
            .timelineFormPhotoEmptyHint: "可以添加最多 9 张照片，保存后会按选择顺序叠放展示。",
            .timelineFormPhotoImporting: "正在导入照片...",
            .timelineFormPhotoMaxReached: "已达到 9 张照片上限。删除一张后可以继续添加。",
            .timelineFormPhotoImportFailedTitle: "部分照片未能导入",
            .timelineFormPhotoImportFailedMessage: "%d 张照片没有成功导入，请重试或选择其他照片。",
            .timelineFormDiscardDialog: "放弃未保存的修改？", .timelineFormDiscardChanges: "放弃修改", .timelineFormKeepEditing: "继续编辑",
            .timelinePhotoCountBadge: "%d 张",
            .lifePrintTitle: "生命印记", .lifePrintSubtitle: "由真实记录沉淀出的陪伴摘要",
            .lifePrintNoPetTitle: "需要先创建宠物档案", .lifePrintNoPetMessage: "LifePrint 会从宠物档案、时间线和记忆内容中生成。请先回到首页创建档案。",
            .lifePrintResultTitle: "生成结果", .lifePrintStatusNotGenerated: "尚未生成", .lifePrintStatusUpdatedAt: "更新于 %@",
            .lifePrintStatusGenerating: "正在整理档案和成长记忆...", .lifePrintStatusEmpty: "点击右上角按钮，生成第一版生命印记。添加更多成长记忆后可以重新生成。",
            .lifePrintGenerateAccessibility: "生成生命印记", .lifePrintRegenerateAccessibility: "重新生成生命印记",
            .lifePrintRowName: "名字", .lifePrintRowBreed: "品种", .lifePrintRowAge: "年龄", .lifePrintRowPersonality: "性格标签",
            .lifePrintGroupFavoriteThings: "喜欢的事物", .lifePrintGroupHabits: "生活习惯",
            .lifePrintErrorNoPet: "请先创建宠物档案。",
            .lifePrintErrorInterrupted: "生成被中断，请重试。",
            .lifePrintSummaryWithMemory: "%@ 是一只%@的伙伴。它喜欢%@，也常常%@。%@",
            .lifePrintSummaryNoMemory: "还没有记录成长节点，可以先写下一个第一次、一次散步，或一个安静的日常。",
            .lifePrintSummaryLatestMemory: "最近的记忆停在「%@」，它让 %@ 的陪伴变得更具体。",
            .lifePrintSummaryDefaultFavorites: "那些被你记住的小习惯",
            .lifePrintSummaryDefaultHabits: "安静靠近你的方式",
            .capsuleTitle: "记忆胶囊", .capsuleSubtitle: "把今天保存成一段温柔纪念",
            .capsuleNoPetTitle: "需要先创建宠物档案", .capsuleNoPetMessage: "记忆胶囊会关联到当前宠物。请回到首页创建档案。",
            .capsuleEmptyTitle: "还没有记忆胶囊", .capsuleEmptyMessage: "写下一段想保存的话，留给之后某个想念的时刻。",
            .capsuleCreate: "创建记忆胶囊", .capsuleEdit: "编辑记忆胶囊", .capsuleDeleteAccessibility: "删除记忆胶囊", .capsuleEditAccessibility: "编辑记忆胶囊",
            .capsuleDeleteDialog: "删除这个记忆胶囊？", .capsuleFormSectionContent: "胶囊内容", .capsuleFormFieldTitle: "标题",
            .capsuleFormFieldDateLabel: "日期标签", .capsuleFormFieldBody: "写下想保存的话", .capsuleFormSectionIcon: "图标",
            .capsuleFormIconMorning: "清晨", .capsuleFormIconMissing: "想念", .capsuleFormIconPrecious: "珍贵时刻", .capsuleFormIconText: "文字",
            .capsuleFormIconNight: "夜晚", .capsuleFormIconGift: "礼物",
            .companionTitle: "Echo 陪伴", .companionNoPetSubtitle: "先创建宠物档案，再开始对话",
            .companionNoPetTitle: "需要先创建宠物档案", .companionNoPetMessage: "Echo Companion 会根据宠物档案回应你。请回到首页创建档案。",
            .companionResponding: "正在回应...", .companionInputPlaceholder: "写一句想说的话", .companionSendAccessibility: "发送消息",
            .companionAIStamp: "AI 生成", .companionAIDisclaimer: "（本消息由 AI 基于宠物记忆生成）", .companionUserAccessibility: "我说，%@", .companionEchoAccessibility: "Echo 回复，%@",
            .companionConnectionBackend: "后端智能体",
            .companionConnectionLocal: "本地智能体",
            .companionConnectionFallback: "后端暂不可用，已切回本地",
            .companionErrorNoPet: "请先创建宠物档案。",
            .companionErrorSendFailed: "发送失败，请重试。",
            .companionReplyMissing: "如果用 %@ 的记忆口吻回应，这份想念很轻，也很真。那些被你认真记下的习惯，还在安静地陪着你。",
            .companionReplyThanks: "%@ 的 LifePrint 里，有很多被你温柔照顾过的线索。谢谢你还愿意把这些小事保存下来。",
            .companionReplyDefault: "我记下了。它不像一个结论，更像一小段还在发光的陪伴。",
            .companionStarterMessage: "%@ 的 LifePrint 已经准备好。写下一段小记忆，我会帮你轻轻保存。",
            .profileTitle: "我的", .profileSubtitle: "账号、宠物、隐私与数据", .profileAccountTitle: "账号与陪伴档案",
            .profileAccountMessage: "Echo Pet 会把宠物档案、成长记忆和陪伴对话整理成一份可持续维护的生命记录。",
            .profileAccountStats: "宠物数 %d · 时间线 %d · 胶囊 %d", .profilePetTitle: "宠物资料",
            .profileAccountLocalDisplayName: "本地账号档案",
            .profileAccountSignedIn: "当前账号：%@",
            .profileAccountLocalOnlyBadge: "本地预览账号",
            .profileAccountCreateLocal: "创建本地账号档案",
            .profileAccountSignOut: "退出账号",
            .profileAccountSignOutDialog: "退出当前账号？",
            .profileAccountBackendPending: "正式账号服务接入后，这里会承载跨设备同步、数据导出和账号删除。",
            .profileAccountEmailBadge: "邮箱账号已连接",
            .profileAccountGuestBadge: "Supabase 游客账号",
            .profileAccountContinueGuest: "以游客模式继续",
            .profileAccountSigningIn: "正在连接账号...",
            .profileAccountSignInFailed: "无法登录。请确认邮箱已注册、邮箱验证已完成，并检查密码。",
            .profileAccountSignUpFailed: "无法创建账号。该邮箱可能已经注册，或密码不符合要求。",
            .profileAccountEmailConfirmationRequired: "如果该邮箱可用，验证邮件已发送。请完成验证后回来登录；如果已经注册，请直接登录或重置密码。",
            .profileAccountVerificationAlertTitle: "请去邮箱完成验证",
            .profileAccountVerificationAlertMessage: "我们会向这个邮箱发送验证邮件。下一步请打开收件箱或垃圾邮件，复制邮件里的验证码，回到 Echo Pet 输入验证码完成注册。",
            .profileAccountResetFailed: "无法发送重置邮件，请检查邮箱后重试。",
            .profileAccountCloudMessage: "登录后，宠物资料、时间线、每日陪伴计划、LifePrint 和陪伴对话会同步到 Supabase，并用于生成更贴近它的 Companion。",
            .profileAccountEmailTitle: "邮箱登录",
            .profileAccountEmailPlaceholder: "邮箱地址",
            .profileAccountPasswordPlaceholder: "密码",
            .profileAccountEmailSignIn: "邮箱登录",
            .profileAccountEmailSignUp: "创建账号",
            .profileAccountEmailHint: "使用 Supabase 邮箱账号保存和同步你的陪伴档案。密码至少 6 位。",
            .profileAccountAuthHint: "请输入有效邮箱地址和至少 6 位密码。",
            .profileAccountForgotPassword: "忘记密码？",
            .profileAccountResetSent: "重置密码邮件已发送，请检查收件箱（含垃圾邮件），复制邮件里的验证码后在下方设置新密码。",
            .profileAccountVerificationCodeTitle: "邮箱验证码",
            .profileAccountVerificationCodePlaceholder: "输入邮件里的验证码",
            .profileAccountVerificationCodeSubmit: "验证邮箱",
            .profileAccountVerificationCodeRequired: "请输入邮箱和邮件里的验证码。",
            .profileAccountVerificationSuccess: "邮箱已验证，账号已登录。",
            .profileAccountVerificationFailed: "邮箱验证码验证失败，请检查验证码或重新创建账号。",
            .profileAccountResetCodeTitle: "用验证码重置密码",
            .profileAccountResetCodeMessage: "不用点击邮件链接。复制邮件里的验证码，输入新密码后即可完成重置。",
            .profileAccountResetCodePlaceholder: "重置验证码",
            .profileAccountResetCodeSubmit: "用验证码更新密码",
            .profileAccountResetCodeRequired: "请输入邮箱和邮件里的重置验证码。",
            .profilePetEmpty: "还没有宠物资料。创建后，LifePrint、时间线和陪伴对话都会获得真实上下文。",
            .profilePetCreate: "创建宠物资料", .profilePetEdit: "编辑宠物资料", .profilePrivacyTitle: "隐私与 AI 透明度",
            .profilePrivacyMessage1: "照片、文字和对话只应用于宠物记忆整理、LifePrint、时间轴、记忆胶囊和陪伴回复。",
            .profilePrivacyMessage2: "AI 生成内容会明确标识，并且不会被包装成真实宠物复活。",
            .profilePermissionsTitle: "媒体权限", .profileSettingsTitle: "设置", .profileSettingsSubtitle: "隐私政策、用户协议、聊天清理和数据删除",
            .profileSyncTitle: "同步准备",
            .profileSyncMessage: "当前仍是本地优先体验。以下数据已经按后端同步边界整理，接入账号服务后可以逐步上传。",
            .profileSyncLocalOnlyStatus: "仅保存在本机",
            .profileSyncReadyStatus: "已准备接入后端同步",
            .profileSyncQueuedChanges: "待同步项目 %d 个",
            .profileSyncDomains: "覆盖范围：%@",
            .profileSyncDomainAccount: "账号",
            .profileSyncDomainPetProfile: "宠物资料",
            .profileSyncDomainMemoryFiles: "Memory 文件",
            .profileSyncDomainLifePrint: "LifePrint",
            .profileSyncDomainTimeline: "Timeline",
            .profileSyncDomainMemoryCapsules: "Memory Capsule",
            .profileSyncDomainCompanion: "Companion",
            .settingsTitle: "设置", .settingsSubtitle: "语言、隐私、协议、数据与版本", .settingsLanguageTitle: "语言",
            .settingsLanguageMessage: "在中文和英文之间切换 App 界面。用户记忆和宠物名字会保持原样。", .settingsLanguagePicker: "语言",
            .settingsPrivacyTitle: "隐私政策", .settingsPrivacyMessage1: "宠物档案、成长记忆、记忆胶囊和聊天内容仅用于 Echo Pet 的生命记录与陪伴体验。",
            .settingsPrivacyMessage2: "云端和 AI 服务会遵循最小必要原则，用户可以关闭 AI 记忆使用并删除账号数据。",
            .settingsViewFullPolicy: "查看完整隐私政策",
            .settingsTermsTitle: "用户协议", .settingsTermsMessage1: "Echo Pet 是基于真实记忆的陪伴产品，不提供医疗、训练或法律建议。",
            .settingsTermsMessage2: "陪伴对话可以拟人化表达，但不会声称宠物被真实复活。",
            .settingsViewFullTerms: "查看完整用户协议",
            .settingsPrivacyIntro: "Echo Pet 用于记录宠物生命故事，并基于你选择保存的资料提供陪伴体验。",
            .settingsPrivacyCollectedTitle: "收集的数据",
            .settingsPrivacyCollectedBody: "我们会保存你主动创建的宠物资料、成长时间线、照片素材、每日陪伴计划、LifePrint、记忆胶囊和陪伴对话。相册、相机和麦克风权限只在你主动使用相关功能时请求。",
            .settingsPrivacyUseTitle: "数据用途",
            .settingsPrivacyUseBody: "这些数据用于展示宠物档案、整理成长记忆、生成 LifePrint、创建记忆胶囊、同步设备数据，并让 Companion 更贴近宠物的真实性格和关系。",
            .settingsPrivacyAIThirdPartyTitle: "AI 与第三方服务",
            .settingsPrivacyAIThirdPartyBody: "当 AI 记忆开关开启时，Echo Pet 会把必要的宠物上下文通过 Supabase 后端发送给 DeepSeek-v4-flash 生成回复。AI 内容会明确标识，并且不能声称宠物真实复活。",
            .settingsPrivacyRetentionTitle: "保存期限",
            .settingsPrivacyRetentionBody: "数据会保存到你主动删除账号或清除数据为止。游客模式数据可能无法跨设备恢复。",
            .settingsPrivacyDeletionTitle: "删除与控制",
            .settingsPrivacyDeletionBody: "你可以清空聊天、删除本地数据，或在登录后发起账号与云端数据删除。删除后，相关宠物资料、记忆和对话将不可恢复。",
            .settingsPrivacyContactTitle: "联系与支持",
            .settingsPrivacyContactBody: "如需隐私、数据访问或删除支持，请通过 Echo Pet 的 App Store 产品页支持链接联系我们，或在 App 内进入“我的 > 设置 > 数据管理”处理可用的数据控制选项。",
            .settingsTermsIntro: "使用 Echo Pet 即表示你理解它是一款记忆记录与陪伴产品，而不是医疗、训练或法律服务。",
            .settingsTermsServiceTitle: "服务内容",
            .settingsTermsServiceBody: "Echo Pet 提供宠物资料、成长时间线、LifePrint、记忆胶囊、背景相册、每日陪伴计划和 Companion 对话。",
            .settingsTermsNoAdviceTitle: "非专业建议",
            .settingsTermsNoAdviceBody: "App 内内容不能替代兽医、训练师、法律或其他专业建议。紧急健康问题请联系专业机构。",
            .settingsTermsUserContentTitle: "用户内容",
            .settingsTermsUserContentBody: "你应确保上传的照片、文字和音频由你拥有或有权使用，并避免上传他人的敏感信息。",
            .settingsTermsAIContentTitle: "AI 内容边界",
            .settingsTermsAIContentBody: "Companion 可以使用宠物第一视角表达陪伴，但必须基于已有记忆，不能编造重大经历，也不能包装成宠物复活。",
            .settingsTermsDeletionTitle: "数据删除",
            .settingsTermsDeletionBody: "删除账号或云端数据后，相关内容将从 Echo Pet 服务中移除。部分备份或日志可能按安全和合规需要短期保留。",
            .settingsDataTitle: "数据管理", .settingsDataClearChat: "清空聊天记录", .settingsDataDeleteAll: "删除全部本地数据", .settingsDataDeleteCloud: "删除账号与云端数据",
            .settingsDataDeleteInProgress: "正在删除数据...",
            .settingsDataDeleteFailed: "数据删除失败，请检查网络后重试。",
            .settingsDataCloudMessage: "已登录账号会优先删除 Supabase 云端数据和账号；本地预览账号只会清除本机数据。",
            .settingsDataLoadDemo: "载入演示数据", .settingsDataDemoMessage: "仅用于本地预览，会用干净的宠物档案、成长记忆、LifePrint、记忆胶囊和陪伴消息替换当前本地数据。",
            .settingsAITitle: "AI 生成提示", .settingsAIMessage: "所有拟人化陪伴回复都需要展示 AI 生成提示。",
            .settingsAIMemoryToggleTitle: "允许 AI 使用宠物记忆",
            .settingsAIMemoryToggleMessage: "开启后，Echo Companion 会参考宠物资料、LifePrint、时间线、今日陪伴计划和聊天历史生成回复。",
            .settingsAIToneCurrent: "默认语气：温柔陪伴型",
            .settingsVersionTitle: "版本", .settingsVersionName: "Echo Pet 1.0", .settingsVersionStage: "产品完善与体验打磨阶段。",
            .settingsClearChatDialog: "清空聊天记录？", .settingsDeleteAllDialog: "删除全部本地数据？", .settingsDeleteCloudDialog: "删除账号与云端数据？", .settingsLoadDemoDialog: "载入演示数据？",
            .passwordResetTitle: "设置新密码",
            .passwordResetMessage: "请输入新的登录密码。完成后，请回到邮箱登录入口使用新密码登录。",
            .passwordResetNewPassword: "新密码（至少 6 位）",
            .passwordResetConfirmPassword: "再次输入新密码",
            .passwordResetSubmit: "更新密码",
            .passwordResetSuccess: "密码已更新，请使用新密码登录。",
            .passwordResetFailed: "密码更新失败。请重新发送重置邮件后再试。",
            .passwordResetTooShort: "密码至少需要 6 位。",
            .passwordResetMismatch: "两次输入的密码不一致。",
            .profileFormTitleCreate: "创建宠物档案", .profileFormTitleEdit: "编辑宠物档案",
            .profileFormSectionAvatar: "宠物头像", .profileFormAvatarChoose: "选择宠物头像", .profileFormAvatarChange: "更换宠物头像", .profileFormAvatarRemove: "移除宠物头像",
            .profileFormSectionBasic: "基础信息",
            .profileFormFieldName: "名字", .profileFormFieldBreed: "品种", .profileFormFieldAge: "年龄", .profileFormFieldPersonality: "性格关键词",
            .profileFormFieldMBTI: "MBTI 或性格标签", .profileFormSectionLife: "生活印记", .profileFormFieldFavoriteThings: "喜欢的事物，用逗号分隔",
            .profileFormFieldHabits: "习惯，用逗号分隔", .profileFormDefaultBreed: "未填写品种", .profileFormDefaultAge: "未填写年龄", .profileFormDefaultMBTI: "温柔型",
            .permissionPhotosTitle: "照片", .permissionPhotosPurpose: "添加宠物照片、时间线照片和记忆胶囊素材。",
            .permissionCameraTitle: "相机", .permissionCameraPurpose: "直接拍摄新的宠物记忆。",
            .permissionMicrophoneTitle: "麦克风", .permissionMicrophonePurpose: "录制语音记忆，供未来 AI 理解。",
            .permissionStatusNotDetermined: "允许", .permissionStatusAuthorized: "已允许", .permissionStatusDenied: "已拒绝",
            .permissionStatusLimited: "有限访问", .permissionStatusRestricted: "受限制", .permissionStatusUnavailable: "不可用"
        ],
        .en: [
            .tabHome: "Home", .tabTimeline: "Timeline", .tabLifePrint: "LifePrint", .tabCompanion: "Companion", .tabProfile: "My",
            .commonCancel: "Cancel", .commonSave: "Save", .commonDelete: "Delete", .commonEdit: "Edit", .commonClear: "Clear", .commonOK: "OK", .commonDone: "Done", .commonNotRecorded: "Not recorded yet",
            .brandIntroTitle: "Echo Pet",
            .brandIntroMessage: "Keep companionship gently recorded.",
            .brandIntroStart: "Get Started",
            .onboardingTitle: "Create the first life profile",
            .onboardingMessage: "Start with a name, a personality, and one little habit. Echo Pet will turn future memories into Timeline, LifePrint, Memory Capsule, and Companion context.",
            .onboardingCreatePet: "Create Pet Profile",
            .onboardingStep1Title: "Create pet profile", .onboardingStep1Subtitle: "Record who your pet is and what your relationship means.",
            .onboardingStep2Title: "Add the first memory", .onboardingStep2Subtitle: "Write down a first day home, a walk, or one quiet everyday moment.",
            .onboardingStep3Title: "Build a companion archive", .onboardingStep3Subtitle: "Gradually prepare LifePrint, Timeline, Memory Capsule, and Companion context.",
            .accountGateTitle: "Save your companion archive",
            .accountGateMessage: "Sign in with email to sync your archive across devices, or continue as a guest to start right away.",
            .accountGateEmailTitle: "Email",
            .accountGateEmailPlaceholder: "Email address",
            .accountGatePasswordPlaceholder: "Password (at least 6 characters)",
            .accountGateSignIn: "Sign In",
            .accountGateSignUp: "Create Account",
            .accountGateContinueGuest: "Continue as Guest",
            .accountGateForgotPassword: "Forgot password?",
            .accountGateAuthHint: "Please enter a valid email address and a password of at least 6 characters",
            .accountGateResetSent: "Reset email sent. Please check your inbox.",
            .accountGateSigningIn: "Processing…",
            .homeTitle: "Echo Pet", .homeSubtitle: "Keep companionship gently recorded", .homePetProfile: "Pet Profile", .homeEditPetProfile: "Edit pet profile",
            .homeCreatePetEmptyTitle: "Create a pet profile first",
            .homeCreatePetEmptyMessage: "After you record a name, personality, and daily habits, Timeline, LifePrint, and Companion can use real context.",
            .homeCreatePetEmptyAction: "Create pet profile",
            .homeTileTimelineTitle: "Timeline", .homeTileTimelineSubtitle: "Life moments",
            .homeTileLifePrintTitle: "LifePrint", .homeTileLifePrintSubtitle: "Companion profile",
            .homeTileCompanionTitle: "Echo Companion", .homeTileCompanionSubtitle: "Continue talking",
            .homeTileCapsuleTitle: "Memory Capsule", .homeTileCapsuleSubtitle: "Save keepsakes",
            .homeLatestMemory: "Latest Memory", .homeNoMemoryTitle: "No growth memories yet",
            .homeNoMemoryMessage: "Start with a first day home, a walk, or one quiet morning.",
            .homeNoMemoryAction: "Add first memory", .homeSettings: "Settings",
            .backgroundAlbumTitle: "Background Album",
            .backgroundAlbumSubtitle: "Keep favorite photos and turn them into a soft background across the app.",
            .backgroundAlbumAddPhotos: "Add Photos",
            .backgroundAlbumPhotoCount: "%d background photos saved",
            .backgroundAlbumEmptyTitle: "No background photos yet",
            .backgroundAlbumEmptyMessage: "Add one photo to use it as a fixed background. Add more to randomize, refresh daily, or cycle gently.",
            .backgroundAlbumModeTitle: "Background Mode",
            .backgroundAlbumModeFixed: "Fixed Photo",
            .backgroundAlbumModeRandom: "Random Each Time",
            .backgroundAlbumModeDailyRandom: "Daily Random",
            .backgroundAlbumModeGentleCycle: "Gentle Cycle",
            .backgroundAlbumBlurTitle: "Background Blur",
            .backgroundAlbumBlurValue: "%d",
            .backgroundAlbumSetFixed: "Set fixed background",
            .backgroundAlbumIncludeInRotation: "Include in rotation",
            .backgroundAlbumRemovePhoto: "Remove background photo",
            .backgroundAlbumRestoreDefault: "Restore Default Background",
            .backgroundAlbumImporting: "Importing background photos",
            .backgroundAlbumImportFailedTitle: "Some background photos could not be imported",
            .backgroundAlbumImportFailedMessage: "%d photos could not be imported. Try again or choose different photos.",
            .backgroundAlbumCurrentBackground: "Background Photos",
            .backgroundAlbumAccessibility: "Open background album",
            .homeDailyMoodTitle: "Today's Mood",
            .homeDailyMoodFallback: "Today can start with one small act of care.",
            .homeDailyMoodMessage1: "%@ feels like a blanket warmed by sunlight today, and wants to make sure you ate well.",
            .homeDailyMoodMessage2: "%@ wants to hear their name today, and hopes you rest slowly after work.",
            .homeDailyMoodMessage3: "%@ feels soft today, like waiting by the door for one gentle glance.",
            .homeDailyMoodMessage4: "%@ wants to share a little quiet with you, and remind you to drink water.",
            .homeDailyMoodMessage5: "%@ misses you a little today. Ten minutes together would already mean a lot.",
            .homeDailyTasksTitle: "Today's Care Plan",
            .homeDailyTasksSubtitle: "Plan the small things you want to do together today.",
            .homeDailyTasksProgress: "%d / %d done",
            .homeDailyTasksAllDone: "Today's care plan is complete",
            .homeDailyTasksEmptyTitle: "No plan yet today",
            .homeDailyTasksEmptyMessage: "Start with feeding, playtime, grooming, or one photo.",
            .homeDailyTaskAdd: "Add Task",
            .homeDailyTasksCollapse: "Collapse today's care plan",
            .homeDailyTasksExpand: "Expand today's care plan",
            .homeDailyTasksMove: "Move today's care plan",
            .homeDailyTaskNoTime: "Today",
            .homeDailyTaskCompleted: "Done",
            .homeDailyTaskPending: "Pending",
            .homeDailyTaskCompleteAccessibility: "Complete task, %@",
            .homeDailyTaskReopenAccessibility: "Reopen task, %@",
            .dailyTaskFormTitleCreate: "Add Today's Task",
            .dailyTaskFormTitleEdit: "Edit Today's Task",
            .dailyTaskFormSectionTemplate: "Task Template",
            .dailyTaskFormSectionDetails: "Task Details",
            .dailyTaskFormFieldTitle: "Task name",
            .dailyTaskFormFieldNote: "Note, optional",
            .dailyTaskFormUseTime: "Set time",
            .dailyTaskFormFieldTime: "Time",
            .dailyTaskTemplateFeeding: "Food/Water",
            .dailyTaskTemplateWalk: "Walk",
            .dailyTaskTemplateGrooming: "Groom",
            .dailyTaskTemplatePlay: "Play",
            .dailyTaskTemplateCleaning: "Clean",
            .dailyTaskTemplateMedicine: "Medicine",
            .dailyTaskTemplatePhoto: "Photo",
            .dailyTaskTemplateCustom: "Custom",
            .timelineTitle: "Timeline", .timelineSubtitleNoPet: "Create a pet profile before recording life stories", .timelineSubtitlePet: "%@'s life story",
            .timelineNoPetTitle: "Create a pet profile first", .timelineNoPetMessage: "Timeline keeps life moments around the current pet. Go back Home and create a profile first.",
            .timelineEmptyTitle: "No life moments yet", .timelineEmptyMessage: "Add a first day home, a walk, or one quiet everyday moment so LifePrint has real material.",
            .timelineAdd: "Add Memory", .timelineEdit: "Edit Memory", .timelineDeleteAccessibility: "Delete growth memory", .timelineEditAccessibility: "Edit growth memory",
            .timelineDeleteDialog: "Delete this growth memory?", .timelineFormTitleCreate: "Add Growth Memory", .timelineFormTitleEdit: "Edit Growth Memory",
            .timelineFormSectionMemory: "Memory", .timelineFormFieldTitle: "Title", .timelineFormFieldDate: "Date", .timelineFormFieldStory: "Write this story",
            .timelineFormSectionIcon: "Icon", .timelineFormIconHome: "First day home", .timelineFormIconDaily: "Daily moment",
            .timelineFormIconLove: "Close companion", .timelineFormIconPaw: "Growth footprint", .timelineFormIconToy: "Toy", .timelineFormIconNature: "Nature",
            .timelineFormSectionPhotos: "Photos", .timelineFormAddPhotos: "Add Photos", .timelineFormPhotoCount: "%d / %d photos",
            .timelineFormPhotoLimit: "Each memory can keep up to 9 photos.", .timelineFormDeletePhoto: "Delete photo",
            .timelineFormPhotoEmptyHint: "Add up to 9 photos. After saving, they will appear as an ordered photo stack.",
            .timelineFormPhotoImporting: "Importing photos...",
            .timelineFormPhotoMaxReached: "You have reached the 9-photo limit. Remove one photo to add another.",
            .timelineFormPhotoImportFailedTitle: "Some photos could not be imported",
            .timelineFormPhotoImportFailedMessage: "%d photos could not be imported. Try again or choose different photos.",
            .timelineFormDiscardDialog: "Discard unsaved changes?", .timelineFormDiscardChanges: "Discard Changes", .timelineFormKeepEditing: "Keep Editing",
            .timelinePhotoCountBadge: "%d photos",
            .lifePrintTitle: "LifePrint", .lifePrintSubtitle: "A companion summary shaped by real memories",
            .lifePrintNoPetTitle: "Create a pet profile first", .lifePrintNoPetMessage: "LifePrint is generated from the pet profile, Timeline, and memories. Please create a profile from Home first.",
            .lifePrintResultTitle: "Generated Result", .lifePrintStatusNotGenerated: "Not generated yet", .lifePrintStatusUpdatedAt: "Updated %@",
            .lifePrintStatusGenerating: "Organizing profile and growth memories...", .lifePrintStatusEmpty: "Tap the top-right button to generate the first LifePrint. Add more memories and regenerate later.",
            .lifePrintGenerateAccessibility: "Generate LifePrint", .lifePrintRegenerateAccessibility: "Regenerate LifePrint",
            .lifePrintRowName: "Name", .lifePrintRowBreed: "Breed", .lifePrintRowAge: "Age", .lifePrintRowPersonality: "Personality Tags",
            .lifePrintGroupFavoriteThings: "Favorite Things", .lifePrintGroupHabits: "Daily Habits",
            .lifePrintErrorNoPet: "Create a pet profile first.",
            .lifePrintErrorInterrupted: "Generation was interrupted. Please try again.",
            .lifePrintSummaryWithMemory: "%@ is a %@ companion. Favorite things: %@. Daily habits: %@. %@",
            .lifePrintSummaryNoMemory: "No growth moments yet. You can start with a first time, a walk, or one quiet everyday moment.",
            .lifePrintSummaryLatestMemory: "The latest memory is \"%@\", making %@'s companion archive more specific.",
            .lifePrintSummaryDefaultFavorites: "the little habits you remembered",
            .lifePrintSummaryDefaultHabits: "quiet ways of staying close",
            .capsuleTitle: "Memory Capsule", .capsuleSubtitle: "Turn today into a gentle keepsake",
            .capsuleNoPetTitle: "Create a pet profile first", .capsuleNoPetMessage: "Memory Capsules are linked to the current pet. Go back Home and create a profile first.",
            .capsuleEmptyTitle: "No memory capsules yet", .capsuleEmptyMessage: "Write a sentence you want to save for a future moment of remembering.",
            .capsuleCreate: "Create Memory Capsule", .capsuleEdit: "Edit Memory Capsule", .capsuleDeleteAccessibility: "Delete memory capsule", .capsuleEditAccessibility: "Edit memory capsule",
            .capsuleDeleteDialog: "Delete this memory capsule?", .capsuleFormSectionContent: "Capsule Content", .capsuleFormFieldTitle: "Title",
            .capsuleFormFieldDateLabel: "Date label", .capsuleFormFieldBody: "Write what you want to keep", .capsuleFormSectionIcon: "Icon",
            .capsuleFormIconMorning: "Morning", .capsuleFormIconMissing: "Missing", .capsuleFormIconPrecious: "Precious moment", .capsuleFormIconText: "Letter",
            .capsuleFormIconNight: "Night", .capsuleFormIconGift: "Gift",
            .companionTitle: "Echo Companion", .companionNoPetSubtitle: "Create a pet profile before starting a conversation",
            .companionNoPetTitle: "Create a pet profile first", .companionNoPetMessage: "Echo Companion replies based on the pet profile. Go back Home and create a profile first.",
            .companionResponding: "Responding...", .companionInputPlaceholder: "Write something you want to say", .companionSendAccessibility: "Send message",
            .companionAIStamp: "AI generated", .companionAIDisclaimer: "(This message was generated by AI based on pet memories)", .companionUserAccessibility: "Me: %@", .companionEchoAccessibility: "Echo reply: %@",
            .companionConnectionBackend: "Backend Agent",
            .companionConnectionLocal: "Local Agent",
            .companionConnectionFallback: "Backend unavailable, using local fallback",
            .companionErrorNoPet: "Create a pet profile first.",
            .companionErrorSendFailed: "Sending failed. Please try again.",
            .companionReplyMissing: "If I answer from %@'s memory, this missing is soft and real. The little habits you saved are still quietly staying with you.",
            .companionReplyThanks: "%@'s LifePrint carries many traces of your gentle care. Thank you for still keeping these small moments.",
            .companionReplyDefault: "I have saved that. It feels less like a conclusion and more like a small piece of companionship still glowing.",
            .companionStarterMessage: "%@'s LifePrint is ready. Share a small memory, and I will help keep it warm.",
            .profileTitle: "My", .profileSubtitle: "Account, pet, privacy, and data", .profileAccountTitle: "Account and Companion Archive",
            .profileAccountMessage: "Echo Pet organizes pet profiles, growth memories, and companion conversations into a life archive you can keep maintaining.",
            .profileAccountStats: "Pets %d · Timeline %d · Capsules %d", .profilePetTitle: "Pet Profile",
            .profileAccountLocalDisplayName: "Local Account Archive",
            .profileAccountSignedIn: "Current account: %@",
            .profileAccountLocalOnlyBadge: "Local preview account",
            .profileAccountCreateLocal: "Create Local Account",
            .profileAccountSignOut: "Sign Out",
            .profileAccountSignOutDialog: "Sign out of the current account?",
            .profileAccountBackendPending: "After the account service is connected, this area will support cross-device sync, data export, and account deletion.",
            .profileAccountEmailBadge: "Email account connected",
            .profileAccountGuestBadge: "Supabase guest account",
            .profileAccountContinueGuest: "Continue as guest",
            .profileAccountSigningIn: "Connecting account...",
            .profileAccountSignInFailed: "Unable to sign in. Check that the email is registered, verified, and that the password is correct.",
            .profileAccountSignUpFailed: "Unable to create account. This email may already be registered, or the password may not meet requirements.",
            .profileAccountEmailConfirmationRequired: "If this email is available, a verification email was sent. Verify it before signing in; if it is already registered, sign in or reset the password.",
            .profileAccountVerificationAlertTitle: "Verify your email next",
            .profileAccountVerificationAlertMessage: "We will send a verification email to this address. Next, open your inbox or spam folder, copy the verification code, and enter it in Echo Pet to finish registration.",
            .profileAccountResetFailed: "Unable to send reset email. Check the email address and try again.",
            .profileAccountCloudMessage: "After sign-in, pet profiles, Timeline, daily care plans, LifePrint, and companion conversations sync to Supabase so Companion can better understand your pet.",
            .profileAccountEmailTitle: "Email Sign In",
            .profileAccountEmailPlaceholder: "Email address",
            .profileAccountPasswordPlaceholder: "Password",
            .profileAccountEmailSignIn: "Sign In",
            .profileAccountEmailSignUp: "Create Account",
            .profileAccountEmailHint: "Use a Supabase email account to save and sync your companion archive. Passwords need at least 6 characters.",
            .profileAccountAuthHint: "Please enter a valid email address and a password with at least 6 characters.",
            .profileAccountForgotPassword: "Forgot password?",
            .profileAccountResetSent: "Password reset email sent. Check your inbox or spam folder, copy the code, then set a new password below.",
            .profileAccountVerificationCodeTitle: "Email Verification Code",
            .profileAccountVerificationCodePlaceholder: "Enter the code from the email",
            .profileAccountVerificationCodeSubmit: "Verify Email",
            .profileAccountVerificationCodeRequired: "Enter your email address and the code from the email.",
            .profileAccountVerificationSuccess: "Email verified. You are signed in.",
            .profileAccountVerificationFailed: "Email verification failed. Check the code or create the account again.",
            .profileAccountResetCodeTitle: "Reset with Code",
            .profileAccountResetCodeMessage: "You do not need to open the email link. Copy the code from the email, enter a new password, and update it here.",
            .profileAccountResetCodePlaceholder: "Reset code",
            .profileAccountResetCodeSubmit: "Update with Code",
            .profileAccountResetCodeRequired: "Enter your email address and the reset code from the email.",
            .profilePetEmpty: "No pet profile yet. After creating one, LifePrint, Timeline, and Companion will have real context.",
            .profilePetCreate: "Create pet profile", .profilePetEdit: "Edit pet profile", .profilePrivacyTitle: "Privacy and AI Transparency",
            .profilePrivacyMessage1: "Photos, text, and conversations are used only for pet memory organization, LifePrint, Timeline, Memory Capsule, and Companion replies.",
            .profilePrivacyMessage2: "AI-generated content is clearly marked and is never presented as real pet resurrection.",
            .profilePermissionsTitle: "Media Permissions", .profileSettingsTitle: "Settings", .profileSettingsSubtitle: "Privacy policy, user agreement, chat cleanup, and data deletion",
            .profileSyncTitle: "Sync Readiness",
            .profileSyncMessage: "The experience is still local-first. These data areas now follow the future backend sync boundary and can be uploaded after account services are connected.",
            .profileSyncLocalOnlyStatus: "Stored on this device only",
            .profileSyncReadyStatus: "Ready for backend sync",
            .profileSyncQueuedChanges: "%d items waiting for sync",
            .profileSyncDomains: "Coverage: %@",
            .profileSyncDomainAccount: "Account",
            .profileSyncDomainPetProfile: "Pet Profile",
            .profileSyncDomainMemoryFiles: "Memory Files",
            .profileSyncDomainLifePrint: "LifePrint",
            .profileSyncDomainTimeline: "Timeline",
            .profileSyncDomainMemoryCapsules: "Memory Capsule",
            .profileSyncDomainCompanion: "Companion",
            .settingsTitle: "Settings", .settingsSubtitle: "Language, privacy, agreement, data, and version", .settingsLanguageTitle: "Language",
            .settingsLanguageMessage: "Switch the app interface between Chinese and English. User memories and pet names stay unchanged.", .settingsLanguagePicker: "Language",
            .settingsPrivacyTitle: "Privacy Policy", .settingsPrivacyMessage1: "Pet profiles, growth memories, Memory Capsules, and chat content are used only for Echo Pet's life archive and companionship experience.",
            .settingsPrivacyMessage2: "Cloud and AI services follow data minimization. You can turn off AI memory use and delete account data.",
            .settingsViewFullPolicy: "View full privacy policy",
            .settingsTermsTitle: "User Agreement", .settingsTermsMessage1: "Echo Pet is a memory-based companionship product and does not provide medical, training, or legal advice.",
            .settingsTermsMessage2: "Companion chat may use anthropomorphic wording, but it must not claim that a pet has truly been resurrected.",
            .settingsViewFullTerms: "View full user agreement",
            .settingsPrivacyIntro: "Echo Pet helps you record a pet's life story and provide companionship from the information you choose to save.",
            .settingsPrivacyCollectedTitle: "Data We Collect",
            .settingsPrivacyCollectedBody: "We store pet profiles, timeline memories, photo materials, daily care plans, LifePrint, Memory Capsules, and companion conversations that you create. Photos, camera, and microphone permissions are requested only when you use related features.",
            .settingsPrivacyUseTitle: "How Data Is Used",
            .settingsPrivacyUseBody: "Data is used to show pet profiles, organize memories, generate LifePrint, create Memory Capsules, sync app data, and help Companion reflect your pet's personality and relationship more accurately.",
            .settingsPrivacyAIThirdPartyTitle: "AI and Third-Party Services",
            .settingsPrivacyAIThirdPartyBody: "When AI memory is enabled, Echo Pet sends necessary pet context through the Supabase backend to DeepSeek-v4-flash to generate replies. AI content is clearly labeled and must not claim that a pet has truly returned to life.",
            .settingsPrivacyRetentionTitle: "Retention",
            .settingsPrivacyRetentionBody: "Data is retained until you delete your account or clear data. Guest-mode data may not be recoverable across devices.",
            .settingsPrivacyDeletionTitle: "Deletion and Control",
            .settingsPrivacyDeletionBody: "You can clear chat history, delete local data, or request account and cloud data deletion after signing in. Deleted pet profiles, memories, and conversations cannot be restored.",
            .settingsPrivacyContactTitle: "Contact and Support",
            .settingsPrivacyContactBody: "For privacy, data access, or deletion support, use the support link on Echo Pet's App Store listing or go to My > Settings > Data Management in the app for available data control options.",
            .settingsTermsIntro: "By using Echo Pet, you understand that it is a memory archive and companionship app, not medical, training, or legal service.",
            .settingsTermsServiceTitle: "Service",
            .settingsTermsServiceBody: "Echo Pet provides pet profiles, Timeline, LifePrint, Memory Capsule, background album, daily care plans, and Companion chat.",
            .settingsTermsNoAdviceTitle: "No Professional Advice",
            .settingsTermsNoAdviceBody: "App content does not replace advice from veterinarians, trainers, lawyers, or other professionals. For urgent health concerns, contact a qualified professional.",
            .settingsTermsUserContentTitle: "User Content",
            .settingsTermsUserContentBody: "You should only upload photos, text, and audio that you own or have permission to use, and avoid uploading other people's sensitive information.",
            .settingsTermsAIContentTitle: "AI Boundaries",
            .settingsTermsAIContentBody: "Companion may speak from a pet-like perspective, but it must be grounded in saved memories, must not invent major experiences, and must not present itself as pet resurrection.",
            .settingsTermsDeletionTitle: "Data Deletion",
            .settingsTermsDeletionBody: "After account or cloud data deletion, related content is removed from Echo Pet services. Some backups or logs may be retained briefly for security and compliance.",
            .settingsDataTitle: "Data Management", .settingsDataClearChat: "Clear chat history", .settingsDataDeleteAll: "Delete all local data", .settingsDataDeleteCloud: "Delete account and cloud data",
            .settingsDataDeleteInProgress: "Deleting data...",
            .settingsDataDeleteFailed: "Data deletion failed. Check your connection and try again.",
            .settingsDataCloudMessage: "Signed-in accounts delete Supabase cloud data and the account first. Local preview accounts only clear this device.",
            .settingsDataLoadDemo: "Load demo data", .settingsDataDemoMessage: "For local preview only. Replaces current local data with a clean pet profile, memories, LifePrint, capsule, and companion messages.",
            .settingsAITitle: "AI Generation Notice", .settingsAIMessage: "All anthropomorphic companion replies must show an AI-generated notice.",
            .settingsAIMemoryToggleTitle: "Allow AI to use pet memories",
            .settingsAIMemoryToggleMessage: "When enabled, Echo Companion uses the pet profile, LifePrint, Timeline, today's care plan, and chat history to generate replies.",
            .settingsAIToneCurrent: "Default tone: gentle companion",
            .settingsVersionTitle: "Version", .settingsVersionName: "Echo Pet 1.0", .settingsVersionStage: "Product completion and experience polish phase.",
            .settingsClearChatDialog: "Clear chat history?", .settingsDeleteAllDialog: "Delete all local data?", .settingsDeleteCloudDialog: "Delete account and cloud data?", .settingsLoadDemoDialog: "Load demo data?",
            .passwordResetTitle: "Set New Password",
            .passwordResetMessage: "Enter a new sign-in password. After it is updated, return to email sign-in and use the new password.",
            .passwordResetNewPassword: "New password (at least 6 characters)",
            .passwordResetConfirmPassword: "Confirm new password",
            .passwordResetSubmit: "Update Password",
            .passwordResetSuccess: "Password updated. Sign in with the new password.",
            .passwordResetFailed: "Password update failed. Send a new reset email and try again.",
            .passwordResetTooShort: "Password must be at least 6 characters.",
            .passwordResetMismatch: "The two passwords do not match.",
            .profileFormTitleCreate: "Create Pet Profile", .profileFormTitleEdit: "Edit Pet Profile",
            .profileFormSectionAvatar: "Pet Avatar", .profileFormAvatarChoose: "Choose pet avatar", .profileFormAvatarChange: "Change pet avatar", .profileFormAvatarRemove: "Remove pet avatar",
            .profileFormSectionBasic: "Basic Information",
            .profileFormFieldName: "Name", .profileFormFieldBreed: "Breed", .profileFormFieldAge: "Age", .profileFormFieldPersonality: "Personality keywords",
            .profileFormFieldMBTI: "MBTI or personality tag", .profileFormSectionLife: "Life Imprint", .profileFormFieldFavoriteThings: "Favorite things, separated by commas",
            .profileFormFieldHabits: "Habits, separated by commas", .profileFormDefaultBreed: "Breed not set", .profileFormDefaultAge: "Age not set", .profileFormDefaultMBTI: "Gentle type",
            .permissionPhotosTitle: "Photos", .permissionPhotosPurpose: "Add pet photos, timeline photos, and capsule materials.",
            .permissionCameraTitle: "Camera", .permissionCameraPurpose: "Capture new pet memories directly.",
            .permissionMicrophoneTitle: "Microphone", .permissionMicrophonePurpose: "Record voice memories for future AI understanding.",
            .permissionStatusNotDetermined: "Allow", .permissionStatusAuthorized: "Allowed", .permissionStatusDenied: "Denied",
            .permissionStatusLimited: "Limited", .permissionStatusRestricted: "Restricted", .permissionStatusUnavailable: "Unavailable"
        ]
    ]
}
