# Echo Pet Privacy Policy

Last updated: August 9, 2026

## 中文

### 1. 我们如何定位 Echo Pet

Echo Pet 是一款宠物生命记忆记录与 AI 陪伴应用。你可以创建宠物资料、记录成长时间线、保存照片和文字记忆、查看 LifePrint、生成 Memory Capsule，并与 Echo Companion 进行基于宠物记忆的陪伴对话。

Echo Pet 不会把 AI 对话包装成宠物复活。所有拟人化陪伴回复都应展示 AI 生成提示。

### 2. 我们收集或处理的数据

根据你使用的功能，Echo Pet 可能会收集或处理以下数据：

- 账号信息：邮箱地址、Supabase 用户 ID、登录状态。
- 宠物资料：宠物名称、品种、年龄、生日、关系标签、性格描述、喜好、习惯、头像。
- 时间线与记忆内容：标题、文字记录、日期、分类、重要程度、情绪或行为标签、照片、视频或音频素材。
- 每日陪伴计划：任务标题、备注、日期、提醒时间、完成状态。
- LifePrint 与 Memory Capsule：基于你保存的宠物资料、时间线、记忆和任务整理出的摘要、标签、纪念内容和来源记录。
- Companion 对话：你发送的消息、AI 回复、生成时间、AI 记忆开关状态、用于生成回复的必要上下文。
- 应用设置：语言设置、AI 记忆使用开关、背景相册和本地偏好。

Echo Pet 不会为了广告追踪出售你的个人数据，也不会接入第三方广告追踪 SDK。当前版本不主动收集联系人、精确位置、健康数据或支付卡信息。

### 3. 照片、相机和麦克风权限

Echo Pet 只会在你主动使用对应功能时请求权限：

- 照片权限用于选择宠物照片、时间线照片、背景相册图片和记忆胶囊素材。
- 相机权限用于直接拍摄新的宠物记忆。
- 麦克风权限用于录制语音记忆，供当前或未来的记忆理解功能使用。

你可以在 iOS 系统设置中随时撤回权限。撤回权限后，相关功能可能无法继续使用，但不会影响其他核心功能。

### 4. 我们如何使用数据

Echo Pet 使用数据用于：

- 创建、编辑、展示和同步宠物资料。
- 保存和展示时间线、每日任务、LifePrint 与 Memory Capsule。
- 让 Echo Companion 在你允许 AI 使用宠物记忆时，根据宠物资料、LifePrint、Timeline、每日任务和近期聊天历史生成更贴近宠物性格的回复。
- 提供账号登录、跨设备同步、数据删除、安全维护和故障排查。
- 满足适用法律、平台规则和安全要求。

### 5. AI 与第三方服务

Echo Pet 当前使用以下服务来提供核心能力：

- Supabase：用于账号认证、数据库、对象存储和 Edge Function 后端。
- DeepSeek-v4-flash：用于 Echo Companion 的 AI 回复生成。

当 AI 记忆开关开启时，Echo Pet 会把生成回复所必需的宠物上下文发送到 Supabase 后端，并由后端调用 DeepSeek-v4-flash。上下文可能包括宠物资料、LifePrint 摘要、时间线记录、每日任务和近期聊天历史。我们会尽量只发送完成当前回复所需的最小数据。

当 AI 记忆开关关闭时，Companion 不应主动使用你的宠物记忆上下文生成回复。

### 6. 数据共享

Echo Pet 不会出售你的个人数据。我们只在以下情况下共享或处理数据：

- 为提供应用功能而使用 Supabase 和 DeepSeek-v4-flash 等必要服务。
- 按你的操作同步、保存、删除或处理你提交的内容。
- 按法律、平台审核、安全或防滥用要求进行必要处理。

### 7. 数据保存与删除

你的数据通常会保存到你主动删除内容、清除本地数据或删除账号为止。

你可以在 App 内进行以下操作：

- 删除单条时间线记录和其中的照片。
- 清空 Companion 聊天记录。
- 删除本地数据。
- 在登录后删除账号与云端数据。
- 关闭 AI 记忆使用开关。

删除账号与云端数据后，Echo Pet 会删除相关账号、宠物资料、时间线记录、媒体素材、每日任务、LifePrint、Memory Capsule 和 Companion 对话。部分安全日志、备份或服务商系统记录可能会按安全、合规和灾备需要短期保留，并在保留期结束后删除或匿名化。

### 8. 数据安全

Echo Pet 使用平台登录、Supabase Row Level Security、服务端密钥隔离和 HTTPS 通信来保护数据。DeepSeek API Key 和 Supabase Service Role Key 不会放入 iOS 客户端。

任何互联网服务都无法保证绝对安全。如果你认为账号或数据存在风险，请通过 App Store 页面提供的支持链接联系我们。

### 9. 儿童隐私

Echo Pet 不是专门面向 13 岁以下儿童的服务。未成年人应在监护人同意和指导下使用本应用。如果监护人认为未成年人提交了不应保存的数据，可以通过 App Store 页面提供的支持方式联系我们处理。

### 10. 国际传输

由于 Echo Pet 使用云服务和 AI 服务，你的数据可能会在你所在国家或地区以外被处理。我们会要求服务提供方按照其安全和隐私承诺处理数据。

### 11. 政策更新

我们可能会根据产品功能、法律法规或平台要求更新本隐私政策。重大变更会在 App 内或 App Store 页面中提示。

### 12. 联系我们

如需隐私、数据访问、删除或支持帮助，请通过 Echo Pet 的 App Store 产品页支持链接联系我们，或在 App 内进入“我的 > 设置 > 数据管理”处理可用的数据控制选项。

## English

### 1. What Echo Pet Is

Echo Pet is a pet life memory archive and AI companionship app. You can create a pet profile, record a growth timeline, save photo and text memories, view LifePrint, generate Memory Capsules, and chat with Echo Companion based on saved pet memories.

Echo Pet does not present AI chat as pet resurrection. Anthropomorphic companion replies should include an AI-generated notice.

### 2. Data We Collect or Process

Depending on the features you use, Echo Pet may collect or process:

- Account information: email address, Supabase user ID, and session state.
- Pet profile data: pet name, breed, age, birthday, relationship label, personality notes, favorite things, habits, and avatar.
- Timeline and memory content: titles, written memories, dates, categories, importance, emotion or behavior tags, photos, videos, or audio materials.
- Daily care plans: task titles, notes, dates, reminder times, and completion state.
- LifePrint and Memory Capsule content: summaries, tags, commemorative content, and source records generated from saved pet data, timeline entries, memories, and tasks.
- Companion conversations: messages you send, AI replies, generation time, AI memory settings, and the minimum context needed to generate replies.
- App settings: language selection, AI memory toggle, background album preferences, and local preferences.

Echo Pet does not sell personal data for advertising tracking and does not include third-party advertising tracking SDKs. The current version does not intentionally collect contacts, precise location, health data, or payment card information.

### 3. Photos, Camera, and Microphone Permissions

Echo Pet asks for permissions only when you use related features:

- Photo access is used to choose pet photos, timeline photos, background album images, and Memory Capsule materials.
- Camera access is used to capture new pet memories.
- Microphone access is used to record voice memories for current or future memory understanding features.

You can revoke permissions in iOS Settings at any time. Some related features may stop working, but other core features remain available.

### 4. How We Use Data

Echo Pet uses data to:

- Create, edit, display, and sync pet profiles.
- Save and show Timeline, daily tasks, LifePrint, and Memory Capsules.
- Allow Echo Companion, when AI memory is enabled, to generate replies that better reflect your pet's personality using the pet profile, LifePrint, Timeline, daily tasks, and recent chat history.
- Provide account login, cross-device sync, data deletion, security maintenance, and troubleshooting.
- Meet applicable legal, platform, safety, and anti-abuse requirements.

### 5. AI and Third-Party Services

Echo Pet currently uses the following services:

- Supabase: authentication, database, object storage, and Edge Function backend.
- DeepSeek-v4-flash: AI reply generation for Echo Companion.

When AI memory is enabled, Echo Pet sends the pet context necessary to generate a reply to the Supabase backend, which calls DeepSeek-v4-flash. This context may include pet profile data, LifePrint summaries, timeline records, daily tasks, and recent chat history. We aim to send only the minimum data needed for the current reply.

When AI memory is disabled, Companion should not actively use your pet memory context to generate replies.

### 6. Data Sharing

Echo Pet does not sell your personal data. Data is shared or processed only when:

- Necessary to provide app functionality through Supabase, DeepSeek-v4-flash, or similar required service providers.
- Needed to sync, store, delete, or process content based on your actions.
- Required by law, platform review, security, or anti-abuse needs.

### 7. Retention and Deletion

Your data is generally retained until you delete content, clear local data, or delete your account.

You can use in-app controls to:

- Delete individual timeline entries and their photos.
- Clear Companion chat history.
- Delete local data.
- Delete your account and cloud data after signing in.
- Turn off AI memory use.

After account and cloud data deletion, Echo Pet deletes related account data, pet profiles, timeline records, media materials, daily tasks, LifePrint, Memory Capsules, and Companion conversations. Some security logs, backups, or provider system records may be retained for a limited period for security, compliance, and disaster recovery, and then deleted or anonymized.

### 8. Data Security

Echo Pet uses platform login, Supabase Row Level Security, server-side key isolation, and HTTPS communication to protect data. The DeepSeek API key and Supabase Service Role Key are not included in the iOS client.

No internet service can guarantee absolute security. If you believe your account or data is at risk, contact us through the support link on Echo Pet's App Store listing.

### 9. Children's Privacy

Echo Pet is not directed to children under 13. Minors should use the app with permission and guidance from a parent or guardian. If a parent or guardian believes a minor has submitted data that should not be retained, contact us through the support method listed on the App Store product page.

### 10. International Transfers

Because Echo Pet uses cloud and AI services, your data may be processed outside your country or region. We require service providers to process data according to their security and privacy commitments.

### 11. Changes to This Policy

We may update this Privacy Policy as product features, laws, or platform requirements change. Material changes will be communicated in the app or on the App Store product page.

### 12. Contact Us

For privacy, data access, deletion, or support requests, use the support link on Echo Pet's App Store listing or go to My > Settings > Data Management in the app for available data control options.
