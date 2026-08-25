import SwiftUI
import UIKit

enum PetAvatarImageStore {
    private static let dataURLPrefix = "data:image/jpeg;base64,"

    static func image(from profile: PetProfile?) -> UIImage? {
        image(fromAvatarAssetID: profile?.avatarAssetID)
    }

    static func image(fromAvatarAssetID avatarAssetID: String?) -> UIImage? {
        guard let avatarAssetID, !avatarAssetID.isEmpty else {
            return nil
        }

        let base64Payload: String
        if avatarAssetID.hasPrefix(dataURLPrefix) {
            base64Payload = String(avatarAssetID.dropFirst(dataURLPrefix.count))
        } else {
            base64Payload = avatarAssetID
        }

        guard let data = Data(base64Encoded: base64Payload) else {
            return nil
        }

        return UIImage(data: data)
    }

    static func encodedDataURL(
        from image: UIImage,
        maxPixelSize: CGFloat = 512,
        compressionQuality: CGFloat = 0.74
    ) -> String? {
        let normalized = image.normalizedUpOrientation()
        let resized = normalized.resizedForAvatar(maxPixelSize: maxPixelSize)
        guard let data = resized.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        return dataURLPrefix + data.base64EncodedString()
    }
}

struct PetAvatarView: View {
    let profile: PetProfile?
    var size: CGFloat = 52
    var lineWidth: CGFloat = 1
    var showsShadow = true

    var body: some View {
        ZStack {
            if let image = PetAvatarImageStore.image(from: profile) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(EchoTheme.softPrimary)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: max(size * 0.42, 14), weight: .semibold))
                        .foregroundStyle(EchoTheme.primary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.66), lineWidth: lineWidth)
        )
        .shadow(color: Color.black.opacity(showsShadow ? 0.12 : 0), radius: showsShadow ? 10 : 0, x: 0, y: 5)
        .accessibilityHidden(true)
    }
}

struct PetCard: View {
    let profile: PetProfile
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                PetAvatarView(profile: profile, size: 76)

                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.name)
                        .font(.title2.bold())
                        .foregroundStyle(EchoTheme.text)
                    Text("\(profile.breed) · \(profile.age)")
                        .font(.subheadline)
                        .foregroundStyle(EchoTheme.secondaryText)
                        .lineLimit(2)
                }
            }

            Text(profile.personality)
                .font(.body)
                .foregroundStyle(EchoTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                PetTraitPill(text: profile.mbti)
                PetTraitPill(text: localization.text(.lifePrintTitle))
            }
        }
        .echoCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.name)，\(profile.breed)，\(profile.age)，\(profile.personality)")
    }
}

private extension UIImage {
    func normalizedUpOrientation() -> UIImage {
        guard imageOrientation != .up else {
            return self
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func resizedForAvatar(maxPixelSize: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxPixelSize else {
            return self
        }

        let scale = maxPixelSize / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

private struct PetTraitPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(EchoTheme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(EchoTheme.softPrimary)
            .clipShape(Capsule())
    }
}
