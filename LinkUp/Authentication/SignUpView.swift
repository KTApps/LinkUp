//
//  SignUpView.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 20/02/2026.
//

import SwiftUI

/// Sign up screen: username, email, password, SIGN UP button, link back to LogInView.
struct SignUpView: View {
    @ObservedObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("LinkUp")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                Input(text: $username, title: "Username", placeholder: "Choose a username")
                Input(text: $email, title: "Email", placeholder: "name@example.com")
                Input(
                    text: $password,
                    title: "Password",
                    placeholder: "******",
                    secureField: true
                )

                Button {
                    Task {
                        await authState.signUp(
                            withEmail: email,
                            password: password,
                            username: username
                        )
                    }
                } label: {
                    Text("SIGN UP")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            Spacer()

            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Text("Already have an account?")
                    Text("LOG IN")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .alert("Sign up failed", isPresented: $authState.signUpError) {
            Button("Try again") {
                authState.signUpError = false
            }
        } message: {
            Text("Email already in use. Try another or log in.")
        }
        .alert("Username is taken", isPresented: $authState.usernameExists) {
            Button("Try again") {
                authState.usernameExists = false
            }
        } message: {
            Text("Choose a different username.")
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView(authState: AuthState())
    }
}
