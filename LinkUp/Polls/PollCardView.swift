//
//  PollCardView.swift
//  LinkUp
//

import SwiftUI

private let progressBarHeight: CGFloat = 7
private let cardCornerRadius: CGFloat = 12
private let progressAnimation = Animation.easeOut(duration: 0.35)
private let tapAnimation = Animation.easeOut(duration: 0.15)

/// Full-bleed media poll card with TikTok-style overlays; owner-only ellipsis.
struct PollCardView: View {
    @Binding var poll: Poll
    var myVoteOptionId: String? = nil
    var onEllipsisTapped: ((Poll) -> Void)? = nil
    var onVote: ((_ pollId: String, _ optionId: String, _ previousOptionId: String?) -> Void)? = nil
    var onConfirm: ((_ pollId: String) -> Void)? = nil
    var isConfirmed: Bool = false

    @State private var selectedOptionId: String?
    @State private var showOverlays = true
    @State private var mediaPageIndex = 0
    @State private var descriptionExpanded = false

    private var total: Int { poll.totalVoteCount }

    private var hasDisplayImage: Bool {
        guard let s = poll.imageURL, !s.isEmpty else { return false }
        return URL(string: s) != nil
    }

    private var dualPage: Bool { hasDisplayImage && poll.hasActivityLocation }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                PollCardMediaPager(
                    poll: poll,
                    pageIndex: $mediaPageIndex,
                    onSingleTap: {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showOverlays.toggle()
                        }
                    },
                    onDoubleTap: {
                        guard dualPage else { return }
                        withAnimation(.easeInOut(duration: 0.35)) {
                            mediaPageIndex = mediaPageIndex == 0 ? 1 : 0
                        }
                    }
                )

                if showOverlays {
                    VStack(spacing: 0) {
                        topOverlay
                        middleHitArea
                        bottomOverlay
                    }
                    .transition(.opacity)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .strokeBorder(AuthTheme.primary.opacity(0.12), lineWidth: 1)
            )

            if onEllipsisTapped != nil {
                Button {
                    onEllipsisTapped?(poll)
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AuthTheme.primary)
                        .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(8)
                .zIndex(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if selectedOptionId == nil, let saved = myVoteOptionId, poll.options.contains(where: { $0.id == saved }) {
                selectedOptionId = saved
            }
        }
        .onChange(of: poll.id) { _, _ in
            selectedOptionId = myVoteOptionId
            showOverlays = true
            mediaPageIndex = 0
            descriptionExpanded = false
        }
        .onChange(of: myVoteOptionId) { _, newValue in
            if let saved = newValue, poll.options.contains(where: { $0.id == saved }) {
                selectedOptionId = saved
            } else {
                selectedOptionId = newValue
            }
        }
    }

    private var topOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(poll.question)
                .font(Typography.headline)
                .foregroundStyle(AuthTheme.primary)
                .multilineTextAlignment(.leading)
                .shadow(color: .black.opacity(0.55), radius: 4, x: 0, y: 1)
            PollActivityDateFormatting.dateSubtitle(activityDate: poll.activityDate)
                .shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.65), Color.black.opacity(0.35), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    @ViewBuilder
    private var middleHitArea: some View {
        Spacer(minLength: 44)
            .frame(maxWidth: .infinity)
            .overlay {
                if dualPage {
                    PollMediaTapOverlayView(
                        onSingleTap: {
                            withAnimation(.easeOut(duration: 0.25)) {
                                showOverlays = false
                            }
                        },
                        onDoubleTap: {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                mediaPageIndex = mediaPageIndex == 0 ? 1 : 0
                            }
                        }
                    )
                } else {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.25)) {
                                showOverlays = false
                            }
                        }
                }
            }
    }

    private var bottomOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(AuthTheme.accent)
                    .frame(width: 3, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 1.5))
                Text("\(total) votes")
                    .font(Typography.subheadline)
                    .foregroundStyle(AuthTheme.primary)
                    .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
            }

            if let desc = poll.activityDescription, !desc.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(desc)
                        .font(Typography.subheadline)
                        .foregroundStyle(AuthTheme.primary)
                        .lineLimit(descriptionExpanded ? nil : 2)
                        .multilineTextAlignment(.leading)
                        .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
                    if !descriptionExpanded && desc.count > 48 {
                        Button("…more") {
                            withAnimation(.easeOut(duration: 0.2)) {
                                descriptionExpanded = true
                            }
                        }
                        .font(Typography.subheadlineSemibold)
                        .foregroundStyle(AuthTheme.accent)
                        .buttonStyle(.plain)
                    }
                }
            }

            optionsView
            confirmButton
            progressBarView
            if total > 0 {
                labeledResultsCaption
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.5), Color.black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
            if isConfirmed { return }
            if selectedOptionId == option.id { return }
            let previousId = selectedOptionId
            if let prevId = previousId,
               let previousIndex = poll.options.firstIndex(where: { $0.id == prevId }) {
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
            onVote?(poll.id, option.id, previousId)
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
            .opacity(isConfirmed ? 0.55 : 1)
        }
        .buttonStyle(PollOptionButtonStyle())
        .disabled(isConfirmed)
    }

    private var confirmButton: some View {
        Button {
            onConfirm?(poll.id)
        } label: {
            Group {
                if isConfirmed {
                    Text("Confirmed")
                        .font(Typography.subheadlineSemibold)
                        .foregroundStyle(AuthTheme.secondary)
                } else {
                    Text("Lock in choice")
                        .font(Typography.subheadlineSemibold)
                        .foregroundStyle(AuthTheme.accent)
                        .underline(true, color: AuthTheme.accent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isConfirmed || selectedOptionId == nil)
        .opacity((!isConfirmed && selectedOptionId == nil) ? 0.7 : 1)
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

    private var labeledResultsCaption: some View {
        HStack(spacing: 8) {
            ForEach(poll.options) { option in
                let pct = total > 0 ? Int(round(Double(option.count) / Double(total) * 100)) : 0
                HStack(spacing: 4) {
                    Text(option.text)
                        .font(Typography.subheadlineSemibold)
                        .foregroundStyle(AuthTheme.primary)
                    Text("·")
                        .font(Typography.subheadline)
                        .foregroundStyle(AuthTheme.secondary)
                    Text("\(pct)%")
                        .font(Typography.subheadline)
                        .foregroundStyle(AuthTheme.secondary)
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            }
        }
    }
}

private struct PollOptionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(tapAnimation, value: configuration.isPressed)
    }
}

#Preview("Image only") {
    struct W: View {
        @State private var poll = HardcodedPolls.previewImageOnly
        var body: some View {
            PollCardView(poll: $poll)
                .padding()
                .background(AuthTheme.background)
        }
    }
    return W()
}

#Preview("Map only") {
    struct W: View {
        @State private var poll = HardcodedPolls.previewMapOnly
        var body: some View {
            PollCardView(poll: $poll)
                .padding()
                .background(AuthTheme.background)
        }
    }
    return W()
}

#Preview("Image + map") {
    struct W: View {
        @State private var poll = HardcodedPolls.previewImageAndMap
        var body: some View {
            PollCardView(poll: $poll)
                .padding()
                .background(AuthTheme.background)
        }
    }
    return W()
}

#Preview("Neither") {
    struct W: View {
        @State private var poll = HardcodedPolls.previewNeitherMedia
        var body: some View {
            PollCardView(poll: $poll)
                .padding()
                .background(AuthTheme.background)
        }
    }
    return W()
}

#Preview("Confirmed") {
    struct W: View {
        @State private var poll = HardcodedPolls.previewConfirmed
        var body: some View {
            PollCardView(poll: $poll, isConfirmed: true)
                .padding()
                .background(AuthTheme.background)
        }
    }
    return W()
}
