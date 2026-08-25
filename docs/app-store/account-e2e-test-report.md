# Echo Pet Account Flow E2E Test Report

Date: 2026-08-11  
Target: Echo Pet iOS, bundle id `com.echopet.mvp`  
Backend: Supabase project `lhcllwbwtbpztbzdduep`

## Scope

This report covers the account hardening work required before App Store review:

- Complete password reset flow.
- Stronger delete account entry inside the app.
- Real Supabase account end-to-end verification.

No API keys, service-role secrets, or user passwords are stored in this report.

## Implemented

### Password Reset

- Password reset no longer depends on opening an email link.
- Supabase recovery email now shows a one-time verification code.
- Added an in-app code-based reset form with:
  - Email address.
  - Recovery code field.
  - New password field.
  - Confirm password field.
  - Minimum length validation.
  - Password match validation.
  - Success and failure messages.
- Added Chinese and English localized strings for code-based signup verification and password reset.

### Email Signup Verification

- Signup email now shows a one-time verification code.
- The Profile/My email sign-in card can verify the code inside Echo Pet.
- After successful code verification, Supabase returns a session and the app signs the user in.

### Supabase Auth Configuration

- `site_url` remains the hosted HTTPS confirmation success page:
  - `https://lhcllwbwtbpztbzdduep.supabase.co/functions/v1/auth-confirmed`
- Allowed redirect URLs include:
  - `https://lhcllwbwtbpztbzdduep.supabase.co/functions/v1/auth-confirmed`
  - `echopet://auth/reset-password`
- CAPTCHA is disabled.
- Email confirmation is enabled.
- Password minimum length is 6 characters.
- Current-password and re-authentication checks are enabled for normal logged-in password changes.
- Signup and recovery email templates are configured to show `{{ .Token }}` so the app can verify codes without relying on mailbox links.

### Delete Account

- Added a direct destructive account deletion entry in the Profile/My account card.
- The app now differentiates between:
  - Cloud account deletion: delete account and cloud data.
  - Local-only deletion: delete local data.
- Added confirmation dialog before destructive deletion.
- Existing Settings data deletion entry remains available.
- The deployed `delete-account` Edge Function deletes:
  - Supabase Auth user.
  - User-owned database rows.
  - User-owned storage files under the media bucket when present.

## Automated Test Results

### iOS Build

Result: Pass

- Generic iOS build succeeded with code signing disabled.
- Simulator build succeeded.
- Simulator launch succeeded.
- OTP-based account UI compiled successfully.

### Password Recovery Request

Result: Pass

- `POST /auth/v1/recover`
- HTTP result: `200`

### Email Signup OTP Flow

Result: Pass

Observed sanitized results:

```json
{
  "signup_http": "200",
  "generate_signup_otp_http": "200",
  "otp_present": "yes",
  "verify_signup_otp_http": "200",
  "session_present": "yes",
  "delete_account_http": "200",
  "auth_user_after_delete_http": "404",
  "overall": "pass"
}
```

### Anonymous Account Delete Flow

Result: Pass

Observed sanitized results:

```json
{
  "password_recovery_request_http": "200",
  "anonymous_signup_http": "200",
  "profile_insert_http": "201",
  "pet_insert_http": "201",
  "pet_created": "true",
  "delete_account_http": "200",
  "auth_user_after_delete_http": "404",
  "remaining_pet_rows": "0",
  "remaining_profile_rows": "0"
}
```

### Confirmed Email Recovery OTP Flow

Result: Pass

Observed sanitized results:

```json
{
  "create_http": "200",
  "generate_recovery_link_http": "200",
  "otp_present": "yes",
  "verify_otp_http": "200",
  "update_password_http": "200",
  "new_password_login_http": "200",
  "old_password_login_after_update_http": "400",
  "delete_account_http": "200",
  "auth_user_after_delete_http": "404",
  "overall": "pass"
}
```

Interpretation:

- A confirmed email account can receive a recovery OTP.
- The recovery OTP can be exchanged for a valid recovery session.
- The password can be updated with that recovery session.
- The new password can sign in.
- The old password is rejected.
- The account can be deleted after password reset.
- The Auth user no longer exists after deletion.

## Manual Test Still Required

Before App Store submission, run this once on a real device with a real mailbox:

1. Create a new account in Echo Pet.
2. Open the verification email and copy the code.
3. Return to Echo Pet and enter the signup verification code.
4. Confirm the account signs in.
5. Tap forgot password.
6. Open the reset email and copy the code.
7. Return to Echo Pet and enter the reset code plus a new password.
8. Sign in with the new password.
9. Confirm the old password fails.
10. Delete the account from Profile/My.
11. Confirm the account cannot sign in again.

## App Store Readiness Notes

Current status: close to review-ready for account basics.

Remaining review-sensitive items:

- Verify the real mailbox OTP flow on iPhone hardware.
- Ensure App Store privacy labels mention account information, uploaded media, user content, and AI/service processing.
- Consider raising the password minimum from 6 to 8 characters before production.
- Keep the in-app account deletion entry visible and reachable without contacting support.
