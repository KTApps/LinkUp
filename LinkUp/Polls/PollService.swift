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
            imageURL: imageURL
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
}

enum PollServiceError: LocalizedError {
    case notAuthenticated
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in to create a poll."
        }
    }
}
