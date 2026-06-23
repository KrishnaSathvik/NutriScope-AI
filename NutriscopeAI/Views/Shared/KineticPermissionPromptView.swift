import SwiftUI

struct KineticPermissionPromptView: View {
    let icon: String
    let title: String
    let message: String
    let primaryTitle: String
    let secondaryTitle: String
    var onPrimary: () -> Void
    var onSecondary: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppTheme.coachOrange.opacity(0.12))
                        .frame(width: 120, height: 120)
                    Circle()
                        .fill(AppTheme.coachOrange.opacity(0.2))
                        .frame(width: 88, height: 88)
                    Circle()
                        .fill(AppTheme.surface)
                        .frame(width: 64, height: 64)
                        .overlay {
                            Image(systemName: icon)
                                .font(.title)
                                .foregroundStyle(AppTheme.coachOrange)
                        }
                        .shadow(color: AppTheme.coachOrange.opacity(0.15), radius: 8, y: 4)
                }

                VStack(spacing: 10) {
                    Text(title)
                        .font(AppTypography.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text(message)
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Button(primaryTitle, action: onPrimary)
                        .buttonStyle(PrimaryButtonStyle(pill: true))
                    Button(secondaryTitle, action: onSecondary)
                        .font(AppTypography.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(28)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
            .padding(.horizontal, AppTheme.marginMain)

            Spacer()
        }
        .background(AppTheme.background)
    }
}

struct MicrophonePermissionPromptView: View {
    var onAllow: () -> Void
    var onSkip: () -> Void

    var body: some View {
        KineticPermissionPromptView(
            icon: "mic.fill",
            title: "Enable Voice Logging",
            message: "Nutriscope uses your microphone so you can describe meals hands-free. Audio is processed on device.",
            primaryTitle: "Enable Microphone",
            secondaryTitle: "Not now",
            onPrimary: onAllow,
            onSecondary: onSkip
        )
    }
}

struct NotificationPermissionPromptView: View {
    var onAllow: () -> Void
    var onSkip: () -> Void

    var body: some View {
        KineticPermissionPromptView(
            icon: "bell.badge.fill",
            title: "Stay on Track",
            message: "Get smart meal reminders and real-time protein gap alerts from Apple’s notification system.",
            primaryTitle: "Enable Notifications",
            secondaryTitle: "Maybe later",
            onPrimary: onAllow,
            onSecondary: onSkip
        )
    }
}

#Preview {
    NotificationPermissionPromptView(onAllow: {}, onSkip: {})
}
