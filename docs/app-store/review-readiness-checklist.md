# Echo Pet App Store Review Readiness Checklist

## Fixed Locally

- App Icon assets are present for iPhone and App Store marketing.
- App icon PNGs are opaque and include a 1024x1024 marketing image.
- The Xcode app target explicitly uses the `AppIcon` asset catalog entry.
- Privacy and User Agreement now have in-app detail screens.
- Data deletion now routes signed-in accounts through a `delete-account` Supabase Edge Function client path.
- Memory Capsule is reachable from the Profile tab.
- Release permission prompts use English descriptions for the overseas App Store target.
- Debug demo-data loading remains excluded from Release UI.
- Sign in with Apple removed; only email/password and anonymous guest login remain.
- Supabase session tokens are stored in Keychain instead of UserDefaults.
- "Forgot password" flow added to the email auth form.
- Onboarding flow rebuilt: Brand Intro → Create Pet Profile → Account Gate (email / guest / forgot password) → Main Tabs. Build + tests pass.

## Must Complete Before Review

- Set `DEVELOPMENT_TEAM` in the app and test targets after confirming the Apple Developer Team ID.
- ~~Deploy `supabase/functions/delete-account`.~~ ✅ Deployed to project `lhcllwbwtbpztbzdduep` on 2026-08-10.
- ~~Run a real account deletion test against Supabase and confirm auth user, app rows, and storage objects are deleted.~~ ✅ Verified end-to-end with anonymous signup + delete-account call returning `{"deleted":true}`.
- ~~Host the Privacy Policy and User Agreement on public URLs.~~ ✅ Hosted on GitHub Pages at `https://cengjunhui4-lgtm.github.io/echopet-legal/` on 2026-08-10.
- Add the Privacy Policy and User Agreement URLs to App Store Connect.
- Complete App Store privacy nutrition labels for account identifiers, user content, photos, diagnostics if used, and AI/backend processing.
- ~~Confirm anonymous guest accounts are allowed in production and verify their deletion path works.~~ ✅ Verified: anonymous signup + delete-account returns `{"deleted":true}`.
- Upload screenshots, support URL, marketing description, and review notes with a working reviewer account path.

## Review Notes Draft

Echo Pet is a pet life memory and companion app. Users can create a pet profile, add timeline memories with photos, manage daily care tasks, generate a LifePrint summary, create Memory Capsules, and chat with an AI Companion. AI replies are clearly labeled and do not claim pet resurrection.

This build uses email/password and anonymous guest accounts. Sign in with Apple is not offered.

Reviewer instructions:

1. Open the app.
2. Brand intro: tap **Get Started**.
3. Create a pet profile.
4. Account gate: create an account with email and password, tap **Continue as Guest**, or tap **Forgot password?** to test reset.
5. Add a Timeline memory and send a Companion message.
6. Data deletion is available in `My -> Settings -> Data Management`.
7. Password reset is also available in `My -> Account` by entering an email and tapping `Forgot password?`.