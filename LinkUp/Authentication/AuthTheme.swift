//
//  AuthTheme.swift
//  LinkUp
//

import SwiftUI

/// Three-color theme for auth screens: black background, white text, single accent. Modern tech look.
enum AuthTheme {
    /// Primary background — deep black.
    static let background = Color.black

    /// Primary text and borders — high contrast on black.
    static let primary = Color.white

    /// Secondary text (placeholders, hints) — primary with reduced opacity.
    static var secondary: Color { primary.opacity(0.6) }

    /// Accent — buttons, links, focus. Bright cyan for a modern tech vibe.
    static let accent = Color(red: 0, green: 0.83, blue: 1) // #00D4FF
}
