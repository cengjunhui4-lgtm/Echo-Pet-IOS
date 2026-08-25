# Apple Provider Preconfiguration

This document tracks the non-sensitive setup for replacing temporary anonymous Supabase auth with production Sign in with Apple.

## Current Safe State

- iOS bundle identifier: `com.echopet.mvp`
- Supabase project ref: `lhcllwbwtbpztbzdduep`
- Supabase project URL: `https://lhcllwbwtbpztbzdduep.supabase.co`
- Supabase auth callback URL: `https://lhcllwbwtbpztbzdduep.supabase.co/auth/v1/callback`
- iOS already includes the Sign in with Apple entitlement.
- iOS already sends Apple `id_token` and nonce to Supabase Auth.
- Anonymous sign-in remains enabled temporarily for preview and TestFlight iteration.
- `supabase/config.toml` contains a disabled Apple provider section with the native client id only.

## Why Apple Developer Is Still Required

Supabase cannot validate real Apple sign-in until Apple Developer provides:

- Apple Team ID
- Apple Key ID
- Sign in with Apple `.p8` private key
- Apple client secret generated from the Team ID, Key ID, and `.p8` key

Do not commit those values to the repository.

## Supabase Dashboard Fields

When the Apple credentials are ready, open:

```text
https://supabase.com/dashboard/project/lhcllwbwtbpztbzdduep/auth/providers
```

Configure the Apple provider:

- Enabled: `true`
- Client IDs: `com.echopet.mvp`
- Secret: Apple client secret generated from Apple Developer credentials

If Echo Pet later adds web OAuth in addition to native iOS sign-in, add the Apple Services ID as the first client id and keep `com.echopet.mvp` as an additional native client id.

## Management API Alternative

The script below can apply the provider config after the Apple client secret exists:

```bash
export SUPABASE_ACCESS_TOKEN=your_local_supabase_management_token
export SUPABASE_PROJECT_REF=lhcllwbwtbpztbzdduep
export APPLE_CLIENT_IDS=com.echopet.mvp
export APPLE_CLIENT_SECRET=your_generated_apple_client_secret

./scripts/configure-supabase-apple-provider.sh
```

The script intentionally refuses to run unless `SUPABASE_ACCESS_TOKEN` and `APPLE_CLIENT_SECRET` are present in the local shell.

## Validation Checklist

After the provider is enabled:

1. Install the app on a physical iPhone or simulator signed by the Apple Developer team.
2. Open `我的` / Profile.
3. Sign out of the temporary guest account if it exists.
4. Tap Sign in with Apple.
5. Confirm Profile shows `Apple ID 已连接`.
6. Create or edit pet profile, Timeline, daily tasks, and LifePrint.
7. Confirm Supabase rows use the Apple-authenticated `owner_id`.
8. Send a Companion message and confirm the Edge Function returns a DeepSeek-backed reply.

## Cutover Notes

Anonymous sign-in should stay enabled only while previewing, testing, or supporting explicit guest mode. Before App Store submission, decide whether Echo Pet supports guest accounts. If not, disable anonymous sign-in after Apple sign-in is fully verified.
