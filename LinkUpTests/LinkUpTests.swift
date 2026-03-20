//
//  LinkUpTests.swift
//  LinkUpTests
//
//  Created by Kelvin Mahaja on 19/02/2026.
//

import XCTest
@testable import LinkUp

final class LinkUpTests: XCTestCase {
    func testOptionSentimentClassifierPositiveCases() {
        XCTAssertEqual(OptionSentimentClassifier.classify(text: "Yes"), .positive)
        XCTAssertEqual(OptionSentimentClassifier.classify(text: "I'm in"), .positive)
    }

    func testOptionSentimentClassifierNegativeCases() {
        XCTAssertEqual(OptionSentimentClassifier.classify(text: "No"), .negative)
        XCTAssertEqual(OptionSentimentClassifier.classify(text: "Can't make it"), .negative)
    }

    func testOptionSentimentClassifierAmbiguousDefaultsNegative() {
        XCTAssertEqual(OptionSentimentClassifier.classify(text: "Maybe"), .negative)
    }
}
