//
//  MessagesListView.swift
//  LinkUp
//

import SwiftUI
import FirebaseFirestore

/// Destination for messages sheet navigation: open thread or create group.
private enum MessagesDestination: Hashable {
    case thread(conversationId: String, displayTitle: String)
    case createGroup
}

/// Root messages view: list of conversations, search, new group. Real-time listener. AuthTheme.
struct MessagesListView: View {
    @ObservedObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    @State private var conversations: [Conversation] = []
    @State private var friends: [Friend] = []
    @State private var searchText = ""
    @State private var navigationPath: [MessagesDestination] = []
    @State private var listener: ListenerRegistration?
    @State private var errorMessage: String?

    private var myUid: String { authState.currentUser?.id ?? "" }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                searchBar
                listContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthTheme.background)
            .navigationTitle("Messages")
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
            .navigationDestination(for: MessagesDestination.self) { dest in
                switch dest {
                case .thread(let conversationId, let displayTitle):
                    if let conv = conversations.first(where: { $0.id == conversationId }) {
                        ConversationThreadView(authState: authState, conversation: conv, displayTitle: displayTitle)
                    }
                case .createGroup:
                    CreateGroupView(authState: authState) { newConv in
                        navigationPath.removeAll()
                        if !conversations.contains(where: { $0.id == newConv.id }) {
                            conversations.insert(newConv, at: 0)
                        }
                        let title = newConv.name ?? "Group"
                        navigationPath.append(.thread(conversationId: newConv.id ?? "", displayTitle: title))
                    }
                }
            }
            .onAppear {
                startListeners()
                Task { await loadFriends() }
            }
            .onDisappear {
                listener?.remove()
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
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AuthTheme.secondary)
            TextField("Search friends or groups", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(AuthTheme.primary)
                .autocapitalization(.none)
        }
        .padding(12)
        .background(AuthTheme.primary.opacity(0.08))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                newGroupRow
                if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    searchResultsSection
                } else {
                    conversationsSection
                }
            }
        }
    }

    private var newGroupRow: some View {
        Button {
            navigationPath.append(.createGroup)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AuthTheme.accent)
                    .frame(width: 36, height: 36)
                Text("New group")
                    .font(.body)
                    .foregroundStyle(AuthTheme.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AuthTheme.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AuthTheme.primary.opacity(0.1))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var searchResultsSection: some View {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if trimmed.isEmpty {
            EmptyView()
        } else {
            let matchingFriends = friends.filter { $0.username.lowercased().contains(trimmed) }
            let matchingGroups = conversations.filter { $0.type == .group && ($0.name?.lowercased().contains(trimmed) ?? false) }
            if matchingFriends.isEmpty && matchingGroups.isEmpty {
                Text("No results")
                    .font(.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(matchingFriends, id: \.friendUid) { friend in
                    Button {
                        Task { await openDM(with: friend) }
                    } label: {
                        conversationRow(title: friend.username, imageURL: friend.profileImageURL, initial: friend.initial, lastPreview: nil, lastAt: nil)
                    }
                    .buttonStyle(.plain)
                }
                ForEach(matchingGroups, id: \.id) { conv in
                    if let id = conv.id {
                        Button {
                            navigationPath.append(.thread(conversationId: id, displayTitle: conv.name ?? "Group"))
                        } label: {
                            conversationRow(title: conv.name ?? "Group", imageURL: nil, initial: String(conv.name?.prefix(1) ?? "G").uppercased(), lastPreview: conv.lastMessageText, lastAt: conv.lastMessageAt)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var conversationsSection: some View {
        Group {
            if conversations.isEmpty {
                Text("No conversations yet")
                    .font(.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(conversations, id: \.id) { conv in
                    if let id = conv.id {
                        Button {
                            let title = titleForConversation(conv)
                            navigationPath.append(.thread(conversationId: id, displayTitle: title))
                        } label: {
                            rowForConversation(conv)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func titleForConversation(_ conv: Conversation) -> String {
        if conv.type == .dm, let otherUid = conv.otherParticipantUid(myUid: myUid) {
            return friends.first { $0.friendUid == otherUid }?.username ?? otherUid
        }
        return conv.name ?? "Group"
    }

    private func rowForConversation(_ conv: Conversation) -> some View {
        let title = titleForConversation(conv)
        let imageURL: String?
        let initial: String
        if conv.type == .dm, let otherUid = conv.otherParticipantUid(myUid: myUid) {
            let friend = friends.first { $0.friendUid == otherUid }
            imageURL = friend?.profileImageURL
            initial = title.first.map { String($0).uppercased() } ?? "?"
        } else {
            imageURL = nil
            initial = String(title.prefix(1)).uppercased()
        }
        return conversationRow(title: title, imageURL: imageURL, initial: initial, lastPreview: conv.lastMessageText, lastAt: conv.lastMessageAt)
    }

    private func conversationRow(title: String, imageURL: String?, initial: String, lastPreview: String?, lastAt: Timestamp?) -> some View {
        HStack(spacing: 12) {
            avatarView(url: imageURL, initial: initial)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(AuthTheme.primary)
                    .lineLimit(1)
                if let preview = lastPreview, !preview.isEmpty {
                    Text(preview)
                        .font(.caption)
                        .foregroundStyle(AuthTheme.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let at = lastAt {
                Text(formatMessageTime(at))
                    .font(.caption2)
                    .foregroundStyle(AuthTheme.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AuthTheme.primary.opacity(0.1))
                .frame(height: 1)
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
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .overlay(Circle().stroke(AuthTheme.secondary.opacity(0.5), lineWidth: 1))
    }

    private func avatarPlaceholder(initial: String) -> some View {
        Text(initial)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(AuthTheme.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Circle().fill(AuthTheme.secondary.opacity(0.4)))
    }

    private func formatMessageTime(_ t: Timestamp) -> String {
        let d = t.dateValue()
        let now = Date()
        if Calendar.current.isDateInToday(d) {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f.string(from: d)
        }
        if Calendar.current.isDateInYesterday(d) {
            return "Yesterday"
        }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: d)
    }

    private func startListeners() {
        guard !myUid.isEmpty else { return }
        listener = authState.addConversationsListener(uid: myUid) { list in
            conversations = list
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

    private func openDM(with friend: Friend) async {
        guard let friendUid = friend.id else { return }
        do {
            let conv = try await authState.getOrCreateDM(myUid: myUid, friendUid: friendUid)
            if let id = conv.id {
                let title = friend.username ?? "Chat"
                navigationPath.append(.thread(conversationId: id, displayTitle: title))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
