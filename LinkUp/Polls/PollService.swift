//
//  PollService.swift
//  LinkUp
//

import Foundation
import UIKit
import FirebaseFirestore
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
}

extension AuthState {

    /// Creates a poll: uploads image to Storage if provided, writes document to Firestore, returns the created Poll.
    /// Options are built from option texts with generated ids and count 0.
    func createPoll(
        question: String,
        optionTexts: [String],
        activityDate: Date?,
        activityDescription: String?,
        imageData: Data?
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
        let poll = Poll(
            id: pollId,
            question: question,
            options: options,
            activityDate: activityDate,
            activityDescription: activityDescription,
            imageURL: imageURL,
            createdBy: uid
        )
        let doc = PollDocument(
            id: poll.id,
            question: poll.question,
            options: poll.options,
            activityDate: poll.activityDate,
            activityDescription: poll.activityDescription,
            imageURL: poll.imageURL,
            createdBy: uid,
            createdAt: Date()
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
        imageData: Data?
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
        let updatedPoll = Poll(
            id: pollId,
            question: question,
            options: options,
            activityDate: activityDate,
            activityDescription: activityDescription,
            imageURL: imageURL,
            createdBy: existingPoll.createdBy
        )
        let doc = PollDocument(
            id: updatedPoll.id,
            question: updatedPoll.question,
            options: updatedPoll.options,
            activityDate: updatedPoll.activityDate,
            activityDescription: updatedPoll.activityDescription,
            imageURL: updatedPoll.imageURL,
            createdBy: uid,
            createdAt: Date()
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
}

enum PollServiceError: LocalizedError {
    case notAuthenticated
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in to create a poll."
        }
    }
}
