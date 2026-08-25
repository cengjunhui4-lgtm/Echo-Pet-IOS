import SwiftUI

struct TimelineDetailView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    let memory: TimelineMemory
    @State private var editingMemory: TimelineMemory?
    @State private var showingDeleteConfirmation = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: localization.language.localeIdentifier)
        return formatter
    }

    var body: some View {
        EchoPage(title: currentMemory.title, subtitle: dateFormatter.string(from: currentMemory.date)) {
            VStack(alignment: .leading, spacing: 18) {
                if currentMemory.mediaAssets.isEmpty {
                    Image(systemName: currentMemory.imageSystemName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(EchoTheme.primary)
                        .frame(width: 64, height: 64)
                        .background(EchoTheme.softPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                } else {
                    TimelinePhotoStack(assets: currentMemory.mediaAssets, fallbackSystemName: currentMemory.imageSystemName)
                        .frame(height: 170)

                    TimelinePhotoGrid(assets: currentMemory.mediaAssets)
                }

                Text(currentMemory.story)
                    .font(.body)
                    .foregroundStyle(EchoTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .echoCard()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    editingMemory = currentMemory
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel(localization.text(.timelineEditAccessibility))

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel(localization.text(.timelineDeleteAccessibility))
            }
        }
        .sheet(item: $editingMemory) { memory in
            TimelineMemoryFormView(memory: memory) { updated in
                viewModel.saveTimelineMemory(updated)
            }
        }
        .confirmationDialog(localization.text(.timelineDeleteDialog), isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button(localization.text(.commonDelete), role: .destructive) {
                viewModel.deleteTimelineMemory(currentMemory)
                dismiss()
            }
            Button(localization.text(.commonCancel), role: .cancel) {}
        }
    }

    private var currentMemory: TimelineMemory {
        viewModel.timeline.first { $0.id == memory.id } ?? memory
    }
}

private struct TimelinePhotoGrid: View {
    let assets: [MediaAsset]

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(assets) { asset in
                TimelinePhotoImage(asset: asset)
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}
