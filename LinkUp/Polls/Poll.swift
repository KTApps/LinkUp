//
//  Poll.swift
//  LinkUp
//

import Foundation

/// A single choice in a poll. Count is number of votes for this option.
struct PollOption: Identifiable {
    let id: String
    let text: String
    var count: Int
}

/// A poll: question and options. Total vote count is derived from sum of option counts.
/// Future: real data from Firestore at groups/{groupId}/polls; only group members see polls.
struct Poll: Identifiable {
    let id: String
    let question: String
    var options: [PollOption]

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
            ]
        ),
        Poll(
            id: "poll-2",
            question: "Tuesday Dinner?",
            options: [
                PollOption(id: "a", text: "Yes", count: 2),
                PollOption(id: "b", text: "No", count: 0)
            ]
        ),
        Poll(
            id: "poll-3",
            question: "Movies?",
            options: [
                PollOption(id: "a", text: "Yes", count: 2),
                PollOption(id: "b", text: "No", count: 1)
            ]
        )
    ]
}
