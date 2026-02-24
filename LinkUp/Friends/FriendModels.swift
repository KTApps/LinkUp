//
//  FriendModels.swift
//  LinkUp
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

/// Lightweight public user info for search results and lists (from usernames or denormalized data).
struct PublicUser: Identifiable, Equatable {
    let id: String
    let username: String
    var profileImageURL: String?

    var initial: String {
        username.first?.uppercased() ?? "?"
    }
}

/// Friend document in users/<uid>/friends/<friendUid>. Denormalized for display.
struct Friend: Identifiable, Codable {
    @DocumentID var id: String?
    let username: String
    var profileImageURL: String?
    var addedAt: Timestamp

    var friendUid: String { id ?? "" }

    var initial: String {
        username.first?.uppercased() ?? "?"
    }
}

/// Friend request status.
enum FriendRequestStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

/// Friend request document in friend_requests/<requestId>.
struct FriendRequest: Identifiable, Codable {
    @DocumentID var id: String?
    let fromUid: String
    let fromUsername: String
    var fromProfileImageURL: String?
    let toUid: String
    let toUsername: String
    var toProfileImageURL: String?
    var status: FriendRequestStatus
    var createdAt: Timestamp

    var initial: String {
        (toUid == "" ? fromUsername : toUsername).first?.uppercased() ?? "?"
    }

    /// Display username for the "other" party (for current user's list).
    func otherUsername(myUid: String) -> String {
        fromUid == myUid ? toUsername : fromUsername
    }

    func otherUid(myUid: String) -> String {
        fromUid == myUid ? toUid : fromUid
    }

    func otherProfileImageURL(myUid: String) -> String? {
        fromUid == myUid ? toProfileImageURL : fromProfileImageURL
    }
}
