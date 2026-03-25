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
        GeometryReader { geometry in
            VStack(spacing: geometry.size.height * 0.03) {
                ScrollView {
                    VStack(spacing: geometry.size.height * 0.03) {
                        HStack(spacing: 0) {
                            Text("Link")
                                .foregroundStyle(AuthTheme.primary)
                            Text("Up")
                                .foregroundStyle(AuthTheme.accent)
                        }
                        .font(Typography.title)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("LinkUp")

                        VStack(spacing: geometry.size.height * 0.02) {
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
                                    .font(Typography.headline)
                                    .foregroundStyle(AuthTheme.background)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .background(AuthTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                }
                .scrollContentBackground(.hidden)

                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(Typography.subheadline)
                            .foregroundStyle(AuthTheme.secondary)
                        Text("LOG IN")
                            .font(Typography.subheadlineSemibold)
                            .foregroundStyle(AuthTheme.accent)
                    }
                }
            }
            .padding(.horizontal, geometry.size.width * 0.05)
            .padding(.vertical, geometry.size.height * 0.05)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthTheme.background)
            .keyboardResponsive()
        }
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
