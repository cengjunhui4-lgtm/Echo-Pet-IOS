import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 52)
            } else {
                PetAvatarView(profile: viewModel.pet, size: 34, lineWidth: 1)
                    .padding(.top, 2)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(message.isUser ? Color.white : EchoTheme.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(message.isUser ? EchoTheme.primary : EchoTheme.softPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))

                if isAIMessage {
                    Label(localization.text(.companionAIStamp), systemImage: "sparkles")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(EchoTheme.secondaryText)
                        .padding(.leading, 4)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(message.isUser ? localization.text(.companionUserAccessibility, message.text) : localization.text(.companionEchoAccessibility, message.text))

            if !message.isUser {
                Spacer(minLength: 44)
            }
        }
    }

    private var isAIMessage: Bool {
        message.isAIGenerated ?? !message.isUser
    }
}
