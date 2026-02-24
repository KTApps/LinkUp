//
//  PollCardView.swift
//  LinkUp
//

import SwiftUI

private let progressBarHeight: CGFloat = 7
private let progressAnimation = Animation.easeOut(duration: 0.35)
private let tapAnimation = Animation.easeOut(duration: 0.15)

/// Single poll card: question, vote count, selectable options, progress bar.
/// Uses AuthTheme; voting updates in-memory state only. Rich motion and clear selected state.
struct PollCardView: View {
    @Binding var poll: Poll
    var onEllipsisTapped: ((Poll) -> Void)? = nil
    @State private var selectedOptionId: String?

    private var total: Int { poll.totalVoteCount }

    var body: some View {
        GeometryReader { geometry in
            let titleY = geometry.size.height * 0.22
            let centerY = geometry.size.height * 0.5

            ZStack(alignment: .top) {
                titleBlock
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: titleY)

                VStack(spacing: 12) {
                    optionsView
                    progressBarView
                    if total > 0 {
                        percentagesCaption
                    }
                }
                .frame(maxWidth: .infinity)
                .position(x: geometry.size.width / 2, y: centerY)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AuthTheme.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AuthTheme.primary.opacity(0.08), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if onEllipsisTapped != nil {
                Button {
                    onEllipsisTapped?(poll)
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AuthTheme.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(8)
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 12) {
            Text(poll.question)
                .font(Typography.headline)
                .foregroundStyle(AuthTheme.primary)
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                Rectangle()
                    .fill(AuthTheme.accent)
                    .frame(width: 3, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 1.5))
                Text("\(total) votes")
                    .font(Typography.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
            }
        }
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
            if selectedOptionId == option.id { return }
            if let previousId = selectedOptionId,
               let previousIndex = poll.options.firstIndex(where: { $0.id == previousId }) {
                var updated = poll
                if updated.options[previousIndex].count > 0 {
                    updated.options[previousIndex].count -= 1
                }
                poll = updated
            }
            selectedOptionId = option.id
            if let index = poll.options.firstIndex(where: { $0.id == option.id }) {
                var updated = poll
                updated.options[index].count += 1
                poll = updated
            }
        } label: {
            HStack(spacing: 6) {
                Text(option.text)
                    .font(Typography.subheadlineMedium)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? AuthTheme.accent : AuthTheme.primary.opacity(0.15))
            .foregroundStyle(isSelected ? AuthTheme.background : AuthTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? AuthTheme.accent : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PollOptionButtonStyle())
    }

    private var progressBarView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            HStack(spacing: 0) {
                ForEach(Array(poll.options.enumerated()), id: \.element.id) { index, option in
                    let fraction = total > 0 ? CGFloat(option.count) / CGFloat(total) : 0
                    let segmentWidth = max(0, width * fraction)
                    RoundedRectangle(cornerRadius: progressBarHeight / 2)
                        .fill(index == 0 ? AuthTheme.accent : AuthTheme.primary.opacity(0.2))
                        .frame(width: segmentWidth, height: progressBarHeight)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: progressBarHeight)
        .animation(progressAnimation, value: poll.options.map(\.count))
    }

    private var percentagesCaption: some View {
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

/// ButtonStyle that scales on press for tap feedback.
private struct PollOptionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(tapAnimation, value: configuration.isPressed)
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
