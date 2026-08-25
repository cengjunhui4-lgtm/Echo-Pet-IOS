# Echo Pet iOS MVP

Echo Pet 是一个 SwiftUI iOS MVP，用来演示 Life Timeline、LifePrint、Echo Companion 和 Memory Capsule 四个核心体验。

## 推荐运行方式

如果 Xcode 顶部设备选择器里没有出现具体的 iPhone，或者弹出：

`A build only device cannot be used to run this target`

请直接运行项目里的脚本：

```bash
cd "/Users/zizy/Documents/New project/EchoPet-iOS"
./Scripts/run-simulator.sh
```

脚本会自动完成：

1. 找到可用的 `iPhone 16` 模拟器。
2. 启动 Simulator。
3. 编译 Echo Pet。
4. 安装到模拟器。
5. 打开 App。

也可以双击：

`Run Echo Pet.command`

## 在 Xcode 里运行

1. 打开 `EchoPet.xcodeproj`。
2. 顶部 Scheme 选择 `EchoPet`。
3. 运行设备必须选择具体设备，例如 `iPhone 16`。
4. 不要选择 `Any iOS Device` 或 `Any iOS Simulator Device`，它们只是占位目标，不能运行 App。
5. 按 `Command + R`。

## 当前工程配置

- Minimum Deployment: `iOS 17.0`
- Device: `iPhone`
- Orientation: `Portrait`
- Bundle Identifier: `com.echopet.mvp`

## Supabase 后端草案

Supabase schema、RLS、Storage 策略和 `companion-chat` Edge Function 草案在：

`docs/backend/supabase-migration-plan.md`

本草案用于把当前本地 AI 后端迁移到 Supabase + DeepSeek。DeepSeek Key 和 Supabase service role key 只能放在服务端 Secrets，不能写入 iOS 客户端。

## 常见问题

### 仍然提示 Build Only Device

这说明 Xcode 当前没有选中具体 iPhone 模拟器。先运行：

```bash
./Scripts/run-simulator.sh
```

脚本启动成功后，重启 Xcode，再从顶部设备下拉框选择 `iPhone 16`。

### 没有 iPhone 16

打开 `Xcode > Settings > Platforms`，安装 iOS Simulator Runtime。安装完成后重启 Xcode。
