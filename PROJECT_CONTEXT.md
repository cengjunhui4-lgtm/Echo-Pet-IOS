# Echo Pet Project Context

Last updated: 2026-08-25

Read this before planning work. It is a concise working snapshot, not a changelog; durable rationale belongs in `docs/decisions.md` and `docs/CODEX_HISTORY.md`.

## Completed

- Native iOS 17 SwiftUI app with four tabs: Home, Timeline, Companion, and My.
- Onboarding and editable pet profile, including a selectable circular pet avatar shared by home and companion UI.
- Timeline memory CRUD with up to nine selected photos, ordered photo-stack presentation, edit/cancel/delete behavior, and local persistence.
- Daily care plan CRUD with completion, templates, swipe actions, a movable/collapsible home card, and local persistence.
- LifePrint, Timeline, Memory Capsule, and Companion experiences are present; LifePrint and capsules can be generated locally from recorded information.
- Chinese/English localization resource layer and in-app language setting.
- Background-album selection with chosen/random/rotating modes, blur controls, and gentle transitions.
- Email/password account gate, email verification guidance, password reset, guest continuation, account deletion UI, and Supabase Auth integration.
- Supabase schema/RLS migration plus `companion-chat`, `delete-account`, and `auth-confirmed` Edge Function sources.
- AI context intentionally includes the pet profile, LifePrint, Timeline, daily tasks, and chat history only when the user enables AI memory use. AI output carries a disclosure.
- App icon, onboarding art, public privacy policy/terms sources, App Store checklists, unit-test targets, simulator scripts, and GitHub remote are present.

## Current Focus

Prepare the iOS product for reliable TestFlight/App Store release while preserving the local-first user journey. Documentation and repository hygiene are being standardized in this change.

## Next Work

1. Implement repository-level cloud pull, conflict handling, and deletion propagation for all user-owned entities.
2. Add Supabase Storage upload/delete for pet avatars and timeline media, with offline/error behavior.
3. Run a fresh real-account end-to-end test: sign-up, email confirmation, sign-in, reset password, create/edit/delete data, AI chat, account deletion, and data recovery expectations.
4. Update App Store Connect privacy labels, review notes, support URL, screenshots, encryption export compliance, and TestFlight checks from verified behavior.
5. Configure Apple Sign in only when Apple Developer and Supabase provider values are available. Email/password remains the shipping account path today.

## Known Issues and Gaps

- Cloud writes exist for selected domains, but the app does not yet perform full cloud reads or reliable cross-device reconciliation.
- Media assets and profile avatars are locally stored; complete cloud-storage ownership, upload, deletion, and restoration are not finished.
- The local FastAPI service is an AI development stub. Production Companion requests must continue through the deployed Supabase Edge Function and server-side secrets.
- `docs/app-store/account-e2e-test-report.md` contains older bundle-ID references and needs to be regenerated after the next real-device test.
- The last XCTest run was blocked by low disk space, not an assertion failure. Do not report the suite as passing until it is rerun successfully.
- There is no CocoaPods or Swift Package Manager dependency manifest because the iOS target uses Apple frameworks. Node versions are locked by `auth-confirmed-site/package-lock.json`; Python requirements are pinned in `backend/EchoPetBackend/requirements.txt`.

## Key Technical Decisions

- Native UI stays platform-specific: SwiftUI for iOS; no ArkTS-to-Swift mechanical translation.
- Product/data contracts are shared conceptually through models, Supabase schema, and documentation, rather than shared UI code.
- Supabase is the production backend boundary for Auth, RLS-protected data, storage, and Edge Functions.
- AI provider keys never enter the iOS binary. Companion requests go through a server-side function.
- Local persistence provides immediate usability; cloud synchronization is an incremental repository responsibility, not a reason to block the MVP.
- The App Store bundle identifier is `com.echopetai.app`; version is 1.0 (build 1).
