//
//  UserRowView.swift
//  LinkUp
//

import SwiftUI

/// Reusable row: small avatar (image or initial), username, optional trailing content. AuthTheme.
struct UserRowView<Trailing: View>: View {
    let imageURL: String?
    let initial: String
    let username: String
    @ViewBuilder let trailing: () -> Trailing

    init(
        imageURL: String?,
        initial: String,
        username: String,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.imageURL = imageURL
        self.initial = initial
        self.username = username
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 12) {
            avatar
            Text(username)
                .font(.body)
                .foregroundStyle(AuthTheme.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            trailing()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AuthTheme.background)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AuthTheme.primary.opacity(0.1))
                .frame(height: 1)
        }
    }

    private var avatar: some View {
        Group {
            if let urlString = imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        avatarPlaceholder
                    @unknown default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
        .overlay(Circle().stroke(AuthTheme.secondary.opacity(0.5), lineWidth: 1))
    }

    private var avatarPlaceholder: some View {
        Text(initial)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AuthTheme.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Circle().fill(AuthTheme.secondary.opacity(0.4)))
    }
}

// No trailing content
extension UserRowView where Trailing == EmptyView {
    init(imageURL: String?, initial: String, username: String) {
        self.imageURL = imageURL
        self.initial = initial
        self.username = username
        self.trailing = { EmptyView() }
    }
}
