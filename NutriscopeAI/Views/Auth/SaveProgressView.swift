import SwiftData
import SwiftUI

struct SaveProgressView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var showEmailSignup = false
    @State private var showCreateAccountOptions = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var authError: String?
    @State private var isSaving = false

    private var trialSubtitle: String {
        if let intro = appState.subscriptionManager.introductoryOfferDescription(for: .yearly) {
            return "\(intro). Unlimited scans, personalized coaching, and deep nutritional insights."
        }
        return "Unlimited scans, personalized coaching, and deep nutritional insights."
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(showsAmbientGlow: true)

                BoundedScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        optionsSection

                        if showCreateAccountOptions {
                            createAccountSection
                        }

                        if let authError {
                            Text(authError)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.primary)
                                .multilineTextAlignment(.center)
                        }

                        legalFooter
                    }
                    .padding(AppTheme.marginMain)
                    .padding(.bottom, 32)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismissSheet()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showEmailSignup) {
                NavigationStack {
                    SignUpView(
                        name: $name,
                        email: $email,
                        password: $password,
                        authError: authError,
                        isLoading: isSaving,
                        onCreateAccount: { submitEmailSignup() },
                        onSignIn: { showEmailSignup = false },
                        onBack: { showEmailSignup = false },
                        onAppleSuccess: {
                            GuestModeManager.isGuest = false
                            showEmailSignup = false
                            dismissSheet()
                        },
                        onAppleError: { authError = $0 }
                    )
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.primaryContainer)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                }
                .shadow(color: AppTheme.coachOrange.opacity(0.15), radius: 8, y: 4)

            Text("Start your journey.")
                .font(AppTypography.displayLGMobile)
                .multilineTextAlignment(.center)

            Text("Choose how you want to experience Nutriscope AI.")
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var optionsSection: some View {
        VStack(spacing: 12) {
            StitchAccountChoiceCard(
                icon: "star.fill",
                iconColor: AppTheme.primary,
                iconBackground: AppTheme.primaryFixed,
                title: "Try Pro free for 7 days",
                subtitle: trialSubtitle,
                isRecommended: true,
                recommendedBorder: true
            ) {
                dismissSheet()
                appState.activeSheet = .paywall
            }

            StitchAccountChoiceCard(
                icon: "person.badge.plus",
                iconColor: Color(hex: 0x574500),
                iconBackground: AppTheme.warmSun.opacity(0.35),
                title: "Create account",
                subtitle: "Secure your data and sync across devices."
            ) {
                withAnimation(.nsStandardSpring) {
                    showCreateAccountOptions = true
                }
            }

            StitchAccountChoiceCard(
                icon: "arrow.forward",
                iconColor: AppTheme.textSecondary,
                iconBackground: AppTheme.surfaceMuted,
                title: "Continue with free plan",
                subtitle: "Basic access with up to 5 scans per week."
            ) {
                dismissSheet()
            }
        }
    }

    private var createAccountSection: some View {
        GlassCard {
            VStack(spacing: 14) {
                Text("Create your account")
                    .font(AppTypography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if BackendConfig.isSupabaseConfigured {
                    StitchAppleSignInRow(
                        onSuccess: {
                            GuestModeManager.isGuest = false
                            dismissSheet()
                        },
                        onError: { authError = $0 }
                    )
                }

                Button("Continue with email") {
                    showEmailSignup = true
                }
                .buttonStyle(PrimaryButtonStyle(pill: true))
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var legalFooter: some View {
        VStack(spacing: 8) {
            Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Terms") { openURL(AppLegalLinks.termsOfUse) }
                Button("Privacy") { openURL(AppLegalLinks.privacyPolicy) }
            }
            .font(AppTypography.caption.weight(.semibold))
            .foregroundStyle(AppTheme.primary)
        }
    }

    private func dismissSheet() {
        dismiss()
        appState.activeSheet = nil
    }

    private func submitEmailSignup() {
        isSaving = true
        Task {
            do {
                let displayName = name.isEmpty ? email.components(separatedBy: "@").first ?? "User" : name
                _ = try AuthSessionManager.signUp(email: email, password: password, displayName: displayName)
                if BackendConfig.isSupabaseConfigured {
                    _ = try await SupabaseAuthClient.signUpWithEmail(email: email, password: password)
                }
                let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first
                await IOSUserProfileSyncService.upsertAfterAuthentication(settings: settings)
                GuestModeManager.isGuest = false
                isSaving = false
                showEmailSignup = false
                dismissSheet()
            } catch {
                authError = error.localizedDescription
                isSaving = false
            }
        }
    }
}

#Preview {
    SaveProgressView()
        .environment(AppState())
}
