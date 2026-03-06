//
//  PollResultsChartView.swift
//  LinkUp
//

import SwiftUI

/// Sheet content: vertical bar chart for a single poll. Title = poll question; Back to dismiss; count-only labels; tappable bars push voters. AuthTheme.
struct PollResultsChartView: View {
    let poll: Poll
    @ObservedObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss

    private let maxBarHeight: CGFloat = 200

    var body: some View {
        NavigationStack {
            Group {
                if poll.totalVoteCount == 0 {
                    emptyView
                } else {
                    chartView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AuthTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(poll.question)
                        .font(.headline)
                        .foregroundStyle(AuthTheme.primary)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundStyle(AuthTheme.accent)
                }
            }
            .navigationDestination(for: PollOption.self) { option in
                PollOptionVotersView(pollId: poll.id, option: option, authState: authState)
            }
        }
    }

    private var emptyView: some View {
        Text("No votes yet")
            .font(Typography.subheadline)
            .foregroundStyle(AuthTheme.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var chartView: some View {
        let maxCount = max(poll.options.map(\.count).max() ?? 1, 1)
        return ScrollView {
            VStack(spacing: 24) {
                HStack(alignment: .bottom, spacing: 20) {
                    ForEach(poll.options) { option in
                        NavigationLink(value: option) {
                            barUnit(option: option, maxCount: maxCount)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 30)
            }
        }
    }

    private func barUnit(option: PollOption, maxCount: Int) -> some View {
        let heightRatio = maxCount > 0 ? CGFloat(option.count) / CGFloat(maxCount) : 0
        let barHeight = heightRatio * maxBarHeight
        return VStack(spacing: 8) {
            Text("\(option.count)")
                .font(Typography.subheadlineMedium)
                .foregroundStyle(AuthTheme.primary)
                .frame(height: 20)
            RoundedRectangle(cornerRadius: 6)
                .fill(AuthTheme.accent)
                .frame(height: max(barHeight, 0))
                .frame(maxWidth: 60)
            Text(option.text)
                .font(Typography.subheadline)
                .foregroundStyle(AuthTheme.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: 80)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PollResultsChartView(poll: HardcodedPolls.sample[0], authState: AuthState())
}
