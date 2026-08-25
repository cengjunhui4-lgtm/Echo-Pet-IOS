import SwiftUI

struct LifePrintView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        EchoPage(title: localization.text(.lifePrintTitle), subtitle: localization.text(.lifePrintSubtitle)) {
            if let pet = viewModel.pet {
                VStack(alignment: .leading, spacing: 16) {
                    LifePrintGeneratorSection()
                    LifePrintCard(profile: pet)
                }
            } else {
                EmptyStateCard(
                    title: localization.text(.lifePrintNoPetTitle),
                    message: localization.text(.lifePrintNoPetMessage),
                    systemName: "sparkles"
                )
            }
        }
    }
}

private struct LifePrintGeneratorSection: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: localization.language.localeIdentifier)
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(localization.text(.lifePrintResultTitle))
                        .font(.headline)
                        .foregroundStyle(EchoTheme.text)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(EchoTheme.secondaryText)
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.generateLifePrint(language: localization.language)
                    }
                } label: {
                    if viewModel.isGeneratingLifePrint {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                    }
                }
                .disabled(viewModel.isGeneratingLifePrint)
                .accessibilityLabel(viewModel.lifePrint == nil ? localization.text(.lifePrintGenerateAccessibility) : localization.text(.lifePrintRegenerateAccessibility))
            }

            if viewModel.isGeneratingLifePrint {
                Text(localization.text(.lifePrintStatusGenerating))
                    .font(.subheadline)
                    .foregroundStyle(EchoTheme.secondaryText)
            } else if let error = viewModel.lifePrintError {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            } else if let lifePrint = viewModel.lifePrint {
                Text(lifePrint.summary)
                    .font(.body)
                    .foregroundStyle(EchoTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(localization.text(.lifePrintStatusEmpty))
                    .font(.subheadline)
                    .foregroundStyle(EchoTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .echoCard()
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        guard let lifePrint = viewModel.lifePrint else {
            return localization.text(.lifePrintStatusNotGenerated)
        }
        return localization.text(.lifePrintStatusUpdatedAt, dateFormatter.string(from: lifePrint.updatedAt))
    }
}
