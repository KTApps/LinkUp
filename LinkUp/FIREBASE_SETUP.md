# Firebase setup (Step 1)

Firebase SDK is added to the app and `FirebaseApp.configure()` runs at launch.

## Replace GoogleService-Info.plist

The current `GoogleService-Info.plist` is a **placeholder**. To connect the app to your Firebase project (linkup-2edb9):

1. Open [Firebase Console](https://console.firebase.google.com) → select project **LinkUp** (linkup-2edb9).
2. Go to Project settings (gear) → **Your apps**.
3. If you haven’t added an iOS app yet: click **Add app** → iOS, use bundle ID **com.KTApps.LinkUp**.
4. Download **GoogleService-Info.plist** and replace `LinkUp/GoogleService-Info.plist` in this project with the downloaded file.

After replacing, the app will use your real API keys and connect to Firebase.
