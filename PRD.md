# Echo Pet Product Requirements

## Product

Echo Pet is a bilingual iOS companion for recording a pet's life and turning authentic records into a warm, clearly AI-generated companionship experience. It is a digital album and memory companion, not a claim that a pet has been revived.

## Audience and Value

- Pet guardians who want a calm place to keep daily memories, routines, photos, and milestones.
- The app helps a guardian move from recording a moment to seeing a coherent story and having a contextual companion conversation.

## Core Journey

1. Create or edit a pet profile and choose an avatar.
2. Add Timeline memories with text, date, tags, and up to nine photos.
3. Create and complete daily companionship tasks.
4. Review Timeline and LifePrint, generated from real recorded information.
5. Create and read Memory Capsules for meaningful moments.
6. Chat with Echo, which may use enabled pet memory context and always identifies its reply as AI-generated.

## In Scope for 1.0

- Email/password accounts, email verification guidance, password reset, guest continuation, and account deletion.
- Pet profile, avatar, background album, Timeline, daily tasks, LifePrint, Memory Capsules, and Companion.
- Chinese and English UI.
- Local-first persistence, selected Supabase synchronization, and Supabase-hosted AI request boundary.
- Privacy policy, terms, AI disclosure, media permission explanation, and data-deletion entry point.

## Product Requirements

### Pet Profile

- Create, edit, and delete a pet profile.
- Support a default avatar and user-selected avatar.
- Preserve name, species/breed, dates, traits, habits, relationship framing, and preferences useful for future AI understanding.

### Timeline and Media

- Create, edit, view, and delete a memory.
- Support text and one to nine photos per memory; retain selected order for the stacked-card presentation.
- Allow cancellation during editing without accidentally overwriting saved content.

### Daily Care Plan

- Add, edit, complete, and delete tasks with optional templates.
- Keep the home card movable/collapsible within a safe, non-overlapping area and scroll its task list internally.

### LifePrint, Capsules, and Companion

- LifePrint summarizes personality, habits, relationship patterns, and evidence from recorded memories.
- Memory Capsule is a meaningful saved/generated collection, not a duplicate Timeline screen.
- Companion uses only approved context and must not manufacture important memories. Every anthropomorphic response ends with the localized AI-generation disclosure.

### Account, Privacy, and Accessibility

- Explain email verification and password-reset next steps in the app.
- Provide accessible account deletion and local-data deletion with confirmation.
- Keep privacy/terms links externally reachable and descriptions aligned with actual data handling.
- Support Dynamic Type, VoiceOver labels, loading, empty, error, permission-denied, and destructive-action states.

## Non-Goals

- Claiming a real pet is alive, revived, or independently conscious.
- Client-side AI keys or direct provider calls from the iOS app.
- Social sharing, ads, subscriptions, webview-based replacement UI, or unbounded feature expansion for 1.0.

## Success Criteria

- A new user can complete the core journey without a dead end.
- A verified account's data has clear ownership, deletion, and synchronization behavior.
- Both supported languages retain function and visual hierarchy.
- The app builds, relevant tests pass, and App Store release material matches the submitted binary.
