import SwiftData
import SwiftUI

struct ProfileAccountView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]

    @State private var apiKey = Secrets.openAIAPIKey
    @State private var usdaKey = Secrets.usdaAPIKey
    @State private var supabaseURL = BackendConfig.supabaseURL
    @State private var supabaseAnonKey = BackendConfig.supabaseAnonKey
    @State private var isRestoring = false
    @State private var restoreMessage: String?
    @State private var showDeleteAccountConfirm = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountError: String?
    @State private var isSavingBackend = false
    @State private var backendSaveMessage: String?
    @State private var backendSaveSucceeded = false

    private var user: UserSettings? { settings.first }

    private var supabaseLooksConfigured: Bool {
        let url = supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return url.hasPrefix("https://") && url.contains("supabase") && !key.isEmpty
    }

    private var predictedScanMode: String {
        if BackendConfig.isSupabaseConfigured { return "Supabase edge functions" }
        #if DEBUG
        if BackendConfig.useDirectOpenAIInDebug, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Direct OpenAI on device (Debug)"
        }
        #endif
        if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Direct OpenAI fallback (Debug)"
        }
        return "Not configured"
    }

    private var predictedCoachMode: String {
        if BackendConfig.isSupabaseConfigured, !BackendConfig.usesDeviceOpenAIForCoach {
            return "Supabase ai-proxy"
        }
        #if DEBUG
        if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Direct OpenAI on device (Debug)"
        }
        #endif
        return "needs Supabase or Debug OpenAI key"
    }

    var body: some View {
        ZStack {
            AppBackground(showsAmbientGlow: true)

            BoundedScrollView {

            VStack(alignment: .leading, spacing: 20) {
                KineticToolHeader(
                    title: "Account",
                    subtitle: "Sign-in details, privacy, and subscription."
                )

                ProfileMenuSection(title: "Sign in") {
                    if let account = AuthSessionManager.currentAccount, AuthSessionManager.isSignedIn {
                        ProfileMenuRow(
                            icon: "person.crop.circle.fill",
                            iconColor: AppTheme.primary,
                            title: account.displayName.isEmpty ? account.email : account.displayName,
                            subtitle: account.email
                        )
                    } else if GuestModeManager.isGuest {
                        ProfileMenuRow(
                            icon: "person.crop.circle",
                            iconColor: AppTheme.textSecondary,
                            title: "Guest mode",
                            subtitle: "Data stays on this device"
                        )
                        Button("Save your progress") {
                            appState.activeSheet = .saveProgress
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    } else {
                        Button("Sign in or create account") {
                            appState.activeSheet = .saveProgress
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(12)
                    }

                    if AuthSessionManager.isSignedIn {
                        Button("Delete account", role: .destructive) {
                            showDeleteAccountConfirm = true
                        }
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .disabled(isDeletingAccount)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }

                    if let deleteAccountError {
                        Text(deleteAccountError)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                    }
                }

                ProfileMenuSection(title: "Subscription") {
                    if appState.subscriptionManager.isSubscribed {
                        ProfileMenuRow(
                            icon: "crown.fill",
                            iconColor: AppTheme.coachOrange,
                            title: "Nutriscope Pro active",
                            trailingValue: "Active"
                        )
                        NavigationLink { ManageSubscriptionView() } label: {
                            ProfileMenuRow(
                                icon: "creditcard.fill",
                                iconColor: AppTheme.primary,
                                title: "Manage subscription"
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        ProfileMenuRow(
                            icon: "camera.viewfinder",
                            iconColor: AppTheme.proteinTeal,
                            title: "Free scans remaining",
                            trailingValue: "\(appState.quotaManager.scansRemaining)"
                        )
                        Button("Upgrade to Pro") { appState.presentPaywall() }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                    }

                    RestorePurchasesButton(isLoading: isRestoring) {
                        Task {
                            isRestoring = true
                            defer { isRestoring = false }
                            if await appState.restorePurchases() {
                                restoreMessage = "Subscription restored."
                            } else {
                                restoreMessage = appState.subscriptionManager.errorMessage
                                    ?? "No active subscription found."
                            }
                        }
                    }
                    .padding(.horizontal, 12)

                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                    }
                }

                ProfileMenuSection(title: "Privacy") {
                    NavigationLink { DataPrivacyView() } label: {
                        ProfileMenuRow(
                            icon: "lock.shield.fill",
                            iconColor: AppTheme.proteinTeal,
                            title: "Data & privacy"
                        )
                    }
                    .buttonStyle(.plain)
                }

                #if DEBUG
                ProfileMenuSection(title: "Developer") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Testing setup")
                            .font(.subheadline.weight(.semibold))
                        Text("1. Paste Supabase URL + anon key (enable Anonymous auth in Supabase).\n2. Deploy analyze-meal + ai-proxy edge functions with OPENAI_API_KEY secret.\n3. Meal scans + Coach use Supabase — OpenAI key here is only for Debug direct mode.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("Supabase URL", text: $supabaseURL)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("Supabase anon key", text: $supabaseAnonKey)
                            .textFieldStyle(.roundedBorder)
                        Toggle("Use direct OpenAI in Debug", isOn: Binding(
                            get: { BackendConfig.useDirectOpenAIInDebug },
                            set: { BackendConfig.useDirectOpenAIInDebug = $0 }
                        ))
                        SecureField("OpenAI API key (Debug only)", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                        SecureField("USDA API key", text: $usdaKey)
                            .textFieldStyle(.roundedBorder)

                        VStack(alignment: .leading, spacing: 6) {
                            LabelCapsText(text: "After save", color: AppTheme.textSecondary)
                            Text("Meal scans: \(predictedScanMode)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Coach / tips: \(predictedCoachMode)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .padding(.top, 4)

                        Button {
                            Task { await saveBackendSettings() }
                        } label: {
                            if isSavingBackend {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Save & test connection")
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(isSavingBackend)

                        if let backendSaveMessage {
                            Text(backendSaveMessage)
                                .font(.caption)
                                .foregroundStyle(backendSaveSucceeded ? AppTheme.proteinTeal : AppTheme.primary)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 4)
                        }

                        Button("Reset onboarding (test Welcome flow)", role: .destructive) {
                            if let profiles = try? modelContext.fetch(FetchDescriptor<UserSettings>()) {
                                profiles.forEach { modelContext.delete($0) }
                                try? modelContext.save()
                            }
                            appState.hasCompletedOnboarding = false
                            GuestModeManager.isGuest = false
                            appState.activeSheet = nil
                        }
                        .font(.footnote.weight(.semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
                #endif
            }
            .padding(AppTheme.marginMain)

            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .kineticConfirmationDialog(
            isPresented: $showDeleteAccountConfirm,
            icon: "person.crop.circle.badge.minus",
            title: "Delete your account?",
            message: "This permanently deletes your Nutriscope account from our servers, removes cloud profile data, wipes meals and settings on this device, and returns you to Welcome. This cannot be undone.",
            confirmTitle: "Delete account",
            onConfirm: { Task { await performAccountDeletion() } }
        )
    }

    private func performAccountDeletion() async {
        isDeletingAccount = true
        deleteAccountError = nil
        defer { isDeletingAccount = false }

        do {
            try await AccountDeletionService.deleteAccount(
                appState: appState,
                modelContext: modelContext
            )
        } catch {
            deleteAccountError = error.localizedDescription
        }
    }

    private func saveBackendSettings() async {
        isSavingBackend = true
        backendSaveMessage = nil
        defer { isSavingBackend = false }

        supabaseURL = supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        supabaseAnonKey = supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        usdaKey = usdaKey.trimmingCharacters(in: .whitespacesAndNewlines)

        UserDefaults.standard.set(supabaseURL, forKey: "supabaseURL")
        UserDefaults.standard.set(supabaseAnonKey, forKey: "supabaseAnonKey")
        UserDefaults.standard.set(apiKey, forKey: "openAIAPIKey")
        UserDefaults.standard.set(usdaKey, forKey: "usdaAPIKey")

        var lines = ["Settings saved to this device."]
        var succeeded = true

        if BackendConfig.isSupabaseConfigured {
            do {
                try await BackendAuthBootstrap.ensureBackendSession()
                lines.append("Supabase: connected (anonymous guest session created).")
                if AuthSessionManager.isSignedIn {
                    do {
                        let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first
                        try await IOSUserProfileSyncService.upsert(settings: settings)
                        lines.append("Profile: synced to ios_user_profiles.")
                    } catch {
                        succeeded = false
                        lines.append("Profile sync failed: \(error.localizedDescription)")
                    }
                }
            } catch {
                succeeded = false
                lines.append("Supabase auth failed: \(error.localizedDescription)")
                lines.append("Fix: Supabase Dashboard → Authentication → enable Anonymous sign-ins.")
            }
        } else if !supabaseURL.isEmpty || !supabaseAnonKey.isEmpty {
            succeeded = false
            lines.append("Supabase incomplete — URL must be https://YOUR_PROJECT.supabase.co plus the anon public key.")
        } else {
            succeeded = false
            lines.append("No Supabase URL/key — meal scans need Supabase or turn on Direct OpenAI in Debug.")
        }

        if apiKey.isEmpty {
            lines.append("OpenAI key missing — only needed for Debug direct-OpenAI mode (Coach bypass).")
        } else {
            lines.append("OpenAI key saved — used only when Direct OpenAI in Debug is ON.")
        }

        backendSaveSucceeded = succeeded
        backendSaveMessage = lines.joined(separator: "\n")
    }
}

#Preview {
    NavigationStack { ProfileAccountView() }
        .environment(AppState())
        .modelContainer(for: UserSettings.self, inMemory: true)
}
