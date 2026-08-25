import SwiftUI
import UIKit

struct EchoCompanionView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.hasPetProfile {
                messagesView
                inputBar
            } else {
                EchoPage(title: localization.text(.companionTitle), subtitle: localization.text(.companionNoPetSubtitle)) {
                    EmptyStateCard(
                        title: localization.text(.companionNoPetTitle),
                        message: localization.text(.companionNoPetMessage),
                        systemName: "message.fill"
                    )
                }
            }
        }
        .background {
            ZStack {
                EchoBackgroundView()
                EchoTheme.pageBackdrop
            }
            .ignoresSafeArea()
        }
        .navigationTitle(localization.text(.companionTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(localization.text(.commonDone)) {
                    dismissKeyboard()
                }
            }
        }
        .onDisappear {
            dismissKeyboard()
        }
    }

    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                companionConnectionPill

                ForEach(viewModel.messages) { message in
                    ChatBubble(message: message)
                }

                if viewModel.isSendingMessage {
                    HStack {
                        ProgressView()
                        Text(localization.text(.companionResponding))
                            .font(.subheadline)
                            .foregroundStyle(EchoTheme.secondaryText)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(EchoTheme.softPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                    .accessibilityElement(children: .combine)
                }

                if let error = viewModel.messageError {
                    Button {
                        Task {
                            await viewModel.retryLastFailedMessage(language: localization.language)
                        }
                    } label: {
                        Label(error, systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(EchoTheme.pagePadding)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
    }

    private var companionConnectionPill: some View {
        HStack(spacing: 8) {
            Image(systemName: companionConnectionIcon)
                .font(.caption.weight(.bold))
            Text(companionConnectionText)
                .font(.caption.weight(.semibold))
            Spacer(minLength: 0)
        }
        .foregroundStyle(companionConnectionColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(EchoTheme.divider)

            HStack(spacing: 12) {
                TextField(localization.text(.companionInputPlaceholder), text: $viewModel.draftMessage, axis: .vertical)
                    .lineLimit(1...3)
                    .focused($isInputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(EchoTheme.softPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                    .disabled(viewModel.isSendingMessage)

                Button {
                    Task {
                        await viewModel.sendDraftMessage(language: localization.language)
                    }
                } label: {
                    Image(systemName: viewModel.isSendingMessage ? "hourglass" : "paperplane.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(width: 44, height: 44)
                        .background(sendButtonColor)
                        .clipShape(Circle())
                }
                .disabled(isDraftEmpty || viewModel.isSendingMessage)
                .accessibilityLabel(localization.text(.companionSendAccessibility))
            }
            .padding(EchoTheme.pagePadding)
            .background(EchoTheme.background)
        }
    }

    private var isDraftEmpty: Bool {
        viewModel.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var sendButtonColor: Color {
        isDraftEmpty || viewModel.isSendingMessage ? EchoTheme.secondaryText.opacity(0.45) : EchoTheme.primary
    }

    private func dismissKeyboard() {
        isInputFocused = false
        UIApplication.shared.echoDismissKeyboard()
    }

    private var companionConnectionText: String {
        switch viewModel.companionConnectionState {
        case .backendConnected:
            return localization.text(.companionConnectionBackend)
        case .localOnly:
            return localization.text(.companionConnectionLocal)
        case .backendUnavailable:
            return localization.text(.companionConnectionFallback)
        }
    }

    private var companionConnectionIcon: String {
        switch viewModel.companionConnectionState {
        case .backendConnected:
            return "checkmark.icloud.fill"
        case .localOnly:
            return "iphone"
        case .backendUnavailable:
            return "exclamationmark.triangle.fill"
        }
    }

    private var companionConnectionColor: Color {
        switch viewModel.companionConnectionState {
        case .backendConnected:
            return EchoTheme.success
        case .localOnly:
            return EchoTheme.secondaryText
        case .backendUnavailable:
            return EchoTheme.warning
        }
    }
}
