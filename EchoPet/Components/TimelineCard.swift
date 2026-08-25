import SwiftUI
import UIKit

struct TimelineCard: View {
    let memory: TimelineMemory
    var onOpen: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    @EnvironmentObject private var localization: LocalizationManager

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: localization.language.localeIdentifier)
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let onOpen {
                Button(action: onOpen) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }

            if hasActions {
                Divider()
                    .padding(.vertical, 14)

                HStack(spacing: 10) {
                    Spacer()

                    if let onEdit {
                        Button(action: onEdit) {
                            Label(localization.text(.commonEdit), systemImage: "pencil")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(TimelineCardActionButtonStyle())
                        .accessibilityLabel(localization.text(.timelineEditAccessibility))
                    }

                    if let onDelete {
                        Button(role: .destructive, action: onDelete) {
                            Label(localization.text(.commonDelete), systemImage: "trash")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(TimelineCardActionButtonStyle(isDestructive: true))
                        .accessibilityLabel(localization.text(.timelineDeleteAccessibility))
                    }
                }
            }
        }
        .echoCard()
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if memory.mediaAssets.isEmpty {
                HStack(alignment: .top, spacing: 16) {
                    fallbackIcon
                    textContent
                }
            } else {
                TimelinePhotoStack(assets: memory.mediaAssets, fallbackSystemName: memory.imageSystemName)
                    .frame(height: 156)

                textContent
            }
        }
        .accessibilityLabel("\(dateFormatter.string(from: memory.date))，\(memory.title)，\(memory.story)")
    }

    private var hasActions: Bool {
        onEdit != nil || onDelete != nil
    }

    private var fallbackIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous)
                .fill(EchoTheme.softPrimary)
            Image(systemName: memory.imageSystemName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(EchoTheme.primary)
        }
        .frame(width: 56, height: 56)
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dateFormatter.string(from: memory.date))
                .font(.caption.weight(.semibold))
                .foregroundStyle(EchoTheme.secondaryText)
            Text(memory.title)
                .font(.headline)
                .foregroundStyle(EchoTheme.text)
            Text(memory.story)
                .font(.subheadline)
                .foregroundStyle(EchoTheme.secondaryText)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct TimelineCardActionButtonStyle: ButtonStyle {
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isDestructive ? Color.red : EchoTheme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background((isDestructive ? Color.red : EchoTheme.primary).opacity(configuration.isPressed ? 0.22 : 0.14))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

struct TimelinePhotoStack: View {
    let assets: [MediaAsset]
    let fallbackSystemName: String
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if assets.isEmpty {
                fallback
            } else {
                ForEach(Array(assets.prefix(3).enumerated()), id: \.element.id) { index, asset in
                    TimelinePhotoImage(asset: asset)
                        .frame(maxWidth: .infinity)
                        .frame(height: 138)
                        .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous)
                                .stroke(Color.white.opacity(0.9), lineWidth: 3)
                        )
                        .rotationEffect(rotation(for: index))
                        .offset(x: offset(for: index).width, y: offset(for: index).height)
                        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
                }

                if assets.count > 1 {
                    Text(localization.text(.timelinePhotoCountBadge, assets.count))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                        .padding(10)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }

    private var fallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous)
                .fill(EchoTheme.softPrimary)
            Image(systemName: fallbackSystemName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(EchoTheme.primary)
        }
    }

    private func rotation(for index: Int) -> Angle {
        switch index {
        case 0:
            return .degrees(-4)
        case 1:
            return .degrees(3)
        default:
            return .degrees(0)
        }
    }

    private func offset(for index: Int) -> CGSize {
        switch index {
        case 0:
            return CGSize(width: -7, height: 6)
        case 1:
            return CGSize(width: 7, height: -2)
        default:
            return CGSize(width: 0, height: -8)
        }
    }
}

struct TimelinePhotoImage: View {
    let asset: MediaAsset

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    EchoTheme.softPrimary
                    Image(systemName: "photo")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(EchoTheme.primary)
                }
            }
        }
        .clipped()
    }

    private var image: UIImage? {
        guard
            let url = LocalMediaStore.shared.fileURL(for: asset),
            FileManager.default.fileExists(atPath: url.path)
        else {
            return nil
        }

        return UIImage(contentsOfFile: url.path)
    }
}
