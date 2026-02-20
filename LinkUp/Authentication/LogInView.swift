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
            GeometryReader { geometry in
                VStack(spacing: geometry.size.height * 0.03) {
                    ScrollView {
                        VStack(spacing: geometry.size.height * 0.03) {
                            Text("LinkUp")
                                .font(Typography.title)

                            VStack(spacing: geometry.size.height * 0.02) {
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
                                            .font(Typography.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.top, geometry.size.height * 0.045)
                                    .padding(.trailing, geometry.size.width * 0.03)
                                }

                                Button {
                                    Task {
                                        await authState.logIn(withEmail: email, password: password)
                                    }
                                } label: {
                                    Text("LOG IN")
                                        .font(Typography.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.horizontal)
                        }
                    }

                    NavigationLink {
                        SignUpView(authState: authState)
                    } label: {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .font(Typography.subheadline)
                            Text("SIGN UP")
                                .font(Typography.subheadlineSemibold)
                        }
                    }
                }
                .padding(.horizontal, geometry.size.width * 0.05)
                .padding(.vertical, geometry.size.height * 0.05)
                .keyboardResponsive()
            }
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
