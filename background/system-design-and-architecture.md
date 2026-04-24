# System design, architecture, and implementation

## Architecture goals and constraints

The goal of LinkUp is to make it easier for small social groups to move from “we should do something” to a confirmed plan without the process turning into long back-and-forth. The main friction I focused on is not only picking an option, but keeping everyone aligned and reducing the work of chasing and summarising. For that reason, the system is designed around a small set of end-to-end journeys that work reliably: creating an account, connecting with friends, forming group conversations, creating and sharing polls, collecting votes, and surfacing outcomes through results, history, and a calendar-style view of confirmed plans.

Privacy is treated as a first-class goal because group membership, chat content, and poll choices can reveal personal information. The design aims for least privilege: users should only see what they are meant to see, and profile data should not be exposed unnecessarily. Another important constraint is that the artefact needs to be evaluable with real users. The build has to be complete enough that participants can follow a realistic flow and provide meaningful feedback, rather than encountering unfinished screens or disconnected features.

Finally, LinkUp is intentionally scoped as an iOS application backed by Firebase. This keeps the system coherent and practical to deliver and document. Some features that are common in larger products (for example full calendar synchronisation or a full push notification delivery pipeline) were not treated as core requirements, so effort could be concentrated on the coordination loop inside the app.

## What the evaluation build supports (scope of “done”)

The evaluation build is a single iOS app built with Swift and SwiftUI. Firebase Authentication supports email/password accounts. Cloud Firestore stores shared application data. Firebase Storage stores JPEG images (profile photos and optional poll activity images).

For the build to be usable in evaluation sessions, the core end-to-end path needed to work without dead ends. “Done” meant a participant could:

- Create an account, sign in, and have the session restore on launch.
- Search for people by username, send/accept friend requests, and build a friends list.
- Open direct chats and create group conversations, then send messages with live updates.
- Create polls with an activity date (required), optionally add an image, share polls to a chosen set of people, and see polls that are meant for them.
- Vote, view results (including drilling into who voted for what), and open poll history.
- Confirm a choice where the flow supports it, then see confirmations in the in-app calendar and reverse (unconfirm) if needed.
- Manage basic settings, including signing out and deleting the account.

By design, the build does not include two-way sync with Apple Calendar or Google Calendar. It also does not include a production push notification delivery pipeline. Instead, it uses in-app notification items that appear when the app is opened.

## High-level architecture overview

LinkUp uses a client–backend architecture:

- The client is a native iOS application written in Swift and SwiftUI. It handles user interaction, presentation, and orchestration of reads and writes.
- The backend uses Firebase:
  - Firebase Authentication for identity (email/password sign-up and sign-in).
  - Cloud Firestore for application data (profiles, friends, conversations/messages, polls, votes/responses, confirmations, and notification items).
  - Firebase Storage for media uploads associated with polls and user profile images.

This split works well for the project because it supports multi-user behaviour without a custom server. When one user votes in a poll or sends a message, other users can see updates through Firestore listeners. Firebase also provides server-side enforcement through security rules, which is important because client code alone cannot be trusted to enforce access rules.

In LinkUp, most application-specific behaviour is implemented on the client (for example building poll objects from form inputs, updating view state, and selecting what to show depending on session state). Firebase provides shared state, persistence, and access control rather than custom server logic. This keeps the system simple and appropriate for a dissertation artefact.

## Client-side structure (SwiftUI + state management)

At the top of the app, LinkUp uses a single observable state object to manage identity and backend access. A single `AuthState` object is created once at the root and passed down into the UI. This object holds:

- Whether there is a current authenticated session (Firebase Auth user).
- The current user’s profile data (username, email, and optional profile image URL) loaded from Firestore.
- Error flags used by the login and sign-up screens.

The UI routes users based on session state. On app launch, the root view restores a persisted Firebase session and then switches between the logged-out experience (login) and the main experience (content) depending on whether the session exists. This makes the navigation behaviour predictable: user identity is always the starting point for accessing features like friends, messaging, and polls.

Once logged in, the main interface is centred on polls. Polls are presented as the main screen, and a bottom bar opens sheets for other areas such as messages, creating a poll, calendar, history, and settings. This design keeps core tasks easy to discover during use and during evaluation (for example, creating a poll and voting are both quick to access).

Instead of a strict separation into many independent view models, LinkUp uses a pragmatic structure: backend operations are grouped as methods on `AuthState` via extensions (for example friends operations, messaging operations, and poll operations). SwiftUI views call these methods using `async/await` and update local state on completion. For screens that need live synchronisation, Firestore snapshot listeners are used and removed when the screen disappears.

## Object-oriented design principles in the app (OOP)

In the development of this app, I used many object-oriented ideas to keep the code maintainable, reliable and scalable. For example, encapsulation which is the process of keeping data private and providing controlled methods to read or change it safely (Martin, 2017). I applied this in the 'AuthState' and in all of its extensions by hiding firebase authentication, firestore and storage details inside a small set of functions. This ensured that views did not talk to firebase directly, which kept the UI simple and reduced the risk of inconsistent reads and writes across the app.

I also used the single responsibility principle, which means each part of the code should have one clear job, so changes in one area do not cause unexpected side effects somewhere else (Martin, 2017). I applied this by grouping related backend operations into feature based extensions on ‘AuthState’, so each extension focused on one functional area. This kept the code easier to navigate and test, and it reduced the risk of mixing unrelated logic (such as poll updates affecting messaging behaviour) as the app grew.

Moreover, I focused on composition over inheritance, which means building features by combining small, focused components rather than relying on deep class hierarchies, so the code stays flexible and easier to change (Martin, 2017). This shows up in the way the app is structured with SwiftUI. Screens are built by combining smaller reusable views, and features are put together from these parts rather than them being created as subclasses of a shared main screen. This made it easier to reuse UI elements across different flows and reduced the risk that changing a shared parent class would unintentionally affect multiple features.

Finally, I used abstraction, which means hiding low level technical details behind simpler concepts so the rest of the code can focus on what it is trying to achieve rather than how it is implemented (Martin, 2017). This appears in the way the app treats Firebase operations as high level actions such as “create poll”, “submit vote”, or “load messages”, instead of repeating Firestore queries and Storage uploads across many screens. This kept the UI code easier to read and update, and it reduced duplication because changes to the data model or query logic could be made in one place rather than across the whole app.

## Core features as components

### Authentication

Authentication is implemented using Firebase Auth with email and password. Firebase Auth is treated as the authoritative identity layer, and Firestore is used to store profile data linked to the Auth UID.

A notable part of the authentication design is username handling. The system supports checking whether a username is taken during sign-up. This is implemented without making private profiles readable by using a separate minimal username index (described later in the Firestore design and security sections).

From a user journey perspective, authentication supports:

- Creating an account.
- Signing in and restoring the session on app launch.
- Signing out.
- Deleting the user account (including removing related profile and username-claim data).

In the build, sign-up checks `usernames/<lowercase-username>` before creating the Auth account. If the username is available, the app creates the Firebase Auth user, writes a private profile document under `users/<uid>` (with profile fields stored in an `AuthenticationData` map), and writes a minimal public mapping document under `usernames/<lowercase-username>`.

On sign-in and on launch restore, the app loads `users/<uid>` and treats the Firestore profile as required. If the profile document is missing or malformed, the app signs out and shows a clear login error. If the failure looks like a network error, the session is kept so a flaky connection does not log people out by accident.

Profile photos are stored in Storage at `profile_images/<uid>.jpg`. The download URL is written into `users/<uid>` and mirrored into the matching username document so search results can show avatars without reading private profile documents.

Account deletion performs best-effort cleanup across services: it deletes the user’s profile image from Storage (if present), removes `users/<uid>` and the username claim document, then deletes the Firebase Auth user and clears local session state.

### Friends

The friends feature supports building a personal network that can be used for direct chat, group creation, and poll sharing. Conceptually it has three parts:

1. Username search: the app searches usernames by prefix using a dedicated username lookup collection. This provides discoverability without exposing private profile documents.
2. Friend requests: requests are created and tracked with statuses (pending/accepted/rejected). This provides a controlled way to connect with people rather than automatically adding them.
3. Friends list: once accepted, each user stores a friend record under their own profile space. This supports quick retrieval and display of friends for group selection and sharing.

This design supports privacy because it avoids making full user profile documents globally readable. It also supports usability because the friend flow is integrated into the app rather than requiring external invitations.

In the build, friend discovery uses a prefix query on the `usernames` collection (ordered by document id, ranged from the typed prefix to a high Unicode sentinel, then capped). Sending a request writes a `friend_requests/<fromUid>_<toUid>` document unless the users are already friends or the request already exists. Accepting a request uses a Firestore batch to write friend documents under both users’ `friends` subcollections and update the request status. Pending lists are loaded with one-off queries rather than permanent listeners because they change less frequently than polls or chat.

### Groups/Messages

Messaging is implemented around a conversation model stored in Firestore. Conversations represent either direct messages (between two users) or named group chats. Each conversation stores:

- The conversation type (direct or group).
- The list of participant UIDs.
- Creation metadata.
- A “last message” summary (text and timestamp) to support ordering and previews.

Messages are stored as a subcollection under each conversation, and message threads are kept in sync using real-time listeners ordered by creation time. This enables a chat-like experience: when a participant sends a message, other participants see it without manual refresh.

Group creation is supported by selecting friends and providing a group name, which creates a group conversation document. Messaging provides a lightweight coordination space that sits alongside polls so decisions and discussion can stay in one place.

In the build, direct messages use deterministic conversation ids: the two UIDs are sorted and joined, so the same pair does not accidentally create duplicates. Opening a DM reads `conversations/<id>` once and creates it if missing. When sending a message, the app also updates `lastMessageText` and `lastMessageAt` on the conversation document, which lets the conversation list show previews and sort without scanning every message document.

The conversation list is kept up to date through a snapshot listener on conversations that include the current user, ordered by `lastMessageAt`. Opening a thread attaches a listener on the `messages` subcollection ordered by timestamp so new messages appear live.

### Polls (create, vote, results, history, confirmations)

Polls are the core coordination mechanism in LinkUp. A poll includes:

- A question.
- A set of options (each with an id, text, count, and sentiment classification).
- Activity metadata such as date/time (required), description (optional), and an image URL (optional).
- The creator UID and created timestamp.
- A visibility list (`visibleToUids`) indicating who can view and participate.

Creation: the user completes a form with question/options and selects who to share with. The app computes the visibility set based on selected friends and selected group conversations (union of participant UIDs), ensuring the creator is included. If an image is provided, it is uploaded to Firebase Storage and the download URL is stored on the poll document.

Voting: votes are stored per user in a responses subcollection under each poll (document id = voter UID). When a user votes, the app updates the poll’s option counts and the user’s response record. A Firestore batch is used so the option-count update and the response write happen together. If a user changes vote, the previous option count is decremented and the new option is incremented.

Results and drill-down: the results UI includes counts and chart views. Drill-through views can query the responses subcollection for a given option id and display usernames of voters. This supports transparency among the poll participants without making data public outside the visibility boundary.

History: a history view allows users to review previous polls (for example in a sheet). This supports the “progress visibility” aim by making decisions and activity records easier to revisit.

Confirmations: LinkUp separates voting from confirming. After voting, a user can confirm their choice. Confirmation writes a record to a dedicated `poll_confirmations` collection and also marks the user’s response as confirmed. This provides a more stable signal for the calendar view and reduces ambiguity about whether a vote represents a final commitment. Confirmations can be reversed (unconfirm) which removes the confirmation record and updates the response state.

Owner actions: poll creators can edit or delete polls through a dedicated owner-actions sheet. Deletion removes the poll document and the associated activity image in Storage.

In the build, polls are presented as a “deck” on the home screen. The client listens to polls where `visibleToUids` contains the current UID, ordered by `createdAt`. When Firestore returns updates, the app merges server changes into the existing deck ordering so the swipe stack does not jump around just because counts changed.

Poll creation requires an activity date. If an image is provided, the app compresses it to JPEG and uploads to `activity_images/<pollId>.jpg`, then stores the download URL on the poll document. Editing a poll rewrites the document while trying to preserve option ids and counts where possible. Deleting a poll removes the Firestore document and attempts Storage cleanup as a best-effort step.

Voting is written as a batch update: the app reads the user’s existing response (if any), adjusts option counts, updates the poll’s options array, and writes `responses/<uid>` (including an `isConfirmed` flag). If a user has already confirmed, the app blocks changing the vote and steers them to unconfirm first. This prevents the calendar view and confirmation counts becoming inconsistent with the “vote then confirm” model.

Confirming writes `poll_confirmations/<pollId>_<uid>` and sets `isConfirmed` true on the response in a single batch. For positive outcomes, the build can also write in-app notification documents under each recipient’s `users/<uid>/notifications`.

### Calendar (what it shows and where data comes from)

The calendar component provides a time-oriented view of confirmed plans. It is implemented as a scrollable calendar across multiple months and is primarily display-focused.

Calendar data is driven by poll confirmations. The app fetches the current user’s positive confirmations, groups them by day for display, and can calculate a confirmation rate per poll by comparing confirmations to the number of responses. Tapping a day can load the related poll and show detail, with the option to unconfirm.

This is not an external calendar integration. It does not synchronise with Apple Calendar or Google Calendar. The intent is to keep outcomes visible inside LinkUp as part of the coordination workflow.

In the build, the calendar loads confirmations via a query on `poll_confirmations` filtered to the current user and positive sentiment, ordered by activity date. Unconfirming reuses the same unconfirm flow as the poll screens and then reloads confirmation data. Only data stored in Firestore drives the calendar grid.

## Data model and storage design (Firestore)

Firestore is organised around clear ownership boundaries and queryability:

- Users (`users/<uid>`): private profile document keyed by Firebase Auth UID. Profile data is stored inside an `AuthenticationData` map.
- Usernames (`usernames/<lowercase-username>`): minimal public lookup collection used for username availability and search. It maps usernames to UIDs and may include lightweight display fields such as profile image URL.
- Friends (`users/<uid>/friends/<friendUid>`): denormalised friend documents stored per user for fast friend-list reads.
- Friend requests (`friend_requests/<fromUid>_<toUid>`): request documents tracking from/to UIDs, usernames, status, and timestamps.
- Conversations (`conversations/<conversationId>`): conversation documents with participant IDs. Direct message conversation IDs are deterministic (sorted UIDs joined) to avoid duplicates.
- Messages (`conversations/<conversationId>/messages/<messageId>`): message documents (sender UID, sender username, text, timestamp).
- Polls (`polls/<pollId>`): poll documents including question, options, activity metadata, creator, createdAt, and `visibleToUids`.
- Poll responses (`polls/<pollId>/responses/<uid>`): per-user vote and confirmation flag.
- Poll confirmations (`poll_confirmations/<pollId>_<uid>`): per-user confirmation record for a poll.
- Notifications (`users/<uid>/notifications/<notificationId>`): per-user in-app notification items (e.g. “someone confirmed”).

Poll visibility is represented explicitly through `visibleToUids`. This supports a straightforward query pattern (array-contains on the current UID) and supports least-privilege access at the data level.

## Data access and synchronisation

LinkUp uses a combination of one-shot fetches and real-time snapshot listeners.

Real-time listeners are used where users expect immediate updates:

- Poll list updates through a listener on polls visible to the current user.
- Conversation list updates through a listener on conversations containing the current user.
- Message threads update through a listener on the messages subcollection.
- Poll confirmations can be listened to for updating confirmed state in the poll deck.

One-shot fetches are used for discrete reads:

- Fetching friends list and friend requests.
- Fetching voter lists for a specific poll option (drill-down).
- Fetching notifications and marking them read.
- Fetching poll-by-id when opening details from the calendar.

On the client, SwiftUI views typically trigger async work using `task` or button actions. The results update local view state, which drives the UI. Listener lifecycles are managed by attaching on appear and removing on disappear, limiting unnecessary background activity.

## Security and privacy by design (high level)

Security is enforced primarily through Firestore security rules, supported by client-side checks that improve usability (for example requiring authentication before writing, or restricting certain UI actions to the poll creator).

A key privacy principle is least privilege:

- User profiles under `users/<uid>` are private and readable/writable only by that user when signed in.
- Username availability and search is supported through a separate `usernames` collection that is intentionally minimal and publicly readable, so sign-up can check availability without exposing private user documents.
- Polls are accessible only to authenticated users whose UID is in `visibleToUids`.
- Conversations and messages are restricted to participants listed in the conversation’s participant IDs.
- Poll confirmations are readable by the user who created them, and also readable to users who can view the related poll (supporting aggregate calendar-related displays without exposing unrelated data).

These rules run on Firebase’s servers, meaning they remain enforced regardless of the client implementation.

## Settings and in-app notifications (evaluation-friendly)

Settings provides entry points for friend management, viewing notifications, signing out, and deleting the account.

The build uses in-app notification items stored under `users/<uid>/notifications`. These are fetched with a one-off ordered query. Marking an item as read updates an `isRead` field on that one document. This is intentionally simpler than building a full APNs/FCM delivery pipeline, but it still gives participants a visible cue that something happened while they were away from the relevant screen.

## Key design decisions and trade-offs

1. Firebase as the backend: Firebase Auth and Firestore provide authentication, persistence, and real-time updates without custom server infrastructure. The trade-off is that data modelling and querying must fit Firestore’s constraints and security rules.
2. iOS-only implementation: focusing on a single platform supports a consistent user experience and simplifies evaluation and documentation. The trade-off is reduced platform coverage, which was acceptable for the project’s scope.
3. Poll-based coordination rather than automatic availability computation: polls allow explicit options and decisions without requiring detailed schedule sharing. The trade-off is that someone must propose options and participants must respond.
4. Explicit visibility (`visibleToUids`) on polls: this keeps sharing intentional and supports simple queries. The trade-off is that visibility changes require updating that list, and it is best suited to small group sizes.
5. Two-step commitment (vote vs confirm): confirmations provide a stronger signal for “agreed plan” and support the calendar view. The trade-off is an extra action, so the UI needs to keep confirmation lightweight.
6. In-app notifications rather than a full push pipeline: storing notification items in Firestore supports progress cues and evaluation without the complexity of APNs/FCM delivery. The trade-off is that users need to open the app to see them.

## Requirements traceability (short)

The table below provides a concise mapping between the dissertation requirements and the implemented features in the evaluation build.


| Requirement (short)                | How the build satisfies it                                                                                  |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Account creation and sign-in       | Firebase Auth plus Firestore profile and username claim writes; session restore on launch.                  |
| User profile                       | `users/<uid>` profile data; optional image in Storage mirrored into `usernames` for search display.         |
| Friends                            | Prefix search on `usernames`; `friend_requests` documents; `users/<uid>/friends` after accept.              |
| Groups and messaging               | `conversations` and `messages` subcollection; deterministic DM ids; group chat creation and live listeners. |
| Polls: viewing and voting          | Poll deck listener on `polls` with `visibleToUids` (array-contains); batch updates to poll + `responses`.   |
| Polls: creating                    | `polls/<pollId>` documents; optional image upload to `activity_images/<pollId>.jpg`.                        |
| Polls: results and history         | Counts on poll document; `responses` query for drill-down; history view of prior polls.                     |
| Confirming plans                   | Confirm/unconfirm flow using `poll_confirmations` plus confirmed state on responses.                        |
| Calendar                           | Calendar view driven by confirmation records; in-app only (no external calendar sync).                      |
| Settings and account actions       | Settings screen provides sign out and account deletion across Auth/Firestore/Storage.                       |
| In-app notifications (should have) | Per-user notification items stored in Firestore; read state updates.                                        |
| Poll owner actions (should have)   | Poll creator can edit and delete polls; delete includes best-effort Storage cleanup.                        |


LinkUp combines a SwiftUI iOS client with Firebase services to support a focused end-to-end coordination workflow: identity through Firebase Auth, persistent shared data through Firestore, and media through Storage. Friends and conversations provide the social context, polls provide the decision mechanism, and confirmations plus the calendar view make outcomes more visible over time. Privacy is supported by least-privilege access and explicit visibility boundaries.