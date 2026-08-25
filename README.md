# Echo Pet AI for iOS

Echo Pet is a native SwiftUI companion for preserving a pet's memories, routines, and personality through Timeline, LifePrint, Memory Capsule, and an explicitly AI-generated Echo Companion.

## Repository Map

| Resource | Purpose |
| --- | --- |
| [AGENTS.md](AGENTS.md) | Highest-priority project rules for contributors and Codex. |
| [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) | Accurate project state, next work, known gaps, and decisions. |
| [PRD.md](PRD.md) | Product requirements and release scope. |
| [docs/architecture.md](docs/architecture.md) | iOS/backend architecture and security boundary. |
| [docs/api.md](docs/api.md) | Auth, Edge Function, and data contract. |
| [docs/database-schema.md](docs/database-schema.md) | Readable map of executable Supabase schema. |
| [docs/design-system.md](docs/design-system.md) | Visual, accessibility, and localization rules. |
| [docs/decisions.md](docs/decisions.md) | Durable architectural/product decisions. |
| [docs/CODEX_HISTORY.md](docs/CODEX_HISTORY.md) | Curated history of prior Codex decisions. |
| [docs/acceptance.md](docs/acceptance.md) | Current release acceptance checklist. |
| [harness.md](harness.md) | Detailed App Store readiness harness and historical audit. |

## Technology

- Swift 5, SwiftUI, MVVM, iOS 17+
- Local `UserDefaults` + `Codable` persistence
- Supabase Auth/PostgREST/RLS/Edge Functions
- Server-side Companion AI gateway
- FastAPI AI stub for local development
- Node/Vinext site for email confirmation pages

The shipping iOS identifier is `com.echopetai.app`, version 1.0 build 1.

## Run iOS

1. Open `EchoPet.xcodeproj` in Xcode.
2. Select the `EchoPet` scheme and a concrete iPhone simulator/device, not `Any iOS Device`.
3. Run with `Command + R`.

Or run:

```bash
cd "/Users/zizy/Documents/New project/EchoPet-iOS"
./Scripts/run-simulator.sh
```

## Verify

```bash
git diff --check
xcodebuild test -project EchoPet.xcodeproj -scheme EchoPet -destination 'platform=iOS Simulator,name=iPhone 16'

cd backend/EchoPetBackend && python -m pytest
cd ../../auth-confirmed-site && npm ci && npm test
```

Simulator/device names vary. See [docs/acceptance.md](docs/acceptance.md) for release-level checks.

## Backend and Secrets

- Deployable Supabase files are in `supabase/`; the migration is the schema source of truth.
- Use root `.env.example`, `supabase/.env.example`, and `backend/EchoPetBackend/.env.example` only as templates.
- Never commit real API keys, Supabase service-role keys, database passwords, certificates, provisioning profiles, Apple private keys, or `.env` files.
- The iOS client must never call an AI provider directly. See [docs/api.md](docs/api.md).

## Dependencies

- The iOS target uses Apple system frameworks, so it has no CocoaPods `Podfile` or Swift Package Manager manifest.
- Python runtime dependencies are pinned in `backend/EchoPetBackend/requirements.txt`.
- Node dependencies are pinned in `auth-confirmed-site/package-lock.json`; install with `npm ci`.

## Git

```bash
git clone git@github.com:cengjunhui4-lgtm/Echo-Pet-IOS.git
```

Do not commit generated build output, local virtual environments, `node_modules`, or credentials.
