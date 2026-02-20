# Step 7 — Enable Email/Password and optional index

## 1. Enable Email/Password in Firebase Console (you do this)

I can’t change Authentication settings for you; it has to be done in the browser.

1. Open **Firebase Console:** https://console.firebase.google.com/
2. Select project **linkup-2edb9** (your LinkUp project).
3. In the left sidebar: **Build** → **Authentication**.
4. Open the **Sign-in method** tab.
5. Click **Email/Password**.
6. Turn **Enable** on (first toggle).
7. Leave **Email link (passwordless sign-in)** off unless you want it.
8. Click **Save**.

After this, Firebase Auth can create and sign in users with email/password; your app’s Log In and Sign Up will work (subject to Firestore rules and any username-uniqueness setup).

---

## 2. Optional: Firestore index for username query

If you later allow the “is username taken?” query (e.g. via a Cloud Function or different rules), Firestore may ask for a composite index on `users` for `AuthenticationData.username`.

- **Index file:** `firestore.indexes.json` in the project root (created for you).
- **Deploy indexes:**  
  `firebase deploy --only firestore:indexes`  
  (from project root, after `firebase use linkup-2edb9` if needed).

You only need to deploy indexes if you see an error in the Firebase Console or in the app logs telling you to create an index.
