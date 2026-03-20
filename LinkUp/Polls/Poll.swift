//
//  Poll.swift
//  LinkUp
//

import Foundation

enum PollOptionSentiment: String, Codable, Hashable {
    case positive
    case negative
}

/// A single choice in a poll. Count is number of votes for this option.
struct PollOption: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    var count: Int
    var sentiment: PollOptionSentiment

    init(id: String, text: String, count: Int, sentiment: PollOptionSentiment? = nil) {
        self.id = id
        self.text = text
        self.count = count
        self.sentiment = sentiment ?? OptionSentimentClassifier.classify(text: text)
    }

    enum CodingKeys: String, CodingKey {
        case id, text, count, sentiment
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        count = try container.decode(Int.self, forKey: .count)
        sentiment = (try? container.decode(PollOptionSentiment.self, forKey: .sentiment))
            ?? OptionSentimentClassifier.classify(text: text)
    }
}

/// Voter for drill-through: who voted for an option.
struct PollVoter: Identifiable {
    let id: String
    let username: String
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
    /// UIDs who can see this poll (includes createdBy). Empty for legacy/hardcoded data.
    var visibleToUids: [String] = []

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
            imageURL: nil,
            visibleToUids: []
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
            imageURL: nil,
            visibleToUids: []
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
            imageURL: nil,
            visibleToUids: []
        )
    ]
}

enum OptionSentimentClassifier {
    static func classify(text: String) -> PollOptionSentiment {
        let normalized = normalize(text)
        if positiveExact.contains(normalized) || positiveKeywords.contains(where: { normalized.contains($0) }) {
            return .positive
        }
        if negativeExact.contains(normalized) || negativeKeywords.contains(where: { normalized.contains($0) }) {
            return .negative
        }
        return .negative
    }

    private static func normalize(_ value: String) -> String {
        let lowered = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return lowered.unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) || CharacterSet.whitespaces.contains($0) || $0 == "'" }
            .map(String.init)
            .joined()
    }

    private static let positiveExact: Set<String> = [
        "yes", "yeah", "yep", "im in", "i'm in", "count me in", "lets do it", "let's do it", "down", "sure"
    ]
    private static let negativeExact: Set<String> = [
        "no", "nope", "cant make it", "can't make it", "not coming", "im out", "i'm out", "pass", "maybe next time"
    ]
    private static let positiveKeywords: [String] = [
        "yes", "in", "join", "coming", "available", "works for me"
    ]
    private static let negativeKeywords: [String] = [
        "no", "cant", "can't", "not", "busy", "skip", "out"
    ]
}
