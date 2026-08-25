# Architecture

## System Shape

```text
SwiftUI iOS app
  -> ViewModels -> Repositories -> LocalDataStore / services
  -> Supabase Auth + PostgREST + Storage + Edge Functions
  -> server-side AI provider (through companion-chat only)
```

The iOS app is a native SwiftUI/MVVM implementation. HarmonyOS remains a separate native ArkTS/ArkUI codebase outside this repository; platforms share product logic and backend contracts, not UI source code.

## iOS Layers

| Layer | Location | Responsibility |
| --- | --- | --- |
| App | `EchoPet/App/` | App root, navigation, onboarding, account/reset gates. |
| Views/components | `EchoPet/Views/`, `EchoPet/Components/` | Presentation and accessible SwiftUI layout. |
| View models | `EchoPet/ViewModels/` | State, validation, and flow orchestration. |
| Models | `EchoPet/Models/` | Codable domain models and AI context. |
| Repositories | `EchoPet/Repositories/` | Domain data-source boundary. |
| Services | `EchoPet/Services/` | Local storage, media permissions, HTTP, Supabase, and AI client code. |

## Backend Assets

- `supabase/migrations/202608090001_echo_pet_backend.sql`: initial Postgres schema, RLS, policies, and storage setup.
- `supabase/functions/companion-chat/`: authenticated AI gateway.
- `supabase/functions/delete-account/`: account/data deletion endpoint.
- `supabase/functions/auth-confirmed/`: email-verification success endpoint.
- `backend/EchoPetBackend/`: local FastAPI/DeepSeek stub, not the production public API.

## Security Boundary

The iOS binary may use only a Supabase publishable/anon key. Service-role credentials, AI-provider keys, Apple private keys, and database credentials are server/deployment secrets. RLS is mandatory even when client filters appear correct.

## Synchronization

Current behavior is local-first with selected cloud upserts. The target is repository-driven push/pull for profiles, memories, tasks, LifePrint, capsules, media metadata, and deletions, with explicit conflict strategy and recovery state.
