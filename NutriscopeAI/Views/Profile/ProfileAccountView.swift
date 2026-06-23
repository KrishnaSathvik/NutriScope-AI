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
    @State private var offlineDemo = BackendConfig.offlineDemoMode
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
        if offlineDemo { return "Mock scans (offline demo)" }
        #if DEBUG
        if BackendConfig.useDirectOpenAIInDebug, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Direct OpenAI on device"
        }
        #endif
        if supabaseLooksConfigured { return "Supabase edge function" }
        if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Direct OpenAI fallback"
        }
        return "Not configured"
    }

    var body: some View {
        BoundedScrollView {

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Account")
                        .font(AppTypography.title2.weight(.black))
                        .foregroundStyle(AppTheme.coachOrange)
                    Text("Sign-in details, privacy, and subscription.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                ProfileMenuSection(title: "Sign in") {
                    if let account = AuthSessionManager.currentAccount, AuthSessionManager.isSignedIn {
                        ProfileMenuRow(
                            icon: "person.crop.circle.fill",
                            iconColor: AppTheme.coachOrange,
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
                            iconColor: AppTheme.warmSun,
                            title: "Nutriscope Pro active",
                            subtitle: "Unlimited scans and coaching"
                        )
                        NavigationLink { ManageSubscriptionView() } label: {
                            ProfileMenuRow(
                                icon: "gearshape.fill",
                                iconColor: AppTheme.coachOrange,
                                title: "Manage subscription",
                                subtitle: "Billing and plan details"
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        ProfileMenuRow(
                            icon: "camera.viewfinder",
                            iconColor: AppTheme.proteinTeal,
                            title: "\(appState.quotaManager.scansRemaining) free scans left",
                            subtitle: "Resets weekly · Upgrade for unlimited"
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
                            title: "Data & privacy",
                            subtitle: "Export, cache, and delete"
                        )
                    }
                    .buttonStyle(.plain)
                }

                #if DEBUG
                ProfileMenuSection(title: "Developer") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Testing setup")
                            .font(.subheadline.weight(.semibold))
                        Text("1. Paste Supabase URL + anon key (enable Anonymous auth in Supabase).\n2. Deploy analyze-meal edge function with OPENAI_API_KEY secret.\n3. Paste OpenAI key here for Coach + Today tips.\n4. Turn OFF offline demo mode for live scans.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("Supabase URL", text: $supabaseURL)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("Supabase anon key", text: $supabaseAnonKey)
                            .textFieldStyle(.roundedBorder)
                        Toggle("Offline demo mode (mock scans)", isOn: $offlineDemo)
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
                            Text("Coach / Today tip: \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "needs OpenAI key" : "ready")")
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
        .background(AppBackground())
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete your account?", isPresented: $showDeleteAccountConfirm) {
            Button("Delete account", role: .destructive) {
                Task { await performAccountDeletion() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your Nutriscope account from our servers, removes cloud profile data, wipes meals and settings on this device, and returns you to Welcome. This cannot be undone.")
        }
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
        BackendConfig.offlineDemoMode = offlineDemo
        UserDefaults.standard.set(apiKey, forKey: "openAIAPIKey")
        UserDefaults.standard.set(usdaKey, forKey: "usdaAPIKey")

        var lines = ["Settings saved to this device."]
        var succeeded = true

        if offlineDemo {
            lines.append("Offline demo is ON — meal scans will use fake mock data, not your APIs.")
            backendSaveSucceeded = true
            backendSaveMessage = lines.joined(separator: "\n")
            return
        }

        if BackendConfig.isSupabaseConfigured {
            do {
                try await BackendAuthBootstrap.ensureBackendSession()
                lines.append("Supabase: connected (anonymous guest session created).")
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
            lines.append("OpenAI key missing — Coach tab and Today tips will not work.")
        } else {
            lines.append("OpenAI key saved — Coach and Today tips can use it.")
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
