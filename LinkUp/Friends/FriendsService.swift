//
//  FriendsService.swift
//  LinkUp
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

extension AuthState {

    // MARK: - Search

    /// Search usernames by prefix (document ID). Excludes current user. Returns PublicUser with id = uid.
    func searchUsernames(prefix: String, currentUserUid: String) async throws -> [PublicUser] {
        let normalized = prefix.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }

        let end = normalized + "\u{f8ff}"
        let snapshot = try await databaseRef.collection("usernames")
            .order(by: "__name__")
            .start(at: [normalized])
            .end(at: [end])
            .limit(to: 30)
            .getDocuments()

        var result: [PublicUser] = []
        for doc in snapshot.documents {
            let data = doc.data()
            guard let uid = data["uid"] as? String, uid != currentUserUid else { continue }
            let profileImageURL = data["profileImageURL"] as? String
            result.append(PublicUser(id: uid, username: doc.documentID, profileImageURL: profileImageURL))
        }
        return result
    }

    // MARK: - Friends list

    /// Fetch current user's friends.
    func fetchFriends(uid: String) async throws -> [Friend] {
        let snapshot = try await databaseRef.collection("users").document(uid).collection("friends").getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Friend.self)
        }
    }

    // MARK: - Friend requests

    /// Fetch incoming (pending) friend requests for the user.
    func fetchIncomingRequests(uid: String) async throws -> [FriendRequest] {
        let snapshot = try await databaseRef.collection("friend_requests")
            .whereField("toUid", isEqualTo: uid)
            .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FriendRequest.self) }
    }

    /// Fetch sent (pending) friend requests.
    func fetchSentRequests(uid: String) async throws -> [FriendRequest] {
        let snapshot = try await databaseRef.collection("friend_requests")
            .whereField("fromUid", isEqualTo: uid)
            .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FriendRequest.self) }
    }

    // MARK: - Send request

    /// Send a friend request. Fails if already friends or a request already exists.
    func sendRequest(
        fromUid: String,
        fromUsername: String,
        fromProfileImageURL: String?,
        toUid: String,
        toUsername: String,
        toProfileImageURL: String?
    ) async throws {
        guard fromUid != toUid else { return }
        let requestId = "\(fromUid)_\(toUid)"

        let existing = try? await databaseRef.collection("friend_requests").document(requestId).getDocument()
        if existing?.exists == true { return }

        let myFriendDoc = try? await databaseRef.collection("users").document(fromUid).collection("friends").document(toUid).getDocument()
        if myFriendDoc?.exists == true { return }

        var data: [String: Any] = [
            "fromUid": fromUid,
            "fromUsername": fromUsername,
            "toUid": toUid,
            "toUsername": toUsername,
            "status": FriendRequestStatus.pending.rawValue,
            "createdAt": Timestamp(date: Date())
        ]
        if let url = fromProfileImageURL { data["fromProfileImageURL"] = url }
        if let url = toProfileImageURL { data["toProfileImageURL"] = url }
        try await databaseRef.collection("friend_requests").document(requestId).setData(data)
    }

    // MARK: - Accept / Reject

    /// Accept a friend request: create mutual friends docs and set request status to accepted.
    func acceptRequest(
        _ request: FriendRequest,
        myUid: String,
        myUsername: String,
        myProfileImageURL: String?
    ) async throws {
        guard let requestId = request.id else { return }
        let otherUid = request.otherUid(myUid: myUid)
        let otherUsername = request.otherUsername(myUid: myUid)
        let otherProfileImageURL = request.otherProfileImageURL(myUid: myUid)
        let now = Timestamp(date: Date())

        let batch = databaseRef.batch()

        var myFriendData: [String: Any] = ["username": otherUsername, "addedAt": now]
        if let url = otherProfileImageURL { myFriendData["profileImageURL"] = url }
        batch.setData(myFriendData, forDocument: databaseRef.collection("users").document(myUid).collection("friends").document(otherUid))

        var otherFriendData: [String: Any] = ["username": myUsername, "addedAt": now]
        if let url = myProfileImageURL { otherFriendData["profileImageURL"] = url }
        batch.setData(otherFriendData, forDocument: databaseRef.collection("users").document(otherUid).collection("friends").document(myUid))

        let requestRef = databaseRef.collection("friend_requests").document(requestId)
        batch.updateData(["status": FriendRequestStatus.accepted.rawValue], forDocument: requestRef)

        try await batch.commit()
    }

    /// Reject a friend request.
    func rejectRequest(_ request: FriendRequest) async throws {
        guard let requestId = request.id else { return }
        try await databaseRef.collection("friend_requests").document(requestId).updateData([
            "status": FriendRequestStatus.rejected.rawValue
        ])
    }

    // MARK: - Remove friend

    /// Remove friendship: delete both users' friend docs.
    func removeFriend(myUid: String, friendUid: String) async throws {
        let batch = databaseRef.batch()
        let myRef = databaseRef.collection("users").document(myUid).collection("friends").document(friendUid)
        let friendRef = databaseRef.collection("users").document(friendUid).collection("friends").document(myUid)
        batch.deleteDocument(myRef)
        batch.deleteDocument(friendRef)
        try await batch.commit()
    }
}
