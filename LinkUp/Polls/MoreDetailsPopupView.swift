//
//  MoreDetailsPopupView.swift
//  LinkUp
//

import SwiftUI

private let popupCornerRadius: CGFloat = 16
private let imageMaxHeight: CGFloat = 160
private let popupMaxWidth: CGFloat = 340
private let popupMaxHeight: CGFloat = 520

/// Centered popup content for "More Details": question, date/time, optional image, description. X to close.
struct MoreDetailsPopupView: View {
    let poll: Poll
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let urlString = poll.imageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure, .empty:
                                Rectangle()
                                    .fill(AuthTheme.primary.opacity(0.1))
                                    .overlay {
                                        ProgressView()
                                            .tint(AuthTheme.primary)
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: imageMaxHeight)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    descriptionSection
                }
                .padding(20)
            }
        }
        .frame(maxWidth: popupMaxWidth, maxHeight: popupMaxHeight)
        .background(AuthTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: popupCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: popupCornerRadius)
                .strokeBorder(AuthTheme.primary.opacity(0.2), lineWidth: 1)
        )
    }

    private var headerBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(poll.question)
                    .font(Typography.headline)
                    .foregroundStyle(AuthTheme.primary)
                    .multilineTextAlignment(.leading)
                if let date = poll.activityDate {
                    HStack(spacing: 4) {
                        Text(date, format: .dateTime.hour().minute())
                        Text("·")
                        Text(date, format: .dateTime.day().month().year())
                    }
                    .font(Typography.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
                } else {
                    Text("No date set")
                        .font(Typography.subheadline)
                        .foregroundStyle(AuthTheme.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AuthTheme.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Description")
                .font(Typography.subheadlineMedium)
                .foregroundStyle(AuthTheme.secondary)
            if let desc = poll.activityDescription, !desc.isEmpty {
                Text(desc)
                    .font(Typography.subheadline)
                    .foregroundStyle(AuthTheme.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("No description")
                    .font(Typography.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
            }
        }
    }
}

#Preview {
    MoreDetailsPopupView(
        poll: Poll(
            id: "p1",
            question: "Movies?",
            options: [PollOption(id: "y", text: "Yes", count: 0), PollOption(id: "n", text: "No", count: 0)],
            activityDate: Date(),
            activityDescription: "This is the description.",
            imageURL: nil
        ),
        onClose: {}
    )
    .padding()
    .background(AuthTheme.background.opacity(0.5))
}
