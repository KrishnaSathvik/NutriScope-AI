import SwiftUI

struct SaveProgressView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var showEmailSignup = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var authError: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            BoundedScrollView {

                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "icloud.and.arrow.up.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(AppTheme.coachOrange)
                        Text("Save your progress")
                            .font(.system(size: 28, weight: .heavy))
                            .multilineTextAlignment(.center)
                        Text("Create an account to protect your profile and keep Pro access connected to your Apple ID or email.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)

                    if BackendConfig.isSupabaseConfigured {
                        StitchAppleSignInRow(
                            onSuccess: {
                                GuestModeManager.isGuest = false
                                dismiss()
                                appState.activeSheet = nil
                            },
                            onError: { authError = $0 }
                        )
                    }

                    Button("Continue with email") {
                        showEmailSignup = true
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button("Skip for now") {
                        dismiss()
                        appState.activeSheet = nil
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    if let authError {
                        Text(authError)
                            .font(.caption)
                            .foregroundStyle(AppTheme.primary)
                    }

                    Text("You can create an account anytime in Profile. Account deletion is available in Data & privacy.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.marginMain)
                .padding(.bottom, 32)
            
        }
        .background(AppTheme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                        appState.activeSheet = nil
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
                            dismiss()
                            appState.activeSheet = nil
                        },
                        onAppleError: { authError = $0 }
                    )
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
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
                GuestModeManager.isGuest = false
                isSaving = false
                showEmailSignup = false
                dismiss()
                appState.activeSheet = nil
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
