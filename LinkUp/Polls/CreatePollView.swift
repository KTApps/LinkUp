//
//  CreatePollView.swift
//  LinkUp
//

import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

struct CreatePollView: View {
    @ObservedObject var authState: AuthState
    var existingPoll: Poll? = nil
    var onCreated: (Poll) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var question = ""
    @State private var optionTexts = ["", ""]
    @State private var activityDate = Date()
    @State private var activityDescription = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var didPrefill = false

    @State private var friends: [Friend] = []
    @State private var groupConversations: [Conversation] = []
    @State private var selectedFriendUids: Set<String> = []
    @State private var selectedGroupIds: Set<String> = []
    @State private var newGroupParticipantIds: [String] = []
    @State private var showNewGroupSheet = false

    private let minOptions = 2

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Input(text: $question, title: "Question", placeholder: "What's the activity?")
                    .padding(.horizontal)

                optionsSection

                dateTimeSection

                descriptionSection

                photoSection

                shareSection

                if let error = errorMessage {
                    Text(error)
                        .font(Typography.subheadline)
                        .foregroundStyle(Color.red)
                        .padding(.horizontal)
                }

                submitButton
            }
            .padding(.vertical, 20)
        }
        .background(AuthTheme.background)
        .onAppear {
            if let existing = existingPoll, !didPrefill {
                question = existing.question
                optionTexts = existing.options.map(\.text)
                if optionTexts.count < minOptions {
                    optionTexts.append(contentsOf: (0..<(minOptions - optionTexts.count)).map { _ in "" })
                }
                activityDate = existing.activityDate ?? Date()
                activityDescription = existing.activityDescription ?? ""
                selectedFriendUids = Set(existing.visibleToUids.filter { $0 != existing.createdBy ?? "" })
                didPrefill = true
            }
        }
        .task {
            await loadShareOptions()
        }
        .sheet(isPresented: $showNewGroupSheet) {
            NavigationStack {
                CreateGroupView(authState: authState) { conv in
                    newGroupParticipantIds = conv.participantIds
                    showNewGroupSheet = false
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showNewGroupSheet = false }
                            .foregroundStyle(AuthTheme.accent)
                    }
                }
            }
        }
    }

    private var isEditMode: Bool { existingPoll != nil }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Answers")
                .font(Typography.subheadlineMedium)
                .foregroundStyle(AuthTheme.secondary)
                .padding(.horizontal)

            ForEach(optionTexts.indices, id: \.self) { index in
                HStack(spacing: 8) {
                    TextField("Option \(index + 1)", text: $optionTexts[index])
                        .textFieldStyle(.plain)
                        .foregroundStyle(AuthTheme.primary)
                        .tint(AuthTheme.accent)
                        .padding(14)
                        .background(AuthTheme.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(AuthTheme.primary.opacity(0.25), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if optionTexts.count > minOptions {
                        Button {
                            optionTexts.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(AuthTheme.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            Button {
                optionTexts.append("")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                    Text("Add option")
                        .font(Typography.subheadline)
                }
                .foregroundStyle(AuthTheme.accent)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date & time")
                .font(Typography.subheadlineMedium)
                .foregroundStyle(AuthTheme.secondary)
                .padding(.horizontal)

            DatePicker("", selection: $activityDate)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(AuthTheme.accent)
                .colorScheme(.dark)
                .padding(12)
                .background(AuthTheme.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(Typography.subheadlineMedium)
                .foregroundStyle(AuthTheme.secondary)
                .padding(.horizontal)

            TextEditor(text: $activityDescription)
                .scrollContentBackground(.hidden)
                .foregroundStyle(AuthTheme.primary)
                .tint(AuthTheme.accent)
                .frame(minHeight: 80)
                .padding(12)
                .background(AuthTheme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AuthTheme.primary.opacity(0.25), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
        }
    }

    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share with")
                .font(Typography.subheadlineMedium)
                .foregroundStyle(AuthTheme.secondary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("People")
                    .font(Typography.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(friends, id: \.friendUid) { friend in
                            let isSelected = selectedFriendUids.contains(friend.friendUid)
                            Button {
                                if isSelected {
                                    selectedFriendUids.remove(friend.friendUid)
                                } else {
                                    selectedFriendUids.insert(friend.friendUid)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(friend.username)
                                        .font(Typography.subheadline)
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                    }
                                }
                                .foregroundStyle(isSelected ? AuthTheme.accent : AuthTheme.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isSelected ? AuthTheme.accent.opacity(0.2) : AuthTheme.primary.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Groups")
                    .font(Typography.subheadline)
                    .foregroundStyle(AuthTheme.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(groupConversations, id: \.id) { conv in
                            let convId = conv.id ?? ""
                            let isSelected = selectedGroupIds.contains(convId)
                            Button {
                                if isSelected {
                                    selectedGroupIds.remove(convId)
                                } else {
                                    selectedGroupIds.insert(convId)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(conv.name ?? "Group")
                                        .font(Typography.subheadline)
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                    }
                                }
                                .foregroundStyle(isSelected ? AuthTheme.accent : AuthTheme.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isSelected ? AuthTheme.accent.opacity(0.2) : AuthTheme.primary.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            Button {
                showNewGroupSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                    Text("Create new group")
                        .font(Typography.subheadline)
                }
                .foregroundStyle(AuthTheme.accent)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)

            if !newGroupParticipantIds.isEmpty {
                Text("New group will be shared with this poll")
                    .font(.caption)
                    .foregroundStyle(AuthTheme.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photo (optional)")
                .font(Typography.subheadlineMedium)
                .foregroundStyle(AuthTheme.secondary)
                .padding(.horizontal)

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Group {
                    if let item = selectedPhotoItem {
                        PhotosPickerView(item: item)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 24))
                            Text("Add photo")
                                .font(Typography.subheadline)
                        }
                        .foregroundStyle(AuthTheme.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(AuthTheme.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(AuthTheme.background)
                } else {
                    Text(isEditMode ? "Edit Poll" : "Create Poll")
                        .font(Typography.subheadlineSemibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AuthTheme.accent)
            .foregroundStyle(AuthTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func loadShareOptions() async {
        guard let uid = authState.currentUser?.id else { return }
        do {
            async let friendsTask = authState.fetchFriends(uid: uid)
            async let groupsTask = authState.fetchMyGroupConversations(uid: uid)
            let (friendsResult, groupsResult) = try await (friendsTask, groupsTask)
            await MainActor.run {
                friends = friendsResult
                groupConversations = groupsResult
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func computedVisibleToUids() -> [String] {
        guard let uid = authState.currentUser?.id else { return [] }
        var uids: Set<String> = [uid]
        uids.formUnion(selectedFriendUids)
        for convId in selectedGroupIds {
            if let conv = groupConversations.first(where: { $0.id == convId }) {
                uids.formUnion(conv.participantIds)
            }
        }
        uids.formUnion(newGroupParticipantIds)
        return Array(uids)
    }

    private func submit() {
        errorMessage = nil
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOptions = optionTexts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !trimmedQuestion.isEmpty else {
            errorMessage = "Enter a question."
            return
        }
        guard trimmedOptions.count >= minOptions else {
            errorMessage = "Add at least \(minOptions) answers."
            return
        }
        let visibleToUids = computedVisibleToUids()
        guard visibleToUids.count > 1 else {
            errorMessage = "Select at least one person or group to share with."
            return
        }
        isSubmitting = true
        Task {
            do {
                var imageData: Data?
                if let item = selectedPhotoItem {
                    if let loaded = try await item.loadTransferable(type: ActivityImageData.self) {
                        imageData = loaded.data
                    }
                }
                let poll: Poll
                if let existing = existingPoll {
                    poll = try await authState.updatePoll(
                        existingPoll: existing,
                        question: trimmedQuestion,
                        optionTexts: trimmedOptions,
                        activityDate: activityDate,
                        activityDescription: activityDescription.isEmpty ? nil : activityDescription,
                        imageData: imageData,
                        visibleToUids: visibleToUids
                    )
                } else {
                    poll = try await authState.createPoll(
                        question: trimmedQuestion,
                        optionTexts: trimmedOptions,
                        activityDate: activityDate,
                        activityDescription: activityDescription.isEmpty ? nil : activityDescription,
                        imageData: imageData,
                        visibleToUids: visibleToUids
                    )
                }
                await MainActor.run {
                    isSubmitting = false
                    onCreated(poll)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

/// Thumbnail/preview for a selected PhotosPickerItem in the form.
private struct PhotosPickerView: View {
    let item: PhotosPickerItem
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AuthTheme.primary.opacity(0.08))
                    .frame(height: 100)
                    .overlay {
                        ProgressView()
                            .tint(AuthTheme.primary)
                    }
            }
        }
        .task {
            if let data = try? await item.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                image = uiImage
            }
        }
    }
}

private struct ActivityImageData: Transferable {
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: UTType.image) { data in
            ActivityImageData(data: data)
        }
    }
}

#Preview {
    CreatePollView(authState: AuthState(), onCreated: { _ in })
}
