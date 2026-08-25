import SwiftUI

struct EmptyStateCard: View {
    let title: String
    let message: String
    let systemName: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        message: String,
        systemName: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemName = systemName
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(EchoTheme.primary)
                .frame(width: 48, height: 48)
                .background(EchoTheme.softPrimary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(EchoTheme.text)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(EchoTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(EchoTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .echoCard()
        .accessibilityElement(children: .combine)
    }
}
