import PhotosUI
import SwiftUI
import UIKit

struct PetProfileFormView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    let profile: PetProfile?
    let onSave: (PetProfile) -> Void

    @State private var name: String
    @State private var breed: String
    @State private var age: String
    @State private var personality: String
    @State private var mbti: String
    @State private var favoriteThingsText: String
    @State private var habitsText: String
    @State private var avatarAssetID: String?
    @State private var selectedAvatarItem: PhotosPickerItem?

    init(profile: PetProfile?, onSave: @escaping (PetProfile) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _name = State(initialValue: profile?.name ?? "")
        _breed = State(initialValue: profile?.breed ?? "")
        _age = State(initialValue: profile?.age ?? "")
        _personality = State(initialValue: profile?.personality ?? "")
        _mbti = State(initialValue: profile?.mbti ?? "")
        _favoriteThingsText = State(initialValue: profile?.favoriteThings.joined(separator: "，") ?? "")
        _habitsText = State(initialValue: profile?.habits.joined(separator: "，") ?? "")
        _avatarAssetID = State(initialValue: profile?.avatarAssetID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(localization.text(.profileFormSectionAvatar)) {
                    HStack {
                        Spacer()
                        PetAvatarView(profile: avatarPreviewProfile, size: 92)
                            .padding(.vertical, 8)
                        Spacer()
                    }

                    PhotosPicker(selection: $selectedAvatarItem, matching: .images, photoLibrary: .shared()) {
                        Label(
                            localization.text(avatarAssetID == nil ? .profileFormAvatarChoose : .profileFormAvatarChange),
                            systemImage: "photo"
                        )
                    }

                    if avatarAssetID != nil {
                        Button(role: .destructive) {
                            avatarAssetID = nil
                        } label: {
                            Label(localization.text(.profileFormAvatarRemove), systemImage: "trash")
                        }
                    }
                }

                Section(localization.text(.profileFormSectionBasic)) {
                    TextField(localization.text(.profileFormFieldName), text: $name)
                    TextField(localization.text(.profileFormFieldBreed), text: $breed)
                    TextField(localization.text(.profileFormFieldAge), text: $age)
                    TextField(localization.text(.profileFormFieldPersonality), text: $personality, axis: .vertical)
                        .lineLimit(2...4)
                    TextField(localization.text(.profileFormFieldMBTI), text: $mbti)
                }

                Section(localization.text(.profileFormSectionLife)) {
                    TextField(localization.text(.profileFormFieldFavoriteThings), text: $favoriteThingsText, axis: .vertical)
                        .lineLimit(2...4)
                    TextField(localization.text(.profileFormFieldHabits), text: $habitsText, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(profile == nil ? localization.text(.profileFormTitleCreate) : localization.text(.profileFormTitleEdit))
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
            .onChange(of: selectedAvatarItem) { _, item in
                Task {
                    await loadAvatar(from: item)
                }
            }
        }
    }

    private var avatarPreviewProfile: PetProfile? {
        var preview = profile ?? PetProfile(
            name: trimmed(name).isEmpty ? "Echo Pet" : trimmed(name),
            breed: "",
            age: "",
            personality: trimmed(personality),
            mbti: "",
            favoriteThings: [],
            habits: []
        )
        preview.avatarAssetID = avatarAssetID
        return preview
    }

    private var isValid: Bool {
        !trimmed(name).isEmpty && !trimmed(personality).isEmpty
    }

    private func save() {
        let now = Date()
        let nextProfile = PetProfile(
            id: profile?.id ?? UUID(),
            name: trimmed(name),
            species: profile?.species,
            breed: trimmed(breed).isEmpty ? localization.text(.profileFormDefaultBreed) : trimmed(breed),
            age: trimmed(age).isEmpty ? localization.text(.profileFormDefaultAge) : trimmed(age),
            birthDate: profile?.birthDate,
            status: profile?.status,
            relationshipLabel: profile?.relationshipLabel,
            avatarAssetID: avatarAssetID,
            personality: trimmed(personality),
            mbti: trimmed(mbti).isEmpty ? localization.text(.profileFormDefaultMBTI) : trimmed(mbti),
            favoriteThings: splitList(favoriteThingsText),
            habits: splitList(habitsText),
            createdAt: profile?.createdAt ?? now,
            updatedAt: now
        )
        onSave(nextProfile)
        dismiss()
    }

    private func loadAvatar(from item: PhotosPickerItem?) async {
        guard let item else {
            return
        }

        defer {
            selectedAvatarItem = nil
        }

        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data),
            let encodedAvatar = PetAvatarImageStore.encodedDataURL(from: image)
        else {
            return
        }

        avatarAssetID = encodedAvatar
    }

    private func splitList(_ value: String) -> [String] {
        value
            .split(whereSeparator: { $0 == "," || $0 == "，" || $0 == "\n" })
            .map { trimmed(String($0)) }
            .filter { !$0.isEmpty }
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
