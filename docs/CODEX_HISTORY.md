# Codex Decision History

This is a distilled record of meaningful prior collaboration, not a transcript. It preserves decisions that affect future implementation.

## Product and Platforms

- Echo Pet began with a HarmonyOS ArkTS/ArkUI implementation. The iOS app was intentionally rebuilt in native SwiftUI rather than mechanically translated. HarmonyOS source must be preserved and evolved separately.
- The core product is pet profile, LifePrint, Timeline, Memory Capsule, daily companionship tasks, and Echo Companion. It is memory-supported companionship, never pet resurrection.
- Near-term effort is iOS release readiness; HarmonyOS parity is a product/contract goal but is not a reason to destabilize iOS work.

## Experience Decisions

- Bottom tabs are Home, Timeline, Companion, and My; duplicated Home shortcuts were removed.
- LifePrint and Memory Capsule live under My to reduce navigation duplication.
- Timeline records support text plus up to nine photos, editing/removal, cancellation, and a layered photo-stack visual.
- Daily plans support templates, add/edit/complete/delete, swipe actions, internal scrolling, and a movable/collapsible frosted-glass Home card.
- Background Album moved from Home to My. It supports selected, rotating, and random background photos with blur and gentle transitions.
- Pet profile avatars are shared by Home interaction and Companion message UI.
- Chinese/English uses a resource-based layer; new visible text must never be ad hoc literals.

## AI, Backend, and Accounts

- Companion context may use pet profile, LifePrint, Timeline, daily tasks, and chat history only with explicit permission.
- Companion tone is gentle; it can follow user-defined relationship framing, cannot invent consequential memories, and includes an AI-generation disclosure.
- AI access moved behind Supabase Edge Functions. A local FastAPI stub exists for development but is not the production security boundary.
- Supabase owns Auth, RLS-protected structured data, storage planning, account deletion, and Edge Functions. Direct provider keys do not enter clients.
- Email/password registration, verification guidance, password reset, and account deletion are the current shipping account path. Apple sign-in requires Apple Developer/Supabase configuration before production enablement.

## Release and Repository

- Public HTTPS privacy policy, terms, and email-confirmation success endpoints were prepared for App Store and email-flow use.
- The App Store listing is `Echo Pet AI`; iOS bundle ID is `com.echopetai.app`, initial version/build is 1.0/1.
- The repository is GitHub-hosted at `cengjunhui4-lgtm/Echo-Pet-IOS` on `main`.
- A dedicated local SSH key is configured for this repository; private key material is never committed.
- Build products, local environments, certificates, provisioning assets, and real `.env` files are ignored. Sanitized examples and dependency lockfiles belong in Git.
