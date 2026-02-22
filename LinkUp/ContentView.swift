//
//  ContentView.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 19/02/2026.
//

import SwiftUI

/// Main app view when the user is logged in. Polls is the root; Messages, Plus, and Calendar open as sheets (back button or swipe down to return).
struct ContentView: View {
    @ObservedObject var authState: AuthState
    @State private var presentedSheet: AppSheet?

    var body: some View {
        NavigationStack {
            PollsView(authState: authState)
                .toolbarBackground(AuthTheme.background, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomBar
                }
        }
        .sheet(item: $presentedSheet) { sheet in
            sheetContent(for: sheet)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            barButton(title: "Messages", image: "paperplane.fill", sheet: .messages)
            barButton(title: "Plus", image: "plus.circle.fill", sheet: .plus)
            barButton(title: "Calendar", image: "calendar", sheet: .calendar)
        }
        .padding(.vertical, 12)
        .background(AuthTheme.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AuthTheme.primary.opacity(0.2))
                .frame(height: 1)
        }
    }

    private func barButton(title: String, image: String, sheet: AppSheet) -> some View {
        Button {
            presentedSheet = sheet
        } label: {
            VStack(spacing: 4) {
                Image(systemName: image)
                    .font(.system(size: 22))
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(AuthTheme.secondary)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sheetContent(for sheet: AppSheet) -> some View {
        switch sheet {
        case .messages:
            SheetHost(title: "Messages") {
                MessagesPlaceholderView(authState: authState)
            }
        case .plus:
            SheetHost(title: "Plus") {
                PlusPlaceholderView(authState: authState)
            }
        case .calendar:
            SheetHost(title: "Calendar") {
                CalendarPlaceholderView(authState: authState)
            }
        }
    }
}

private enum AppSheet: String, Identifiable {
    case messages
    case plus
    case calendar
    var id: String { rawValue }
}

/// Wraps sheet content with a navigation bar and back button; swipe down or tap back to dismiss.
private struct SheetHost<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AuthTheme.background)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(AuthTheme.background, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back") {
                            dismiss()
                        }
                        .foregroundStyle(AuthTheme.accent)
                    }
                }
        }
    }
}

// MARK: - Placeholder content (used inside sheets)

private struct MessagesPlaceholderView: View {
    @ObservedObject var authState: AuthState

    var body: some View {
        Text("Messages")
            .font(.title2)
            .foregroundStyle(AuthTheme.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthTheme.background)
    }
}

private struct PlusPlaceholderView: View {
    @ObservedObject var authState: AuthState

    var body: some View {
        Text("Plus")
            .font(.title2)
            .foregroundStyle(AuthTheme.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthTheme.background)
    }
}

private struct CalendarPlaceholderView: View {
    @ObservedObject var authState: AuthState

    var body: some View {
        Text("Calendar")
            .font(.title2)
            .foregroundStyle(AuthTheme.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthTheme.background)
    }
}

#Preview {
    ContentView(authState: AuthState())
}
