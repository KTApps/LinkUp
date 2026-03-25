//
//  PollsView.swift
//  LinkUp
//

import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers
import FirebaseFirestore

private let headerBarHeight: CGFloat = 56
private let headerBottomPadding: CGFloat = 2

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
    @Binding var polls: [Poll]
    @Binding var confirmedPollIds: Set<String>
    var onOpenSettings: () -> Void
    var onOpenPollHistory: () -> Void
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingProfileImage = false
    @State private var topCardDragOffset: CGFloat = 0
    @State private var isSendingTopToBack = false
    @State private var isBringingBackToFront = false
    @State private var pollForMoreDetails: Poll?
    @State private var pollForOwnerSheet: Poll?
    @State private var pollForEdit: Poll?
    @State private var pollToDeleteForConfirmation: Poll?
    /// Current user's vote per poll: pollId -> optionId (so we can show it highlighted).
    @State private var myVotes: [String: String] = [:]
    @State private var confirmationsListener: ListenerRegistration?

    var body: some View {
        // `NavigationStack` already applies the top safe area; don’t add `safeAreaInsets.top` again on the header or deck.
        VStack(spacing: 0) {
            pollsHeader
            GeometryReader { geometry in
                deckContent(geometry: geometry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AuthTheme.background)
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if let poll = pollForMoreDetails {
                moreDetailsOverlay(poll: poll)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.94)),
                        removal: .opacity.combined(with: .scale(scale: 0.94))
                    ))
            }
        }
        .animation(.easeOut(duration: 0.4), value: pollForMoreDetails?.id)
        .task(id: polls.map(\.id)) {
            await loadMyVotes()
        }
        .onAppear {
            attachConfirmationsListener()
        }
        .onDisappear {
            confirmationsListener?.remove()
            confirmationsListener = nil
        }
        .sheet(item: $pollForOwnerSheet) { poll in
            pollOwnerActionsSheet(poll: poll)
        }
        .sheet(item: $pollForEdit) { poll in
            NavigationStack {
                CreatePollView(authState: authState, existingPoll: poll) { updatedPoll in
                    if let i = polls.firstIndex(where: { $0.id == updatedPoll.id }) {
                        polls[i] = updatedPoll
                    }
                    pollForEdit = nil
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AuthTheme.background)
                .navigationTitle("Edit Poll")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(AuthTheme.background, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("< Back") {
                            pollForEdit = nil
                        }
                        .foregroundStyle(AuthTheme.accent)
                    }
                }
            }
        }
        .alert("Delete poll?", isPresented: .init(
            get: { pollToDeleteForConfirmation != nil },
            set: { if !$0 { pollToDeleteForConfirmation = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                pollToDeleteForConfirmation = nil
            }
            Button("Delete", role: .destructive) {
                confirmDeletePoll()
            }
        } message: {
            if pollToDeleteForConfirmation != nil {
                Text("This poll will be permanently deleted.")
            }
        }
    }

    private func confirmDeletePoll() {
        guard let poll = pollToDeleteForConfirmation else { return }
        let pollId = poll.id
        pollToDeleteForConfirmation = nil
        if pollForMoreDetails?.id == pollId {
            pollForMoreDetails = nil
        }
        Task {
            do {
                try await authState.deletePoll(pollId: pollId)
                await MainActor.run {
                    polls.removeAll { $0.id == pollId }
                }
            } catch {
                await MainActor.run {
                    // Could set an error state to show alert; for now leave list unchanged
                }
            }
        }
    }

    private func isOwnPoll(_ poll: Poll) -> Bool {
        guard let uid = authState.currentUser?.id else { return false }
        return poll.createdBy == uid
    }

    private func loadMyVotes() async {
        guard authState.authRef.currentUser != nil else { return }
        var votes: [String: String] = [:]
        for poll in polls {
            if let optionId = try? await authState.fetchMyVote(pollId: poll.id) {
                votes[poll.id] = optionId
            }
        }
        await MainActor.run {
            myVotes = votes
        }
    }

    private func handleVote(pollId: String, optionId: String, previousOptionId: String?) {
        Task {
            do {
                let updated = try await authState.submitVote(pollId: pollId, optionId: optionId, previousOptionId: previousOptionId)
                await MainActor.run {
                    if let i = polls.firstIndex(where: { $0.id == pollId }) {
                        polls[i] = updated
                    }
                    myVotes[pollId] = optionId
                }
            } catch {
                // Keep local state; server write failure should not crash the deck interaction.
            }
        }
    }

    private func handleConfirm(pollId: String) {
        Task {
            do {
                let confirmation = try await authState.confirmVote(pollId: pollId)
                await MainActor.run {
                    confirmedPollIds.insert(pollId)
                    if confirmation.selectedSentiment == .negative {
                        // Negative confirmations are removed from stack only.
                        confirmedPollIds.insert(pollId)
                    }
                }
            } catch {
                // Keep UI unchanged if confirmation fails.
            }
        }
    }

    private func attachConfirmationsListener() {
        confirmationsListener?.remove()
        confirmationsListener = authState.addMyConfirmationsListener { confirmations in
            Task { @MainActor in
                confirmedPollIds = Set(confirmations.map(\.pollId))
            }
        }
    }

    @ViewBuilder
    private func pollOwnerActionsSheet(poll: Poll) -> some View {
        VStack(spacing: 0) {
            Text("Poll options")
                .font(.subheadline)
                .foregroundStyle(AuthTheme.secondary)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                ownerActionRow(icon: "doc.text", title: "More details", showDivider: true) {
                    pollForOwnerSheet = nil
                    withAnimation(.easeOut(duration: 0.28)) {
                        pollForMoreDetails = poll
                    }
                }
                ownerActionRow(icon: "pencil", title: "Edit poll", showDivider: true) {
                    pollForOwnerSheet = nil
                    pollForEdit = poll
                }
                ownerActionRow(icon: "trash", title: "Delete poll", isDestructive: true, showDivider: false) {
                    pollForOwnerSheet = nil
                    pollToDeleteForConfirmation = poll
                }
            }
            .background(AuthTheme.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(AuthTheme.primary.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(AuthTheme.background)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }

    private func ownerActionRow(icon: String, title: String, isDestructive: Bool = false, showDivider: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isDestructive ? Color.red.opacity(0.9) : AuthTheme.accent)
                    .frame(width: 28, height: 28)
                Text(title)
                    .font(.body)
                    .foregroundStyle(isDestructive ? Color.red : AuthTheme.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AuthTheme.secondary.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if showDivider {
                Rectangle()
                    .fill(AuthTheme.primary.opacity(0.08))
                    .frame(height: 1)
                    .padding(.leading, 56)
            }
        }
    }

    @ViewBuilder
    private func moreDetailsOverlay(poll: Poll) -> some View {
        ZStack(alignment: .center) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.15))
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.4)) {
                        pollForMoreDetails = nil
                    }
                }

            MoreDetailsPopupView(poll: poll) {
                withAnimation(.easeOut(duration: 0.28)) {
                    pollForMoreDetails = nil
                }
            }
        }
    }

    @ViewBuilder
    private func deckContent(geometry: GeometryProxy) -> some View {
        let activeIndices = polls.indices.filter { !confirmedPollIds.contains(polls[$0].id) }
        let activeCount = activeIndices.count
        let width = geometry.size.width

        Group {
            if activeCount == 0 {
                emptyDeckView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    if activeCount > 1 {
                        let secondIndex = activeIndices[1]
                        PollCardView(
                            poll: Binding(get: { polls[secondIndex] }, set: { polls[secondIndex] = $0 }),
                            myVoteOptionId: myVotes[polls[secondIndex].id],
                            onVote: handleVote,
                            onConfirm: handleConfirm,
                            isConfirmed: confirmedPollIds.contains(polls[secondIndex].id)
                        )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal, deckHorizontalPadding)
                            .padding(.bottom, deckBottomPadding)
                            .opacity(topCardDragOffset < 0 ? underlyingOpacity : 0)
                            .allowsHitTesting(false)
                            .zIndex(0)
                    }
                    if activeCount > 1 {
                        let lastIndex = activeIndices[activeCount - 1]
                        PollCardView(
                            poll: Binding(get: { polls[lastIndex] }, set: { polls[lastIndex] = $0 }),
                            myVoteOptionId: myVotes[polls[lastIndex].id],
                            onVote: handleVote,
                            onConfirm: handleConfirm,
                            isConfirmed: confirmedPollIds.contains(polls[lastIndex].id)
                        )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal, deckHorizontalPadding)
                            .padding(.bottom, deckBottomPadding)
                            .opacity(topCardDragOffset > 0 ? underlyingOpacity : 0)
                            .allowsHitTesting(false)
                            .zIndex(0)
                    }

                    let topIndex = activeIndices[0]
                    PollCardView(poll: Binding(get: { polls[topIndex] }, set: { polls[topIndex] = $0 }), myVoteOptionId: myVotes[polls[topIndex].id], onEllipsisTapped: { poll in
                        if isOwnPoll(poll) {
                            pollForOwnerSheet = poll
                        } else {
                            withAnimation(.easeOut(duration: 0.28)) {
                                pollForMoreDetails = poll
                            }
                        }
                    }, onVote: handleVote, onConfirm: handleConfirm, isConfirmed: confirmedPollIds.contains(polls[topIndex].id))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, deckHorizontalPadding)
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
                                    } else if value.translation.width > swipeThreshold, activeCount > 1 {
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
            let activeIndices = polls.indices.filter { !confirmedPollIds.contains(polls[$0].id) }
            if let topActive = activeIndices.first {
                let top = polls[topActive]
                polls.remove(at: topActive)
                polls.append(top)
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
            let activeIndices = polls.indices.filter { !confirmedPollIds.contains(polls[$0].id) }
            if activeIndices.count > 1, let lastActiveIndex = activeIndices.last {
                let last = polls[lastActiveIndex]
                polls.remove(at: lastActiveIndex)
                polls.insert(last, at: activeIndices[0])
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

    /// Above the deck in a `VStack`. Top inset comes from the system (`NavigationStack`); no manual safe-area padding.
    private var pollsHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    profileImageButton

                    Text(authState.currentUser?.username ?? "username")
                        .font(.subheadline)
                        .foregroundStyle(AuthTheme.primary)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        onOpenPollHistory()
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
            }
            .overlay {
                HStack(spacing: 0) {
                    Text("Link")
                        .foregroundStyle(AuthTheme.primary)
                    Text("Up")
                        .foregroundStyle(AuthTheme.accent)
                }
                .font(.title.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("LinkUp")
                .accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, 16)
            .frame(height: headerBarHeight)
            .padding(.bottom, headerBottomPadding)
            .background(AuthTheme.background)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(AuthTheme.background)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await handleSelectedPhotoItem(newItem)
            }
        }
    }

    @ViewBuilder
    private var profileImageButton: some View {
        let initial = authState.currentUser?.username.first.map { String($0).uppercased() } ?? "?"
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
                            profileImagePlaceholder(initial: initial)
                        @unknown default:
                            profileImagePlaceholder(initial: initial)
                        }
                    }
                } else {
                    profileImagePlaceholder(initial: initial)
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

    private func profileImagePlaceholder(initial: String) -> some View {
        Text(initial)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AuthTheme.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Circle().fill(AuthTheme.secondary.opacity(0.4)))
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
        PollsView(
            authState: AuthState(),
            polls: .constant(HardcodedPolls.sample),
            confirmedPollIds: .constant([]),
            onOpenSettings: {},
            onOpenPollHistory: {}
        )
    }
}
