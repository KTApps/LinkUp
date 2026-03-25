//
//  ContentView.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 19/02/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Main app view when the user is logged in. Polls is the root; bottom bar opens sheets (back or swipe down to dismiss).
struct ContentView: View {
    @ObservedObject var authState: AuthState
    @State private var polls: [Poll] = []
    @State private var presentedSheet: AppSheet?
    @State private var pollsListener: ListenerRegistration?
    @State private var confirmedPollIds: Set<String> = []

    var body: some View {
        NavigationStack {
            PollsView(
                authState: authState,
                polls: $polls,
                confirmedPollIds: $confirmedPollIds,
                onOpenSettings: { presentedSheet = .settings }
            )
                .toolbarBackground(AuthTheme.background, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomBar
                }
        }
        .sheet(item: $presentedSheet) { sheet in
            if sheet == .history {
                NavigationStack {
                    PollHistoryView(authState: authState, polls: polls)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AuthTheme.background)
                }
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
            } else {
                sheetContent(for: sheet)
            }
        }
        .onAppear {
            // Use Firebase Auth UID so the listener attaches as soon as the user is signed in,
            // without waiting for the Firestore profile (currentUser) to load.
            guard let uid = authState.authRef.currentUser?.uid else { return }
            pollsListener = authState.addPollsListener(uid: uid) { newPolls in
                Task { @MainActor in
                    // Preserve current deck order (from user swiping); only update poll data from server.
                    // Deduplicate by id (first occurrence wins) so the same poll never appears twice in the stack.
                    let currentIds = polls.map(\.id)
                    let newById = Dictionary(uniqueKeysWithValues: newPolls.map { ($0.id, $0) })
                    var merged: [Poll] = []
                    var seenIds: Set<String> = []
                    for id in currentIds {
                        guard !seenIds.contains(id), let poll = newById[id] else { continue }
                        seenIds.insert(id)
                        merged.append(poll)
                    }
                    for p in newPolls where !seenIds.contains(p.id) {
                        merged.append(p)
                    }
                    polls = merged
                }
            }
        }
        .onDisappear {
            pollsListener?.remove()
            pollsListener = nil
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            barButton(title: "Messages", image: "paperplane.fill", sheet: .messages)
            barButton(title: "Plus", image: "plus.circle.fill", sheet: .plus)
            barButton(title: "Calendar", image: "calendar", sheet: .calendar)
            barButton(title: "History", image: "chart.bar.fill", sheet: .history)
        }
        .padding(.vertical, 15)
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
            SheetHost(title: "Messages", contentOwnsNavigation: true) {
                MessagesListView(authState: authState)
            }
        case .plus:
            SheetHost(title: "Create Poll") {
                CreatePollView(authState: authState) { poll in
                    polls.insert(poll, at: 0)
                    presentedSheet = nil
                }
            }
        case .calendar:
            SheetHost(title: "Calendar") {
                CalendarView(authState: authState, confirmedPollIds: $confirmedPollIds)
            }
        case .settings:
            SheetHost(title: "Settings") {
                SettingsView(authState: authState)
            }
        case .history:
            EmptyView()
        }
    }
}

private enum AppSheet: String, Identifiable, Equatable {
    case messages
    case plus
    case calendar
    case history
    case settings
    var id: String { rawValue }
}

/// Wraps sheet content with a navigation bar and back button; swipe down or tap back to dismiss.
/// Use `contentOwnsNavigation: true` when content has its own NavigationStack and Back (e.g. MessagesListView).
private struct SheetHost<Content: View>: View {
    let title: String
    var contentOwnsNavigation: Bool = false
    @ViewBuilder let content: () -> Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if contentOwnsNavigation {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AuthTheme.background)
        } else {
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
                            Button("< Back") {
                                dismiss()
                            }
                            .foregroundStyle(AuthTheme.accent)
                        }
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


#Preview {
    ContentView(authState: AuthState())
}
