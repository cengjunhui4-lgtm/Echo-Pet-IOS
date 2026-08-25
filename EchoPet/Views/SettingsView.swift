import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @StateObject private var permissionService = MediaPermissionService()
    @State private var showingSignOutConfirmation = false
    @State private var showingDeleteAccountConfirmation = false
    @State private var showingClearChatConfirmation = false
    @State private var showingDeleteAllConfirmation = false
    @State private var showingLoadDemoConfirmation = false
    @State private var showingEmailVerificationReminder = false
    @State private var accountEmail = ""
    @State private var accountPassword = ""
    @State private var accountVerificationCode = ""
    @State private var isShowingSignupVerification = false
    @State private var isShowingPasswordResetForm = false
    @State private var passwordResetCode = ""
    @State private var passwordResetNewPassword = ""
    @State private var passwordResetConfirmPassword = ""

    var body: some View {
        EchoPage(title: localization.text(.settingsTitle), subtitle: localization.text(.settingsSubtitle)) {
            VStack(alignment: .leading, spacing: 16) {
                accountCard
                syncStatusCard
                privacyAndAITransparencyCard
                mediaPermissionCard
                languageCard
                SettingsCard(title: localization.text(.settingsPrivacyTitle), systemName: "lock.fill") {
                    Text(localization.text(.settingsPrivacyMessage1))
                    Text(localization.text(.settingsPrivacyMessage2))
                    NavigationLink {
                        LegalDocumentView(kind: .privacy)
                    } label: {
                        Label(localization.text(.settingsViewFullPolicy), systemImage: "chevron.right")
                    }
                    .buttonStyle(.bordered)
                }

                SettingsCard(title: localization.text(.settingsTermsTitle), systemName: "doc.plaintext.fill") {
                    Text(localization.text(.settingsTermsMessage1))
                    Text(localization.text(.settingsTermsMessage2))
                    NavigationLink {
                        LegalDocumentView(kind: .terms)
                    } label: {
                        Label(localization.text(.settingsViewFullTerms), systemImage: "chevron.right")
                    }
                    .buttonStyle(.bordered)
                }

                SettingsCard(title: localization.text(.settingsDataTitle), systemName: "externaldrive.fill") {
                    Button(localization.text(.settingsDataClearChat)) {
                        showingClearChatConfirmation = true
                    }
                    .disabled(!viewModel.hasPetProfile)

                    Text(localization.text(.settingsDataCloudMessage))

                    if viewModel.isDeletingAccountData {
                        Label(localization.text(.settingsDataDeleteInProgress), systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(EchoTheme.secondaryText)
                    }

                    if let dataDeletionError = viewModel.dataDeletionError {
                        Label(dataDeletionError, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(EchoTheme.warning)
                    }

#if DEBUG
                    Text(localization.text(.settingsDataDemoMessage))

                    Button(localization.text(.settingsDataLoadDemo)) {
                        showingLoadDemoConfirmation = true
                    }
#endif

                    Button(deleteDataTitle, role: .destructive) {
                        showingDeleteAllConfirmation = true
                    }
                    .disabled(viewModel.isDeletingAccountData)
                }

                SettingsCard(title: localization.text(.settingsAITitle), systemName: "sparkles") {
                    Text(localization.text(.settingsAIMessage))
                    Toggle(isOn: aiMemoryContextSelection) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(localization.text(.settingsAIMemoryToggleTitle))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(EchoTheme.text)
                            Text(localization.text(.settingsAIMemoryToggleMessage))
                                .font(.caption)
                                .foregroundStyle(EchoTheme.secondaryText)
                        }
                    }
                    .tint(EchoTheme.primary)

                    Text(localization.text(.settingsAIToneCurrent))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(EchoTheme.text)

                    Text(EchoAIContent.companionDisclaimer(language: localization.language))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(EchoTheme.text)
                }

                SettingsCard(title: localization.text(.settingsVersionTitle), systemName: "info.circle.fill") {
                    Text(localization.text(.settingsVersionName))
                    Text(localization.text(.settingsVersionStage))
                }
            }
        }
        .confirmationDialog(localization.text(.profileAccountSignOutDialog), isPresented: $showingSignOutConfirmation, titleVisibility: .visible) {
            Button(localization.text(.profileAccountSignOut), role: .destructive) {
                viewModel.signOutAccount()
            }
            Button(localization.text(.commonCancel), role: .cancel) {}
        }
        .confirmationDialog(deleteDataDialogTitle, isPresented: $showingDeleteAccountConfirmation, titleVisibility: .visible) {
            Button(deleteDataTitle, role: .destructive) {
                Task {
                    await viewModel.deleteAccountAndContent(language: localization.language)
                }
            }
            Button(localization.text(.commonCancel), role: .cancel) {}
        }
        .confirmationDialog(localization.text(.settingsClearChatDialog), isPresented: $showingClearChatConfirmation, titleVisibility: .visible) {
            Button(localization.text(.commonClear), role: .destructive) {
                viewModel.clearMessages(language: localization.language)
            }
            Button(localization.text(.commonCancel), role: .cancel) {}
        }
        .confirmationDialog(localization.text(.settingsLoadDemoDialog), isPresented: $showingLoadDemoConfirmation, titleVisibility: .visible) {
            Button(localization.text(.settingsDataLoadDemo), role: .destructive) {
                viewModel.loadDemoData(language: localization.language)
            }
            Button(localization.text(.commonCancel), role: .cancel) {}
        }
        .confirmationDialog(deleteDataDialogTitle, isPresented: $showingDeleteAllConfirmation, titleVisibility: .visible) {
            Button(deleteDataTitle, role: .destructive) {
                Task {
                    await viewModel.deleteAccountAndContent(language: localization.language)
                }
            }
            Button(localization.text(.commonCancel), role: .cancel) {}
        }
        .alert(localization.text(.profileAccountVerificationAlertTitle), isPresented: $showingEmailVerificationReminder) {
            Button(localization.text(.commonOK), role: .cancel) {}
        } message: {
            Text(localization.text(.profileAccountVerificationAlertMessage))
        }
    }

    private var accountCard: some View {
        SettingsCard(title: localization.text(.profileAccountTitle), systemName: "person.crop.circle.fill") {
            accountContent
        }
    }

    @ViewBuilder
    private var accountContent: some View {
        if let session = viewModel.accountSession {
            Text(localization.text(.profileAccountSignedIn, session.displayName))
                .foregroundStyle(EchoTheme.text)

            Label(accountBadgeText(for: session), systemImage: accountBadgeIcon(for: session))
                .font(.caption.weight(.semibold))
                .foregroundStyle(accountBadgeColor(for: session))

            if shouldShowEmailAuthUpgrade(for: session) {
                emailAuthForm
            }

            Button(role: .destructive) {
                showingSignOutConfirmation = true
            } label: {
                Label(localization.text(.profileAccountSignOut), systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Button(role: .destructive) {
                showingDeleteAccountConfirmation = true
            } label: {
                Label(deleteDataTitle, systemImage: "trash.fill")
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(viewModel.isDeletingAccountData)

            if viewModel.isDeletingAccountData {
                Label(localization.text(.settingsDataDeleteInProgress), systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(EchoTheme.secondaryText)
            }

            if let dataDeletionError = viewModel.dataDeletionError {
                Label(dataDeletionError, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(EchoTheme.warning)
            }
        } else {
            Text(localization.text(.profileAccountMessage))
            Text(localization.text(.profileAccountCloudMessage))
                .font(.caption)

            emailAuthForm

            Button {
                UIApplication.shared.echoDismissKeyboard()
                Task {
                    await viewModel.continueAsGuest(language: localization.language)
                }
            } label: {
                Label(localization.text(.profileAccountContinueGuest), systemImage: "person.crop.circle.badge.clock")
            }
            .buttonStyle(.borderedProminent)
            .tint(EchoTheme.primary)
            .disabled(viewModel.isSigningInAccount)

            if viewModel.isSigningInAccount {
                Label(localization.text(.profileAccountSigningIn), systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(EchoTheme.secondaryText)
            }

            if let accountError = viewModel.accountError {
                Label(accountError, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(EchoTheme.warning)
            }
        }

        Text(localization.text(.profileAccountStats, viewModel.hasPetProfile ? 1 : 0, viewModel.timeline.count, viewModel.capsules.count))
            .font(.caption.weight(.semibold))
            .foregroundStyle(EchoTheme.text)
    }

    private var emailAuthForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(localization.text(.profileAccountEmailTitle), systemImage: "envelope.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(EchoTheme.text)

            TextField(localization.text(.profileAccountEmailPlaceholder), text: $accountEmail)
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

            SecureField(localization.text(.profileAccountPasswordPlaceholder), text: $accountPassword)
                .textContentType(.password)
                .submitLabel(.done)
                .onSubmit { signInIfValid() }
                .foregroundStyle(EchoTheme.text)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(spacing: 10) {
                Button {
                    signInIfValid()
                } label: {
                    Label(localization.text(.profileAccountEmailSignIn), systemImage: "envelope.open.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(EchoTheme.primary)
                .disabled(viewModel.isSigningInAccount)

                Button {
                    signUpIfValid()
                } label: {
                    Label(localization.text(.profileAccountEmailSignUp), systemImage: "person.crop.circle.badge.plus")
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

            Button {
                sendPasswordResetIfValid()
            } label: {
                Text(localization.text(.profileAccountForgotPassword))
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.plain)
            .tint(EchoTheme.primary)
            .disabled(!accountEmail.contains("@") || viewModel.isSigningInAccount)

            if isShowingPasswordResetForm {
                passwordResetOTPForm
            }

            if let accountMessage = viewModel.accountMessage {
                Label(accountMessage, systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(EchoTheme.success)
            }

            Text(localization.text(.profileAccountEmailHint))
                .font(.caption)
                .foregroundStyle(EchoTheme.secondaryText)
        }
        .padding(12)
        .background(EchoTheme.softPrimary.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: EchoTheme.cardRadius, style: .continuous))
    }

    private var signupVerificationForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(localization.text(.profileAccountVerificationCodeTitle), systemImage: "number.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(EchoTheme.text)

            TextField(localization.text(.profileAccountVerificationCodePlaceholder), text: $accountVerificationCode)
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
            .disabled(accountVerificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSigningInAccount)
        }
        .padding(10)
        .background(Color.white.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var passwordResetOTPForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(localization.text(.profileAccountResetCodeTitle), systemImage: "lock.rotation")
                .font(.caption.weight(.semibold))
                .foregroundStyle(EchoTheme.text)

            Text(localization.text(.profileAccountResetCodeMessage))
                .font(.caption)
                .foregroundStyle(EchoTheme.secondaryText)

            TextField(localization.text(.profileAccountResetCodePlaceholder), text: $passwordResetCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(EchoTheme.text)
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            SecureField(localization.text(.passwordResetNewPassword), text: $passwordResetNewPassword)
                .textContentType(.newPassword)
                .foregroundStyle(EchoTheme.text)
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            SecureField(localization.text(.passwordResetConfirmPassword), text: $passwordResetConfirmPassword)
                .textContentType(.newPassword)
                .onSubmit { completePasswordResetIfValid() }
                .foregroundStyle(EchoTheme.text)
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                completePasswordResetIfValid()
            } label: {
                Label(localization.text(.profileAccountResetCodeSubmit), systemImage: "checkmark.seal.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(EchoTheme.primary)
            .font(.subheadline.weight(.semibold))
            .disabled(!canSubmitPasswordReset || viewModel.isSigningInAccount)
        }
        .padding(10)
        .background(Color.white.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var syncStatusCard: some View {
        let readiness = viewModel.syncReadiness

        return SettingsCard(title: localization.text(.profileSyncTitle), systemName: "arrow.triangle.2.circlepath.circle.fill") {
            Label(syncStatusTitle(for: readiness.state), systemImage: syncStatusIcon(for: readiness.state))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(readiness.state == .readyForBackend ? EchoTheme.success : EchoTheme.warning)

            Text(localization.text(.profileSyncMessage))

            Text(localization.text(.profileSyncQueuedChanges, readiness.queuedChangeCount))
                .font(.caption.weight(.semibold))
                .foregroundStyle(EchoTheme.text)

            if !readiness.activeDomains.isEmpty {
                Text(localization.text(.profileSyncDomains, syncDomainList(readiness.activeDomains)))
                    .font(.caption)
            }
        }
    }

    private var privacyAndAITransparencyCard: some View {
        SettingsCard(title: localization.text(.profilePrivacyTitle), systemName: "sparkles.rectangle.stack.fill") {
            Text(localization.text(.profilePrivacyMessage1))
            Text(localization.text(.profilePrivacyMessage2))
                .font(.caption.weight(.semibold))
                .foregroundStyle(EchoTheme.text)
        }
    }

    private var mediaPermissionCard: some View {
        SettingsCard(title: localization.text(.profilePermissionsTitle), systemName: "photo.on.rectangle") {
            ForEach(MediaPermissionKind.allCases) { kind in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: kind.systemName)
                        .font(.headline)
                        .foregroundStyle(EchoTheme.primary)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title(for: kind))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(EchoTheme.text)
                        Text(purpose(for: kind))
                            .font(.caption)
                            .foregroundStyle(EchoTheme.secondaryText)
                    }

                    Spacer(minLength: 8)

                    Button(title(for: permissionService.status(for: kind))) {
                        Task {
                            await permissionService.request(kind)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(EchoTheme.primary)
                    .disabled(permissionService.status(for: kind) == .authorized)
                }

                if kind != .microphone {
                    Divider()
                }
            }
        }
    }

    private var languageCard: some View {
        SettingsCard(title: localization.text(.settingsLanguageTitle), systemName: "globe") {
            Text(localization.text(.settingsLanguageMessage))
            Picker(localization.text(.settingsLanguagePicker), selection: languageSelection) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName)
                        .tag(language)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var canSubmitEmailAuth: Bool {
        accountEmail.contains("@") && accountPassword.count >= 6
    }

    private var canSubmitPasswordReset: Bool {
        !passwordResetCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        passwordResetNewPassword.count >= 6 &&
        passwordResetConfirmPassword.count >= 6
    }

    private func signInIfValid() {
        guard canSubmitEmailAuth else {
            viewModel.accountError = localization.text(.profileAccountAuthHint)
            return
        }
        UIApplication.shared.echoDismissKeyboard()
        Task {
            await viewModel.signInWithEmail(
                email: accountEmail,
                password: accountPassword,
                language: localization.language
            )
        }
    }

    private func signUpIfValid() {
        guard canSubmitEmailAuth else {
            viewModel.accountError = localization.text(.profileAccountAuthHint)
            return
        }
        UIApplication.shared.echoDismissKeyboard()
        isShowingPasswordResetForm = false
        Task {
            let shouldShowVerification = await viewModel.signUpWithEmail(
                email: accountEmail,
                password: accountPassword,
                language: localization.language
            )
            if shouldShowVerification && viewModel.accountSession == nil {
                showingEmailVerificationReminder = true
                isShowingSignupVerification = true
            } else {
                showingEmailVerificationReminder = false
                isShowingSignupVerification = false
            }
        }
    }

    private func verifySignupCodeIfValid() {
        guard accountEmail.contains("@"), !accountVerificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            viewModel.accountError = localization.text(.profileAccountVerificationCodeRequired)
            return
        }
        UIApplication.shared.echoDismissKeyboard()
        Task {
            await viewModel.verifyEmailSignupCode(
                email: accountEmail,
                code: accountVerificationCode,
                language: localization.language
            )
            if viewModel.accountSession != nil {
                accountVerificationCode = ""
                isShowingSignupVerification = false
            }
        }
    }

    private func sendPasswordResetIfValid() {
        guard accountEmail.contains("@") else {
            viewModel.accountError = localization.text(.profileAccountEmailHint)
            return
        }
        UIApplication.shared.echoDismissKeyboard()
        isShowingPasswordResetForm = true
        isShowingSignupVerification = false
        Task {
            await viewModel.resetPassword(
                email: accountEmail,
                language: localization.language
            )
        }
    }

    private func completePasswordResetIfValid() {
        guard canSubmitPasswordReset else {
            viewModel.accountError = localization.text(.profileAccountResetCodeRequired)
            return
        }
        guard passwordResetNewPassword == passwordResetConfirmPassword else {
            viewModel.accountError = localization.text(.passwordResetMismatch)
            return
        }
        UIApplication.shared.echoDismissKeyboard()
        Task {
            let success = await viewModel.completePasswordReset(
                email: accountEmail,
                code: passwordResetCode,
                newPassword: passwordResetNewPassword,
                language: localization.language
            )
            if success {
                passwordResetCode = ""
                passwordResetNewPassword = ""
                passwordResetConfirmPassword = ""
                isShowingPasswordResetForm = false
            }
        }
    }

    private func shouldShowEmailAuthUpgrade(for session: AccountSession) -> Bool {
        session.provider == .supabaseAnonymous || session.provider == .localPreview
    }

    private func accountBadgeText(for session: AccountSession) -> String {
        switch session.provider {
        case .email:
            return localization.text(.profileAccountEmailBadge)
        case .supabaseAnonymous:
            return localization.text(.profileAccountGuestBadge)
        case .localPreview:
            return localization.text(.profileAccountLocalOnlyBadge)
        }
    }

    private func accountBadgeIcon(for session: AccountSession) -> String {
        switch session.provider {
        case .email:
            return "envelope.fill"
        case .supabaseAnonymous:
            return "cloud.fill"
        case .localPreview:
            return "iphone"
        }
    }

    private func accountBadgeColor(for session: AccountSession) -> Color {
        switch session.provider {
        case .email, .supabaseAnonymous:
            return EchoTheme.success
        case .localPreview:
            return EchoTheme.warning
        }
    }

    private func title(for kind: MediaPermissionKind) -> String {
        switch kind {
        case .photoLibrary:
            return localization.text(.permissionPhotosTitle)
        case .camera:
            return localization.text(.permissionCameraTitle)
        case .microphone:
            return localization.text(.permissionMicrophoneTitle)
        }
    }

    private func purpose(for kind: MediaPermissionKind) -> String {
        switch kind {
        case .photoLibrary:
            return localization.text(.permissionPhotosPurpose)
        case .camera:
            return localization.text(.permissionCameraPurpose)
        case .microphone:
            return localization.text(.permissionMicrophonePurpose)
        }
    }

    private func title(for state: MediaPermissionState) -> String {
        switch state {
        case .notDetermined:
            return localization.text(.permissionStatusNotDetermined)
        case .authorized:
            return localization.text(.permissionStatusAuthorized)
        case .limited:
            return localization.text(.permissionStatusLimited)
        case .denied:
            return localization.text(.permissionStatusDenied)
        case .restricted:
            return localization.text(.permissionStatusRestricted)
        case .unavailable:
            return localization.text(.permissionStatusUnavailable)
        }
    }

    private func syncStatusTitle(for state: SyncConnectionState) -> String {
        switch state {
        case .localOnly:
            return localization.text(.profileSyncLocalOnlyStatus)
        case .readyForBackend:
            return localization.text(.profileSyncReadyStatus)
        }
    }

    private func syncStatusIcon(for state: SyncConnectionState) -> String {
        switch state {
        case .localOnly:
            return "iphone"
        case .readyForBackend:
            return "checkmark.icloud.fill"
        }
    }

    private func syncDomainList(_ domains: [SyncDomain]) -> String {
        let separator = localization.language == .zhHans ? "、" : ", "
        return domains.map(syncDomainName).joined(separator: separator)
    }

    private func syncDomainName(_ domain: SyncDomain) -> String {
        switch domain {
        case .account:
            return localization.text(.profileSyncDomainAccount)
        case .petProfile:
            return localization.text(.profileSyncDomainPetProfile)
        case .memoryFiles:
            return localization.text(.profileSyncDomainMemoryFiles)
        case .lifePrint:
            return localization.text(.profileSyncDomainLifePrint)
        case .timeline:
            return localization.text(.profileSyncDomainTimeline)
        case .memoryCapsules:
            return localization.text(.profileSyncDomainMemoryCapsules)
        case .companion:
            return localization.text(.profileSyncDomainCompanion)
        }
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding {
            localization.language
        } set: { language in
            localization.setLanguage(language)
        }
    }

    private var aiMemoryContextSelection: Binding<Bool> {
        Binding {
            viewModel.aiCompanionSettings.allowsMemoryContext
        } set: { isEnabled in
            viewModel.setAICompanionMemoryContextEnabled(isEnabled)
        }
    }

    private var deleteDataTitle: String {
        if viewModel.accountSession?.isLocalOnly == false {
            return localization.text(.settingsDataDeleteCloud)
        }
        return localization.text(.settingsDataDeleteAll)
    }

    private var deleteDataDialogTitle: String {
        if viewModel.accountSession?.isLocalOnly == false {
            return localization.text(.settingsDeleteCloudDialog)
        }
        return localization.text(.settingsDeleteAllDialog)
    }
}

private enum LegalDocumentKind {
    case privacy
    case terms
}

private struct LegalDocumentView: View {
    @EnvironmentObject private var localization: LocalizationManager
    let kind: LegalDocumentKind

    var body: some View {
        EchoPage(title: title, subtitle: subtitle) {
            VStack(alignment: .leading, spacing: 14) {
                Text(intro)
                    .font(.subheadline)
                    .foregroundStyle(EchoTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(sections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.headline)
                            .foregroundStyle(EchoTheme.text)
                        Text(section.body)
                            .font(.subheadline)
                            .foregroundStyle(EchoTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .echoCard()
                }
            }
        }
    }

    private var title: String {
        switch kind {
        case .privacy:
            return localization.text(.settingsPrivacyTitle)
        case .terms:
            return localization.text(.settingsTermsTitle)
        }
    }

    private var subtitle: String {
        switch kind {
        case .privacy:
            return localization.text(.profilePrivacyTitle)
        case .terms:
            return localization.text(.settingsTermsMessage1)
        }
    }

    private var intro: String {
        switch kind {
        case .privacy:
            return localization.text(.settingsPrivacyIntro)
        case .terms:
            return localization.text(.settingsTermsIntro)
        }
    }

    private var sections: [(title: String, body: String)] {
        switch kind {
        case .privacy:
            return [
                (localization.text(.settingsPrivacyCollectedTitle), localization.text(.settingsPrivacyCollectedBody)),
                (localization.text(.settingsPrivacyUseTitle), localization.text(.settingsPrivacyUseBody)),
                (localization.text(.settingsPrivacyAIThirdPartyTitle), localization.text(.settingsPrivacyAIThirdPartyBody)),
                (localization.text(.settingsPrivacyRetentionTitle), localization.text(.settingsPrivacyRetentionBody)),
                (localization.text(.settingsPrivacyDeletionTitle), localization.text(.settingsPrivacyDeletionBody)),
                (localization.text(.settingsPrivacyContactTitle), localization.text(.settingsPrivacyContactBody))
            ]
        case .terms:
            return [
                (localization.text(.settingsTermsServiceTitle), localization.text(.settingsTermsServiceBody)),
                (localization.text(.settingsTermsNoAdviceTitle), localization.text(.settingsTermsNoAdviceBody)),
                (localization.text(.settingsTermsUserContentTitle), localization.text(.settingsTermsUserContentBody)),
                (localization.text(.settingsTermsAIContentTitle), localization.text(.settingsTermsAIContentBody)),
                (localization.text(.settingsTermsDeletionTitle), localization.text(.settingsTermsDeletionBody))
            ]
        }
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let systemName: String
    let content: Content

    init(title: String, systemName: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemName = systemName
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemName)
                .font(.headline)
                .foregroundStyle(EchoTheme.text)

            VStack(alignment: .leading, spacing: 10) {
                content
                    .font(.subheadline)
                    .foregroundStyle(EchoTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .echoCard()
        .accessibilityElement(children: .combine)
    }
}
