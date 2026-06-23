import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    var onBack: (() -> Void)?

    @State private var email = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var didReset = false

    var body: some View {
        BoundedScrollView {

            VStack(alignment: .leading, spacing: 24) {
                KineticAuthHeader(
                    title: "Reset password",
                    subtitle: "Enter the email for your account and choose a new password."
                )

                VStack(spacing: 14) {
                    KineticAuthField(label: "Email", placeholder: "you@example.com", text: $email)
                    KineticAuthField(label: "New password", placeholder: "At least 6 characters", text: $newPassword, isSecure: true)
                    KineticAuthField(label: "Confirm password", placeholder: "Repeat password", text: $confirmPassword, isSecure: true)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.primary)
                }

                if didReset {
                    SurfaceCard {
                        Label("Password updated. You can sign in with your new password.", systemImage: "checkmark.circle.fill")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppTheme.proteinTeal)
                    }
                }

                Button("Update password") { submit() }
                    .buttonStyle(PrimaryButtonStyle(pill: true))

                Button(onBack != nil ? "Back to sign in" : "Back to sign in") {
                    if let onBack { onBack() } else { dismiss() }
                }
                .buttonStyle(OutlineButtonStyle())
            }
            .padding(AppTheme.marginMain)
        
        }
        .background(AppBackground())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() {
        errorMessage = nil
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        do {
            try AuthSessionManager.resetPassword(email: email, newPassword: newPassword)
            didReset = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack { ResetPasswordView() }
}
