import SwiftUI

struct SignInView: View {
    @Binding var email: String
    @Binding var password: String
    var authError: String?
    var isLoading: Bool
    var onSignIn: () -> Void
    var onForgotPassword: () -> Void
    var onSignUp: () -> Void
    var onBack: () -> Void
    var onAppleSuccess: () -> Void
    var onAppleError: (String) -> Void
    var onRestorePurchases: (() -> Void)? = nil
    var isRestoringPurchases: Bool = false

    @State private var passwordVisible = false

    var body: some View {
        ZStack {
            AppBackground(showsAmbientGlow: true)

            BoundedScrollView {

            VStack(spacing: 32) {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.coachOrange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                StitchSignInLogoHeader()

                VStack(spacing: 20) {
                    StitchSignInField(
                        label: "Email Address",
                        icon: "envelope",
                        placeholder: "you@example.com",
                        text: $email,
                        keyboardType: .emailAddress
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Password")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            Button("Forgot Password?", action: onForgotPassword)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.primary)
                        }
                        HStack(spacing: 0) {
                            Image(systemName: "lock")
                                .font(.body)
                                .foregroundStyle(AppTheme.outline)
                                .frame(width: 44)
                            Group {
                                if passwordVisible {
                                    TextField("••••••••", text: $password)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("••••••••", text: $password)
                                }
                            }
                            Button {
                                passwordVisible.toggle()
                            } label: {
                                Image(systemName: passwordVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(AppTheme.outline)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 8)
                        }
                        .padding(.vertical, 4)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(AppTheme.surfaceContainerHighest, lineWidth: 1)
                        )
                    }

                    if let authError {
                        Text(authError)
                            .font(.caption)
                            .foregroundStyle(AppTheme.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: onSignIn) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In")
                                    .font(.subheadline.weight(.bold))
                                Image(systemName: "arrow.right")
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    if BackendConfig.isSupabaseConfigured {
                        StitchAuthOrDivider()
                            .padding(.top, 4)

                        HStack {
                            Spacer()
                            StitchCircularAppleButton(
                                onSuccess: onAppleSuccess,
                                onError: onAppleError
                            )
                            Spacer()
                        }
                    }
                }
                .padding(20)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous)
                        .strokeBorder(AppTheme.glassBorder, lineWidth: 1)
                )
                .shadow(color: AppTheme.coachOrange.opacity(0.08), radius: 20, y: 4)

                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.textSecondary)
                    Button("Sign Up", action: onSignUp)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                }

                if let onRestorePurchases {
                    RestorePurchasesButton(
                        isLoading: isRestoringPurchases,
                        action: onRestorePurchases
                    )
                    .padding(.top, 4)
                }

                SubscriptionLegalLinksView()
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, AppTheme.marginMain)

            }
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var email = ""
        @State private var password = ""
        var body: some View {
            SignInView(
                email: $email,
                password: $password,
                authError: nil,
                isLoading: false,
                onSignIn: {},
                onForgotPassword: {},
                onSignUp: {},
                onBack: {},
                onAppleSuccess: {},
                onAppleError: { _ in }
            )
        }
    }
    return PreviewHost()
}
