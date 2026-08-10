import SwiftUI
import PhotosUI

/// Sheet for adding a new Build Log entry: text, optional photo, tag picker.
struct AddBuildLogEntryView: View {
    let kid: Kid
    let progressService: ProgressService
    @Binding var isPresented: Bool

    @State private var noteText = ""
    @State private var selectedTag: BuildLogTag = .coding
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Your note") {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 100)
                        .accessibilityLabel("Build log note. Enter your thoughts here.")
                }

                Section("Tag") {
                    Picker("Tag", selection: $selectedTag) {
                        ForEach(BuildLogTag.allCases, id: \.self) { tag in
                            Text(tag.displayName).tag(tag)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Entry tag")
                }

                Section("Photo (optional)") {
                    photoPickerRow
                }

                if let error = saveError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    .accessibilityLabel("Save build log entry")
                }
            }
        }
    }

    // MARK: - Photo picker row

    @ViewBuilder
    private var photoPickerRow: some View {
        // Capture as a local constant so the PhotosPicker @Sendable label
        // closure doesn't reference a @MainActor property directly.
        let hasPhoto = selectedPhotoData != nil
        HStack {
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(
                    hasPhoto ? "Change Photo" : "Add Photo",
                    systemImage: "photo.badge.plus"
                )
                .frame(minHeight: 44)
            }
            .onChange(of: selectedPhotoItem) { _, item in
                Task {
                    selectedPhotoData = try? await item?.loadTransferable(type: Data.self)
                }
            }

            if let data = selectedPhotoData, let uiImage = UIImage(data: data) {
                Spacer()
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Selected photo")

                Button {
                    selectedPhotoData = nil
                    selectedPhotoItem = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Remove photo")
            }
        }
    }

    // MARK: - Save

    private func saveEntry() {
        isSaving = true
        saveError = nil
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        var photoFilename: String?

        // Save photo to Documents if selected.
        if let data = selectedPhotoData {
            let filename = "\(UUID().uuidString).jpg"
            photoFilename = try? progressService.savePhoto(data, filename: filename)
        }

        do {
            try progressService.addBuildLogEntry(
                kidID: kid.id,
                noteText: trimmed,
                photoFilename: photoFilename,
                tag: selectedTag
            )
            isPresented = false
        } catch {
            saveError = "Couldn't save your entry. Please try again."
            isSaving = false
        }
    }
}
