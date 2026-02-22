//
//  PollsView.swift
//  LinkUp
//

import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

private let headerBarHeight: CGFloat = 44
private let headerBottomPadding: CGFloat = 10

/// Main poll page: vertical list of poll cards (hardcoded data).
/// Custom header with settings (top left); content scrolls underneath the header like the tab bar.
struct PollsView: View {
    @ObservedObject var authState: AuthState
    @State private var polls: [Poll] = HardcodedPolls.sample
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingProfileImage = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: geometry.size.height * 0.03) {
                        ForEach(polls.indices, id: \.self) { index in
                            PollCardView(poll: $polls[index])
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, geometry.size.width * 0.05)
                    .padding(.top, headerBarHeight + headerBottomPadding + geometry.safeAreaInsets.top)
                    .padding(.bottom, geometry.size.height * 0.03)
                }

                pollsHeader(safeAreaTop: geometry.safeAreaInsets.top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthTheme.background)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func pollsHeader(safeAreaTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                profileImageButton

                Text(authState.currentUser?.username ?? "username")
                    .font(.subheadline)
                    .foregroundStyle(AuthTheme.primary)

                Spacer()

                Button {
                    // TODO: open bar chart / stats
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AuthTheme.secondary)
                }
                .buttonStyle(.plain)

                Button {
                    // TODO: open settings
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AuthTheme.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .frame(height: headerBarHeight)
            .padding(.top, safeAreaTop)
            .padding(.bottom, headerBottomPadding)
            .background(AuthTheme.background)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(AuthTheme.background)
        .ignoresSafeArea(edges: .top)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await handleSelectedPhotoItem(newItem)
            }
        }
    }

    @ViewBuilder
    private var profileImageButton: some View {
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Group {
                if let urlString = authState.currentUser?.profileImageURL,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty:
                            profileImagePlaceholder
                        @unknown default:
                            profileImagePlaceholder
                        }
                    }
                } else {
                    profileImagePlaceholder
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .overlay(Circle().stroke(AuthTheme.secondary.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isUploadingProfileImage)
        .overlay {
            if isUploadingProfileImage {
                Circle()
                    .fill(AuthTheme.background.opacity(0.7))
                    .frame(width: 32, height: 32)
                ProgressView()
                    .tint(AuthTheme.primary)
            }
        }
    }

    private var profileImagePlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 32))
            .foregroundStyle(AuthTheme.secondary)
    }

    private func handleSelectedPhotoItem(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isUploadingProfileImage = true
        defer { isUploadingProfileImage = false }

        do {
            guard let loaded = try await item.loadTransferable(type: ProfileImageData.self) else { return }
            let jpegData = UIImage(data: loaded.data)?.jpegData(compressionQuality: 0.8) ?? loaded.data
            await authState.uploadProfileImage(jpegData: jpegData)
        } catch {
            // TODO: show error if desired
        }
        selectedPhotoItem = nil
    }
}

private struct ProfileImageData: Transferable {
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: UTType.image) { data in
            ProfileImageData(data: data)
        }
    }
}

#Preview {
    NavigationStack {
        PollsView(authState: AuthState())
    }
}
