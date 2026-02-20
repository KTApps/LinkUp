//
//  AuthViewModel.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 20/02/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Sign up, log in, listen for user

extension AuthState {

    /// Sign up with email, password, and username. Checks username uniqueness in Firestore,
    /// creates Firebase Auth user, writes profile to `users/<uid>`, then loads current user.
    func signUp(withEmail email: String, password: String, username: String) async {
        signUpError = false
        usernameExists = false

        do {
            let querySnapshot = try await databaseRef.collection("users")
                .whereField("AuthenticationData.username", isEqualTo: username)
                .getDocuments()

            if !querySnapshot.isEmpty {
                usernameExists = true
                return
            }

            let result = try await authRef.createUser(withEmail: email, password: password)
            userSession = result.user

            let user = AuthModel(id: result.user.uid, username: username, email: email)
            let encodedUser = try Firestore.Encoder().encode(user)
            let userRef = databaseRef.collection("users").document(user.id)
            try await userRef.setData(["AuthenticationData": encodedUser])

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
}
