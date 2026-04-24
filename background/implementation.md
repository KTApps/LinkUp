# Implementation

*Approximate length: ~1,850 words.*

Chapter 6 described the intended system: what LinkUp is for, how Firebase backs it, and how data is grouped in Firestore. This chapter explains how that design was turned into working software in the app (and its Firebase setup). It stays close to what the code actually does: screen flows, reads and writes, live updates versus one-off fetches, and a few deliberate limits of the MVP build.

## Build context and what “done” meant

The client is a single iOS target built with Swift and SwiftUI, using Xcode and Apple’s iOS SDK. Firebase Authentication handles email and password accounts. Cloud Firestore holds shared application data. Firebase Storage holds JPEGs for profile photos and poll activity images. “Done” for the evaluation build meant a participant could sign up, add friends, open or create group chats, create polls with an activity date (and optional image), see polls meant for them, vote, open results and history, confirm a choice where the flow allows, see confirmations on the in-app calendar, and manage account basics from settings—including signing out and deleting the account. I did not aim for a production push-notification pipeline or two-way sync with Apple Calendar or Google Calendar; those sit outside the scope described in the requirements chapter.

## How the code is organised

The app uses one shared observable object, `AuthState`, created at the root and passed into the views that need it. That object holds the Firebase Auth session, the signed-in user’s profile after it is loaded from Firestore, and simple error flags for login and sign-up. Firebase handles (`Auth`, default `Firestore`, default `Storage`) live on `AuthState` so the rest of the UI does not recreate connections.

Backend work is not split into many small service types. Instead, `AuthState` gains extra methods through Swift extensions grouped by feature (authentication and profile, friends, messages, polls). SwiftUI screens call those methods with `async/await`. Where the user expects the UI to move as soon as someone else changes data, the code attaches a Firestore snapshot listener (a subscription that pushes new snapshots when documents change) and removes it when the screen goes away, so work does not keep running in the background without need.

Navigation is kept simple. `StartView` switches between the login experience and `ContentView` depending on whether `userSession` is set. The main signed-in experience is a navigation stack whose root is the poll deck (`PollsView`). A bottom bar opens sheets for messages, creating a poll, the calendar, and poll history; settings open from the poll screen’s toolbar. That matches the requirement to keep voting and poll creation easy to find during user studies.

## Authentication and profile

Sign-up asks for email, password, and username. Before creating the Auth account, the app reads `usernames/<lowercase-username>` in Firestore. If that document already exists, the UI sets a “username taken” flag and stops. If the name is free, the app creates the Firebase Auth user, writes the private profile under `users/<uid>` inside an `AuthenticationData` map, and writes the public mapping in `usernames/<lowercase-username>` with the new uid. Password handling stays inside Firebase Auth; the app does not store passwords in Firestore.

Sign-in loads `users/<uid>`. If the profile document is missing or malformed, the app signs the user out and shows a login error, because a usable account must have a matching profile. If the fetch fails for a network-style error, the session is kept so a flaky connection does not log people out by accident.

On launch, `restoreSession` runs from the root view. If Firebase still has a current user, the app sets `userSession`, reloads the Auth user from the server, and loads the profile. If the server reports the user is gone or disabled, the app signs out. That gives predictable behaviour: either you see the main app with a loaded profile, or you see login.

Profile photos upload to `profile_images/<uid>.jpg` in Storage. The download URL is written into `users/<uid>` and mirrored into the matching `usernames` document so search results can show avatars without reading private profile documents.

Account deletion (from settings) deletes the Storage profile image if present, deletes `users/<uid>` and the `usernames` claim, then deletes the Firebase Auth user and clears local session state. Failures surface as an alert so the user is not left guessing.

## Friends

Friend discovery uses prefix search on the `usernames` collection: documents are ordered by id, the query spans from the typed prefix to a high Unicode sentinel, and results are capped. Each hit becomes a small public row (uid, username, optional image URL from the username doc).

Sending a request writes `friend_requests/<fromUid>_<toUid>` with pending status, unless a request already exists or the users are already friends under `users/<fromUid>/friends/<toUid>`. Accepting uses a Firestore batch: it writes friend documents under both users’ `friends` subcollections, updates the request to accepted, and clears the other side’s symmetric pending state as needed (the implementation follows the models in `FriendsService`). Incoming and outgoing pending lists are loaded with one-off queries when the add-friends UI needs them, not with a permanent listener, because those lists change less often than chat or polls.

## Groups and messaging

Direct chats use a deterministic conversation id: the two user ids are sorted and joined with an underscore. Opening a DM calls `getOrCreateDM`, which reads `conversations/<id>` once and creates the document if it is missing. Named groups call `createGroupConversation`, which allocates a new document id and stores participant ids, a display name, and timestamps.

Sending a message adds a document under `conversations/<id>/messages` and updates `lastMessageText` and `lastMessageAt` on the parent conversation so the list view can sort and preview without scanning every message.

The conversation list uses a snapshot listener on `conversations` where `participantIds` contains the current user, ordered by `lastMessageAt`. That listener (again, a live Firestore subscription) means new messages reorder the list and refresh previews without a pull-to-refresh. Opening a thread attaches a listener on the `messages` subcollection ordered by time so new lines appear as others send them.

For poll sharing, the create-poll flow can load group conversations with `fetchMyGroupConversations`, which queries conversations that include the user and filters to group type on the client.

## Polls: deck, creation, voting, results, and owner tools

The poll deck is the home screen. When `ContentView` appears, it starts `addPollsListener`, which listens to `polls` where `visibleToUids` contains the signed-in uid, ordered by `createdAt`. When Firestore returns new data, the client merges server updates into the existing deck order so a swipe stack does not jump around only because counts changed; new polls still append when they were not in the list before.

Creating a poll requires an activity date in the build I shipped. Optional text, sentiment labels on options (classified in Swift from option text), and an optional image are supported. If there is an image, it is compressed to JPEG, uploaded to `activity_images/<pollId>.jpg`, and the download URL is stored on the poll document. The app ensures the creator’s uid is included in `visibleToUids`. Updating an existing poll rewrites the document while trying to preserve option ids and counts where indexes align; replacing an image overwrites the Storage object for that poll id. Deleting removes the poll document and best-effort deletes the activity image.

Voting reads the user’s existing response document if any, adjusts option counts on an in-memory copy of the poll, then commits a batch: it updates the `options` array on the poll document and merges `responses/<uid>` with `optionId`, `username`, and `isConfirmed` false. If the user has already confirmed, changing the vote throws a clear error so the flow steers them to unconfirm from the calendar first—this keeps counts and calendar data consistent with the two-step vote-then-confirm idea from the design chapter.

Confirming writes `poll_confirmations/<pollId>_<uid>` and sets `isConfirmed` true on the response in one batch. For “positive” sentiment options, the code can create in-app notification documents for other participants (stored under each recipient’s `users/<uid>/notifications`). Unconfirm deletes the confirmation document and clears the flag on the response.

Results views use the poll document for counts. Drilling into who chose an option uses a one-off query on `responses` filtered by `optionId`, which returns voter usernames without keeping a listener open forever. History reuses the in-memory poll list passed into `PollHistoryView` from the sheet opened from the bottom bar.

Poll owner edit and delete are implemented as async calls from the owner UI; delete also attempts Storage cleanup as noted above.

## Calendar

The calendar screen is mainly for viewing information: it scrolls across many months and groups the current user’s confirmations by day. On appear it loads confirmations with a query on `poll_confirmations` filtered to the user and positive sentiment, ordered by activity date. It can compute a simple “confirmation rate” per poll by comparing confirmation documents to response documents for that poll id. Tapping a day can open a detail overlay; unconfirm calls the same unconfirm path as the poll flow and reloads confirmations. There is no import or export to the device calendar app—only what is stored in Firestore drives the grid.

## Settings and in-app notifications

Settings exposes add friends, a notifications list, sign out, and delete account. Notifications are fetched with a one-off ordered query on `users/<uid>/notifications`. Marking read updates `isRead` on a single document. Unread counts drive a badge on the notifications row. This is lighter than wiring APNs and FCM for a dissertation MVP, but it still gives participants a sense of activity when they open the app.

## Traceability (requirements to what the build does)

| Requirement (short) | How the build satisfies it |
|----------------------|----------------------------|
| Account creation and sign-in | `signUp` / `logIn` on `AuthState`; Firebase Auth plus Firestore profile and username claim writes. |
| User profile | `users/<uid>` with `AuthenticationData`; optional image in Storage and mirrored URL in `usernames`. |
| Session handling | `restoreSession` on launch; `StartView` gates `ContentView` vs `LogInView`; `signOut` clears session. |
| Friends | Prefix search on `usernames`; `friend_requests` documents; `users/<uid>/friends` after accept. |
| Groups and messaging | `conversations` and `messages` subcollection; deterministic DM ids; group `createGroupConversation`. |
| Polls: viewing and voting | Poll deck listener on `polls` with `arrayContains` uid; `submitVote` batch to poll + `responses`. |
| Polls: creating | `createPoll` with Storage upload path `activity_images/<pollId>.jpg` and `polls/<pollId>` document. |
| Polls: results and history | Counts on poll doc; `responses` query per option; history sheet over current poll list. |
| Confirming plans | `confirmVote` / `unconfirmVote` and `poll_confirmations` documents linked to calendar display. |
| Calendar | `CalendarView` loads confirmations and maps them to days; in-app only. |
| Settings | `SettingsView` for friends entry, notifications fetch, sign out, delete account. |
| In-app notifications (should have) | `users/<uid>/notifications` items; read flag updates from settings UI. |
| Poll owner actions (should have) | Owner flows call `updatePoll` and `deletePoll` on `AuthState`. |

## Closing note for the evaluation chapter

The implementation priorities were an end-to-end slice that evaluators could walk through without hitting dead ends: identity, social graph, chat, polls, confirmations, and a calendar that reflects agreed dates inside the app. The next chapter on user evaluation can treat these flows as fixed “tasks” in sessions, while later iterations can trace UI and behaviour changes back to specific participant feedback rather than to abstract architecture alone.
