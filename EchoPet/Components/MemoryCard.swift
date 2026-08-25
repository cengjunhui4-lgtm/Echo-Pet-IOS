import SwiftUI

struct MemoryCard: View {
    let capsule: MemoryCapsule

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: capsule.accentSystemName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(EchoTheme.primary)
                    .frame(width: 34, height: 34)
                    .background(EchoTheme.softPrimary)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(capsule.title)
                        .font(.headline)
                        .foregroundStyle(EchoTheme.text)
                    Text(capsule.dateLabel)
                        .font(.caption)
                        .foregroundStyle(EchoTheme.secondaryText)
                }
            }

            Text(capsule.body)
                .font(.body)
                .foregroundStyle(EchoTheme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .echoCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(capsule.title)，\(capsule.dateLabel)，\(capsule.body)")
    }
}
