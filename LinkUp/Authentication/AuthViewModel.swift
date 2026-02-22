//
//  AuthViewModel.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 20/02/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - Sign up, log in, listen for user

extension AuthState {

    /// Sign up with email, password, and username. Checks username uniqueness via `usernames`
    /// (allowed when not signed in), creates Firebase Auth user, writes profile to `users/<uid>`
    /// and claim to `usernames/<lowercase-username>`, then loads current user.
    func signUp(withEmail email: String, password: String, username: String) async {
        signUpError = false
        usernameExists = false

        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedUsername.isEmpty else {
            signUpError = true
            return
        }

        do {
            // Check username availability (usernames collection is readable without auth).
            let usernameDoc = try await databaseRef.collection("usernames").document(normalizedUsername).getDocument()
            if usernameDoc.exists {
                usernameExists = true
                return
            }

            let result = try await authRef.createUser(withEmail: email, password: password)
            userSession = result.user

            let user = AuthModel(id: result.user.uid, username: username, email: email, profileImageURL: nil)
            let encodedUser = try Firestore.Encoder().encode(user)
            let userRef = databaseRef.collection("users").document(user.id)
            try await userRef.setData(["AuthenticationData": encodedUser])

            try await databaseRef.collection("usernames").document(normalizedUsername).setData(["uid": result.user.uid])

            await listenForUser()
        } catch {
            signUpError = true
        }
    }

    /// Log in with email and password, then load current user from Firestore.
    func logIn(withEmail email: String, password: String) async {
        logInError = false

        do {
            let result = try await authRef.signIn(withEmail: email, password: password)
            userSession = result.user
            await listenForUser()
        } catch {
            logInError = true
        }
    }

    /// Sign out: clear Firebase Auth session and local state. StartView will show LogInView.
    func signOut() {
        try? authRef.signOut()
        userSession = nil
        currentUser = nil
    }

    /// Restore session on app launch (e.g. from persisted Firebase Auth). Call from root view .onAppear.
    func restoreSession() async {
        guard let user = authRef.currentUser else { return }
        userSession = user
        await listenForUser()
    }

    /// Load current user profile from Firestore into `currentUser`. Call after sign up or log in.
    func listenForUser() async {
        guard let uid = authRef.currentUser?.uid else { return }

        let userRef = databaseRef.collection("users").document(uid)
        do {
            let document = try await userRef.getDocument()
            guard document.exists, let data = document.data(),
                  let authData = data["AuthenticationData"] as? [String: Any] else {
                return
            }
            let decoded = try Firestore.Decoder().decode(AuthModel.self, from: authData)
            currentUser = decoded
        } catch {
            // Non-fatal: UI can still show session
        }
    }

    /// Upload profile image to Storage, store download URL in Firestore, refresh currentUser.
    func uploadProfileImage(jpegData: Data) async {
        guard let uid = authRef.currentUser?.uid else { return }
        guard let existing = currentUser else { return }

        do {
            let ref = storageRef.child("profile_images/\(uid).jpg")
            _ = try await ref.putDataAsync(jpegData)
            let urlString = try await ref.downloadURL().absoluteString

            let updated = AuthModel(
                id: existing.id,
                username: existing.username,
                email: existing.email,
                profileImageURL: urlString
            )
            let encoded = try Firestore.Encoder().encode(updated)
            try await databaseRef.collection("users").document(uid).setData(["AuthenticationData": encoded])
            await listenForUser()
        } catch {
            // TODO: surface profileImageUploadError if desired
        }
    }

    /// Delete account: remove Storage profile image, Firestore user + usernames claim, then Firebase Auth user. Clears session.
    func deleteAccount() async throws {
        guard let uid = authRef.currentUser?.uid else { return }
        guard let existing = currentUser else { return }
        let normalizedUsername = existing.username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let profileRef = storageRef.child("profile_images/\(uid).jpg")
        try? await profileRef.delete()

        try await databaseRef.collection("users").document(uid).delete()
        try await databaseRef.collection("usernames").document(normalizedUsername).delete()

        guard let user = authRef.currentUser else { return }
        try await user.delete()
        userSession = nil
        currentUser = nil
    }
}
