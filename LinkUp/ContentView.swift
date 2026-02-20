//
//  ContentView.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 19/02/2026.
//

import SwiftUI

/// Main app view when the user is logged in. TabView with Polls (default), Messages, Plus, and Calendar tabs.
struct ContentView: View {
    @ObservedObject var authState: AuthState
    @State private var selectedTab: SelectedTab = .polls

    var body: some View {
        TabView(selection: $selectedTab) {
            MessagesPlaceholderView(authState: authState)
                .tabItem {
                    Label("Messages", systemImage: "paperplane.fill")
                }
                .tag(SelectedTab.messages)
            
            PollsTabView(authState: authState)
                .tabItem {
                    Label("Polls", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(SelectedTab.polls)

            PlusPlaceholderView(authState: authState)
                .tabItem {
                    Label("Add Poll", systemImage: "plus.circle.fill")
                }
                .tag(SelectedTab.plus)

            CalendarPlaceholderView(authState: authState)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(SelectedTab.calendar)
        }
        .tint(AuthTheme.accent)
        .toolbarBackground(AuthTheme.background, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

private enum SelectedTab: String {
    case polls
    case messages
    case plus
    case calendar
}

// MARK: - Placeholder tab content (Option A: inline in same file)

private struct PollsTabView: View {
    @ObservedObject var authState: AuthState

    var body: some View {
        NavigationStack {
            PollsView()
        }
    }
}

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
