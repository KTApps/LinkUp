//
//  PollHistoryView.swift
//  LinkUp
//

import SwiftUI

/// History page: list of all polls as "Title - N votes" with bar chart icon per row. Pushed when user taps bar chart in Polls header. Title "History"; settings icon opens Settings sheet.
private struct ChartSheetItem: Identifiable {
    let poll: Poll
    var id: String { poll.id }
}

struct PollHistoryView: View {
    @ObservedObject var authState: AuthState
    let polls: [Poll]
    @Environment(\.dismiss) private var dismiss
    @State private var showSettings = false
    @State private var pollForChart: ChartSheetItem?

    var body: some View {
        Group {
            if polls.isEmpty {
                emptyView
            } else {
                listContent
                    .padding(.vertical, 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AuthTheme.background)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AuthTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("< Back") {
                    dismiss()
                }
                .foregroundStyle(AuthTheme.accent)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                }
                .foregroundStyle(AuthTheme.secondary)
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(authState: authState)
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(AuthTheme.background, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Back") {
                                showSettings = false
                            }
                            .foregroundStyle(AuthTheme.accent)
                        }
                    }
            }
        }
        .sheet(item: $pollForChart) { item in
            PollResultsChartView(poll: item.poll, authState: authState)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
        }
    }

    private var emptyView: some View {
        Text("No polls yet")
            .font(Typography.subheadline)
            .foregroundStyle(AuthTheme.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(polls) { poll in
                    historyRow(poll: poll)
                }
            }
        }
    }

    private func historyRow(poll: Poll) -> some View {
        HStack(spacing: 12) {
            Button {
                pollForChart = ChartSheetItem(poll: poll)
            } label: {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AuthTheme.secondary)
            }
            .buttonStyle(.plain)

            Text("\(poll.question) - \(poll.totalVoteCount) votes")
                .font(Typography.subheadline)
                .foregroundStyle(AuthTheme.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(AuthTheme.background)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AuthTheme.primary.opacity(0.1))
                .frame(height: 1)
        }
    }
}

#Preview {
    NavigationStack {
        PollHistoryView(authState: AuthState(), polls: HardcodedPolls.sample)
    }
}
