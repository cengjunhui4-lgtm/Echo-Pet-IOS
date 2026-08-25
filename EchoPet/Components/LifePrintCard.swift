import SwiftUI

struct LifePrintCard: View {
    let profile: PetProfile
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(localization.text(.lifePrintTitle))
                .font(.title3.bold())
                .foregroundStyle(EchoTheme.text)

            LifePrintRow(label: localization.text(.lifePrintRowName), value: profile.name)
            LifePrintRow(label: localization.text(.lifePrintRowBreed), value: profile.breed)
            LifePrintRow(label: localization.text(.lifePrintRowAge), value: profile.age)
            LifePrintRow(label: localization.text(.lifePrintRowPersonality), value: profile.mbti)

            Divider()
                .background(EchoTheme.divider)

            LifePrintTagGroup(title: localization.text(.lifePrintGroupFavoriteThings), values: profile.favoriteThings)
            LifePrintTagGroup(title: localization.text(.lifePrintGroupHabits), values: profile.habits)
        }
        .echoCard()
        .accessibilityElement(children: .combine)
    }
}

private struct LifePrintRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(EchoTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(EchoTheme.text)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct LifePrintTagGroup: View {
    let title: String
    let values: [String]
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(EchoTheme.text)

            if values.isEmpty {
                Text(localization.text(.commonNotRecorded))
                    .font(.subheadline)
                    .foregroundStyle(EchoTheme.secondaryText)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(values, id: \.self) { value in
                        Label(value, systemImage: "heart.fill")
                            .font(.subheadline)
                            .foregroundStyle(EchoTheme.secondaryText)
                    }
                }
            }
        }
    }
}
