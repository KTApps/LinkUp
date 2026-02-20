# Firestore security rules — explained simply

This doc explains how LinkUp’s Firestore security works and why we have two collections.

---

## The big idea

- **Your profile** (email, username, etc.) is private. Only you can read or change it.
- **Checking if a username is taken** has to work *before* anyone is logged in. So we use a separate, minimal collection that anyone can read for that one purpose only.

---

## Two collections

### 1. `users` — your private profile

| What | Details |
|------|--------|
| **Document ID** | Your Firebase Auth UID (e.g. `abc123xyz`) |
| **What’s stored** | A map called **AuthenticationData**: your id, username, email, and anything else we add later. |
| **Who can read it** | Only **you** when you’re signed in. |
| **Who can write it** | Only **you** when you’re signed in. |

So: one document per person, keyed by their UID. Nobody else can see or edit your `users/<your-uid>` document.

---

### 2. `usernames` — “is this username taken?”

| What | Details |
|------|--------|
| **Document ID** | The username in lowercase (e.g. `johndoe`) |
| **What’s stored** | A single field **uid**: the UID of the person who claimed that username. |
| **Who can read it** | **Anyone** — including people who aren’t signed in. |
| **Who can create it** | Only a **signed-in user** (when they sign up and claim that username). |
| **Who can update/delete it** | Only the user whose **uid** is in that document. |

So: we only use this collection to answer “is this username already taken?” during sign-up. Everyone can read that a document exists (and which uid owns it), but they don’t get your email or full profile from here — that stays in `users`, which only you can read.

---

## Why two collections?

- Sign-up needs to check “is this username taken?” **before** the user has an account. At that moment nobody is logged in, so the app can’t read the private `users` collection.
- So we added **usernames**: a small, public lookup (document id = username, one field = uid). The app can read it without being logged in, and when you sign up we write your username and uid there so future sign-ups can see it’s taken.
- Your real data (email, profile) stays in **users**, which only you can read and write. That’s where security really protects your data.

---

## Where are the rules defined?

- **File:** `firestore.rules` in the **root of the LinkUp project** (same folder as `LinkUp.xcodeproj`).
- **Deploy:** From the project root run:  
  `firebase deploy --only firestore:rules`  
  (and use `--project linkup-2edb9` if you haven’t set a default project).
- **In Firebase:** After deployment, these rules run on Firebase’s servers for every read and write to Firestore. Your app doesn’t “apply” them — Firebase does, automatically.

---

## Short summary

- **users** = your private profile; only you can read/write your `users/<uid>` doc.
- **usernames** = public “is this username taken?” lookup; anyone can read, only signed-in users can create/update/delete their own claim.
- The rules that enforce this live in **firestore.rules** and are deployed with the Firebase CLI.
