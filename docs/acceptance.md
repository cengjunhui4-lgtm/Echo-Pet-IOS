# Release Acceptance

Use this alongside [harness.md](../harness.md) and `docs/app-store/review-readiness-checklist.md`.

## Product Paths

- [ ] A new user can create a pet and select/change default or custom avatar.
- [ ] A user can add, edit, cancel, and delete a Timeline memory with one to nine ordered photos.
- [ ] A user can add, edit, complete, and delete daily tasks, including internal card scrolling and non-overlapping card movement.
- [ ] A user can generate/view LifePrint and create/view/edit/delete Memory Capsules.
- [ ] Companion sends a context-aware reply, handles loading/error/retry, displays pet avatar correctly, and includes AI disclosure.
- [ ] Chinese/English switching causes no clipped or stale visible copy.
- [ ] Background Album applies the selected image immediately and rotates gently when enabled.
- [ ] App provides useful empty/loading/error/permission-denied/destructive-confirmation states.

## Account and Privacy Paths

- [ ] Email sign-up instructs verification and the verification link reaches public HTTPS success page.
- [ ] A verified user can sign in, reset password, sign out, and sign in again.
- [ ] Account deletion is clear, confirmed, succeeds on backend, and clears local session/state.
- [ ] Privacy policy and terms are reachable in-app and by public HTTPS URL.
- [ ] App Store privacy labels and review notes match current data collection, AI processing, media, and deletion behavior.

## Engineering Checks

- [ ] `git diff --check` passes and staged files contain no secrets.
- [ ] iOS app builds for a concrete simulator or release archive target.
- [ ] Relevant XCTest targets pass; do not reuse historic pass claims after environment failures.
- [ ] Python tests pass when changing `backend/EchoPetBackend/`.
- [ ] `npm ci && npm test` passes when changing `auth-confirmed-site/`.
- [ ] Supabase migration/function verification is recorded when backend assets change.
