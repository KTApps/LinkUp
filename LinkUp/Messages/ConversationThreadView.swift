//
//  ConversationThreadView.swift
//  LinkUp
//

import SwiftUI
import FirebaseFirestore

/// Thread view: message bubbles, text input, send. Real-time listener. AuthTheme.
struct ConversationThreadView: View {
    @ObservedObject var authState: AuthState
    let conversation: Conversation
    let displayTitle: String
    @State private var messages: [Message] = []
    @State private var inputText = ""
    @State private var listener: ListenerRegistration?
    @State private var errorMessage: String?

    private var myUid: String { authState.currentUser?.id ?? "" }
    private var myUsername: String { authState.currentUser?.username ?? "" }

    var body: some View {
        VStack(spacing: 0) {
            messagesList
            inputBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AuthTheme.background)
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AuthTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            startListener()
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

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { msg in
                        messageRow(msg)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last?.id {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func messageRow(_ msg: Message) -> some View {
        let isMe = msg.isFromMe(myUid: myUid)
        return HStack {
            if isMe { Spacer(minLength: 60) }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                Text(msg.text)
                    .font(.body)
                    .foregroundStyle(isMe ? AuthTheme.background : AuthTheme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isMe ? AuthTheme.accent : AuthTheme.primary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(formatTime(msg.createdAt))
                    .font(.caption2)
                    .foregroundStyle(AuthTheme.secondary)
            }
            if !isMe { Spacer(minLength: 60) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $inputText)
                .textFieldStyle(.plain)
                .foregroundStyle(AuthTheme.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AuthTheme.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? AuthTheme.secondary : AuthTheme.accent)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AuthTheme.background)
    }

    private func formatTime(_ t: Timestamp) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: t.dateValue())
    }

    private func startListener() {
        guard let id = conversation.id else { return }
        listener = authState.addMessagesListener(conversationId: id) { list in
            messages = list
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let conversationId = conversation.id else { return }
        inputText = ""
        Task {
            do {
                try await authState.sendMessage(conversationId: conversationId, senderUid: myUid, senderUsername: myUsername, text: text)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
