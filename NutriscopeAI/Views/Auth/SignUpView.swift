import SwiftUI

struct SignUpView: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var password: String
    var authError: String?
    var isLoading: Bool
    var onCreateAccount: () -> Void
    var onSignIn: () -> Void
    var onBack: () -> Void
    var onAppleSuccess: () -> Void
    var onAppleError: (String) -> Void

    var body: some View {
        ZStack {
            AppBackground(showsAmbientGlow: true)

            VStack(spacing: 0) {
            StitchAuthTopBar(onBack: onBack)

            BoundedScrollView {

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Join the Movement")
                            .font(AppTypography.headlineLG)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Start tracking your protein-first progress today.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 16) {
                        StitchCoachTextField(
                            label: "Full Name",
                            placeholder: "Alex Carter",
                            text: $name
                        )
                        StitchCoachTextField(
                            label: "Email Address",
                            placeholder: "alex@example.com",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        StitchCoachTextField(
                            label: "Password",
                            placeholder: "••••••••",
                            text: $password,
                            isSecure: true
                        )
                    }

                    if let authError {
                        Text(authError)
                            .font(.caption)
                            .foregroundStyle(AppTheme.primary)
                    }

                    StitchAuthPrimaryButton(
                        title: "Create Account",
                        isLoading: isLoading,
                        action: onCreateAccount
                    )
                    .padding(.top, 4)

                    if BackendConfig.isSupabaseConfigured {
                        StitchAuthOrDivider()
                            .padding(.vertical, 4)

                        StitchAppleSignInRow(
                            onSuccess: onAppleSuccess,
                            onError: onAppleError
                        )
                    }

                    HStack(spacing: 4) {
                        Spacer()
                        Text("Already have an account?")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Button("Log In", action: onSignIn)
                            .font(AppTypography.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.coachOrange)
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, AppTheme.marginMain)

            }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var name = ""
        @State private var email = ""
        @State private var password = ""
        var body: some View {
            SignUpView(
                name: $name,
                email: $email,
                password: $password,
                authError: nil,
                isLoading: false,
                onCreateAccount: {},
                onSignIn: {},
                onBack: {},
                onAppleSuccess: {},
                onAppleError: { _ in }
            )
        }
    }
    return PreviewHost()
}
