import SwiftUI

struct SubscriptionSuccessView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var bounce = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            Circle()
                .fill(AppTheme.coachOrange.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(y: -180)

            BoundedScrollView {

                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    ZStack {
                        Circle()
                            .fill(AppTheme.coachOrange.opacity(0.15))
                            .frame(width: 120, height: 120)
                            .scaleEffect(bounce ? 1 : 0.7)
                        Circle()
                            .fill(AppTheme.coachOrange)
                            .frame(width: 96, height: 96)
                            .shadow(color: AppTheme.coachOrange.opacity(0.35), radius: 16, y: 8)
                            .scaleEffect(bounce ? 1 : 0.5)
                            .overlay {
                                Image(systemName: "crown.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white)
                            }
                    }

                    VStack(spacing: 12) {
                        Text("You're Pro!")
                            .font(AppTypography.largeTitle.weight(.heavy))
                            .foregroundStyle(AppTheme.coachOrange)
                        Text("Pro is active now.")
                            .font(AppTypography.body.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                        Text("Create an account to save your profile and keep your Pro access connected across devices.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        if !AuthSessionManager.isSignedIn {
                            Text("You can skip this and keep using Pro on this device.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pro benefits unlocked")
                                .font(AppTypography.headline)
                            KineticPaywallFeatureRow(
                                icon: "brain.head.profile",
                                title: "Unlimited Coach Access",
                                subtitle: "Chat with your AI nutritionist anytime."
                            )
                            KineticPaywallFeatureRow(
                                icon: "camera.fill",
                                title: "Advanced Scanning",
                                subtitle: "Unlimited meal scans with smart corrections."
                            )
                            KineticPaywallFeatureRow(
                                icon: "chart.bar.fill",
                                title: "Deep Analytics",
                                subtitle: "Weekly reports and saved meals."
                            )
                        }
                    }

                    Button {
                        appState.activeSheet = nil
                        appState.promptSaveProgressIfNeeded()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Continue to Pro dashboard")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(pill: true))

                    if !AuthSessionManager.isSignedIn {
                        Button("Skip for now") {
                            appState.activeSheet = nil
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, AppTheme.marginMain)
            
        }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                bounce = true
            }
        }
    }
}

#Preview {
    SubscriptionSuccessView()
        .environment(AppState())
}
