import SwiftUI

// MARK: - iOS native permission prep (camera_permission_prep_ios_native)

struct IOSNativePermissionScreen: View {
    let icon: String
    let title: String
    let message: String
    let primaryTitle: String
    let secondaryTitle: String
    var onPrimary: () -> Void
    var onSecondary: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            Circle()
                .fill(AppTheme.coachOrange.opacity(0.04))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 120, y: -320)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(AppTheme.coachOrange.opacity(0.1))
                        .frame(width: 96, height: 96)
                        .overlay {
                            Image(systemName: icon)
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(AppTheme.coachOrange)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                    VStack(spacing: 16) {
                        Text(title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppTheme.inkBlack)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)

                        Text(message)
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .frame(maxWidth: 300)
                    }
                }
                .padding(.horizontal, AppTheme.marginMain)

                Spacer()

                VStack(spacing: 8) {
                    Button(primaryTitle, action: onPrimary)
                        .buttonStyle(PrimaryButtonStyle())

                    Button(secondaryTitle, action: onSecondary)
                        .font(AppTypography.body.weight(.medium))
                        .foregroundStyle(AppTheme.coachOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .padding(.horizontal, AppTheme.marginMain)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Voice permission (mic_permission_prep_ios_native_2)

struct MicrophonePermissionPromptView: View {
    var onAllow: () -> Void
    var onSkip: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 40) {
                    Circle()
                        .fill(AppTheme.primaryFixed)
                        .frame(width: 128, height: 128)
                        .overlay {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 52, weight: .medium))
                                .foregroundStyle(AppTheme.coachOrange)
                                .symbolRenderingMode(.monochrome)
                        }
                        .shadow(color: AppTheme.coachOrange.opacity(0.12), radius: 16, y: 6)

                    VStack(spacing: 16) {
                        Text("Enable Voice Logging")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(AppTheme.inkBlack)
                            .multilineTextAlignment(.center)
                            .tracking(-0.4)

                        Text("Log your meals hands-free with AI-powered voice recognition. Just describe what you're eating and we'll handle the macros.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .frame(maxWidth: 320)
                    }
                }
                .padding(.horizontal, AppTheme.marginMain)

                Spacer()

                VStack(spacing: 8) {
                    Button("Allow Microphone Access", action: onAllow)
                        .font(AppTypography.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.coachOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: AppTheme.coachOrange.opacity(0.22), radius: 10, y: 4)

                    Button("Maybe Later", action: onSkip)
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.coachOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .padding(.horizontal, AppTheme.marginMain)
                .padding(.bottom, 48)
            }
        }
    }
}

struct NotificationPermissionPromptView: View {
    var onAllow: () -> Void
    var onSkip: () -> Void

    var body: some View {
        IOSNativePermissionScreen(
            icon: "bell.badge.fill",
            title: "Stay on\nTrack",
            message: "Get smart meal reminders and real-time protein gap alerts from Apple's notification system.",
            primaryTitle: "Enable Notifications",
            secondaryTitle: "Maybe Later",
            onPrimary: onAllow,
            onSecondary: onSkip
        )
    }
}

#Preview("Camera") {
    IOSNativePermissionScreen(
        icon: "camera.viewfinder",
        title: "Enable Camera for\nAI Scanning",
        message: "Scan your meals in seconds to track protein and get instant coaching. We never store photos without your permission.",
        primaryTitle: "Allow Camera Access",
        secondaryTitle: "Maybe Later",
        onPrimary: {},
        onSecondary: {}
    )
}

#Preview("Microphone") {
    MicrophonePermissionPromptView(onAllow: {}, onSkip: {})
}
