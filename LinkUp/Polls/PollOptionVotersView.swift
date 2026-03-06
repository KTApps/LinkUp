//
//  PollOptionVotersView.swift
//  LinkUp
//

import SwiftUI

/// Drill-through from a chart bar: lists usernames who voted for the selected option. AuthTheme.
struct PollOptionVotersView: View {
    let pollId: String
    let option: PollOption
    @ObservedObject var authState: AuthState
    @State private var voters: [PollVoter] = []
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(AuthTheme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = loadError {
                Text(error)
                    .font(Typography.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if voters.isEmpty {
                Text("No one has voted for this option yet")
                    .font(Typography.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                voterList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AuthTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AuthTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(option.text)
                        .font(.headline)
                        .foregroundStyle(AuthTheme.primary)
                    Text("\(option.count) votes")
                        .font(.caption)
                        .foregroundStyle(AuthTheme.secondary)
                }
            }
        }
        .task {
            await loadVoters()
        }
    }

    private var voterList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(voters) { voter in
                    HStack(spacing: 12) {
                        Text(voter.username)
                            .font(Typography.subheadline)
                            .foregroundStyle(AuthTheme.primary)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(AuthTheme.primary.opacity(0.1))
                            .frame(height: 1)
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }

    private func loadVoters() async {
        isLoading = true
        loadError = nil
        do {
            let result = try await authState.fetchVoters(pollId: pollId, optionId: option.id)
            await MainActor.run {
                voters = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        PollOptionVotersView(
            pollId: "poll-1",
            option: PollOption(id: "yes", text: "Yes", count: 5),
            authState: AuthState()
        )
    }
}
