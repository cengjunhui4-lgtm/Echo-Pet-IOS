import SwiftUI
import PhotosUI

struct TimelineMemoryFormView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    let memory: TimelineMemory?
    let onSave: (TimelineMemory) -> Void
    private let maxPhotoCount = 9
    private let originalMediaAssetIDs: Set<UUID>

    @State private var title: String
    @State private var date: Date
    @State private var story: String
    @State private var imageSystemName: String
    @State private var mediaAssets: [MediaAsset]
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isImportingPhotos = false
    @State private var importFailureCount = 0
    @State private var showingDiscardConfirmation = false
    @State private var showingImportFailureAlert = false

    private let icons = [
        "house.fill",
        "sun.max.fill",
        "heart.fill",
        "pawprint.fill",
        "circle.fill",
        "leaf.fill"
    ]

    init(memory: TimelineMemory?, onSave: @escaping (TimelineMemory) -> Void) {
        self.memory = memory
        self.onSave = onSave
        let existingMediaAssets = memory?.mediaAssets ?? []
        originalMediaAssetIDs = Set(existingMediaAssets.map(\.id))
        _title = State(initialValue: memory?.title ?? "")
        _date = State(initialValue: memory?.date ?? Date())
        _story = State(initialValue: memory?.story ?? "")
        _imageSystemName = State(initialValue: memory?.imageSystemName ?? "heart.fill")
        _mediaAssets = State(initialValue: existingMediaAssets)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(localization.text(.timelineFormSectionMemory)) {
                    TextField(localization.text(.timelineFormFieldTitle), text: $title)
                    DatePicker(localization.text(.timelineFormFieldDate), selection: $date, displayedComponents: .date)
                    TextField(localization.text(.timelineFormFieldStory), text: $story, axis: .vertical)
                        .lineLimit(4...8)
                }

                Section(localization.text(.timelineFormSectionIcon)) {
                    Picker(localization.text(.timelineFormSectionIcon), selection: $imageSystemName) {
                        ForEach(icons, id: \.self) { icon in
                            Label(iconName(for: icon), systemImage: icon)
                                .tag(icon)
                        }
                    }
                }

                Section(localization.text(.timelineFormSectionPhotos)) {
                    photoPickerRow
                }
            }
            .navigationTitle(memory == nil ? localization.text(.timelineFormTitleCreate) : localization.text(.timelineFormTitleEdit))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.text(.commonCancel)) {
                        attemptDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.text(.commonSave)) {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
            .interactiveDismissDisabled(isDirty)
            .confirmationDialog(localization.text(.timelineFormDiscardDialog), isPresented: $showingDiscardConfirmation, titleVisibility: .visible) {
                Button(localization.text(.timelineFormDiscardChanges), role: .destructive) {
                    cleanupUnsavedMediaAssets()
                    dismiss()
                }
                Button(localization.text(.timelineFormKeepEditing), role: .cancel) {}
            }
            .alert(localization.text(.timelineFormPhotoImportFailedTitle), isPresented: $showingImportFailureAlert) {
                Button(localization.text(.commonOK), role: .cancel) {}
            } message: {
                Text(localization.text(.timelineFormPhotoImportFailedMessage, importFailureCount))
            }
            .onChange(of: selectedPhotoItems) { _, items in
                Task {
                    await importPhotos(from: items)
                }
            }
        }
    }

    private var photoPickerRow: some View {
        let addPhotosTitle = localization.text(.timelineFormAddPhotos)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localization.text(.timelineFormPhotoCount, mediaAssets.count, maxPhotoCount))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(EchoTheme.secondaryText)

                Spacer()

                if isImportingPhotos {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(localization.text(.timelineFormPhotoImporting))
                            .font(.caption)
                            .foregroundStyle(EchoTheme.secondaryText)
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(mediaAssets) { asset in
                        EditableTimelinePhoto(asset: asset) {
                            removePhoto(asset)
                        }
                    }

                    if remainingPhotoSlots > 0 {
                        PhotosPicker(
                            selection: $selectedPhotoItems,
                            maxSelectionCount: remainingPhotoSlots,
                            matching: .images
                        ) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title3.weight(.semibold))
                                Text(addPhotosTitle)
                                    .font(.caption.weight(.semibold))
                                    .multilineTextAlignment(.center)
                            }
                            .foregroundStyle(EchoTheme.primary)
                            .frame(width: 92, height: 92)
                            .background(EchoTheme.softPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                        }
                        .disabled(isImportingPhotos)
                    }
                }
                .padding(.vertical, 2)
            }

            Text(photoStatusMessage)
                .font(.caption)
                .foregroundStyle(photoStatusColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var isValid: Bool {
        !trimmed(title).isEmpty && !trimmed(story).isEmpty
    }

    private var isDirty: Bool {
        guard let memory else {
            return !trimmed(title).isEmpty ||
                !trimmed(story).isEmpty ||
                !mediaAssets.isEmpty ||
                imageSystemName != "heart.fill"
        }

        return trimmed(title) != memory.title ||
            trimmed(story) != memory.story ||
            !Calendar.current.isDate(date, inSameDayAs: memory.date) ||
            imageSystemName != memory.imageSystemName ||
            mediaAssets.map(\.id) != memory.mediaAssets.map(\.id)
    }

    private var remainingPhotoSlots: Int {
        max(0, maxPhotoCount - mediaAssets.count)
    }

    private var photoStatusMessage: String {
        if mediaAssets.isEmpty {
            return localization.text(.timelineFormPhotoEmptyHint)
        }

        if remainingPhotoSlots == 0 {
            return localization.text(.timelineFormPhotoMaxReached)
        }

        return localization.text(.timelineFormPhotoLimit)
    }

    private var photoStatusColor: Color {
        remainingPhotoSlots == 0 ? EchoTheme.warning : EchoTheme.secondaryText
    }

    private func attemptDismiss() {
        if isDirty {
            showingDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func save() {
        onSave(
            TimelineMemory(
                id: memory?.id ?? UUID(),
                petID: memory?.petID,
                memoryID: memory?.memoryID,
                date: date,
                title: trimmed(title),
                story: trimmed(story),
                imageSystemName: imageSystemName,
                mediaAssets: mediaAssets,
                category: memory?.category,
                sourceMemoryIDs: memory?.sourceMemoryIDs
            )
        )
        dismiss()
    }

    private func importPhotos(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty, remainingPhotoSlots > 0 else {
            selectedPhotoItems = []
            return
        }

        isImportingPhotos = true
        defer {
            selectedPhotoItems = []
            isImportingPhotos = false
        }

        var failedCount = 0

        for item in items.prefix(remainingPhotoSlots) {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                failedCount += 1
                continue
            }

            if let asset = try? LocalMediaStore.shared.savePhotoData(data) {
                mediaAssets.append(asset)
            } else {
                failedCount += 1
            }
        }

        if failedCount > 0 {
            importFailureCount = failedCount
            showingImportFailureAlert = true
        }
    }

    private func removePhoto(_ asset: MediaAsset) {
        mediaAssets.removeAll { $0.id == asset.id }

        if !originalMediaAssetIDs.contains(asset.id) {
            LocalMediaStore.shared.delete(asset)
        }
    }

    private func cleanupUnsavedMediaAssets() {
        let unsavedAssets = mediaAssets.filter { !originalMediaAssetIDs.contains($0.id) }
        LocalMediaStore.shared.delete(unsavedAssets)
    }

    private func iconName(for icon: String) -> String {
        switch icon {
        case "house.fill":
            return localization.text(.timelineFormIconHome)
        case "sun.max.fill":
            return localization.text(.timelineFormIconDaily)
        case "heart.fill":
            return localization.text(.timelineFormIconLove)
        case "pawprint.fill":
            return localization.text(.timelineFormIconPaw)
        case "circle.fill":
            return localization.text(.timelineFormIconToy)
        default:
            return localization.text(.timelineFormIconNature)
        }
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct EditableTimelinePhoto: View {
    @EnvironmentObject private var localization: LocalizationManager

    let asset: MediaAsset
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TimelinePhotoImage(asset: asset)
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 24, height: 24)
                    .background(Color.black.opacity(0.62))
                    .clipShape(Circle())
            }
            .padding(6)
            .accessibilityLabel(localization.text(.timelineFormDeletePhoto))
        }
    }
}
