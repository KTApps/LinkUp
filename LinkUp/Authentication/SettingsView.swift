//
//  SettingsView.swift
//  LinkUp
//

import SwiftUI

/// Settings screen: Add friends, Sign out, Delete account. AuthTheme throughout.
struct SettingsView: View {
    @ObservedObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    @State private var showAddFriends = false
    @State private var showDeleteAccountConfirmation = false
    @State private var deleteAccountError: String?
    @State private var showDeleteAccountError = false
    @State private var isDeleting = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                settingsButton(title: "Add friends", image: "person.badge.plus") {
                    showAddFriends = true
                }

                settingsButton(title: "Sign out", image: "rectangle.portrait.and.arrow.right") {
                    authState.signOut()
                    dismiss()
                }

                settingsButton(
                    title: "Delete account",
                    image: "trash",
                    isDestructive: true
                ) {
                    showDeleteAccountConfirmation = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            Spacer()
        }
        .background(AuthTheme.background)
        .sheet(isPresented: $showAddFriends) {
            AddFriendsPlaceholderView()
        }
        .alert("Delete account?", isPresented: $showDeleteAccountConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await confirmDeleteAccount() }
            }
        } message: {
            Text("This cannot be undone. Your account and data will be permanently removed.")
        }
        .alert("Could not delete account", isPresented: $showDeleteAccountError) {
            Button("OK", role: .cancel) {
                deleteAccountError = nil
            }
        } message: {
            if let deleteAccountError {
                Text(deleteAccountError)
            }
        }
        .overlay {
            if isDeleting {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(AuthTheme.primary)
            }
        }
    }

    private func settingsButton(
        title: String,
        image: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: image)
                    .font(.system(size: 18))
                    .frame(width: 24, alignment: .center)
                Text(title)
                    .font(.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .foregroundStyle(isDestructive ? AuthTheme.accent : AuthTheme.primary)
            .background(AuthTheme.primary.opacity(0.08))
        }
        .buttonStyle(.plain)
        .disabled(isDeleting)
    }

    private func confirmDeleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await authState.deleteAccount()
            dismiss()
        } catch {
            deleteAccountError = error.localizedDescription
            showDeleteAccountError = true
        }
    }
}

/// Placeholder for Add friends – real friend logic (search, requests) can be added later.
struct AddFriendsPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Add friends")
                    .font(.title2)
                    .foregroundStyle(AuthTheme.primary)
                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthTheme.background)
            .navigationTitle("Add friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AuthTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AuthTheme.accent)
                }
            }
        }
    }
}

#Preview("Settings") {
    SettingsView(authState: AuthState())
}

#Preview("Add friends placeholder") {
    AddFriendsPlaceholderView()
}
