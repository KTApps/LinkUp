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
                didPrefill = true
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
                        imageData: imageData
                    )
                } else {
                    poll = try await authState.createPoll(
                        question: trimmedQuestion,
                        optionTexts: trimmedOptions,
                        activityDate: activityDate,
                        activityDescription: activityDescription.isEmpty ? nil : activityDescription,
                        imageData: imageData
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
