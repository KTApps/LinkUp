//
//  Poll.swift
//  LinkUp
//

import Foundation

/// A single choice in a poll. Count is number of votes for this option.
struct PollOption: Identifiable, Codable {
    let id: String
    let text: String
    var count: Int
}

/// A poll: question and options. Total vote count is derived from sum of option counts.
/// Optional activity fields for date, description, and image (e.g. "more details" screen).
/// Codable for Firestore; activityDate encoded/decoded as Timestamp.
struct Poll: Identifiable, Codable {
    let id: String
    let question: String
    var options: [PollOption]
    var activityDate: Date?
    var activityDescription: String?
    var imageURL: String?
    /// UID of the user who created the poll; nil for legacy/hardcoded data.
    var createdBy: String? = nil

    var totalVoteCount: Int {
        options.reduce(0) { $0 + $1.count }
    }
}

// MARK: - Hardcoded sample data (groups not implemented yet)

enum HardcodedPolls {
    static let sample: [Poll] = [
        Poll(
            id: "poll-1",
            question: "Climbing?",
            options: [
                PollOption(id: "yes", text: "Yes", count: 5),
                PollOption(id: "no", text: "No", count: 5)
            ],
            activityDate: nil,
            activityDescription: nil,
            imageURL: nil
        ),
        Poll(
            id: "poll-2",
            question: "Tuesday Dinner?",
            options: [
                PollOption(id: "a", text: "Yes", count: 2),
                PollOption(id: "b", text: "No", count: 0)
            ],
            activityDate: nil,
            activityDescription: nil,
            imageURL: nil
        ),
        Poll(
            id: "poll-3",
            question: "Movies?",
            options: [
                PollOption(id: "a", text: "Yes", count: 2),
                PollOption(id: "b", text: "No", count: 1)
            ],
            activityDate: nil,
            activityDescription: nil,
            imageURL: nil
        )
    ]
}
