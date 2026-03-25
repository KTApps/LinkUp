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

// MARK: - Profile sync (restore vs transient errors)

private enum UserProfileSyncResult {
    /// `AuthenticationData` loaded into `currentUser`.
    case loaded
    /// Document missing or wrong shape — account not in Firestore.
    case missingProfile
    /// Network or other fetch error — do not sign out on restore.
    case fetchFailed(Error)
}

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
            let profileResult = await syncUserProfileFromFirestore()
            switch profileResult {
            case .loaded:
                break
            case .missingProfile, .fetchFailed:
                signOut()
                logInError = true
            }
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
    /// Signs out if the Auth user no longer exists on the server or the Firestore profile is gone (not on network errors).
    func restoreSession() async {
        guard let user = authRef.currentUser else { return }
        userSession = user
        do {
            try await user.reloadAsync()
        } catch {
            // Offline / network: keep persisted session. Only sign out when the server says the user is gone.
            if isFirebaseAuthUserRecordMissing(error) {
                signOut()
                return
            }
        }
        let profileResult = await syncUserProfileFromFirestore()
        switch profileResult {
        case .loaded, .fetchFailed:
            break
        case .missingProfile:
            signOut()
        }
    }

    /// Load current user profile from Firestore into `currentUser`. Call after sign up or log in.
    func listenForUser() async {
        _ = await syncUserProfileFromFirestore()
    }

    /// Fetches `users/<uid>` and updates `currentUser` when valid.
    fileprivate func syncUserProfileFromFirestore() async -> UserProfileSyncResult {
        guard let uid = authRef.currentUser?.uid else { return .missingProfile }

        let userRef = databaseRef.collection("users").document(uid)
        do {
            let document = try await userRef.getDocument()
            guard document.exists, let data = document.data(),
                  let authData = data["AuthenticationData"] as? [String: Any] else {
                return .missingProfile
            }
            let decoded = try Firestore.Decoder().decode(AuthModel.self, from: authData)
            currentUser = decoded
            if let url = decoded.profileImageURL {
                let normalizedUsername = decoded.username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                try? await databaseRef.collection("usernames").document(normalizedUsername).updateData(["profileImageURL": url])
            }
            return .loaded
        } catch {
            return .fetchFailed(error)
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
            let normalizedUsername = existing.username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            try await databaseRef.collection("usernames").document(normalizedUsername).updateData(["profileImageURL": urlString])
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

// MARK: - Firebase Auth

private extension User {
    func reloadAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.reload { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

/// True when `reload()` failed because the Auth user no longer exists (or is disabled), not for network errors.
private func isFirebaseAuthUserRecordMissing(_ error: Error) -> Bool {
    let ns = error as NSError
    guard ns.domain == AuthErrorDomain,
          let code = AuthErrorCode.Code(rawValue: ns.code) else { return false }
    switch code {
    case .userNotFound, .userDisabled:
        return true
    default:
        return false
    }
}
