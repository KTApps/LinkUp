# Plan: LinkUp System Architecture Document

Create one markdown file (e.g. **ARCHITECTURE.md** at the repo root or in **processes/**) that works through your template step by step. Below is the section-by-section outline and what each part will state or decide, so you can review before we draft the full text.

---

## 1. File and location

- **File:** ARCHITECTURE.md (at repo root or `processes/ARCHITECTURE.md`).
- **Structure:** Use your headings and subheadings exactly; add 1–3 short paragraphs or bullet lists under each so the doc is copy-paste and review friendly.

---

## 2. Section-by-section content direction

**Architecture goals and constraints**

- **Goals:** Privacy (who sees whose availability), low friction (quick to add availability and get suggestions), reliability (correct overlap and suggestions), MVP scope (full stack).
- **Assumptions:** Online-first (Firebase); small groups (e.g. 2–10 people); availability and event data are sensitive (only group members see it).

**High-level architectural style**

- **Style:** iOS client (Swift/SwiftUI) + Firebase backend (Auth, Firestore, Storage).
- **In-app pattern:** MVVM; business logic and coordination in ViewModels; views only bind to ViewModel state and send actions.
- **Where logic lives:** ViewModels for UI state and use-case orchestration.

**Component overview**

- **Client:** UI (SwiftUI views), ViewModels, optional domain/services (e.g. overlap calculator), data layer (repositories or services that talk to Firebase).
- **Backend:** Firebase Auth, Firestore (users, groups, availability, proposals, polls), Firebase Storage (if needed for profile/media), optional Cloud Functions (e.g. for heavy matching or notifications).
- **External:** Push notifications (FCM/APNs) if in scope; no other external services unless you add them.

**Key modules and responsibilities**

- **Authentication:** Sign up / log in, session, identity; feed user id into all other modules.
- **Friends / Groups:** Create/join groups, list members, membership checks; foundation for "who can see my availability."
- **Availability:** CRUD for "when I'm free" (e.g. blocks or recurring); used as input to matching.
- **Matching / Overlap:** Takes availability of N people, returns overlapping free slots (or ranked options); can run on-device for MVP or later in Cloud Functions.
- **Poll / Decision:** Propose one or more meet-up options (times/places); collect responses; optionally pick a winner (e.g. first majority, or manual).
- **Notifications (if included):** Reminders for polls, new proposals, or "your group has a new suggestion"; FCM + APNs.
- **Common utilities:** Date/time handling (time zones, ranges), validation (e.g. availability bounds, poll deadlines).

**Data model and storage design**

- **Core entities:** User (profile, linked to Auth uid), Group, Membership (user–group), AvailabilityBlock (user, time range, optional recurrence), EventProposal (group, suggested time/place), Poll (proposal + options or yes/no), Response (user's answer to a poll).
- **Relationships and ownership:** Users own their availability; groups have members; only members read/write a group's proposals and polls; document/collection rules reflect this (e.g. `users/{uid}`, `groups/{gid}`, `groups/{gid}/proposals`, `groups/{gid}/polls`).
- **Why this structure:** Keeps data minimal per group; allows queries like "availability for these user ids" and "polls for this group"; supports security rules that check membership.

**Data flow and state management**

- **Flow:** Firestore (and Auth) → repository/service layer → ViewModel → SwiftUI views (one-way: ViewModel drives UI).
- **Real-time vs fetch:** Use listeners for "live" data (e.g. current group, active poll, availability for selected members); fetch-on-demand for heavy or rare operations (e.g. full overlap run) if needed.
- **Caching/offline:** At least persistence enabled (Firestore offline); optional local caching of "my availability" or "current group" for resilience; document that offline is best-effort for MVP.

**Scheduling / overlap logic as a subsystem**

- **Inputs:** Set of user ids (or group id → members) + date range (and optionally time zone).
- **Outputs:** List of overlapping free slots (or ranked suggestions) for the group.
- **Where it runs:** On-device for MVP (keeps backend simple); move to Cloud Function later if groups grow or logic gets heavy.
- **Ranking/selection:** High-level only (e.g. "sort by slot start," "prefer longer slots," "filter by min duration"); no deep algorithm detail in the doc.

**Security and privacy architecture**

- **Auth/identity:** Firebase Auth as source of truth; Firestore user docs keyed by Auth uid.
- **Access control:** All group-scoped data gated by "is current user a member of this group"; availability readable only by group members (or explicit "shared with" if you add that later); least-privilege (users can't write others' availability or delete others' responses without rules).
- **Data minimisation:** Only store what's needed for matching and polls (e.g. no long-term history of every availability change unless you explicitly need it); state what you intentionally do not store.

**Error handling and resilience**

- **Partial participation:** Define behaviour when some members have no availability or don't respond to a poll (e.g. "show slots for those who have responded," "allow closing poll with partial responses").
- **Missing responses / conflicts:** How the app behaves when a poll expires, or two people edit the same proposal; simple rules (e.g. last-write-wins, or "poll closed = no more edits").
- **Network issues:** Offline queue for writes; clear messaging when offline or when a fetch fails; no silent data loss.
- **Fail-safe:** What the user sees on error (e.g. "Couldn't load group," "Check your connection," "Poll closed").

**Performance and scalability**

- **Scale:** Design for small groups (e.g. 2–10); avoid "load all users' availability for the whole year" in one query.
- **Guardrails:** Pagination or date-range limits on availability reads; limit overlap computation to a bounded window; denormalise only where it avoids N+1 or huge reads (e.g. group member ids in the group doc for membership checks).

**Traceability to requirements**

- Short table or list: "Requirement → Architectural decision" (e.g. "Find meet-up times → Overlap subsystem + Availability module"; "Only friends see my availability → Membership-based Firestore rules"; "Low friction → On-device matching for MVP").

---

## 3. How we'll work through it

1. **Draft:** Add ARCHITECTURE.md with the headings above and fill each section with 1–3 paragraphs or bullets based on this plan (and your two answers).
2. **Review:** You read the doc and say what to change (e.g. "we're offline-first" or "notifications are out of scope for MVP").
3. **Iterate:** Update the doc until it matches how you want LinkUp built; then we can use it as the single source of truth for implementation (e.g. when doing Step 2 of the login plan or adding the Availability module).

---

## 4. What I need from you before drafting

- **Location:** Prefer **ARCHITECTURE.md** at repo root, or **processes/ARCHITECTURE.md**?
- **Notifications:** In MVP scope (yes/no)? If yes, we'll include the Notifications module and FCM/APNs in the doc; if no, we'll mark it "future" and keep the rest unchanged.
- **Offline:** "Online-first with best-effort offline" (as above) or do you want a stronger commitment (e.g. "full offline support for availability and polls")?

Once you confirm location, notifications in/out, and offline level, the next step is to add the file and fill in each section accordingly.
