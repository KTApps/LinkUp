//
//  LogInView.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 20/02/2026.
//

import SwiftUI

/// Login screen: email, password, LOG IN button, link to SignUpView.
struct LogInView: View {
    @ObservedObject var authState: AuthState

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("LinkUp")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    Input(text: $email, title: "Email", placeholder: "name@example.com")
                    Input(
                        text: $password,
                        title: "Password",
                        placeholder: "******",
                        secureField: !showPassword
                    )
                    .overlay(alignment: .topTrailing) {
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 37)   // align with text field (Input title + spacing)
                        .padding(.trailing, 12)
                    }

                    Button {
                        Task {
                            await authState.logIn(withEmail: email, password: password)
                        }
                    } label: {
                        Text("LOG IN")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                Spacer()

                NavigationLink {
                    SignUpView(authState: authState)
                } label: {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                        Text("SIGN UP")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
            }
            .padding()
            .alert("Log in failed", isPresented: $authState.logInError) {
                Button("Try again") {
                    authState.logInError = false
                }
            } message: {
                Text("User doesn't exist or wrong password. Try again.")
            }
        }
    }
}

#Preview {
    LogInView(authState: AuthState())
}
