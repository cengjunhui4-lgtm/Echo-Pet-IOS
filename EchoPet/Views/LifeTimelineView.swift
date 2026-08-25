import SwiftUI

struct LifeTimelineView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @State private var showingNewMemory = false
    @State private var selectedMemory: TimelineMemory?
    @State private var editingMemory: TimelineMemory?
    @State private var deletingMemory: TimelineMemory?

    var body: some View {
        EchoPage(title: localization.text(.timelineTitle), subtitle: subtitle) {
            if !viewModel.hasPetProfile {
                EmptyStateCard(
                    title: localization.text(.timelineNoPetTitle),
                    message: localization.text(.timelineNoPetMessage),
                    systemName: "pawprint.fill"
                )
            } else if viewModel.timeline.isEmpty {
                EmptyStateCard(
                    title: localization.text(.timelineEmptyTitle),
                    message: localization.text(.timelineEmptyMessage),
                    systemName: "clock.badge.plus",
                    actionTitle: localization.text(.timelineAdd)
                ) {
                    showingNewMemory = true
                }
            } else {
                VStack(spacing: 14) {
                    ForEach(viewModel.timeline) { memory in
                        TimelineCard(
                            memory: memory,
                            onOpen: {
                                selectedMemory = memory
                            },
                            onEdit: {
                                editingMemory = memory
                            },
                            onDelete: {
                                deletingMemory = memory
                            }
                        )
                        .contextMenu {
                            Button {
                                editingMemory = memory
                            } label: {
                                Label(localization.text(.commonEdit), systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                deletingMemory = memory
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
                    showingNewMemory = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!viewModel.hasPetProfile)
                .accessibilityLabel(localization.text(.timelineAdd))
            }
        }
        .sheet(isPresented: $showingNewMemory) {
            TimelineMemoryFormView(memory: nil) { memory in
                viewModel.saveTimelineMemory(memory)
            }
        }
        .sheet(item: $editingMemory) { memory in
            TimelineMemoryFormView(memory: memory) { updated in
                viewModel.saveTimelineMemory(updated)
            }
        }
        .confirmationDialog(localization.text(.timelineDeleteDialog), isPresented: isConfirmingDelete, titleVisibility: .visible) {
            Button(localization.text(.commonDelete), role: .destructive) {
                if let deletingMemory {
                    viewModel.deleteTimelineMemory(deletingMemory)
                    self.deletingMemory = nil
                }
            }
            Button(localization.text(.commonCancel), role: .cancel) {
                deletingMemory = nil
            }
        }
        .navigationDestination(isPresented: isShowingSelectedMemory) {
            if let selectedMemory {
                TimelineDetailView(memory: selectedMemory)
            }
        }
    }

    private var subtitle: String {
        guard let pet = viewModel.pet else {
            return localization.text(.timelineSubtitleNoPet)
        }
        return localization.text(.timelineSubtitlePet, pet.name)
    }

    private var isConfirmingDelete: Binding<Bool> {
        Binding(
            get: { deletingMemory != nil },
            set: { isPresented in
                if !isPresented {
                    deletingMemory = nil
                }
            }
        )
    }

    private var isShowingSelectedMemory: Binding<Bool> {
        Binding(
            get: { selectedMemory != nil },
            set: { isPresented in
                if !isPresented {
                    selectedMemory = nil
                }
            }
        )
    }
}
