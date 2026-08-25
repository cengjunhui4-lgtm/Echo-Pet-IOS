# Design System

## Brand Direction

Echo Pet should feel like a gentle digital album: warm, calm, photo-forward, and emotionally supportive. The UI must make everyday pet care and memories clear rather than ornamental.

## Foundations

- Canonical SwiftUI tokens and modifiers are in `EchoPet/Utils/Theme.swift`.
- User-facing strings and language behavior are in `EchoPet/Utils/Localization.swift`.
- Use the existing asset catalog for the app icon, brand logo, and onboarding art.
- Prefer system typography, adaptive spacing, native controls, and SF Symbols.

## Composition Rules

- Home provides a pet interaction message and daily plan without duplicating bottom-tab destinations.
- Bottom navigation is Home, Timeline, Companion, and My. LifePrint and Memory Capsule are entered from My.
- Photo stacks preserve media order and must not obscure essential text.
- Glass treatment is reserved for the daily-plan card and must stay legible over custom backgrounds.
- Background images crossfade gently and can be blurred; foreground text retains contrast and shadow as needed.

## Accessibility and Localization

- Never use fixed widths that clip English translations. Support wrapping and Dynamic Type.
- Provide VoiceOver labels for icon-only actions and descriptive combined labels for cards.
- Do not rely on color alone for completion, warnings, or destructive actions.
- All text is resource-driven; add both Chinese and English values with each feature.

Every data surface needs deliberate empty, loading, error, success, cancellation, and permission-denied states. Avoid placeholder pages or no-op controls in release builds.
