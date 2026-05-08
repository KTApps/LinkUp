//
//  AuthState.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 20/02/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Single "auth brain" for the app: holds login state, user profile, and error flags.
/// Pass down as @StateObject in the root view and @ObservedObject in login/sign up screens.
@MainActor
class AuthState: ObservableObject {

    // MARK: - Firebase references

    let authRef = Auth.auth()
    let databaseRef = Firestore.firestore()
    let storageRef = Storage.storage().reference()

    // MARK: - Auth state

    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: AuthModel?

    // MARK: - Error flags (for UI alerts)

    @Published var logInError: Bool = false
    /// Set when sign-up fails after client-side checks (Firebase or Firestore). Cleared on success or dismiss.
    @Published var signUpErrorMessage: String?
    @Published var usernameExists: Bool = false

    init() {}
}
