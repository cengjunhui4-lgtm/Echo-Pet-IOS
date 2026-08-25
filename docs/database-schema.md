# Database Schema

The executable source of truth is [202608090001_echo_pet_backend.sql](../supabase/migrations/202608090001_echo_pet_backend.sql). This page is a readable map.

## Ownership

- Every application record is owned by `auth.users.id`.
- Row Level Security restricts read/write/delete to the owner.
- Storage paths and policies must encode and validate the owning user ID.
- Account deletion is responsible for user-owned records and media cleanup.

## Conceptual Entities

| Entity | Purpose |
| --- | --- |
| Pet profile | Pet identity, traits, relationship context, avatar metadata. |
| Timeline memory | Time, text, emotion, importance, tags, and media references. |
| Daily task | Care-plan text, time, completion, template/source metadata. |
| LifePrint | Generated/edited personality and habit summary with source context. |
| Memory Capsule | Curated/generated commemorative collection. |
| Conversation/message | Consent-aware Companion history. |

## Migration Policy

1. Create a new timestamped SQL migration for every production schema change.
2. Include table/index/policy/function changes in the same reviewable migration.
3. Verify RLS with positive and negative ownership tests before deployment.
4. Update this page and `docs/api.md` when a contract changes.
5. Do not edit a migration after it has been applied to a shared environment.
