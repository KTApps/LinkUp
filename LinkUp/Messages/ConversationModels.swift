//
//  ConversationModels.swift
//  LinkUp
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

/// Conversation type: DM (1:1) or group.
enum ConversationType: String, Codable {
    case dm
    case group
}

/// Conversation document in conversations/<conversationId>. DMs use deterministic id (sorted uids); groups use auto-id.
struct Conversation: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var type: ConversationType
    var name: String?
    var participantIds: [String]
    var createdBy: String
    var createdAt: Timestamp
    var lastMessageText: String?
    var lastMessageAt: Timestamp?
    /// Optional: uid -> { username, profileImageURL } for list display.
    var participantSummary: [String: ParticipantSummaryValue]?

    init(id: String? = nil, type: ConversationType, name: String? = nil, participantIds: [String], createdBy: String, createdAt: Timestamp, lastMessageText: String? = nil, lastMessageAt: Timestamp? = nil, participantSummary: [String: ParticipantSummaryValue]? = nil) {
        self.id = id
        self.type = type
        self.name = name
        self.participantIds = participantIds
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.lastMessageText = lastMessageText
        self.lastMessageAt = lastMessageAt
        self.participantSummary = participantSummary
    }

    /// Display title: for DM the other user's name (caller must resolve); for group the name.
    func displayTitle(forUid myUid: String) -> String? {
        switch type {
        case .dm:
            return nil
        case .group:
            return name
        }
    }

    /// Other participant's uid in a DM (exactly two participants).
    func otherParticipantUid(myUid: String) -> String? {
        guard type == .dm, participantIds.count == 2 else { return nil }
        return participantIds.first { $0 != myUid }
    }
}

/// Stored in conversation.participantSummary[uid]. Codable map value.
struct ParticipantSummaryValue: Codable, Equatable {
    var username: String
    var profileImageURL: String?
}

/// Message document in conversations/<id>/messages/<messageId>.
struct Message: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var senderUid: String
    var senderUsername: String?
    var text: String
    var createdAt: Timestamp

    func isFromMe(myUid: String) -> Bool {
        senderUid == myUid
    }
}
