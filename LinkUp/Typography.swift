//
//  Typography.swift
//  LinkUp
//

import SwiftUI

/// Central typography for auth and shared screens. Use instead of inline `.font(.headline)` so styles scale with Dynamic Type and stay consistent.
enum Typography {
    /// Screen title (e.g. "LinkUp").
    static var title: Font { .largeTitle.weight(.bold) }

    /// Primary button label (e.g. "LOG IN", "SIGN UP").
    static var headline: Font { .headline }

    /// Secondary text and footer.
    static var subheadline: Font { .subheadline }

    /// Footer action word (e.g. "SIGN UP", "LOG IN").
    static var subheadlineSemibold: Font { .subheadline.weight(.semibold) }

    /// Input field label.
    static var subheadlineMedium: Font { .subheadline.weight(.medium) }
}
