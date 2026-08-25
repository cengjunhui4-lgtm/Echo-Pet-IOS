# API Contract

## Principles

- User-owned APIs require an authenticated Supabase session unless explicitly public.
- The client never contacts an AI provider directly.
- Use UUID identifiers and ISO 8601 timestamps.
- Ownership is enforced by RLS in Postgres/Storage and repeated in Edge Function authorization.

## Auth

The iOS client uses Supabase Auth for email sign-up, email/password sign-in, password reset, guest exploration, and account deletion. A guest session is not presented as a durable registered account.

## Domain Resources

| Resource | Client model | Operations |
| --- | --- | --- |
| Pet | `PetProfile` | create, read, update, delete |
| Memory / Timeline event | `TimelineEvent` | create, read, update, delete; media metadata |
| Daily task | `DailyTask` | create, read, update, complete, delete |
| LifePrint | `LifePrint` | read, upsert/generated revision |
| Memory Capsule | `MemoryCapsule` | create, read, update, delete/generate |
| Conversation / message | Companion models | append/read as authorized |

Canonical tables, columns, policies, and triggers are in [the initial migration](../supabase/migrations/202608090001_echo_pet_backend.sql). Additive database changes require a new migration.

## Edge Functions

### `POST /functions/v1/companion-chat`

Requires a bearer access token. Receives user text plus a minimized, consent-aware pet context. The reply must include AI disclosure and must not imply knowledge absent from context.

### `POST /functions/v1/delete-account`

Requires a bearer access token. Deletes authenticated-user data/account according to the deployed function. The client confirms first and clears local state only after success.

### `GET /functions/v1/auth-confirmed`

Public HTTPS success endpoint for email verification; it is not an authenticated API.

## Errors

Map failures to offline, expired-session, authorization, validation, retryable-server, or permanent error states. Never expose provider credentials in errors or logs.
