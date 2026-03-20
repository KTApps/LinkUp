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
    @State private var notifications: [AppNotificationItem] = []
    @State private var isLoadingNotifications = false
    @State private var showNotificationsSheet = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                settingsButton(title: "Add friends", image: "person.badge.plus") {
                    showAddFriends = true
                }

                settingsButton(
                    title: "Notifications",
                    image: "bell.fill",
                    badgeCount: unreadNotificationsCount > 0 ? unreadNotificationsCount : nil
                ) {
                    showNotificationsSheet = true
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
        .task {
            await loadNotifications()
        }
        .sheet(isPresented: $showAddFriends) {
            AddFriendsView(authState: authState)
        }
        .sheet(isPresented: $showNotificationsSheet) {
            notificationsBottomSheet
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
        badgeCount: Int? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: image)
                    .font(.system(size: 18))
                    .frame(width: 24, alignment: .center)
                Text(title)
                    .font(.body)
                if let count = badgeCount, count > 0 {
                    Text("\(count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AuthTheme.background)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AuthTheme.accent)
                        .clipShape(Capsule())
                }
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

    private var notificationsBottomSheet: some View {
        NavigationStack {
            Group {
                if isLoadingNotifications && notifications.isEmpty {
                    ProgressView()
                        .tint(AuthTheme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notifications.isEmpty {
                    Text("No notifications yet")
                        .font(Typography.subheadline)
                        .foregroundStyle(AuthTheme.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(notifications) { item in
                                notificationRow(item)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthTheme.background)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AuthTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showNotificationsSheet = false
                    }
                    .foregroundStyle(AuthTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            await loadNotifications()
        }
    }

    private func notificationRow(_ item: AppNotificationItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(item.actorUsername) confirmed")
                .font(Typography.subheadlineSemibold)
                .foregroundStyle(AuthTheme.primary)
            Text(item.pollQuestion)
                .font(Typography.subheadline)
                .foregroundStyle(AuthTheme.secondary)

            HStack(spacing: 8) {
                Button("Confirm too") {
                    Task {
                        try? await authState.confirmVote(pollId: item.pollId)
                        try? await authState.markNotificationRead(notificationId: item.id)
                        await loadNotifications()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AuthTheme.accent)

                Button("Change vote") {
                    Task {
                        try? await authState.unconfirmVote(pollId: item.pollId)
                        try? await authState.markNotificationRead(notificationId: item.id)
                        await loadNotifications()
                    }
                }
                .buttonStyle(.bordered)
                .tint(AuthTheme.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AuthTheme.primary.opacity(0.08))
    }

    @MainActor
    private func loadNotifications() async {
        isLoadingNotifications = true
        defer { isLoadingNotifications = false }
        if let loaded = try? await authState.fetchNotifications() {
            notifications = loaded
        } else {
            notifications = []
        }
    }

    private var unreadNotificationsCount: Int {
        notifications.reduce(0) { partial, item in
            partial + (item.isRead ? 0 : 1)
        }
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

#Preview("Settings") {
    SettingsView(authState: AuthState())
}
