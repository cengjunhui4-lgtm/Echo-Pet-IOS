import PhotosUI
import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @State private var taskForm: DailyTaskFormState?
    @AppStorage("echoPet.dailyTaskCardCollapsed") private var isTaskCardCollapsed = false
    @AppStorage("echoPet.dailyTaskCardOffsetX") private var storedTaskCardOffsetX = 0.0
    @AppStorage("echoPet.dailyTaskCardOffsetY") private var storedTaskCardOffsetY = 0.0
    @State private var taskCardDragOffset: CGSize = .zero
    private let taskCardBottomClearance: CGFloat = 78
    private let taskCardMinimumTop: CGFloat = 188
    private let collapsedDailyTaskCardHeight: CGFloat = 116

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { proxy in
                    let cardHeight = isTaskCardCollapsed ? collapsedDailyTaskCardHeight : dailyTaskCardHeight(for: proxy.size.height)
                    let cardWidth = max(proxy.size.width - EchoTheme.pagePadding * 2, 240)
                    let defaultTop = dailyTaskCardTopOffset(in: proxy.size.height, cardHeight: cardHeight)
                    let cardSize = CGSize(width: cardWidth, height: cardHeight)
                    let cardOffset = currentDailyTaskCardOffset(screenSize: proxy.size, cardSize: cardSize, defaultTop: defaultTop)

                    ZStack(alignment: .topLeading) {
                        dailyMoodHeader
                            .padding(.horizontal, EchoTheme.pagePadding)
                            .padding(.top, 54)

                        dailyTasksCard(
                            height: cardHeight,
                            cardDragGesture: dailyTaskCardDragGesture(
                                screenSize: proxy.size,
                                cardSize: cardSize,
                                defaultTop: defaultTop
                            )
                        )
                        .frame(width: cardWidth)
                        .position(
                            x: proxy.size.width / 2 + cardOffset.width,
                            y: defaultTop + cardHeight / 2 + cardOffset.height
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .background {
                ZStack {
                    EchoBackgroundView()
                    EchoTheme.pageBackdrop
                }
                .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(localization.text(.homeSettings))
                }
            }
            .sheet(item: $taskForm) { state in
                DailyTaskFormView(task: state.task) { task in
                    viewModel.saveDailyTask(task)
                }
            }
        }
    }

    private var dailyMoodHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            PetAvatarView(profile: viewModel.pet, size: 42)

            Text(viewModel.dailyPetGreeting(language: localization.language))
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: Color.black.opacity(0.62), radius: 7, x: 0, y: 3)
                .shadow(color: Color.black.opacity(0.38), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: 318, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func dailyTasksCard<CardDragGesture: Gesture>(height: CGFloat, cardDragGesture: CardDragGesture) -> some View {
        VStack(alignment: .leading, spacing: isTaskCardCollapsed ? 12 : 16) {
            dailyTasksHeader(cardDragGesture: cardDragGesture)

            if viewModel.todayTaskCount > 0 {
                taskProgress
            }

            if !isTaskCardCollapsed {
                if viewModel.todaysDailyTasks.isEmpty {
                    DailyTaskEmptyState {
                        taskForm = DailyTaskFormState(task: nil)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(viewModel.todaysDailyTasks) { task in
                                DailyTaskSwipeRow(
                                    task: task,
                                    onToggle: {
                                        viewModel.toggleDailyTaskCompletion(task)
                                    },
                                    onEdit: {
                                        taskForm = DailyTaskFormState(task: task)
                                    },
                                    onDelete: {
                                        viewModel.deleteDailyTask(task)
                                    }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .padding(18)
        .frame(height: height, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(Color.white.opacity(0.12))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 22, x: 0, y: 14)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func dailyTasksHeader<CardDragGesture: Gesture>(cardDragGesture: CardDragGesture) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text(localization.text(.homeDailyTasksTitle))
                    .font(.title3.bold())
                    .foregroundStyle(EchoTheme.text)
                if !isTaskCardCollapsed {
                    Text(localization.text(.homeDailyTasksSubtitle))
                        .font(.subheadline)
                        .foregroundStyle(EchoTheme.secondaryText)
                }
            }
            .contentShape(Rectangle())
            .gesture(cardDragGesture)

            Spacer(minLength: 8)

            Button {
                taskForm = DailyTaskFormState(task: nil)
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 36, height: 36)
                    .background(EchoTheme.primary)
                    .clipShape(Circle())
            }
            .accessibilityLabel(localization.text(.homeDailyTaskAdd))

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                    isTaskCardCollapsed.toggle()
                }
            } label: {
                Image(systemName: isTaskCardCollapsed ? "chevron.up" : "chevron.down")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(EchoTheme.text)
                    .frame(width: 36, height: 36)
                    .background(.thinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(localization.text(isTaskCardCollapsed ? .homeDailyTasksExpand : .homeDailyTasksCollapse))

            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(EchoTheme.secondaryText)
                .frame(width: 32, height: 36)
                .contentShape(Rectangle())
                .gesture(cardDragGesture)
                .accessibilityLabel(localization.text(.homeDailyTasksMove))
        }
    }

    private func dailyTaskCardHeight(for screenHeight: CGFloat) -> CGFloat {
        min(326, max(292, screenHeight * 0.34))
    }

    private func dailyTaskCardTopOffset(in screenHeight: CGFloat, cardHeight: CGFloat) -> CGFloat {
        let belowMiddle = max(screenHeight * 0.76, 430)
        let maximumTop = max(screenHeight - cardHeight - taskCardBottomClearance, 0)
        return min(belowMiddle, maximumTop)
    }

    private func currentDailyTaskCardOffset(screenSize: CGSize, cardSize: CGSize, defaultTop: CGFloat) -> CGSize {
        let proposed = CGSize(
            width: CGFloat(storedTaskCardOffsetX) + taskCardDragOffset.width,
            height: CGFloat(storedTaskCardOffsetY) + taskCardDragOffset.height
        )
        return clampedDailyTaskCardOffset(screenSize: screenSize, cardSize: cardSize, defaultTop: defaultTop, proposed: proposed)
    }

    private func clampedDailyTaskCardOffset(screenSize: CGSize, cardSize: CGSize, defaultTop: CGFloat, proposed: CGSize) -> CGSize {
        let horizontalLimit = max((screenSize.width - cardSize.width) / 2 - 8, 0)
        let minimumTop = min(taskCardMinimumTop, max(defaultTop, 0))
        let maximumTop = max(minimumTop, screenSize.height - cardSize.height - taskCardBottomClearance)

        return CGSize(
            width: min(max(proposed.width, -horizontalLimit), horizontalLimit),
            height: min(max(proposed.height, minimumTop - defaultTop), maximumTop - defaultTop)
        )
    }

    private func dailyTaskCardDragGesture(screenSize: CGSize, cardSize: CGSize, defaultTop: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                let proposed = CGSize(
                    width: CGFloat(storedTaskCardOffsetX) + value.translation.width,
                    height: CGFloat(storedTaskCardOffsetY) + value.translation.height
                )
                let clamped = clampedDailyTaskCardOffset(screenSize: screenSize, cardSize: cardSize, defaultTop: defaultTop, proposed: proposed)
                taskCardDragOffset = CGSize(
                    width: clamped.width - CGFloat(storedTaskCardOffsetX),
                    height: clamped.height - CGFloat(storedTaskCardOffsetY)
                )
            }
            .onEnded { value in
                let proposed = CGSize(
                    width: CGFloat(storedTaskCardOffsetX) + value.translation.width,
                    height: CGFloat(storedTaskCardOffsetY) + value.translation.height
                )
                let clamped = clampedDailyTaskCardOffset(screenSize: screenSize, cardSize: cardSize, defaultTop: defaultTop, proposed: proposed)
                storedTaskCardOffsetX = Double(clamped.width)
                storedTaskCardOffsetY = Double(clamped.height)
                taskCardDragOffset = .zero
            }
    }

    private var taskProgress: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(progressText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(EchoTheme.secondaryText)
                Spacer()
                if viewModel.todayTaskCount == viewModel.completedTodayTaskCount {
                    Text(localization.text(.homeDailyTasksAllDone))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(EchoTheme.success)
                }
            }

            ProgressView(
                value: Double(viewModel.completedTodayTaskCount),
                total: Double(max(viewModel.todayTaskCount, 1))
            )
            .tint(viewModel.todayTaskCount == viewModel.completedTodayTaskCount ? EchoTheme.success : EchoTheme.primary)
        }
    }

    private var progressText: String {
        localization.text(
            .homeDailyTasksProgress,
            viewModel.completedTodayTaskCount,
            viewModel.todayTaskCount
        )
    }
}

private struct DailyTaskFormState: Identifiable {
    let id = UUID()
    let task: DailyCareTask?
}

private struct DailyTaskEmptyState: View {
    @EnvironmentObject private var localization: LocalizationManager
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(EchoTheme.primary)
                .frame(width: 48, height: 48)
                .background(EchoTheme.softPrimary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(localization.text(.homeDailyTasksEmptyTitle))
                    .font(.headline)
                    .foregroundStyle(EchoTheme.text)
                Text(localization.text(.homeDailyTasksEmptyMessage))
                    .font(.subheadline)
                    .foregroundStyle(EchoTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                onAdd()
            } label: {
                Label(localization.text(.homeDailyTaskAdd), systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(EchoTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EchoTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
    }
}

private struct DailyTaskSwipeRow: View {
    @EnvironmentObject private var localization: LocalizationManager
    let task: DailyCareTask
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var offsetX: CGFloat = 0
    private let actionWidth: CGFloat = 72

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                Button {
                    close()
                    onEdit()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text(localization.text(.commonEdit))
                            .font(.caption2.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.white)
                .background(EchoTheme.warning)

                Button {
                    close()
                    onDelete()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text(localization.text(.commonDelete))
                            .font(.caption2.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.white)
                .background(Color.red.opacity(0.82))
            }
            .frame(width: actionWidth * 2)
            .opacity(offsetX < -1 ? 1 : 0)

            DailyTaskRow(task: task, onToggle: onToggle)
                .offset(x: offsetX)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { value in
                            let nextOffset = min(0, max(-(actionWidth * 2), value.translation.width))
                            offsetX = nextOffset
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                                offsetX = value.translation.width < -48 ? -(actionWidth * 2) : 0
                            }
                        }
                )
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
    }

    private func close() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
            offsetX = 0
        }
    }
}

private struct DailyTaskRow: View {
    @EnvironmentObject private var localization: LocalizationManager
    let task: DailyCareTask
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(task.isCompleted ? EchoTheme.success : EchoTheme.secondaryText.opacity(0.55))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                localization.text(
                    task.isCompleted ? .homeDailyTaskReopenAccessibility : .homeDailyTaskCompleteAccessibility,
                    task.title
                )
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: templateIcon(for: task.template))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(EchoTheme.primary)
                    Text(timeLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(EchoTheme.secondaryText)
                }

                Text(task.title)
                    .font(.headline)
                    .foregroundStyle(EchoTheme.text)
                    .strikethrough(task.isCompleted, color: EchoTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

            }

            Spacer(minLength: 0)

            Text(localization.text(task.isCompleted ? .homeDailyTaskCompleted : .homeDailyTaskPending))
                .font(.caption.weight(.semibold))
                .foregroundStyle(task.isCompleted ? EchoTheme.success : EchoTheme.warning)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(.thinMaterial)
        .overlay(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
    }

    private var timeLabel: String {
        guard let dueAt = task.dueAt else {
            return localization.text(.homeDailyTaskNoTime)
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: localization.language.localeIdentifier)
        return formatter.string(from: dueAt)
    }
}

private struct DailyTaskFormView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    let task: DailyCareTask?
    let onSave: (DailyCareTask) -> Void

    @State private var title: String
    @State private var note: String
    @State private var hasDueTime: Bool
    @State private var dueAt: Date
    @State private var template: DailyCareTaskTemplate

    init(task: DailyCareTask?, onSave: @escaping (DailyCareTask) -> Void) {
        self.task = task
        self.onSave = onSave
        _title = State(initialValue: task?.title ?? "")
        _note = State(initialValue: task?.note ?? "")
        _hasDueTime = State(initialValue: task?.dueAt != nil)
        _dueAt = State(initialValue: task?.dueAt ?? Date())
        _template = State(initialValue: task?.template ?? .custom)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(localization.text(.dailyTaskFormSectionTemplate)) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(DailyCareTaskTemplate.allCases, id: \.self) { item in
                                Button {
                                    selectTemplate(item)
                                } label: {
                                    Label(templateTitle(for: item), systemImage: templateIcon(for: item))
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 9)
                                        .foregroundStyle(template == item ? Color.white : EchoTheme.text)
                                        .background(template == item ? EchoTheme.primary : EchoTheme.softPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(localization.text(.dailyTaskFormSectionDetails)) {
                    TextField(localization.text(.dailyTaskFormFieldTitle), text: $title)
                    TextField(localization.text(.dailyTaskFormFieldNote), text: $note, axis: .vertical)
                        .lineLimit(2...5)
                    Toggle(localization.text(.dailyTaskFormUseTime), isOn: $hasDueTime)
                    if hasDueTime {
                        DatePicker(
                            localization.text(.dailyTaskFormFieldTime),
                            selection: $dueAt,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
            }
            .navigationTitle(task == nil ? localization.text(.dailyTaskFormTitleCreate) : localization.text(.dailyTaskFormTitleEdit))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.text(.commonCancel)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.text(.commonSave)) {
                        save()
                    }
                    .disabled(trimmed(title).isEmpty)
                }
            }
        }
    }

    private func selectTemplate(_ item: DailyCareTaskTemplate) {
        let previousTitle = templateTitle(for: template)
        template = item
        if trimmed(title).isEmpty || trimmed(title) == previousTitle {
            title = item == .custom ? "" : templateTitle(for: item)
        }
    }

    private func save() {
        onSave(
            DailyCareTask(
                id: task?.id ?? UUID(),
                petID: task?.petID,
                title: trimmed(title),
                note: trimmed(note),
                dueAt: hasDueTime ? dueAt : nil,
                date: task?.date ?? Date(),
                template: template,
                isCompleted: task?.isCompleted ?? false,
                createdAt: task?.createdAt ?? Date(),
                updatedAt: Date()
            )
        )
        dismiss()
    }

    private func templateTitle(for template: DailyCareTaskTemplate) -> String {
        dailyTaskTemplateTitle(template, localization: localization)
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct BackgroundAlbumView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isImporting = false
    @State private var failedImportCount = 0
    @State private var showingImportFailure = false

    private let columns = [
        GridItem(.adaptive(minimum: 96), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: EchoTheme.sectionSpacing) {
                    headerCard

                    if !viewModel.backgroundAlbum.photos.isEmpty {
                        modeCard
                        blurCard
                    }

                    photoGridCard
                }
                .padding(EchoTheme.pagePadding)
                .padding(.bottom, EchoTheme.pagePadding)
            }
            .background(EchoTheme.pageBackdrop.ignoresSafeArea())
            .navigationTitle(localization.text(.backgroundAlbumTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.text(.commonOK)) {
                        dismiss()
                    }
                    .disabled(isImporting)
                }
            }
            .onChange(of: selectedPhotoItems) { _, items in
                Task {
                    await importSelectedPhotos(items)
                }
            }
            .alert(localization.text(.backgroundAlbumImportFailedTitle), isPresented: $showingImportFailure) {
                Button(localization.text(.commonOK), role: .cancel) {}
            } message: {
                Text(localization.text(.backgroundAlbumImportFailedMessage, failedImportCount))
            }
        }
    }

    private var headerCard: some View {
        let addPhotosTitle = localization.text(.backgroundAlbumAddPhotos)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(EchoTheme.primary)
                    .frame(width: 52, height: 52)
                    .background(EchoTheme.softPrimary)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(localization.text(.backgroundAlbumTitle))
                        .font(.title3.bold())
                        .foregroundStyle(EchoTheme.text)

                    Text(localization.text(.backgroundAlbumSubtitle))
                        .font(.subheadline)
                        .foregroundStyle(EchoTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 12) {
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 24,
                    matching: .images
                ) {
                    Label(addPhotosTitle, systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(EchoTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isImporting)

                if isImporting {
                    ProgressView()
                        .frame(width: 24, height: 24)
                        .accessibilityLabel(localization.text(.backgroundAlbumImporting))
                }
            }

            Text(localization.text(.backgroundAlbumPhotoCount, viewModel.backgroundAlbum.photos.count))
                .font(.caption.weight(.semibold))
                .foregroundStyle(EchoTheme.secondaryText)
        }
        .echoCard()
    }

    private var modeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localization.text(.backgroundAlbumModeTitle))
                .font(.headline)
                .foregroundStyle(EchoTheme.text)

            VStack(spacing: 10) {
                ForEach(BackgroundDisplayMode.allCases) { mode in
                    Button {
                        viewModel.setBackgroundDisplayMode(mode)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: viewModel.backgroundAlbum.displayMode == mode ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(viewModel.backgroundAlbum.displayMode == mode ? EchoTheme.primary : EchoTheme.secondaryText.opacity(0.55))

                            Text(modeTitle(mode))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(EchoTheme.text)

                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(EchoTheme.softPrimary.opacity(viewModel.backgroundAlbum.displayMode == mode ? 1 : 0.58))
                        .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .echoCard()
    }

    private var blurCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localization.text(.backgroundAlbumBlurTitle))
                    .font(.headline)
                    .foregroundStyle(EchoTheme.text)

                Spacer()

                Text(localization.text(.backgroundAlbumBlurValue, Int(viewModel.backgroundAlbum.blurRadius)))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(EchoTheme.secondaryText)
            }

            Slider(
                value: Binding(
                    get: { viewModel.backgroundAlbum.blurRadius },
                    set: { viewModel.setBackgroundBlurRadius($0) }
                ),
                in: 0...32,
                step: 1
            )
            .tint(EchoTheme.primary)
        }
        .echoCard()
    }

    private var photoGridCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localization.text(.backgroundAlbumCurrentBackground))
                .font(.headline)
                .foregroundStyle(EchoTheme.text)

            if viewModel.backgroundAlbum.photos.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.text(.backgroundAlbumEmptyTitle))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(EchoTheme.text)
                    Text(localization.text(.backgroundAlbumEmptyMessage))
                        .font(.caption)
                        .foregroundStyle(EchoTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(EchoTheme.background.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.backgroundAlbum.photos) { photo in
                        BackgroundAlbumPhotoTile(
                            photo: photo,
                            isSelected: viewModel.backgroundAlbum.selectedPhotoID == photo.id,
                            image: uiImage(for: photo),
                            onSetFixed: {
                                viewModel.setFixedBackgroundPhoto(photo)
                            },
                            onToggleRotation: {
                                viewModel.setBackgroundPhotoRotation(
                                    photo,
                                    isIncluded: !photo.isIncludedInRotation
                                )
                            },
                            onDelete: {
                                viewModel.deleteBackgroundPhoto(photo)
                            }
                        )
                    }
                }

                Button(role: .destructive) {
                    viewModel.resetBackgroundAlbum()
                } label: {
                    Label(localization.text(.backgroundAlbumRestoreDefault), systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .echoCard()
    }

    @MainActor
    private func importSelectedPhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else {
            return
        }

        isImporting = true
        var failureCount = 0
        var firstImportedPhoto: BackgroundAlbumPhoto?

        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    failureCount += 1
                    continue
                }

                let photo = try viewModel.importBackgroundPhotoData(data, activate: false)
                firstImportedPhoto = firstImportedPhoto ?? photo
            } catch {
                failureCount += 1
            }
        }

        if let firstImportedPhoto {
            viewModel.setFixedBackgroundPhoto(firstImportedPhoto)
        }

        selectedPhotoItems = []
        isImporting = false

        if failureCount > 0 {
            failedImportCount = failureCount
            showingImportFailure = true
        }
    }

    private func uiImage(for photo: BackgroundAlbumPhoto) -> UIImage? {
        guard let fileURL = viewModel.backgroundFileURL(for: photo.asset) else {
            return nil
        }

        return UIImage(contentsOfFile: fileURL.path)
    }

    private func modeTitle(_ mode: BackgroundDisplayMode) -> String {
        switch mode {
        case .fixed:
            return localization.text(.backgroundAlbumModeFixed)
        case .random:
            return localization.text(.backgroundAlbumModeRandom)
        case .dailyRandom:
            return localization.text(.backgroundAlbumModeDailyRandom)
        case .gentleCycle:
            return localization.text(.backgroundAlbumModeGentleCycle)
        }
    }
}

private struct BackgroundAlbumPhotoTile: View {
    @EnvironmentObject private var localization: LocalizationManager

    let photo: BackgroundAlbumPhoto
    let isSelected: Bool
    let image: UIImage?
    let onSetFixed: () -> Void
    let onToggleRotation: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button {
                onSetFixed()
            } label: {
                ZStack(alignment: .topTrailing) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        EchoTheme.softPrimary
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(EchoTheme.secondaryText)
                    }

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(EchoTheme.primary)
                            .padding(8)
                    }
                }
                .frame(height: 112)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous)
                        .stroke(isSelected ? EchoTheme.primary : Color.white.opacity(0.7), lineWidth: isSelected ? 2 : 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localization.text(.backgroundAlbumSetFixed))

            HStack(spacing: 8) {
                Button {
                    onToggleRotation()
                } label: {
                    Image(systemName: photo.isIncludedInRotation ? "arrow.triangle.2.circlepath.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(photo.isIncludedInRotation ? EchoTheme.success : EchoTheme.secondaryText)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(localization.text(.backgroundAlbumIncludeInRotation))

                Spacer(minLength: 0)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(localization.text(.backgroundAlbumRemovePhoto))
            }
        }
        .padding(8)
        .background(EchoTheme.background.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
    }
}

private func templateIcon(for template: DailyCareTaskTemplate) -> String {
    switch template {
    case .feeding:
        return "fork.knife"
    case .walk:
        return "figure.walk"
    case .grooming:
        return "comb.fill"
    case .play:
        return "tennisball.fill"
    case .cleaning:
        return "sparkles"
    case .medicine:
        return "cross.case.fill"
    case .photo:
        return "camera.fill"
    case .custom:
        return "plus.circle.fill"
    }
}

@MainActor
private func dailyTaskTemplateTitle(
    _ template: DailyCareTaskTemplate,
    localization: LocalizationManager
) -> String {
    switch template {
    case .feeding:
        return localization.text(.dailyTaskTemplateFeeding)
    case .walk:
        return localization.text(.dailyTaskTemplateWalk)
    case .grooming:
        return localization.text(.dailyTaskTemplateGrooming)
    case .play:
        return localization.text(.dailyTaskTemplatePlay)
    case .cleaning:
        return localization.text(.dailyTaskTemplateCleaning)
    case .medicine:
        return localization.text(.dailyTaskTemplateMedicine)
    case .photo:
        return localization.text(.dailyTaskTemplatePhoto)
    case .custom:
        return localization.text(.dailyTaskTemplateCustom)
    }
}
