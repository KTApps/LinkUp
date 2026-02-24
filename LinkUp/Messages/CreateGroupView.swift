//
//  CreateGroupView.swift
//  LinkUp
//

import SwiftUI

/// Create group flow: group name, multi-select friends, Create. AuthTheme.
struct CreateGroupView: View {
    @ObservedObject var authState: AuthState
    var onCreated: (Conversation) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var groupName = ""
    @State private var friends: [Friend] = []
    @State private var selectedFriendIds: Set<String> = []
    @State private var isCreating = false
    @State private var errorMessage: String?

    private var myUid: String { authState.currentUser?.id ?? "" }
    private var canCreate: Bool {
        let name = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && !selectedFriendIds.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            nameField
            friendsList
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AuthTheme.background)
        .navigationTitle("New group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AuthTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task { await createGroup() }
                }
                .foregroundStyle(canCreate ? AuthTheme.accent : AuthTheme.secondary)
                .disabled(!canCreate || isCreating)
            }
        }
        .onAppear {
            Task { await loadFriends() }
        }
        .overlay {
            if isCreating {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(AuthTheme.primary)
            }
        }
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            if let errorMessage { Text(errorMessage) }
        }
    }

    private var nameField: some View {
        HStack(spacing: 8) {
            Text("Name")
                .font(.subheadline)
                .foregroundStyle(AuthTheme.secondary)
                .frame(width: 60, alignment: .leading)
            TextField("Group name", text: $groupName)
                .textFieldStyle(.plain)
                .foregroundStyle(AuthTheme.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AuthTheme.primary.opacity(0.1))
                .frame(height: 1)
        }
    }

    private var friendsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add friends")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AuthTheme.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(friends, id: \.friendUid) { friend in
                        let isSelected = friend.id.map { selectedFriendIds.contains($0) } ?? false
                        Button {
                            toggleFriend(friend)
                        } label: {
                            HStack(spacing: 12) {
                                avatarView(url: friend.profileImageURL, initial: friend.initial)
                                Text(friend.username)
                                    .font(.body)
                                    .foregroundStyle(AuthTheme.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AuthTheme.accent)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(AuthTheme.primary.opacity(0.1))
                                .frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private func avatarView(url: String?, initial: String) -> some View {
        Group {
            if let urlString = url, let u = URL(string: urlString) {
                AsyncImage(url: u) { phase in
                    switch phase {
                    case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                    default: avatarPlaceholder(initial: initial)
                    }
                }
            } else {
                avatarPlaceholder(initial: initial)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay(Circle().stroke(AuthTheme.secondary.opacity(0.5), lineWidth: 1))
    }

    private func avatarPlaceholder(initial: String) -> some View {
        Text(initial)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(AuthTheme.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Circle().fill(AuthTheme.secondary.opacity(0.4)))
    }

    private func toggleFriend(_ friend: Friend) {
        guard let uid = friend.id else { return }
        if selectedFriendIds.contains(uid) {
            selectedFriendIds.remove(uid)
        } else {
            selectedFriendIds.insert(uid)
        }
    }

    private func loadFriends() async {
        guard !myUid.isEmpty else { return }
        do {
            friends = try await authState.fetchFriends(uid: myUid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createGroup() async {
        let name = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !selectedFriendIds.isEmpty else { return }
        isCreating = true
        defer { isCreating = false }
        do {
            var participantIds = [myUid]
            participantIds.append(contentsOf: selectedFriendIds)
            let conv = try await authState.createGroupConversation(name: name, participantIds: participantIds, createdBy: myUid)
            onCreated(conv)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
