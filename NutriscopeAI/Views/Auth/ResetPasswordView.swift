import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    var onBack: (() -> Void)?

    @State private var email = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var didSendLink = false
    @State private var isSubmitting = false

    private var usesSupabaseReset: Bool { BackendConfig.isSupabaseConfigured }

    var body: some View {
        ZStack {
            AppBackground(showsAmbientGlow: true)

            BoundedScrollView {
            VStack(alignment: .leading, spacing: 24) {
                KineticAuthHeader(
                    title: "Reset Password",
                    subtitle: usesSupabaseReset
                        ? "Enter your account email and we'll send a link to reset your password."
                        : "Enter the email for your account and choose a new password."
                )

                VStack(spacing: 14) {
                    KineticAuthField(label: "Email", placeholder: "you@example.com", text: $email)

                    if !usesSupabaseReset {
                        KineticAuthField(
                            label: "New password",
                            placeholder: "At least 6 characters",
                            text: $newPassword,
                            isSecure: true
                        )
                        KineticAuthField(
                            label: "Confirm password",
                            placeholder: "Repeat password",
                            text: $confirmPassword,
                            isSecure: true
                        )
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.primary)
                }

                if didSendLink {
                    GlassCard {
                        Label(
                            usesSupabaseReset
                                ? "Check your email for a link to reset your password."
                                : "Password updated. You can sign in with your new password.",
                            systemImage: usesSupabaseReset ? "envelope.fill" : "checkmark.circle.fill"
                        )
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.proteinTeal)
                    }
                }

                Button(usesSupabaseReset ? "Send reset link" : "Update password") {
                    submit()
                }
                .buttonStyle(PrimaryButtonStyle(pill: true))
                .disabled(isSubmitting)

                Button("Back to sign in") {
                    if let onBack { onBack() } else { dismiss() }
                }
                .buttonStyle(OutlineButtonStyle())
            }
            .padding(AppTheme.marginMain)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() {
        errorMessage = nil
        isSubmitting = true

        Task {
            defer { isSubmitting = false }

            do {
                if usesSupabaseReset {
                    try await SupabaseAuthClient.requestPasswordReset(
                        email: email,
                        redirectTo: BackendConfig.passwordResetRedirectURL
                    )
                    didSendLink = true
                } else {
                    guard newPassword == confirmPassword else {
                        errorMessage = "Passwords do not match."
                        return
                    }
                    try AuthSessionManager.resetPassword(email: email, newPassword: newPassword)
                    didSendLink = true
                }
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack { ResetPasswordView() }
}
