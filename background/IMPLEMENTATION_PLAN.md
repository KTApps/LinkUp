# Implementation Plan

This document describes what is built (or planned) in the LinkUp MVP and how it is implemented. Work through each section step by step; update as features are delivered.

---

## Implementation overview

### What you actually built in the MVP (features delivered)

*(List the features that are implemented and shipped in the MVP. For example:)*

- [ ] User authentication (sign up, log in, log out)
- [ ] User profile (create/update, basic fields)
- [ ] Friends and groups (create group, add members, view membership)
- [ ] Availability input (create/edit/delete availability blocks, validation)
- [ ] Overlap / suggestion generation (compute overlapping free slots, rank options)
- [ ] Event proposals and polls (create proposal, add options, collect responses, resolve outcome)
- [ ] Notifications *(if included)* (e.g. poll reminder, new proposal)
- [ ] Settings (e.g. log out, delete account, privacy controls)

*Replace with a short bullet list of what is actually delivered.*

### Tech stack summary (SwiftUI, Firebase Auth, Firestore, notifications if any)

*(One short paragraph.)*

- **Client:** iOS app in Swift, UI with SwiftUI; architecture pattern (e.g. MVVM).
- **Backend:** Firebase Auth (email/password), Firestore (users, groups, availability, polls), Firebase Storage *(if used)*.
- **Notifications:** *(e.g. Firebase Cloud Messaging + APNs, or “None in MVP”.)*

---

## Codebase structure

### Folder/module layout (e.g., Views, ViewModels, Services, Models, Repositories, Utilities)

*(Describe how the Xcode project and/or Swift packages are organised.)*

Example structure:

```
LinkUp/
  App/
    LinkUpApp.swift
  Features/
    Auth/           # Login, SignUp, profile
    Groups/         # List, create, members
    Availability/   # Calendar, blocks, input
    Matching/       # Overlap view, suggestions
    Polls/          # Proposals, options, responses
  Core/
    Models/         # User, Group, AvailabilityBlock, Poll, etc.
    ViewModels/     # Or per-feature
    Services/       # Auth, Firestore access, overlap logic
    Repositories/   # UserRepo, GroupRepo, AvailabilityRepo, etc.
  Shared/
    Components/     # Reusable UI
    Utilities/      # Date handling, validation
```

*Replace with your actual layout and a one-line purpose for each top-level folder.*

### Naming conventions and how you kept things consistent

*(Short list. For example:)*

- **Views:** `*View.swift` (e.g. `LogInView`, `AvailabilityCalendarView`).
- **ViewModels:** `*ViewModel.swift` or `*State` for shared app state.
- **Models:** Nouns, e.g. `User`, `AvailabilityBlock`, `Poll`.
- **Services/Repositories:** `*Service` or `*Repository`, e.g. `AuthService`, `GroupRepository`.
- **Files:** One main type per file; extensions in same file or `*+Extension.swift` if needed.

---

## Core feature implementations

### Authentication

**Sign in/out flow, session handling, user profile creation**

*(Describe in a few sentences or bullets.)*

- **Sign up:** Flow (email/password, optional username), where profile is created (e.g. Firestore `users/{uid}`), validation and error handling.
- **Sign in:** Flow, how session is stored (e.g. Firebase Auth `currentUser`), what happens on launch if session exists.
- **Sign out:** How session is cleared and what UI state is reset.
- **Session handling:** Who observes auth state (e.g. root ViewModel or `AuthState`), how the app switches between login and main UI.
- **User profile:** Where profile is stored, which fields, how they are created/updated and shown in the app.

---

### Friends and Groups

**Creating groups, inviting/adding members, membership state**

- How a user creates a group (screen, data stored, e.g. Firestore `groups/{gid}`).
- How members are added (invite by email/username, join link, or in-app add).
- Where membership is stored (e.g. `groups/{gid}/members` or field on group doc).
- How membership state is used (e.g. to gate visibility of availability and polls, and to enforce security).

---

### Availability input

**How users create/edit availability blocks (data validation, time handling)**

- UI for creating/editing a block (e.g. date range, time range, optional recurrence).
- Data shape of an availability block (e.g. start/end timestamps, time zone if stored).
- Validation (e.g. end after start, max range, allowed recurrence).
- Where blocks are stored (e.g. `users/{uid}/availability` or a dedicated collection) and how they are updated (real-time or on save).
- How time zones and “today” are handled (e.g. stored in UTC, displayed in local).

---

### Overlap / suggestion generation

**Where the overlap logic runs and how results are produced (high-level algorithm + key edge cases)**

- **Where it runs:** On-device (Swift) vs Cloud Function; why that choice.
- **Inputs:** e.g. set of user ids (or group id), date range, optional time zone.
- **High-level steps:** e.g. fetch availability blocks for all users in range → merge into a timeline or interval list → find intersections → rank (e.g. by number of people, duration).
- **Key edge cases:** No overlap; one user has no availability; time zone differences; blocks that touch but don’t overlap; minimum slot duration.
- **Output:** What the app shows (e.g. list of ranked slots, with labels like “3/4 people, 2 hours”).

---

### Event proposals and polls

**Creating options, collecting votes/responses, resolving outcomes**

- How a proposal is created (who can create, from which screen, what data: e.g. group, list of time/place options).
- Data model (e.g. `EventProposal` or `Poll` with options, and `Response` per user per option).
- How responses are collected (UI, e.g. yes/no/if-need-be per option), stored (e.g. `polls/{pollId}/responses/{uid}`), and validated (one response per user, or per option).
- How outcomes are resolved (e.g. show counts, “majority wins,” or “organiser picks from top options”).
- What happens when the poll is closed (e.g. no more edits, show final result, optional notification).

---

### Notifications (if included)

**What triggers them and what’s delivered**

- **Triggers:** e.g. new poll in group, poll closing soon, new proposal, or “someone responded.”
- **Content:** Title/body (or data payload) and how the app uses it (e.g. deep link to poll).
- **Implementation:** FCM + APNs setup, where device token is stored, any backend (e.g. Cloud Function) that sends messages.
- If notifications are **not** in MVP: write “Not implemented in MVP; planned for later” and list intended triggers.

---

## Data access implementation

### Firestore reads/writes (repositories/services)

- Which repositories or services talk to Firestore (e.g. `UserRepository`, `GroupRepository`, `AvailabilityRepository`, `PollRepository`).
- Main operations per entity (e.g. create user, get group, list members, add availability block, get poll with responses).
- How you avoid duplicating Firestore logic (e.g. all access through repositories, ViewModels only call repositories).

### Real-time listeners vs one-time fetches

- **Listeners:** Where used (e.g. current user doc, current group, active poll) and how they are added/removed (e.g. on appear/disappear or when selected group changes).
- **One-time fetches:** Where used (e.g. overlap computation, initial load of a screen) and why not real-time.
- How you avoid leaking listeners (e.g. cancel on view dismiss or when dependency changes).

### Handling loading states and sync issues

- How loading is represented (e.g. `@Published isLoading`, or loading state per screen).
- What the user sees while data is loading (e.g. spinner, skeleton).
- How you handle “no data yet” (e.g. empty state message).
- Basic sync issues: e.g. offline writes queued by Firestore SDK; how you show “saved” vs “syncing” if at all.

---

## State management

### How state is held and updated (ViewModels, observable state)

- Where state lives: e.g. ViewModels per screen, plus optional shared state (e.g. `AuthState`, `SelectedGroupState`).
- How views observe state (e.g. `@StateObject`, `@ObservedObject`, `@EnvironmentObject`).
- Who can update what (e.g. only the ViewModel that owns the state; services/repositories don’t hold UI state).

### Avoiding duplicated sources of truth

- Single source of truth per concept (e.g. “current user” from one place; “current group” from one place).
- How you pass data down (e.g. binding, closure, or shared observable) without copying the same data in multiple places.

### Managing asynchronous operations (tasks, callbacks)

- How async work is triggered (e.g. `Task { }`, `async/await`, or completion handlers).
- How you update UI from async results (e.g. `@MainActor` or `DispatchQueue.main`).
- How you cancel or ignore outdated work (e.g. task cancellation when view disappears, or checking a “generation” id).

---

## Security implementation details (practical)

### How you enforce access rules in code (membership checks before reads/writes)

- Before reading/writing group or poll data: how you check that the current user is a member (e.g. fetch membership first, or rely on Firestore rules and handle permission denied).
- Before writing availability: how you ensure the user can only write their own (e.g. only pass `Auth.currentUser.uid` as document id).
- Any other checks (e.g. only poll creator can close the poll).

### Any Firestore rules highlights at a high level (not a full rules chapter)

- **Users:** e.g. user can read/write only `users/{uid}` where `uid == request.auth.uid`.
- **Groups:** e.g. read/write only if `request.auth.uid` is in the group’s members list (or in a `members` subcollection).
- **Availability:** e.g. user can read/write only their own `users/{uid}/availability` (or equivalent).
- **Polls/Responses:** e.g. only group members can read/write polls for that group; users can write only their own response doc.

*(No need to paste full rules; a few lines per area is enough.)*

---

## Error handling and edge cases

### Network loss, partial group participation, conflicts, invalid inputs

- **Network loss:** What the user sees (e.g. “Check your connection”), whether writes are queued (Firestore offline), and how you surface retry or “pending” state if at all.
- **Partial participation:** e.g. some group members have no availability or haven’t responded to a poll; how the UI behaves (show “3/5 responded,” allow closing poll with partial data or not).
- **Conflicts:** e.g. two users edit the same poll at once; last-write-wins or simple rule (e.g. “poll closed = no more edits”).
- **Invalid inputs:** e.g. availability end before start, empty poll title; how you validate (client-side) and what message the user sees.

### User-facing error messages and recovery paths

- List the main error messages (e.g. “Couldn’t load group,” “You’re not a member,” “Invalid time range”) and what the user can do (e.g. retry, go back, fix input).

---

## Performance and optimisation

### Reducing reads/writes, query design decisions (only the ones that affected implementation)

- **Reads:** e.g. fetch availability only for the date range in view; fetch only active polls for the group; avoid loading all users’ full history.
- **Writes:** e.g. batch updates where it makes sense; don’t write on every keystroke.
- **Query design:** e.g. indexes used (composite indexes for “polls by group + updated”), or why you chose a certain collection layout (e.g. subcollections vs top-level with `groupId`).

### Debouncing, pagination, limiting listeners (if relevant)

- **Debouncing:** e.g. search or availability range changes debounced before running overlap.
- **Pagination:** e.g. load polls or group list in pages; how you implement (limit + startAfter, or similar).
- **Listeners:** e.g. only one active group listener at a time; unsubscribe when leaving screen or switching group.

---

## Build and deployment notes

### How to run it (local setup summary)

- **Requirements:** e.g. Xcode 15+, iOS 17+, macOS.
- **Steps:** e.g. clone repo → open `LinkUp.xcworkspace` (or `.xcodeproj`) → resolve Swift packages → add `GoogleService-Info.plist` (from Firebase Console) → select scheme and simulator/device → Run.
- **Firebase:** e.g. create project, enable Auth (email/password), create Firestore DB, add iOS app and download plist; any environment (e.g. dev/prod) if relevant.

### Any environment/config management (Firebase config, bundle IDs)

- **GoogleService-Info.plist:** Where it lives, that it must not be committed with real keys if policy says so (or that it is committed for this project).
- **Bundle ID:** e.g. `com.KTApps.LinkUp`; must match Firebase iOS app.
- **Other config:** e.g. different Firebase projects for dev vs prod (if any); how you switch (e.g. scheme or build config).

---

## Implementation summary

### What’s complete vs incomplete

*(Table or list.)*

| Area              | Status      | Notes                          |
|-------------------|------------|---------------------------------|
| Authentication    | Complete / In progress / Not started | e.g. Login/signup done; profile edit missing |
| Friends & groups  | …          | …                               |
| Availability      | …          | …                               |
| Overlap logic     | …          | …                               |
| Polls             | …          | …                               |
| Notifications     | …          | …                               |
| Settings          | …          | …                               |

### What would be next to implement and why

*(Short list of the next 3–5 features or improvements, in order, with one line each on why.)*

- e.g. “Poll close + result screen – so groups can lock in a time.”
- e.g. “Push notifications for new poll – to reduce need to open app.”
- e.g. “Recurring availability – so users don’t re-enter weekly patterns.”

---

*Update this document as you implement each part of the MVP.*
