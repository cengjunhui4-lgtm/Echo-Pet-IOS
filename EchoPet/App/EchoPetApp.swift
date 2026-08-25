import SwiftUI
import UIKit

@main
struct EchoPetApp: App {
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var localization = LocalizationManager()
    @State private var passwordResetRequest: PasswordResetRequest?

    var body: some Scene {
        WindowGroup {
            ZStack {
                EchoBackgroundView()
                RootTabView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
                .environmentObject(homeViewModel)
                .environmentObject(localization)
                .environment(\.locale, Locale(identifier: localization.language.localeIdentifier))
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    passwordResetRequest = PasswordResetRequest(url: url)
                }
                .sheet(item: $passwordResetRequest) { request in
                    PasswordResetView(request: request)
                        .environmentObject(homeViewModel)
                        .environmentObject(localization)
                }
        }
    }
}

private struct PasswordResetRequest: Identifiable {
    let id = UUID()
    let accessToken: String?

    init?(url: URL) {
        guard
            url.scheme == "echopet",
            url.host == "auth",
            url.path == "/reset-password"
        else {
            return nil
        }

        let values = Self.values(from: url.query)
            .merging(Self.values(from: url.fragment)) { current, _ in current }
        accessToken = values["access_token"]
    }

    private static func values(from string: String?) -> [String: String] {
        guard let string, !string.isEmpty else {
            return [:]
        }

        var components = URLComponents()
        components.percentEncodedQuery = string
        return Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
                guard let value = item.value else {
                    return nil
                }
                return (item.name, value)
            }
        )
    }
}

private struct PasswordResetView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    let request: PasswordResetRequest

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var statusMessage: String?
    @State private var didSucceed = false

    private var canSubmit: Bool {
        request.accessToken != nil && !isSubmitting && !didSucceed
    }

    var body: some View {
        NavigationStack {
            ZStack {
                EchoBackgroundView()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Label(localization.text(.passwordResetTitle), systemImage: "lock.rotation")
                            .font(.title2.bold())
                            .foregroundStyle(EchoTheme.text)

                        Text(localization.text(.passwordResetMessage))
                            .font(.body)
                            .foregroundStyle(EchoTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        if request.accessToken == nil {
                            Label(localization.text(.passwordResetFailed), systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(EchoTheme.warning)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            SecureField(localization.text(.passwordResetNewPassword), text: $newPassword)
                                .textContentType(.newPassword)
                                .submitLabel(.next)
                                .foregroundStyle(EchoTheme.text)
                                .padding(.horizontal, 12)
                                .frame(height: 46)
                                .background(Color.white.opacity(0.72))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            SecureField(localization.text(.passwordResetConfirmPassword), text: $confirmPassword)
                                .textContentType(.newPassword)
                                .submitLabel(.done)
                                .onSubmit(updatePassword)
                                .foregroundStyle(EchoTheme.text)
                                .padding(.horizontal, 12)
                                .frame(height: 46)
                                .background(Color.white.opacity(0.72))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            Button {
                                updatePassword()
                            } label: {
                                Label(localization.text(.passwordResetSubmit), systemImage: "checkmark.seal.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(EchoTheme.primary)
                            .disabled(!canSubmit)
                        }

                        if isSubmitting {
                            Label(localization.text(.accountGateSigningIn), systemImage: "arrow.triangle.2.circlepath")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(EchoTheme.secondaryText)
                        }

                        if let statusMessage {
                            Label(statusMessage, systemImage: didSucceed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(didSucceed ? EchoTheme.success : EchoTheme.warning)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(20)
                    .background(EchoTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: EchoTheme.cardRadius, style: .continuous))
                    .padding(EchoTheme.pagePadding)
                }
            }
            .navigationTitle(localization.text(.passwordResetTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.text(didSucceed ? .commonDone : .commonCancel)) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func updatePassword() {
        guard !isSubmitting, !didSucceed, let accessToken = request.accessToken else {
            return
        }

        guard newPassword.count >= 6 else {
            statusMessage = localization.text(.passwordResetTooShort)
            didSucceed = false
            return
        }

        guard newPassword == confirmPassword else {
            statusMessage = localization.text(.passwordResetMismatch)
            didSucceed = false
            return
        }

        UIApplication.shared.echoDismissKeyboard()
        isSubmitting = true
        statusMessage = nil

        Task {
            let success = await viewModel.updatePassword(
                accessToken: accessToken,
                newPassword: newPassword,
                language: localization.language
            )
            isSubmitting = false
            didSucceed = success
            statusMessage = localization.text(success ? .passwordResetSuccess : .passwordResetFailed)
        }
    }
}

struct EchoBackgroundView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @State private var cycleIndex = 0
    @State private var sessionSeed = Int.random(in: 0...Int.max)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                EchoTheme.background

                if let image = activeBackgroundImage, let photo = activePhoto {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .scaleEffect(1.08)
                        .clipped()
                        .blur(radius: CGFloat(viewModel.backgroundAlbum.blurRadius), opaque: true)
                        .opacity(0.88)
                        .id(photo.id)
                        .transition(.opacity)
                }

                if activeBackgroundImage == nil {
                    EchoTheme.background
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 2.8), value: activePhoto?.id)
        .task(id: viewModel.backgroundAlbum.displayMode) {
            await runGentleCycle()
        }
    }

    private var activePhoto: BackgroundAlbumPhoto? {
        viewModel.activeBackgroundPhoto(
            cycleIndex: cycleIndex,
            sessionSeed: sessionSeed
        )
    }

    private var activeBackgroundImage: UIImage? {
        guard
            let activePhoto,
            let fileURL = viewModel.backgroundFileURL(for: activePhoto.asset)
        else {
            return nil
        }

        return UIImage(contentsOfFile: fileURL.path)
    }

    private func runGentleCycle() async {
        guard viewModel.backgroundAlbum.displayMode == .gentleCycle else {
            return
        }

        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 60_000_000_000)

            guard
                viewModel.backgroundAlbum.displayMode == .gentleCycle,
                viewModel.backgroundAlbum.photos.count > 1
            else {
                continue
            }

            withAnimation(.easeInOut(duration: 2.8)) {
                cycleIndex += 1
            }
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @State private var selectedTab: RootTab = .home
    @AppStorage("echoPet.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var onboardingPhase: OnboardingPhase = .brandIntro

#if DEBUG
    @State private var hasAppliedDebugPreviewSeed = false
#endif

    init() {
        Self.configureTabBarAppearance()
    }

    var body: some View {
        Group {
            switch currentPhase {
            case .brandIntro:
                BrandIntroView {
                    advanceOnboarding()
                }

            case .petOnboarding:
                FirstPetOnboardingView {
                    advanceOnboarding()
                }

            case .accountGate:
                AccountGateView {
                    completeOnboarding()
                }

            case .main:
                mainTabView
            }
        }
#if DEBUG
        .onAppear {
            applyDebugPreviewSeedIfNeeded()
        }
#endif
    }

    private var currentPhase: OnboardingPhase {
        if hasCompletedOnboarding {
            return .main
        }

        switch onboardingPhase {
        case .brandIntro:
            return .brandIntro
        case .petOnboarding:
            return viewModel.hasPetProfile ? .accountGate : .petOnboarding
        case .accountGate:
            return .accountGate
        case .main:
            return .main
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(localization.text(.tabHome), systemImage: "house.fill")
                }
                .tag(RootTab.home)

            NavigationStack {
                LifeTimelineView()
            }
            .tabItem {
                Label(localization.text(.tabTimeline), systemImage: "clock.fill")
            }
            .tag(RootTab.timeline)

            NavigationStack {
                EchoCompanionView()
            }
            .tabItem {
                Label(localization.text(.tabCompanion), systemImage: "message.fill")
            }
            .tag(RootTab.companion)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label(localization.text(.tabProfile), systemImage: "person.crop.circle.fill")
            }
            .tag(RootTab.profile)
        }
        .tint(EchoTheme.primary)
        .gesture(pageSwipeGesture)
        .onChange(of: selectedTab) { _, _ in
            UIApplication.shared.echoDismissKeyboard()
        }
    }

    private func advanceOnboarding() {
        switch onboardingPhase {
        case .brandIntro:
            onboardingPhase = .petOnboarding
        case .petOnboarding:
            onboardingPhase = .accountGate
        case .accountGate, .main:
            break
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        onboardingPhase = .main
    }

    private static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        appearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private var pageSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 54, coordinateSpace: .local)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > 72, abs(horizontal) > abs(vertical) * 1.55 else {
                    return
                }

                withAnimation(.easeInOut(duration: 0.2)) {
                    moveTab(by: horizontal < 0 ? 1 : -1)
                }
            }
    }

    private func moveTab(by step: Int) {
        let tabs = RootTab.allCases
        guard let currentIndex = tabs.firstIndex(of: selectedTab) else {
            return
        }

        let nextIndex = min(max(currentIndex + step, 0), tabs.count - 1)
        guard nextIndex != currentIndex else {
            return
        }

        selectedTab = tabs[nextIndex]
    }

#if DEBUG
    private func applyDebugPreviewSeedIfNeeded() {
        guard !hasAppliedDebugPreviewSeed else { return }

        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-EchoPetLoadDemoData") else { return }

        hasAppliedDebugPreviewSeed = true
        let language = debugPreviewLanguage(from: arguments) ?? localization.language
        let shouldPreviewSignedOut = arguments.contains("-EchoPetPreviewSignedOut")
        localization.setLanguage(language)
        viewModel.loadDemoData(language: language, syncToCloud: !shouldPreviewSignedOut)
        if shouldPreviewSignedOut {
            viewModel.clearAccountForDebugPreview()
        }
        selectedTab = debugPreviewTab(from: arguments) ?? selectedTab

        if let companionMessage = debugPreviewCompanionMessage(from: arguments) {
            viewModel.draftMessage = companionMessage
            Task {
                await viewModel.sendDraftMessage(language: language)
            }
        }
    }

    private func debugPreviewLanguage(from arguments: [String]) -> AppLanguage? {
        guard
            let keyIndex = arguments.firstIndex(of: "-EchoPetPreviewLanguage"),
            arguments.indices.contains(keyIndex + 1)
        else {
            return nil
        }

        return AppLanguage(rawValue: arguments[keyIndex + 1])
    }

    private func debugPreviewTab(from arguments: [String]) -> RootTab? {
        guard
            let keyIndex = arguments.firstIndex(of: "-EchoPetPreviewTab"),
            arguments.indices.contains(keyIndex + 1)
        else {
            return nil
        }

        let rawValue = arguments[keyIndex + 1]
        if rawValue == "lifePrint" {
            return .profile
        }
        return RootTab(rawValue: rawValue)
    }

    private func debugPreviewCompanionMessage(from arguments: [String]) -> String? {
        guard
            let keyIndex = arguments.firstIndex(of: "-EchoPetPreviewCompanionMessage"),
            arguments.indices.contains(keyIndex + 1)
        else {
            return nil
        }

        return arguments[keyIndex + 1]
    }
#endif
}

private enum RootTab: String, CaseIterable {
    case home
    case timeline
    case companion
    case profile
}

private enum OnboardingPhase {
    case brandIntro
    case petOnboarding
    case accountGate
    case main
}

extension UIApplication {
    func echoDismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct FirstPetOnboardingView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @State private var showingProfileForm = false
    let onPetCreated: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 18)

                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(EchoTheme.primary)
                        .frame(width: 64, height: 64)
                        .background(EchoTheme.softPrimary)
                        .clipShape(Circle())

                    Text(localization.text(.onboardingTitle))
                        .font(.largeTitle.bold())
                        .foregroundStyle(EchoTheme.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(localization.text(.onboardingMessage))
                        .font(.body)
                        .foregroundStyle(EchoTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    OnboardingStep(number: "1", title: localization.text(.onboardingStep1Title), subtitle: localization.text(.onboardingStep1Subtitle))
                    OnboardingStep(number: "2", title: localization.text(.onboardingStep2Title), subtitle: localization.text(.onboardingStep2Subtitle))
                    OnboardingStep(number: "3", title: localization.text(.onboardingStep3Title), subtitle: localization.text(.onboardingStep3Subtitle))
                }
                .echoCard()

                Spacer()

                Button {
                    showingProfileForm = true
                } label: {
                    Label(localization.text(.onboardingCreatePet), systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(EchoTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(EchoTheme.pagePadding)
            .background {
                ZStack {
                    EchoBackgroundView()
                    EchoTheme.pageBackdrop
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingProfileForm) {
                PetProfileFormView(profile: nil) { profile in
                    viewModel.savePetProfile(profile, language: localization.language)
                    onPetCreated()
                }
            }
        }
    }
}

private struct BrandIntroView: View {
    @EnvironmentObject private var localization: LocalizationManager
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Image("EchoPetOnboardingHero")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack {
                Spacer()

                Button {
                    onContinue()
                } label: {
                    Text(localization.text(.brandIntroStart))
                        .font(.headline)
                        .foregroundStyle(EchoTheme.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.82))
                        .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous)
                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, EchoTheme.pagePadding)
            .padding(.bottom, 34)
        }
    }
}

private struct AccountGateView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager
    let onContinue: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var verificationCode = ""
    @State private var isShowingSignupVerification = false
    @State private var showingEmailVerificationReminder = false

    private var canSubmitEmailAuth: Bool {
        email.contains("@") && password.count >= 6
    }

    private var canSubmitSignupVerification: Bool {
        email.contains("@") && !verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            EchoBackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 24)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localization.text(.accountGateTitle))
                            .font(.largeTitle.bold())
                            .foregroundStyle(EchoTheme.text)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(localization.text(.accountGateMessage))
                            .font(.body)
                            .foregroundStyle(EchoTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label(localization.text(.accountGateEmailTitle), systemImage: "envelope.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(EchoTheme.text)

                        TextField(localization.text(.accountGateEmailPlaceholder), text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .foregroundStyle(EchoTheme.text)
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(Color.white.opacity(0.72))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        SecureField(localization.text(.accountGatePasswordPlaceholder), text: $password)
                            .textContentType(.password)
                            .submitLabel(.done)
                            .onSubmit(signInIfValid)
                            .foregroundStyle(EchoTheme.text)
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(Color.white.opacity(0.72))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        HStack(spacing: 10) {
                            Button {
                                signInIfValid()
                            } label: {
                                Label(localization.text(.accountGateSignIn), systemImage: "envelope.open.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(EchoTheme.primary)
                            .disabled(viewModel.isSigningInAccount)

                            Button {
                                signUpIfValid()
                            } label: {
                                Label(localization.text(.accountGateSignUp), systemImage: "person.crop.circle.badge.plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(EchoTheme.primary)
                            .disabled(viewModel.isSigningInAccount)
                        }
                        .font(.subheadline.weight(.semibold))
                        .contentShape(Rectangle())

                        if isShowingSignupVerification {
                            signupVerificationForm
                        }

                        if !canSubmitEmailAuth, !email.isEmpty || !password.isEmpty {
                            Text(localization.text(.accountGateAuthHint))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(EchoTheme.warning)
                        }

                        Button {
                            UIApplication.shared.echoDismissKeyboard()
                            Task {
                                await viewModel.resetPassword(
                                    email: email,
                                    language: localization.language
                                )
                            }
                        } label: {
                            Text(localization.text(.accountGateForgotPassword))
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.plain)
                        .tint(EchoTheme.primary)
                        .disabled(!email.contains("@") || viewModel.isSigningInAccount)
                    }
                    .padding(16)
                    .background(EchoTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: EchoTheme.cardRadius, style: .continuous))

                    VStack(spacing: 12) {
                        Button {
                            UIApplication.shared.echoDismissKeyboard()
                            Task {
                                await viewModel.continueAsGuest(language: localization.language)
                            }
                        } label: {
                            Label(localization.text(.accountGateContinueGuest), systemImage: "person.crop.circle.badge.clock")
                                .font(.headline)
                                .foregroundStyle(EchoTheme.text)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(EchoTheme.softPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: EchoTheme.controlRadius, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSigningInAccount)

                        if viewModel.isSigningInAccount {
                            Label(localization.text(.accountGateSigningIn), systemImage: "arrow.triangle.2.circlepath")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(EchoTheme.secondaryText)
                        }

                        if let accountMessage = viewModel.accountMessage {
                            Label(accountMessage, systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(EchoTheme.success)
                        }

                        if let accountError = viewModel.accountError {
                            Label(accountError, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(EchoTheme.warning)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(EchoTheme.pagePadding)
            }
        }
        .onChange(of: viewModel.accountSession) { _, newValue in
            if newValue != nil {
                onContinue()
            }
        }
        .alert(localization.text(.profileAccountVerificationAlertTitle), isPresented: $showingEmailVerificationReminder) {
            Button(localization.text(.commonOK), role: .cancel) {}
        } message: {
            Text(localization.text(.profileAccountVerificationAlertMessage))
        }
    }

    private func signInIfValid() {
        guard canSubmitEmailAuth else {
            viewModel.accountError = localization.text(.accountGateAuthHint)
            return
        }
        UIApplication.shared.echoDismissKeyboard()
        isShowingSignupVerification = false
        Task {
            await viewModel.signInWithEmail(
                email: email,
                password: password,
                language: localization.language
            )
        }
    }

    private func signUpIfValid() {
        guard canSubmitEmailAuth else {
            viewModel.accountError = localization.text(.accountGateAuthHint)
            return
        }
        UIApplication.shared.echoDismissKeyboard()
        Task {
            let shouldShowVerification = await viewModel.signUpWithEmail(
                email: email,
                password: password,
                language: localization.language
            )
            if shouldShowVerification && viewModel.accountSession == nil {
                isShowingSignupVerification = true
                showingEmailVerificationReminder = true
            } else {
                isShowingSignupVerification = false
            }
        }
    }

    private var signupVerificationForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(localization.text(.profileAccountVerificationCodeTitle), systemImage: "number.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(EchoTheme.text)

            TextField(localization.text(.profileAccountVerificationCodePlaceholder), text: $verificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(EchoTheme.text)
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                verifySignupCodeIfValid()
            } label: {
                Label(localization.text(.profileAccountVerificationCodeSubmit), systemImage: "checkmark.seal.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(EchoTheme.primary)
            .font(.subheadline.weight(.semibold))
            .disabled(!canSubmitSignupVerification || viewModel.isSigningInAccount)
        }
        .padding(10)
        .background(Color.white.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func verifySignupCodeIfValid() {
        guard canSubmitSignupVerification else {
            viewModel.accountError = localization.text(.profileAccountVerificationCodeRequired)
            return
        }
        UIApplication.shared.echoDismissKeyboard()
        Task {
            await viewModel.verifyEmailSignupCode(
                email: email,
                code: verificationCode,
                language: localization.language
            )
            if viewModel.accountSession != nil {
                verificationCode = ""
                isShowingSignupVerification = false
            }
        }
    }
}

private struct OnboardingStep: View {
    let number: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(EchoTheme.accent)
                .frame(width: 28, height: 28)
                .background(EchoTheme.softPrimary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(EchoTheme.text)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(EchoTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}
