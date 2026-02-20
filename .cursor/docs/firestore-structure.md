# Firestore structure (LinkUp)

Defined for Step 6 of the Login SignUp plan.

## User document

- **Path:** `users/<uid>` where `<uid>` is the Firebase Auth UID.
- **Shape:** One document per user. At minimum, a map:
  - **AuthenticationData** (map): Encoded `AuthModel` — `id`, `username`, `email`.
- More keys (e.g. Analytics, Progress) can be added later.

## Security

- **firestore.rules:** Only the signed-in user can read/write their own `users/<uid>` document (`request.auth.uid == userId`).
- Deploy with: `firebase deploy --only firestore:rules` (from project root, after `firebase use` or `firebase init`).

## Username-uniqueness check

The app currently checks "is username taken?" with a client-side query on the `users` collection. That query is **not** allowed by the rules above (client cannot read other users’ documents). To support sign-up with unique usernames you can either:

1. **Cloud Function:** Implement sign-up in a function that checks uniqueness, creates the Auth user, and writes the Firestore document (client calls the function).
2. **Dedicated collection:** e.g. `usernames` with documents keyed by username and rules that allow the needed read (e.g. for existence check) without exposing full user data.
