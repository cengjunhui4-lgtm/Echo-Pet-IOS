# Echo Pet iOS Development Guide

Version:
MVP v1.0

Platform:
iOS

IDE:
Xcode

Framework:
SwiftUI

Language:
Swift

---

# Product Mission

Echo Pet 是一个 AI 宠物数字陪伴平台。

核心理念：

> 不是为了留住过去，而是让陪伴继续。

Echo Pet 不创造一个虚假的宠物。

而是通过真实成长数据，构建宠物专属 LifePrint（生命印记），延续人与宠物之间的情感连接。

所有代码、UI、交互必须服务于：

- Warm
- Natural
- Minimal
- Emotional

---

# Current Development Goal

当前目标：

完成 Echo Pet iOS MVP。

优先级：

1. 可运行
2. 可演示
3. 体验完整
4. 代码质量

禁止：

为了展示技术而增加复杂功能。

---

# MVP Scope

当前只实现：

- Life Timeline
- LifePrint
- Echo Companion
- Memory Capsule

---

# Tech Stack

Language:

Swift

UI:

SwiftUI

Architecture:

MVVM

Data:

SwiftData / CoreData

Network:

URLSession

AI:

DeepSeek API

Qwen API

OpenAI API

---

# Project Structure

EchoPet/

├── App/

├── Models/

├── Views/

├── ViewModels/

├── Services/

├── Components/

├── Assets/

└── Utils/

Rules:

- View只负责展示
- ViewModel负责业务逻辑
- Service负责数据请求
- Model负责数据结构

禁止：

单文件超过300行。

---

# SwiftUI Development Rules

优先：

- Component化
- 状态管理清晰
- 可复用View

推荐：

创建：

PetCard

LifePrintCard

TimelineCard

ChatBubble

禁止：

重复UI代码。

---

# Apple Design Rules

遵循：

Apple Human Interface Guidelines

视觉关键词：

Minimal

Elegant

Warm

Calm

颜色：

Background:

#FFFFFF

Primary:

#A9A3FF

Text:

#222222

Secondary:

#888888

禁止：

- 赛博朋克风
- 科技蓝
- 复杂渐变
- 过度动画
- 炫技交互

---

# Testing Rules

每次修改必须：

1. Build成功
2. Simulator运行正常
3. 页面正常打开
4. 核心流程可操作

---

# Final Principle

Echo Pet不是展示AI技术。

而是通过技术，让人与宠物之间的陪伴拥有新的表达方式。
