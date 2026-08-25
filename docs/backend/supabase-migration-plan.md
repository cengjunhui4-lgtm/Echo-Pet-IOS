# Echo Pet Supabase Backend Plan

This folder prepares Echo Pet to move from the local FastAPI preview backend to Supabase without putting AI secrets in the iOS app.

## Target Architecture

```text
Echo Pet iOS
  -> Supabase Auth
  -> Supabase Postgres with RLS
  -> Supabase Storage: pet-media
  -> Supabase Edge Function: companion-chat
  -> DeepSeek deepseek-v4-flash
```

## Generated Files

- `supabase/config.toml`: Supabase project ref and Edge Function JWT verification.
- `supabase/migrations/202608090001_echo_pet_backend.sql`: tables, indexes, RLS policies, and private `pet-media` bucket policies.
- `supabase/functions/companion-chat/index.ts`: authenticated Companion AI Edge Function.
- `supabase/functions/delete-account/index.ts`: authenticated account and cloud data deletion Edge Function.
- `supabase/functions/_shared/cors.ts`: shared CORS/JSON helper.
- `supabase/.env.example`: local-only environment variable template with placeholders.
- `scripts/configure-supabase-apple-provider.sh`: guarded Management API helper for enabling Apple auth after Apple credentials exist.
- `docs/backend/apple-provider-preconfiguration.md`: non-sensitive Apple/Supabase provider checklist.

## Current Deployment Status

- Supabase project `Echo Pet` is linked to project ref `lhcllwbwtbpztbzdduep`.
- `202608090001_echo_pet_backend.sql` has been pushed to the remote database.
- `companion-chat` has been deployed as a Supabase Edge Function.
- `delete-account` exists locally and still needs deployment before App Store review.
- DeepSeek secrets have been set in Supabase Edge Function secrets.
- Anonymous sign-in is enabled temporarily so the iOS preview can obtain a Supabase access token before formal account management is implemented.
- The iOS app can sign in with Apple using native `AuthenticationServices`, or use temporary anonymous sign-in for preview.
- The iOS Repository layer now syncs the current pet context into Supabase before Companion calls `functions/v1/companion-chat`.
- Apple provider preconfiguration is documented locally, but the provider is not enabled remotely until Apple Developer credentials are available.

## Data Model Scope

The first Supabase schema covers the current iOS product loop:

- `profiles`: app profile paired to Supabase Auth user.
- `pets`: pet profile, relationship label, habits, favorites, AI memory switch.
- `timeline_events`: user memories and story events.
- `timeline_media_assets`: ordered photos/videos/audio per timeline event.
- `daily_tasks`: daily care/todo plan, completion state, mood and AI context.
- `lifeprints`: AI-ready personality and relationship summary.
- `memory_capsules`: generated or saved memory capsules.
- `companion_messages`: user and AI chat history with source references.
- `user_data_requests`: export/delete request tracking.

## Security Rules

- RLS is enabled on all app-owned tables.
- Every user-owned table has `owner_id = auth.uid()` policies.
- `pet-media` is private.
- Storage object paths must start with the authenticated user id:

```text
{userId}/{petId}/{timelineEventId}/{sortOrder}-{filename}
```

- iOS may use the Supabase publishable key.
- iOS must never contain `SUPABASE_SERVICE_ROLE_KEY` or `DEEPSEEK_API_KEY`.
- DeepSeek is called only inside `companion-chat`.
- Account and cloud data deletion is performed only inside `delete-account` with a verified user JWT and service-role server context.

## Deploy Draft

Link the local folder to the Supabase project:

```bash
supabase login
supabase link --project-ref lhcllwbwtbpztbzdduep
```

Apply the database schema:

```bash
supabase db push
```

Set server-only secrets:

```bash
supabase secrets set DEEPSEEK_API_KEY=your_deepseek_key
supabase secrets set DEEPSEEK_BASE_URL=https://api.deepseek.com
supabase secrets set DEEPSEEK_MODEL=deepseek-v4-flash
```

Deploy the Edge Function:

```bash
supabase functions deploy companion-chat
```

## Companion Chat Contract

Request body:

```json
{
  "petId": "uuid",
  "message": "我有点想豆包",
  "languageCode": "zh_Hans",
  "relationship": {
    "userRole": "主人",
    "petRole": "宠物"
  },
  "settings": {
    "memoryEnabled": true,
    "tone": "gentle"
  }
}
```

Response body matches the current iOS client:

```json
{
  "messageId": "uuid",
  "reply": "AI reply with disclosure",
  "isAiGenerated": true,
  "sourceMemoryIds": ["uuid"],
  "modelVersion": "deepseek-v4-flash-deepseek-v1",
  "provider": "deepseek",
  "mode": "deepseek",
  "generatedAt": "2026-08-09T00:00:00.000Z",
  "petId": "uuid"
}
```

The server appends the required AI disclosure:

```text
（本消息由 AI 基于宠物记忆生成）
```

## iOS Migration Order

1. Store Supabase URL and publishable key in app configuration.
2. Add Auth session state with native Sign in with Apple and temporary anonymous preview mode.
3. Sync pet profile, Timeline, Daily Tasks, and LifePrint through the Repository layer.
4. Invoke `companion-chat` with the user's Supabase access token.
5. Upload timeline photos to `pet-media`.
6. Keep local fallback only for offline/error states.

## Apple Sign-In Setup Still Required

The iOS code path is implemented, but production Apple sign-in also requires Apple Developer and Supabase Dashboard configuration:

- Enable Sign in with Apple for the app identifier.
- Configure the bundle identifier for `com.echopet.mvp` or the final production bundle id.
- Create the Apple key used by Supabase Auth.
- Configure Supabase Auth Apple provider with Team ID, Key ID, Client ID, and the Apple private key.
- Replace anonymous preview mode with mandatory Apple sign-in before App Store submission if the product should not support guest accounts.

See `docs/backend/apple-provider-preconfiguration.md` for the exact non-sensitive values, Dashboard fields, and guarded Management API script.

## Remaining Decisions

- Whether launch version requires mandatory login before pet creation.
- Whether anonymous auth is acceptable during TestFlight.
- Whether data export/delete is implemented fully inside Supabase Edge Functions or through a separate backend job.
