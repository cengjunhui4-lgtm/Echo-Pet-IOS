# EchoPet App Store Readiness Harness

本文档汇总 EchoPet 当前 UI 界面与功能完善度距离 App Store 上架的主要不足，并作为后续迭代检查清单使用。

## 原始判断

以下是 2026-08-05 UI 审计时的原始判断。本轮代码修复后的状态见下一节。

主要原因：

- 功能以静态 demo 数据为主，缺少真实创建、编辑、保存流程。
- 核心体验尚未闭环，用户无法完整完成宠物档案、成长记忆、LifePrint 和陪伴对话的长期使用流程。
- UI 已具备基础风格，但页面信息层级、首屏密度、文案统一性和状态设计仍不足。
- 上架所需的隐私、权限、数据删除、错误处理和审核准备还未完整覆盖。

## 2026-08-05 本地修复状态

本轮已把 EchoPet 从静态 demo 推进到本地可用 MVP。以下问题已在代码中落地：

- 宠物档案支持创建、编辑、删除。
- Timeline 支持创建、详情、编辑、删除和本地保存。
- Memory Capsule 支持创建、详情、编辑、删除和本地保存。
- LifePrint 支持基于宠物档案和 Timeline 生成本地摘要。
- Echo Companion 支持发送中状态、失败提示、重试入口和聊天历史保存。
- 增加 `LocalDataStore`，使用 `UserDefaults + Codable` 保存本地 App 状态。
- 增加设置页，包含隐私说明、清空聊天记录、删除全部本地数据和版本信息。
- 增加空状态、loading 状态、错误状态、删除确认。
- 内部文案已基本中文化，品牌名 `Echo Pet` 和功能名 `Echo` 保留。
- 增加基础 VoiceOver label 和卡片语义组合。
- 当前版本锁定浅色模式，作为 v1 的深色模式策略。
- 收紧卡片圆角、阴影、页面间距，修复首页标题遮挡和短内容卡片不满宽问题。
- 已通过 `xcodebuild` 编译，并安装运行到 iPhone 16 模拟器。

仍不能仅靠本地代码完全解决的事项：

- App Store Connect 隐私标签需要开发者账号内填写。
- 隐私政策 URL 需要线上页面或网站承载。
- 真实 AI 服务需要后端代理，不能把 API Key 放到客户端。
- 照片、相机、麦克风权限目前未启用；如果后续加入媒体功能，再补 Info.plist 权限文案。
- 真机多设备测试和 TestFlight 流程需要实际设备、账号和分发配置。

下面保留原始问题清单用于追踪；已解决项以“2026-08-05 本地修复状态”为准。

## 1. 功能完整度不足

### 宠物档案

- 当前宠物资料固定为 Momo。
- 缺少新增宠物流程。
- 缺少编辑宠物资料能力。
- 缺少头像或照片上传。
- 缺少空状态：首次打开时没有宠物资料应如何展示。

### Life Timeline

- 当前 Timeline 是固定 demo 数据。
- 缺少添加成长节点。
- 缺少编辑成长节点。
- 缺少删除成长节点。
- 缺少记忆详情页。
- 缺少日期选择、标题输入、正文输入等真实表单。
- 缺少照片或媒体支持。

### LifePrint

- 当前 LifePrint 只是宠物资料展示。
- 缺少由真实记忆沉淀 LifePrint 的核心生成过程。
- 缺少生成中、生成失败、重新生成等状态。
- 缺少用户确认和编辑生成结果的能力。
- 缺少 LifePrint 版本或更新时间展示。

### Echo Companion

- 当前只有一条初始消息。
- 缺少真实 AI 对话接入或完整本地模拟策略。
- 缺少发送后的 loading 状态。
- 缺少失败提示和重试。
- 缺少聊天历史保存。
- 缺少网络异常处理。
- 缺少输入为空、发送中、重复点击等边界状态。

### Memory Capsule

- 当前 Create Memory 更像 demo 生成按钮。
- 缺少真实创建页。
- 缺少编辑标题、日期和正文。
- 缺少删除或归档。
- 缺少详情页。
- 缺少保存成功、保存失败、空状态。

## 2. UI 和交互不足

### 首页

- 首页整体干净，但信息密度偏低。
- 功能卡片高度偏大，首屏能展示的有效内容有限。
- Latest Memory 在当前截图中只露出标题，内容被首屏截断。
- 宠物卡片、功能卡片、记忆卡片视觉层级接近，主次关系还不够明确。
- 卡片圆角和阴影偏重，连续页面会显得模板化。

### 二级页面

- Life Timeline、LifePrint、Memory Capsule 页面结构偏静态。
- 页面都像展示页，缺少明确的操作入口和状态流转。
- Echo Companion 页面留白过大，首次体验内容不足。
- 部分页面标题重复出现：导航栏标题和页面大标题同时存在，视觉上略重复。

### 文案统一性

- 当前存在中英文混用：
  - Back
  - Create Memory
  - Life Timeline
  - LifePrint
  - Echo Companion
  - Memory Capsule
  - 中文副标题
- 需要确定语言策略：
  - 全中文。
  - 全英文。
  - 中英双语本地化。

### 状态设计

- 缺少空状态。
- 缺少 loading 状态。
- 缺少错误状态。
- 缺少成功反馈。
- 缺少删除确认。
- 缺少不可用状态解释。

## 3. App Store 审核风险

### App Completeness

App Store 提交版本需要是完整可用版本。当前 demo 数据、静态页面和未闭环流程可能被认为不完整。

参考：

- App Review Guidelines 2.1 App Completeness
- https://developer.apple.com/app-store/review/guidelines/

### Minimum Functionality

如果核心功能过少，或更像包装网页、样机、静态展示页，可能触发最低功能要求问题。

参考：

- App Review Guidelines 4.2 Minimum Functionality
- https://developer.apple.com/app-store/review/guidelines/

### Demo 内容风险

- 固定宠物资料可能被认为是示例内容。
- 固定 Timeline 和 Capsule 可能被认为不是用户可用功能。
- AI Companion 如果无法真正对话，容易被认为核心功能缺失。

## 4. 隐私与权限不足

### 隐私政策

- App Store Connect 需要隐私政策 URL。
- App 内建议提供隐私政策入口。
- 需要说明用户数据如何收集、存储、删除和用于 AI 处理。

参考：

- Manage app privacy
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/

### App Privacy Details

需要在 App Store Connect 中声明数据类型和用途，包括：

- 宠物资料。
- 用户输入的记忆内容。
- 聊天内容。
- 照片或媒体。
- 设备标识或诊断数据。
- 第三方 AI 服务处理的数据。

参考：

- App Privacy Details
- https://developer.apple.com/app-store/app-privacy-details/

### 权限文案

如果后续支持相关能力，需要补充 Info.plist 权限说明：

- Photo Library：上传宠物照片或记忆照片。
- Camera：拍摄宠物照片。
- Microphone：录制语音记忆。
- Notifications：提醒用户记录记忆或查看 Capsule。

### 数据删除

- 需要提供删除宠物资料。
- 需要提供删除 Timeline 记忆。
- 需要提供删除聊天记录。
- 需要提供删除 Memory Capsule。
- 如果有账号或云同步，需要提供账号删除入口。

## 5. 数据与技术架构不足

### 持久化

- 当前功能看起来以 demo service 为主。
- 需要本地持久化，建议明确使用 SwiftData 或 CoreData。
- 需要处理 App 重启后的数据保留。

### AI 服务

- 不应把 API Key 放在客户端。
- 需要后端代理或安全的服务层。
- 需要速率限制。
- 需要失败兜底。
- 需要内容安全策略。
- 需要用户授权或明确告知数据会发送给 AI 服务。

### 网络与异常

- 缺少无网络状态。
- 缺少超时处理。
- 缺少服务异常处理。
- 缺少请求取消或重复提交保护。

## 6. 可访问性与系统适配不足

### Dynamic Type

- 需要测试大字体。
- 当前卡片标题、标签、按钮在大字体下可能撑开或截断。
- 需要确保文本不会溢出或互相遮挡。

### VoiceOver

- 图标按钮需要明确 accessibilityLabel。
- 功能卡片需要可读的语义描述。
- 发送按钮需要说明 disabled 状态。
- 记忆卡片和 Timeline 卡片需要读出日期、标题和内容。

### 视觉对比度

- 浅紫色文字和浅紫色背景的对比度可能偏低。
- 禁用状态的发送按钮和 placeholder 需要检查可读性。

### 深色模式

- 当前 UI 主要按浅色设计。
- 需要决定：
  - 支持深色模式。
  - 或明确锁定浅色模式。
- 如果支持深色模式，需要重新定义背景、卡片、文字、阴影和分割线。

## 7. 测试不足

### 设备覆盖

至少需要测试：

- iPhone SE 小屏。
- 标准 iPhone。
- iPhone Pro Max。
- iOS 17。
- iOS 18。

### 功能测试

需要覆盖：

- 首次打开。
- 新增宠物。
- 编辑宠物。
- 添加 Timeline。
- 编辑 Timeline。
- 删除 Timeline。
- 生成 LifePrint。
- 创建 Memory Capsule。
- 发送 Companion 消息。
- AI 失败重试。
- App 重启后数据仍存在。

### UI 测试

需要检查：

- 中文长文案。
- 英文长文案。
- 大字体。
- 页面滚动。
- 键盘弹出。
- 横竖屏策略。
- 空状态。
- 错误状态。

## 8. 建议优先级

### P0：上架前必须补齐

- 宠物档案真实创建和编辑。
- Timeline 真实创建、编辑、删除和保存。
- Memory Capsule 真实创建、编辑、删除和保存。
- Echo Companion 发送、加载、失败重试和历史保存。
- 本地持久化。
- 隐私政策入口。
- 数据删除能力。
- 权限文案。
- 空状态、loading 状态、错误状态。
- 基础真机或模拟器多尺寸测试。

### P1：提高通过率和产品完整度

- LifePrint 基于宠物资料和 Timeline 生成摘要。
- Memory Capsule 详情页。
- Timeline 详情页。
- 统一中文或中英本地化。
- 设置页。
- VoiceOver 支持。
- Dynamic Type 适配。
- 深色模式策略。

### P2：增强体验

- 照片上传。
- 语音记忆。
- 云同步。
- AI 生成多版本 LifePrint。
- 分享 Memory Capsule。
- 通知提醒。
- 更细腻的情绪化动效。

## 9. 下一步建议

建议先把 App 从静态 demo 改成可用 MVP：

1. 增加宠物档案创建和编辑流程。
2. 增加 Timeline 记忆创建、编辑、删除和本地保存。
3. 增加 Memory Capsule 创建、编辑、删除和本地保存。
4. 给 Echo Companion 增加 loading、失败、重试和历史保存。
5. 增加设置页，放置隐私政策、数据删除和版本信息。

完成以上内容后，再进入 App Store 审核材料、隐私标签和 TestFlight 测试阶段。
