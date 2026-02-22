//
//  PollsView.swift
//  LinkUp
//

import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

private let headerBarHeight: CGFloat = 20
private let headerBottomPadding: CGFloat = 0

/// Main poll page: one poll per page; swipe top card to send to back.
private let deckHorizontalPadding: CGFloat = 16
private let deckBottomPadding: CGFloat = 15
private let swipeThreshold: CGFloat = 100
private let swipeAnimationDuration: Double = 0.25
private let cardRotationPerPoint: Double = 0.12
private let underlyingCardRevealRotation: Double = 15
private let underlyingCardFadeStartRotation: Double = 22

struct PollsView: View {
    @ObservedObject var authState: AuthState
    var onOpenSettings: () -> Void
    @State private var polls: [Poll] = HardcodedPolls.sample
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingProfileImage = false
    @State private var topCardDragOffset: CGFloat = 0
    @State private var isSendingTopToBack = false
    @State private var isBringingBackToFront = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                deckContent(geometry: geometry)

                pollsHeader(safeAreaTop: geometry.safeAreaInsets.top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthTheme.background)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private func deckContent(geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let contentTop = max(0, headerBarHeight + headerBottomPadding + geometry.safeAreaInsets.top - 20)

        Group {
            if polls.isEmpty {
                emptyDeckView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, contentTop)
                    .padding(.bottom, deckBottomPadding)
            } else {
                let topCardRotation = Double(topCardDragOffset) * cardRotationPerPoint
                let underlyingOpacity: Double = {
                    let absRotation = abs(topCardRotation)
                    if absRotation < underlyingCardFadeStartRotation { return 0 }
                    if absRotation >= underlyingCardRevealRotation { return 1 }
                    return (absRotation - underlyingCardFadeStartRotation) / (underlyingCardRevealRotation - underlyingCardFadeStartRotation)
                }()

                ZStack(alignment: .top) {
                    if polls.count > 1 {
                        PollCardView(poll: $polls[1])
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal, deckHorizontalPadding)
                            .padding(.top, contentTop)
                            .padding(.bottom, deckBottomPadding)
                            .opacity(topCardDragOffset < 0 ? underlyingOpacity : 0)
                            .allowsHitTesting(false)
                            .zIndex(0)
                    }
                    if polls.count > 1 {
                        PollCardView(poll: $polls[polls.count - 1])
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal, deckHorizontalPadding)
                            .padding(.top, contentTop)
                            .padding(.bottom, deckBottomPadding)
                            .opacity(topCardDragOffset > 0 ? underlyingOpacity : 0)
                            .allowsHitTesting(false)
                            .zIndex(0)
                    }

                    PollCardView(poll: $polls[0])
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, deckHorizontalPadding)
                        .padding(.top, contentTop)
                        .padding(.bottom, deckBottomPadding)
                        .offset(x: topCardDragOffset)
                        .rotation3DEffect(
                            .degrees(Double(topCardDragOffset) * cardRotationPerPoint),
                            axis: (x: 0, y: 0, z: 1),
                            perspective: 0.4
                        )
                        .zIndex(1)
                        .gesture(
                            DragGesture(minimumDistance: 20)
                                .onChanged { value in
                                    guard !isSendingTopToBack, !isBringingBackToFront else { return }
                                    topCardDragOffset = value.translation.width
                                }
                                .onEnded { value in
                                    guard !isSendingTopToBack, !isBringingBackToFront else { return }
                                    if value.translation.width < -swipeThreshold {
                                        sendTopCardToBack(screenWidth: width)
                                    } else if value.translation.width > swipeThreshold, polls.count > 1 {
                                        bringBackCardToFront(screenWidth: width)
                                    } else {
                                        withAnimation(.easeOut(duration: swipeAnimationDuration)) {
                                            topCardDragOffset = 0
                                        }
                                    }
                                }
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sendTopCardToBack(screenWidth: CGFloat) {
        withAnimation(.easeOut(duration: swipeAnimationDuration)) {
            isSendingTopToBack = true
            topCardDragOffset = -screenWidth
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + swipeAnimationDuration) {
            if !polls.isEmpty {
                let top = polls[0]
                polls = Array(polls.dropFirst()) + [top]
            }
            topCardDragOffset = 0
            isSendingTopToBack = false
        }
    }

    private func bringBackCardToFront(screenWidth: CGFloat) {
        withAnimation(.easeOut(duration: swipeAnimationDuration)) {
            isBringingBackToFront = true
            topCardDragOffset = screenWidth
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + swipeAnimationDuration) {
            if polls.count > 1, let last = polls.last {
                polls = [last] + polls.dropLast()
            }
            topCardDragOffset = 0
            isBringingBackToFront = false
        }
    }

    private var emptyDeckView: some View {
        VStack(spacing: 8) {
            Text("No polls")
                .font(Typography.headline)
                .foregroundStyle(AuthTheme.primary)
            Text("Swipe through polls when you have some.")
                .font(Typography.subheadline)
                .foregroundStyle(AuthTheme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
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
                }
                .buttonStyle(HeaderIconButtonStyle())

                Button {
                    onOpenSettings()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                }
                .buttonStyle(HeaderIconButtonStyle())
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

/// Header icon button: accent when pressed for micro-interaction feedback.
private struct HeaderIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? AuthTheme.accent : AuthTheme.secondary)
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
        PollsView(authState: AuthState(), onOpenSettings: {})
    }
}
