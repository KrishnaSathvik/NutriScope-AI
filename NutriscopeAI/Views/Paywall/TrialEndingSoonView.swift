import SwiftUI

struct TrialEndingSoonView: View {
    @Environment(AppState.self) private var appState

    private var daysRemaining: Int {
        max(0, appState.subscriptionManager.daysUntilTrialEnds ?? 0)
    }

    private var progressFraction: Double {
        let totalTrialDays = 7.0
        let remaining = Double(daysRemaining)
        return min(1, max(0.15, (totalTrialDays - remaining) / totalTrialDays))
    }

    private var monthlyPrice: String {
        appState.subscriptionManager.displayPrice(for: .monthly)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(showsAmbientGlow: true)

                BoundedScrollView {
                    VStack(spacing: 24) {
                        heroGraphic
                        headlineSection
                        countdownCard
                        benefitsSection
                        actionSection
                    }
                    .padding(.horizontal, AppTheme.marginMain)
                    .padding(.bottom, 32)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismissSheet()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Coach Pro")
                        .font(AppTypography.title2.weight(.bold))
                }
            }
        }
    }

    private var heroGraphic: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.warmSun.opacity(0.2), AppTheme.coachOrange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "crown.fill")
                .font(.system(size: 72))
                .foregroundStyle(AppTheme.coachOrange.opacity(0.9))
        }
        .frame(height: 192)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous)
                .strokeBorder(AppTheme.outlineVariant.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: AppTheme.coachOrange.opacity(0.15), radius: 24, y: 8)
    }

    private var headlineSection: some View {
        VStack(spacing: 8) {
            Text("Your trial is ending.")
                .font(AppTypography.largeTitle)
                .multilineTextAlignment(.center)
            Text("Keep your momentum going. Don't lose access to personalized meal plans and macro coaching.")
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
    }

    private var countdownCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                LabelCapsText(text: "Time Remaining", color: AppTheme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(daysRemaining)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.coachOrange)
                        .monospacedDigit()
                    Text(daysRemaining == 1 ? "Day" : "Days")
                        .font(AppTypography.title3)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.warmSun.opacity(0.2))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.coachOrange, AppTheme.warmSun],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progressFraction)
                    }
                }
                .frame(height: 12)
            }
        }
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabelCapsText(text: "What you'll keep", color: AppTheme.textSecondary)
                .padding(.leading, 8)

            GlassCard {
                VStack(spacing: 4) {
                    benefitRow(
                        icon: "fork.knife",
                        iconColor: AppTheme.coachOrange,
                        iconBackground: AppTheme.coachOrange.opacity(0.1),
                        title: "Custom Meal Plans",
                        subtitle: "Weekly recipes tailored exactly to your macro targets."
                    )
                    benefitRow(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: AppTheme.proteinTeal,
                        iconBackground: AppTheme.proteinTeal.opacity(0.1),
                        title: "Deep Analytics",
                        subtitle: "Understand your trends and optimize your nutrition."
                    )
                    benefitRow(
                        icon: "brain.head.profile",
                        iconColor: Color(hex: 0x574500),
                        iconBackground: AppTheme.warmSun.opacity(0.2),
                        title: "1-on-1 AI Coach",
                        subtitle: "24/7 access to your personal nutrition mentor."
                    )
                }
            }
        }
    }

    private func benefitRow(
        icon: String,
        iconColor: Color,
        iconBackground: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(iconBackground)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.title3.weight(.semibold))
                Text(subtitle)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private var actionSection: some View {
        VStack(spacing: 16) {
            Button {
                appState.activeSheet = .paywall
            } label: {
                HStack(spacing: 8) {
                    Text("Keep Pro Access")
                        .font(AppTypography.title3.weight(.bold))
                    Image(systemName: "arrow.right")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.coachOrange)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous))
                .shadow(color: AppTheme.coachOrange.opacity(0.25), radius: 12, y: 6)
            }
            .buttonStyle(.plain)

            Button("Maybe later") {
                dismissSheet()
            }
            .font(AppTypography.body)
            .foregroundStyle(AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)

            Text("\(monthlyPrice)/month after trial ends. Cancel anytime in Settings.")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.top, 8)
    }

    private func dismissSheet() {
        appState.markTrialEndingPromptSeen()
        appState.activeSheet = nil
    }
}

#Preview {
    TrialEndingSoonView()
        .environment(AppState())
}
