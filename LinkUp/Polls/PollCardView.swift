//
//  PollCardView.swift
//  LinkUp
//

import SwiftUI

/// Single poll card: question, vote count, selectable options, percentages.
/// Uses AuthTheme; voting updates in-memory state only.
struct PollCardView: View {
    @Binding var poll: Poll
    @State private var selectedOptionId: String?

    private var total: Int { poll.totalVoteCount }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(poll.question)
                .font(Typography.headline)
                .foregroundStyle(AuthTheme.primary)

            Text("\(total) votes")
                .font(Typography.subheadline)
                .foregroundStyle(AuthTheme.secondary)

            optionsView

            percentagesView
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AuthTheme.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var optionsView: some View {
        HStack(spacing: 8) {
            ForEach(poll.options) { option in
                optionButton(option)
            }
        }
    }

    private func optionButton(_ option: PollOption) -> some View {
        let isSelected = selectedOptionId == option.id
        return Button {
            selectedOptionId = option.id
            if let index = poll.options.firstIndex(where: { $0.id == option.id }) {
                var updated = poll
                updated.options[index].count += 1
                poll = updated
            }
        } label: {
            Text(option.text)
                .font(Typography.subheadlineMedium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? AuthTheme.accent : AuthTheme.primary.opacity(0.15))
                .foregroundStyle(isSelected ? AuthTheme.background : AuthTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var percentagesView: some View {
        HStack(spacing: 8) {
            ForEach(poll.options) { option in
                let pct = total > 0 ? Int(round(Double(option.count) / Double(total) * 100)) : 0
                Text("\(pct)%")
                    .font(Typography.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var poll = HardcodedPolls.sample[0]
        var body: some View {
            PollCardView(poll: $poll)
                .padding()
                .background(AuthTheme.background)
        }
    }
    return PreviewWrapper()
}
