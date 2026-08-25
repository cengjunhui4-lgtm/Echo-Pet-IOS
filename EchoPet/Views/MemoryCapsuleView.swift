import SwiftUI

struct MemoryCapsuleView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @State private var showingNewCapsule = false

    var body: some View {
        EchoPage(title: localization.text(.capsuleTitle), subtitle: localization.text(.capsuleSubtitle)) {
            if !viewModel.hasPetProfile {
                EmptyStateCard(
                    title: localization.text(.capsuleNoPetTitle),
                    message: localization.text(.capsuleNoPetMessage),
                    systemName: "pawprint.fill"
                )
            } else if viewModel.capsules.isEmpty {
                EmptyStateCard(
                    title: localization.text(.capsuleEmptyTitle),
                    message: localization.text(.capsuleEmptyMessage),
                    systemName: "heart.text.square.fill",
                    actionTitle: localization.text(.capsuleCreate)
                ) {
                    showingNewCapsule = true
                }
            } else {
                VStack(spacing: 14) {
                    ForEach(viewModel.capsules) { capsule in
                        NavigationLink {
                            MemoryCapsuleDetailView(capsule: capsule)
                        } label: {
                            MemoryCard(capsule: capsule)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.deleteMemoryCapsule(capsule)
                            } label: {
                                Label(localization.text(.commonDelete), systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewCapsule = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!viewModel.hasPetProfile)
                .accessibilityLabel(localization.text(.capsuleCreate))
            }
        }
        .sheet(isPresented: $showingNewCapsule) {
            MemoryCapsuleFormView(capsule: nil) { capsule in
                viewModel.saveMemoryCapsule(capsule)
            }
        }
    }
}
