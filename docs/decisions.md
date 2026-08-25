# Key Decisions

| Date | Decision | Rationale | Consequence |
| --- | --- | --- | --- |
| 2026-08 | Keep iOS and HarmonyOS native and separate | Product logic may be shared; platform UI should remain native. | No ArkTS-to-Swift translation. |
| 2026-08 | Use SwiftUI + MVVM + repository/service layers | Matches the current app and separates UI from storage/networking. | New logic belongs outside Views. |
| 2026-08 | Use Supabase for Auth, database, RLS, Storage, and Edge Functions | Provides one backend contract with owner-based access. | Schema/policy changes are migrations; client uses public credentials only. |
| 2026-08 | Route Companion AI through `companion-chat` | Keys and prompt policy must stay server-side. | Clients send consent-aware context; server owns provider integration. |
| 2026-08 | Keep a local-first MVP | Recording should feel immediate in limited connectivity. | Full repository pull/conflict handling remains planned. |
| 2026-08 | Email/password is the current real-account path | It completes an accessible release path before Apple Provider configuration is available. | Sign in with Apple is future configuration, not a placeholder. |
| 2026-08 | Include AI disclosure and memory-use controls | Companion language must not deceive users about pet revival or hidden data use. | Replies include disclosure; context honors settings. |
| 2026-08 | Bilingual UI now | The product targets Chinese-speaking and overseas App Store users. | No hard-coded visible copy. |
| 2026-08 | Use `com.echopetai.app` for distribution | The earlier identifier was unavailable/stale. | Release docs/settings must use this identifier. |
