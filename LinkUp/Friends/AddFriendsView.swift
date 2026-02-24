//
//  AddFriendsView.swift
//  LinkUp
//

import SwiftUI

/// Add Friends screen: search by username, list friends, incoming/sent requests. Back button like History; AuthTheme.
struct AddFriendsView: View {
    @ObservedObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [PublicUser] = []
    @State private var friends: [Friend] = []
    @State private var incomingRequests: [FriendRequest] = []
    @State private var sentRequests: [FriendRequest] = []
    @State private var isSearching = false
    @State private var isLoading = true
    @State private var friendToRemove: Friend?
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    private var myUid: String { authState.currentUser?.id ?? "" }
    private var myUsername: String { authState.currentUser?.username ?? "" }
    private var myProfileImageURL: String? { authState.currentUser?.profileImageURL }
    private var friendIds: Set<String> { Set(friends.compactMap { $0.id }) }
    private var sentRequestUids: Set<String> { Set(sentRequests.map { $0.otherUid(myUid: myUid) }) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthTheme.background)
            .navigationTitle("Add friends")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(AuthTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("< Back") {
                        dismiss()
                    }
                    .foregroundStyle(AuthTheme.accent)
                }
            }
            .onAppear {
                Task { await loadAll() }
            }
            .onChange(of: searchText) { _, newValue in
                scheduleSearch(prefix: newValue)
            }
            .alert("Remove friend?", isPresented: Binding(
                get: { friendToRemove != nil },
                set: { if !$0 { friendToRemove = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    friendToRemove = nil
                }
                Button("Remove", role: .destructive) {
                    if let friend = friendToRemove {
                        Task { await removeFriend(friend) }
                    }
                    friendToRemove = nil
                }
            } message: {
                if let friend = friendToRemove {
                    Text("Remove \(friend.username) from friends?")
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AuthTheme.secondary)
            TextField("Search by username", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(AuthTheme.primary)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(AuthTheme.primary.opacity(0.08))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            Spacer()
            ProgressView()
                .tint(AuthTheme.primary)
            Spacer()
        } else if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchResultsContent
        } else {
            mainContent
        }
    }

    private var searchResultsContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(AuthTheme.primary)
                            .padding()
                        Spacer()
                    }
                } else if searchResults.isEmpty {
                    Text("No users found")
                        .font(.subheadline)
                        .foregroundStyle(AuthTheme.secondary)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(searchResults) { user in
                        searchResultRow(user)
                    }
                }
            }
        }
    }

    private func searchResultRow(_ user: PublicUser) -> some View {
        let isFriend = friendIds.contains(user.id)
        let sentPending = sentRequestUids.contains(user.id)
        return UserRowView(
            imageURL: user.profileImageURL,
            initial: user.initial,
            username: user.username
        ) {
            if isFriend {
                Text("Friend")
                    .font(.caption)
                    .foregroundStyle(AuthTheme.secondary)
            } else if sentPending {
                Text("Pending")
                    .font(.caption)
                    .foregroundStyle(AuthTheme.secondary)
            } else {
                Button("Add") {
                    Task { await sendRequest(to: user) }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AuthTheme.accent)
            }
        }
    }

    private var mainContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                friendsSection
                incomingSection
                sentSection
                inviteSection
            }
            .padding(.vertical, 20)
        }
    }

    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Invite to LinkUp")
            ShareLink(
                item: inviteMessage,
                subject: Text("Join me on LinkUp"),
                message: Text(inviteMessage)
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundStyle(AuthTheme.accent)
                    Text("Invite friends to the app")
                        .font(.subheadline)
                        .foregroundStyle(AuthTheme.accent)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AuthTheme.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(AuthTheme.primary.opacity(0.08))
            .padding(.horizontal, 20)
        }
    }

    private var inviteMessage: String {
        "Join me on LinkUp – plan activities and polls with friends!"
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Friends")
            if friends.isEmpty {
                Text("No friends yet")
                    .font(.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            } else {
                ForEach(friends, id: \.friendUid) { friend in
                    UserRowView(
                        imageURL: friend.profileImageURL,
                        initial: friend.initial,
                        username: friend.username
                    ) {
                        Button("Remove") {
                            friendToRemove = friend
                        }
                        .font(.subheadline)
                        .foregroundStyle(AuthTheme.accent)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
    }

    private var incomingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Friend requests")
            if incomingRequests.isEmpty {
                Text("No pending requests")
                    .font(.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            } else {
                ForEach(incomingRequests, id: \.id) { request in
                    UserRowView(
                        imageURL: request.otherProfileImageURL(myUid: myUid),
                        initial: request.otherUsername(myUid: myUid).first.map { String($0).uppercased() } ?? "?",
                        username: request.otherUsername(myUid: myUid)
                    ) {
                        HStack(spacing: 12) {
                            Button("Accept") {
                                Task { await acceptRequest(request) }
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AuthTheme.accent)
                            Button("Reject") {
                                Task { await rejectRequest(request) }
                            }
                            .font(.subheadline)
                            .foregroundStyle(AuthTheme.secondary)
                        }
                    }
                }
            }
        }
    }

    private var sentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Sent requests")
            if sentRequests.isEmpty {
                Text("No sent requests")
                    .font(.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            } else {
                ForEach(sentRequests, id: \.id) { request in
                    UserRowView(
                        imageURL: request.otherProfileImageURL(myUid: myUid),
                        initial: request.otherUsername(myUid: myUid).first.map { String($0).uppercased() } ?? "?",
                        username: request.otherUsername(myUid: myUid)
                    ) {
                        Text("Pending")
                            .font(.caption)
                            .foregroundStyle(AuthTheme.secondary)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AuthTheme.secondary)
            .padding(.horizontal, 20)
    }

    private func scheduleSearch(prefix: String) {
        searchTask?.cancel()
        let trimmed = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            searchResults = []
            isSearching = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await runSearch(prefix: trimmed)
        }
    }

    private func runSearch(prefix: String) async {
        isSearching = true
        defer { isSearching = false }
        do {
            let results = try await authState.searchUsernames(prefix: prefix, currentUserUid: myUid)
            guard !Task.isCancelled else { return }
            searchResults = results
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        guard !myUid.isEmpty else { return }
        do {
            async let f = authState.fetchFriends(uid: myUid)
            async let inc = authState.fetchIncomingRequests(uid: myUid)
            async let sent = authState.fetchSentRequests(uid: myUid)
            friends = try await f
            incomingRequests = try await inc
            sentRequests = try await sent
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sendRequest(to user: PublicUser) async {
        do {
            try await authState.sendRequest(
                fromUid: myUid,
                fromUsername: myUsername,
                fromProfileImageURL: myProfileImageURL,
                toUid: user.id,
                toUsername: user.username,
                toProfileImageURL: user.profileImageURL
            )
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func acceptRequest(_ request: FriendRequest) async {
        do {
            try await authState.acceptRequest(request, myUid: myUid, myUsername: myUsername, myProfileImageURL: myProfileImageURL)
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func rejectRequest(_ request: FriendRequest) async {
        do {
            try await authState.rejectRequest(request)
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeFriend(_ friend: Friend) async {
        guard let uid = friend.id else { return }
        do {
            try await authState.removeFriend(myUid: myUid, friendUid: uid)
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Add Friends") {
    AddFriendsView(authState: AuthState())
}
