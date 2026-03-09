//
//  PollService.swift
//  LinkUp
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

/// Firestore document shape for a poll (includes metadata not on the in-app Poll model).
private struct PollDocument: Encodable {
    let id: String
    let question: String
    let options: [PollOption]
    let activityDate: Date?
    let activityDescription: String?
    let imageURL: String?
    let createdBy: String
    let createdAt: Date
    let visibleToUids: [String]
}

extension AuthState {

    /// Creates a poll: uploads image to Storage if provided, writes document to Firestore, returns the created Poll.
    /// Options are built from option texts with generated ids and count 0. visibleToUids must include createdBy.
    func createPoll(
        question: String,
        optionTexts: [String],
        activityDate: Date?,
        activityDescription: String?,
        imageData: Data?,
        visibleToUids: [String]
    ) async throws -> Poll {
        guard let uid = authRef.currentUser?.uid else {
            throw PollServiceError.notAuthenticated
        }
        let pollId = UUID().uuidString
        var imageURL: String?
        if let data = imageData {
            let jpegData = UIImage(data: data)?.jpegData(compressionQuality: 0.8) ?? data
            let ref = storageRef.child("activity_images/\(pollId).jpg")
            _ = try await ref.putDataAsync(jpegData)
            imageURL = try await ref.downloadURL().absoluteString
        }
        let options: [PollOption] = optionTexts.enumerated().map { index, text in
            PollOption(id: "opt-\(index)", text: text, count: 0)
        }
        let allVisible = visibleToUids.contains(uid) ? visibleToUids : [uid] + visibleToUids
        let poll = Poll(
            id: pollId,
            question: question,
            options: options,
            activityDate: activityDate,
            activityDescription: activityDescription,
            imageURL: imageURL,
            createdBy: uid,
            visibleToUids: allVisible
        )
        let doc = PollDocument(
            id: poll.id,
            question: poll.question,
            options: poll.options,
            activityDate: poll.activityDate,
            activityDescription: poll.activityDescription,
            imageURL: poll.imageURL,
            createdBy: uid,
            createdAt: Date(),
            visibleToUids: allVisible
        )
        let encoded = try Firestore.Encoder().encode(doc)
        try await databaseRef.collection("polls").document(pollId).setData(encoded)
        return poll
    }

    /// Updates an existing poll. Preserves option vote counts by index; new options get count 0.
    /// Caller must pass the existing poll (for option counts and createdBy). Replaces image if imageData is non-nil.
    func updatePoll(
        existingPoll: Poll,
        question: String,
        optionTexts: [String],
        activityDate: Date?,
        activityDescription: String?,
        imageData: Data?,
        visibleToUids: [String]
    ) async throws -> Poll {
        guard let uid = authRef.currentUser?.uid else {
            throw PollServiceError.notAuthenticated
        }
        guard existingPoll.createdBy == uid else {
            throw PollServiceError.notAuthenticated
        }
        let pollId = existingPoll.id
        var imageURL = existingPoll.imageURL
        if let data = imageData {
            let jpegData = UIImage(data: data)?.jpegData(compressionQuality: 0.8) ?? data
            let ref = storageRef.child("activity_images/\(pollId).jpg")
            _ = try await ref.putDataAsync(jpegData)
            imageURL = try await ref.downloadURL().absoluteString
        }
        let existingOptions = existingPoll.options
        let options: [PollOption] = optionTexts.enumerated().map { index, text in
            let existingCount = index < existingOptions.count ? existingOptions[index].count : 0
            let optionId = index < existingOptions.count ? existingOptions[index].id : "opt-\(index)"
            return PollOption(id: optionId, text: text, count: existingCount)
        }
        let allVisible = visibleToUids.contains(uid) ? visibleToUids : [uid] + visibleToUids
        let updatedPoll = Poll(
            id: pollId,
            question: question,
            options: options,
            activityDate: activityDate,
            activityDescription: activityDescription,
            imageURL: imageURL,
            createdBy: existingPoll.createdBy,
            visibleToUids: allVisible
        )
        let doc = PollDocument(
            id: updatedPoll.id,
            question: updatedPoll.question,
            options: updatedPoll.options,
            activityDate: updatedPoll.activityDate,
            activityDescription: updatedPoll.activityDescription,
            imageURL: updatedPoll.imageURL,
            createdBy: uid,
            createdAt: Date(),
            visibleToUids: allVisible
        )
        let encoded = try Firestore.Encoder().encode(doc)
        try await databaseRef.collection("polls").document(pollId).setData(encoded)
        return updatedPoll
    }

    /// Deletes a poll document. Optionally deletes the activity image from Storage. Caller removes from local list.
    func deletePoll(pollId: String) async throws {
        guard authRef.currentUser != nil else {
            throw PollServiceError.notAuthenticated
        }
        let ref = databaseRef.collection("polls").document(pollId)
        try await ref.delete()
        let imageRef = storageRef.child("activity_images/\(pollId).jpg")
        try? await imageRef.delete()
    }

    /// Submits a vote: updates poll option counts and stores response. Requires current user (uid + username).
    /// Decrements previous option if any; increments new option. Use batch for atomicity.
    func submitVote(pollId: String, optionId: String, previousOptionId: String?) async throws -> Poll {
        guard let uid = authRef.currentUser?.uid,
              let username = currentUser?.username else {
            throw PollServiceError.notAuthenticated
        }
        let pollRef = databaseRef.collection("polls").document(pollId)
        let responseRef = pollRef.collection("responses").document(uid)

        let snapshot = try await pollRef.getDocument()
        guard snapshot.exists, let data = snapshot.data() else { throw PollServiceError.pollNotFound }
        let poll = try snapshot.data(as: Poll.self)

        var options = poll.options
        if let prevId = previousOptionId, let prevIdx = options.firstIndex(where: { $0.id == prevId }), options[prevIdx].count > 0 {
            options[prevIdx].count -= 1
        }
        if let newIdx = options.firstIndex(where: { $0.id == optionId }) {
            options[newIdx].count += 1
        }

        let updatedPoll = Poll(
            id: poll.id,
            question: poll.question,
            options: options,
            activityDate: poll.activityDate,
            activityDescription: poll.activityDescription,
            imageURL: poll.imageURL,
            createdBy: poll.createdBy,
            visibleToUids: poll.visibleToUids
        )
        // Build options as plain maps so Firestore stores them in a form that decodes correctly for all clients.
        let optionsData: [[String: Any]] = options.map { opt in
            ["id": opt.id, "text": opt.text, "count": opt.count]
        }

        let batch = databaseRef.batch()
        batch.updateData(["options": optionsData], forDocument: pollRef)
        batch.setData(["optionId": optionId, "username": username], forDocument: responseRef)

        try await batch.commit()
        return updatedPoll
    }

    /// Fetches the current user's vote for a poll (optionId if they voted). Returns nil if they haven't voted.
    func fetchMyVote(pollId: String) async throws -> String? {
        guard let uid = authRef.currentUser?.uid else { return nil }
        let ref = databaseRef.collection("polls").document(pollId).collection("responses").document(uid)
        let snapshot = try await ref.getDocument()
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        return data["optionId"] as? String
    }

    /// Fetches usernames of users who voted for the given option. Query responses subcollection.
    func fetchVoters(pollId: String, optionId: String) async throws -> [PollVoter] {
        guard authRef.currentUser != nil else {
            throw PollServiceError.notAuthenticated
        }
        let snapshot = try await databaseRef.collection("polls").document(pollId)
            .collection("responses")
            .whereField("optionId", isEqualTo: optionId)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            let uid = doc.documentID
            let username = doc.data()["username"] as? String ?? "?"
            return PollVoter(id: uid, username: username)
        }
    }

    /// Fetches polls visible to the user (visibleToUids contains uid), ordered by createdAt descending.
    func fetchPolls(uid: String) async throws -> [Poll] {
        guard authRef.currentUser != nil else {
            throw PollServiceError.notAuthenticated
        }
        let snapshot = try await databaseRef.collection("polls")
            .whereField("visibleToUids", arrayContains: uid)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Poll.self)
        }
    }

    /// Real-time listener for polls visible to the user. Call remove() on the return value to stop.
    func addPollsListener(uid: String, onUpdate: @escaping ([Poll]) -> Void) -> ListenerRegistration {
        databaseRef.collection("polls")
            .whereField("visibleToUids", arrayContains: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }
                let polls = snapshot.documents.compactMap { doc -> Poll? in
                    try? doc.data(as: Poll.self)
                }
                onUpdate(polls)
            }
    }
}

enum PollServiceError: LocalizedError {
    case notAuthenticated
    case pollNotFound
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in to create a poll."
        case .pollNotFound: return "Poll not found."
        }
    }
}
