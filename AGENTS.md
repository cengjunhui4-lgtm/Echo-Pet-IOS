# Echo Pet Project Rules

This file is the highest-priority project guidance for Codex and human contributors. Read it with `PROJECT_CONTEXT.md` before changing the repository.

## Product Guardrails

- Echo Pet is an AI companion and life-memory app for pets. It preserves memories; it must not claim to revive a real pet or invent important experiences.
- Keep the core loop coherent: create a pet, record memories and care tasks, see the Timeline and LifePrint, then talk with Echo using those records as context.
- The app supports Simplified Chinese and English. New user-visible text must use `EchoPet/Utils/Localization.swift`; do not add hard-coded UI copy.
- AI companion replies must include the localized disclosure that the message is generated from pet memories. AI context is opt-in and must respect the user's memory-use setting.
- Do not change product positioning or add broad features without an explicit product decision.

## Technology and Ownership

- iOS app: Swift 5, SwiftUI, MVVM, iOS 17+, Xcode project `EchoPet.xcodeproj`.
- Local persistence: `UserDefaults` plus `Codable` in `EchoPet/Services/LocalDataStore.swift`.
- Cloud/auth: Supabase Auth, PostgREST, Storage, and Edge Functions under `supabase/`.
- AI: the mobile app calls the `companion-chat` Edge Function. Provider credentials belong only in Supabase secrets. The Python service in `backend/EchoPetBackend/` is a local/stub reference, not the production credential boundary.
- Public legal pages live in `docs/app-store/public/`; their source documents live in `docs/app-store/`.

## Repository Layout

- `EchoPet/App/`: app entry, root navigation, onboarding, and account gate.
- `EchoPet/Views/`: feature screens and forms. Views render state and invoke declared actions only.
- `EchoPet/ViewModels/`: presentation state, validation, orchestration, and optimistic UI behavior.
- `EchoPet/Models/`: shared app-domain models and transport contexts.
- `EchoPet/Repositories/`: data-source boundary used by view models.
- `EchoPet/Services/`: storage, permissions, networking, Supabase, and AI client code.
- `EchoPet/Components/`: reusable SwiftUI components. Prefer extending an existing component over copying a card implementation.
- `Tests/EchoPetTests/`: XCTest coverage for models, storage, view-model behavior, and API contracts.
- `supabase/`: migrations and deployable Edge Functions. Treat migrations as immutable once deployed.
- `backend/EchoPetBackend/`: FastAPI/AI stub and its Python tests.
- `auth-confirmed-site/`: hosted email-confirmation success page; `package-lock.json` is the Node dependency lock.
- `docs/`: project knowledge. Keep architecture, API, decision, release, and legal docs current with code changes.

## Change Rules

- Preserve the existing HarmonyOS source outside this repository. Never delete or mechanically translate ArkTS code as part of iOS work.
- Do not delete or rename `supabase/migrations/202608090001_echo_pet_backend.sql`; add a new ordered migration for schema changes.
- Do not remove privacy, terms, account deletion, password reset, media-permission, localization, or AI-disclosure flows without an explicit replacement and migration plan.
- Keep Views focused on UI. Put reusable business behavior in a view model, repository, or service matching the existing dependency direction.
- Use `PhotosPicker` and the existing media service for media selection. Preserve the current maximum of nine images per timeline memory unless product requirements change.
- Avoid unrelated refactors, generated-file churn, and changing bundle/version/signing settings unless the task requires it.
- Use `apply_patch` for source and documentation edits. Do not overwrite user changes or revert unrelated work.

## UI and Interaction Standards

- Follow the existing warm, calm, photo-led Echo Pet visual language in `EchoPet/Utils/Theme.swift`; do not introduce a separate visual system.
- Use native SwiftUI controls and SF Symbols where available. Maintain accessible labels for icon-only controls.
- Cards are functional content containers, not page decoration. Avoid cards inside cards and avoid duplicated navigation routes.
- Keep primary navigation to Home, Timeline, Companion, and My. Memory Capsule and LifePrint belong in My unless a deliberate IA change is documented.
- Support Chinese and English length differences. Use adaptive layout, not fixed text widths or viewport-scaled fonts.
- Provide loading, empty, error, permission-denied, destructive-confirmation, and cancellation states for user-facing data flows.
- Keep motion gentle and interruptible. Background-photo changes must crossfade rather than flash.

## Data, Privacy, and Security

- Never commit API keys, database passwords, Supabase service-role keys, Apple private keys, signing certificates, provisioning profiles, or real `.env` files.
- Commit only sanitized `*.env.example` templates. Keep `.env`, `.env.*`, `.dev.vars`, certificates, and local runtime output ignored.
- Publishable Supabase configuration may be embedded in the client only when it is intended to be public; never embed server credentials.
- All user-owned database data must be protected by Supabase RLS. Every new table, storage bucket, or function must define ownership and deletion behavior.
- Account deletion must delete or schedule deletion of user data and provide a clear user-visible result. Keep privacy policy and App Store privacy declarations aligned with actual collection and sharing.

## Verification and Definition of Done

For code changes, complete the relevant checks before reporting completion:

1. Run `git diff --check` and ensure no secrets are staged.
2. Build the iOS app with a concrete simulator destination; run relevant XCTest targets when storage, models, networking, or view models change.
3. Exercise the changed user journey in Simulator or on device, including cancellation and failure/permission states where applicable.
4. For Supabase changes, validate migration/function syntax and verify the deployed endpoint only when deployment is in scope.
5. Update `PROJECT_CONTEXT.md`, `docs/architecture.md`, `docs/api.md`, `docs/decisions.md`, and/or release material when the change affects them.
6. Commit source, docs, schema, tests, and lockfiles together. Do not commit generated builds or credentials.

A task is done only when the requested behavior works, has focused tests proportional to risk, its documentation is accurate, and no pre-existing product flow was unintentionally broken.
