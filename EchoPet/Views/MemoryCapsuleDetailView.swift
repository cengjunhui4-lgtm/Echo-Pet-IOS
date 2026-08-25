import SwiftUI

struct MemoryCapsuleDetailView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    let capsule: MemoryCapsule
    @State private var editingCapsule: MemoryCapsule?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        EchoPage(title: currentCapsule.title, subtitle: currentCapsule.dateLabel) {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: currentCapsule.accentSystemName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(EchoTheme.primary)
                    .frame(width: 64, height: 64)
                    .background(EchoTheme.softPrimary)
                    .clipShape(Circle())

                Text(currentCapsule.body)
                    .font(.body)
                    .foregroundStyle(EchoTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .echoCard()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    editingCapsule = currentCapsule
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel(localization.text(.capsuleEditAccessibility))

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel(localization.text(.capsuleDeleteAccessibility))
            }
        }
        .sheet(item: $editingCapsule) { capsule in
            MemoryCapsuleFormView(capsule: capsule) { updated in
                viewModel.saveMemoryCapsule(updated)
            }
        }
        .confirmationDialog(localization.text(.capsuleDeleteDialog), isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button(localization.text(.commonDelete), role: .destructive) {
                viewModel.deleteMemoryCapsule(currentCapsule)
                dismiss()
            }
            Button(localization.text(.commonCancel), role: .cancel) {}
        }
    }

    private var currentCapsule: MemoryCapsule {
        viewModel.capsules.first { $0.id == capsule.id } ?? capsule
    }
}
