import SwiftUI

struct MemoryCapsuleFormView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    let capsule: MemoryCapsule?
    let onSave: (MemoryCapsule) -> Void

    @State private var title: String
    @State private var dateLabel: String
    @State private var bodyText: String
    @State private var accentSystemName: String

    private let icons = [
        "sun.max.fill",
        "heart.fill",
        "sparkles",
        "text.book.closed.fill",
        "moon.fill",
        "gift.fill"
    ]

    init(capsule: MemoryCapsule?, onSave: @escaping (MemoryCapsule) -> Void) {
        self.capsule = capsule
        self.onSave = onSave
        _title = State(initialValue: capsule?.title ?? "")
        _dateLabel = State(initialValue: capsule?.dateLabel ?? "")
        _bodyText = State(initialValue: capsule?.body ?? "")
        _accentSystemName = State(initialValue: capsule?.accentSystemName ?? "heart.fill")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(localization.text(.capsuleFormSectionContent)) {
                    TextField(localization.text(.capsuleFormFieldTitle), text: $title)
                    TextField(localization.text(.capsuleFormFieldDateLabel), text: $dateLabel)
                    TextField(localization.text(.capsuleFormFieldBody), text: $bodyText, axis: .vertical)
                        .lineLimit(5...10)
                }

                Section(localization.text(.capsuleFormSectionIcon)) {
                    Picker(localization.text(.capsuleFormSectionIcon), selection: $accentSystemName) {
                        ForEach(icons, id: \.self) { icon in
                            Label(iconName(for: icon), systemImage: icon)
                                .tag(icon)
                        }
                    }
                }
            }
            .navigationTitle(capsule == nil ? localization.text(.capsuleCreate) : localization.text(.capsuleEdit))
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
                    .disabled(!isValid)
                }
            }
        }
        .onAppear {
            if dateLabel.isEmpty {
                dateLabel = defaultDateLabel
            }
        }
    }

    private var defaultDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: localization.language.localeIdentifier)
        return formatter.string(from: Date())
    }

    private var isValid: Bool {
        !trimmed(title).isEmpty && !trimmed(bodyText).isEmpty
    }

    private func save() {
        onSave(
            MemoryCapsule(
                id: capsule?.id ?? UUID(),
                title: trimmed(title),
                dateLabel: trimmed(dateLabel).isEmpty ? defaultDateLabel : trimmed(dateLabel),
                body: trimmed(bodyText),
                accentSystemName: accentSystemName
            )
        )
        dismiss()
    }

    private func iconName(for icon: String) -> String {
        switch icon {
        case "sun.max.fill":
            return localization.text(.capsuleFormIconMorning)
        case "heart.fill":
            return localization.text(.capsuleFormIconMissing)
        case "sparkles":
            return localization.text(.capsuleFormIconPrecious)
        case "text.book.closed.fill":
            return localization.text(.capsuleFormIconText)
        case "moon.fill":
            return localization.text(.capsuleFormIconNight)
        default:
            return localization.text(.capsuleFormIconGift)
        }
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
