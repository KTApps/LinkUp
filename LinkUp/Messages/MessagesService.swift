//
//  MessagesService.swift
//  LinkUp
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

extension AuthState {

    // MARK: - DM conversation id

    /// Deterministic conversation id for a DM between two users (sorted uids).
    static func dmConversationId(uid1: String, uid2: String) -> String {
        [uid1, uid2].sorted().joined(separator: "_")
    }

    // MARK: - Create conversation

    /// Get or create a DM conversation between current user and friend. Returns existing or newly created.
    func getOrCreateDM(myUid: String, friendUid: String) async throws -> Conversation {
        let conversationId = Self.dmConversationId(uid1: myUid, uid2: friendUid)
        let ref = databaseRef.collection("conversations").document(conversationId)
        if let existing = try? await ref.getDocument(), existing.exists, let conv = try? existing.data(as: Conversation.self) {
            return conv
        }
        let now = Timestamp(date: Date())
        let participantIds = [myUid, friendUid].sorted()
        let newConv = Conversation(
            id: conversationId,
            type: .dm,
            name: nil,
            participantIds: participantIds,
            createdBy: myUid,
            createdAt: now,
            lastMessageText: nil,
            lastMessageAt: now,
            participantSummary: nil
        )
        var data = try Firestore.Encoder().encode(newConv)
        data["participantIds"] = participantIds
        try await ref.setData(data)
        return newConv
    }

    /// Create a named group conversation. Caller must include myUid in participantIds.
    func createGroupConversation(
        name: String,
        participantIds: [String],
        createdBy: String
    ) async throws -> Conversation {
        let ref = databaseRef.collection("conversations").document()
        let now = Timestamp(date: Date())
        let conv = Conversation(
            id: ref.documentID,
            type: .group,
            name: name,
            participantIds: participantIds,
            createdBy: createdBy,
            createdAt: now,
            lastMessageText: nil,
            lastMessageAt: now,
            participantSummary: nil
        )
        try ref.setData(from: conv)
        return conv
    }

    // MARK: - Send message

    /// Send a message and update conversation lastMessage*.
    func sendMessage(
        conversationId: String,
        senderUid: String,
        senderUsername: String,
        text: String
    ) async throws {
        let now = Timestamp(date: Date())
        let messageRef = databaseRef.collection("conversations").document(conversationId).collection("messages").document()
        let message = Message(
            id: messageRef.documentID,
            senderUid: senderUid,
            senderUsername: senderUsername,
            text: text,
            createdAt: now
        )
        try messageRef.setData(from: message)
        try await databaseRef.collection("conversations").document(conversationId).updateData([
            "lastMessageText": text,
            "lastMessageAt": now
        ])
    }

    // MARK: - Fetch group conversations

    /// Fetches group conversations the user is in (for poll share picker).
    func fetchMyGroupConversations(uid: String) async throws -> [Conversation] {
        let snapshot = try await databaseRef.collection("conversations")
            .whereField("participantIds", arrayContains: uid)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            guard let conv = try? doc.data(as: Conversation.self), conv.type == .group else { return nil }
            return conv
        }
    }

    // MARK: - Listeners

    /// Real-time listener for conversations where the user is a participant. Call remove() on return value to stop.
    func addConversationsListener(uid: String, onUpdate: @escaping ([Conversation]) -> Void) -> ListenerRegistration {
        databaseRef.collection("conversations")
            .whereField("participantIds", arrayContains: uid)
            .order(by: "lastMessageAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    if let error { print("Conversations listener error: \(error)") }
                    return
                }
                let list = snapshot.documents.compactMap { doc -> Conversation? in
                    try? doc.data(as: Conversation.self)
                }
                DispatchQueue.main.async { onUpdate(list) }
            }
    }

    /// Real-time listener for messages in a conversation. Call remove() on return value to stop.
    func addMessagesListener(conversationId: String, onUpdate: @escaping ([Message]) -> Void) -> ListenerRegistration {
        databaseRef.collection("conversations").document(conversationId).collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    if let error { print("Messages listener error: \(error)") }
                    return
                }
                let list = snapshot.documents.compactMap { doc -> Message? in
                    try? doc.data(as: Message.self)
                }
                DispatchQueue.main.async { onUpdate(list) }
            }
    }
}
