# Plan Mode Prompt: Poll Confirmation, Notifications & Calendar

Use this prompt in plan mode to generate an implementation plan for the poll confirmation feature.

---

Create a detailed implementation plan for the LinkUp app for the following feature. Save the plan under `.cursor/plans/` with a short hyphenated name (e.g. `poll-confirm-calendar.plan.md`) and use the existing plan format (frontmatter with name, overview, todos). The plan must be implementable step-by-step and must respect the project's existing structure (SwiftUI, Firebase/Firestore, AuthTheme, existing Poll/PollService, CalendarView, ContentView).

---

## Feature: Poll Confirmation, In-App Notifications, and Calendar Integration

### 1. Poll Option Sentiment (Positive vs Negative)

- When creating a poll, the user types each option's text (e.g. "Yes", "No", "I'm in", "Can't make it").
- The app must classify each option as **positive** or **negative** so it can decide: add to calendar and notify others (positive) vs remove from stack only (negative).
- The user wants the app to "figure out the meaning" of the text they type; they are open to how (e.g. client-side allowlist, small ML model, or a sentiment/classification API). The plan must propose a concrete, implementable approach (with pros/cons if multiple options) and recommend one for v1.

### 2. Confirmation Behavior

- After voting, the user can **optionally** confirm their answer (one confirmation per user per poll).
- **If they confirm a positive option:** the poll is removed from their stack, stays in history, an event is added to their calendar on the poll's activity date, and all other voters in that poll receive an in-app notification.
- **If they confirm a negative option:** the poll is removed from their stack and stays in history only; no calendar event and no notifications to others.
- Once confirmed, the user cannot change their vote unless they unconfirm (see below).
- Activity date is **required** when creating a poll; the plan must include enforcing this in poll creation (validation + UI).

### 3. Unconfirm

- The user can unconfirm **only from the calendar** (e.g. from the event/dot or the more-details popup).
- After unconfirming, they can reconfirm later. When they unconfirm, the poll **re-enters their stack** so they can vote again and optionally confirm again.

### 4. In-App Notifications

- When someone confirms (with a positive option), **everyone who has voted** in that poll (including the poll creator) gets an in-app notification.
- Notification content: e.g. "[Username] confirmed" for that poll, with actions: **"Confirm too"** and **"Change vote"**.
- No push notifications; in-app only.
- Confirmations are **private**: not shown on the poll card (no "X, Y confirmed" list); they only appear via these notifications and on the calendar.

### 5. Calendar

- The calendar shows **only the current user's confirmations** (events they confirmed with a positive option), on the poll's activity date.
- Each such day has a **dot**; tapping the dot opens the **existing more-details blur popup** for that poll/event so the user can see what they confirmed.
- **Dot color** reflects how many voters confirmed with a positive option: **% of all voters** in that poll who confirmed positive.
  - **Green:** >79%
  - **Orange:** 60–79%
  - **Red:** <60%
- If the poll is deleted or the user is removed from the poll's visibility, the corresponding confirmation and calendar entry are **removed** (or not shown).

### 6. Data and Backend

- The plan must specify Firestore (and optional Cloud Functions) design: e.g. where confirmations are stored, how notifications are created and stored per user, how calendar events are derived or stored, and how to enforce "one confirmation per user per poll" and cleanup when a poll is deleted or visibility changes.

### 7. Scope and Ordering

- The plan should be broken into ordered steps (e.g. data model + sentiment approach → confirm/unconfirm API → calendar data and UI → notification model and UI → integration and edge cases).
- Each step should state which files to add or change and what "done" looks like.
- Mention that the app must still build successfully after implementable steps (e.g. Xcode build); no step should leave the project in a broken state.
