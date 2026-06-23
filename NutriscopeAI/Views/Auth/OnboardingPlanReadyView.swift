import SwiftUI

struct OnboardingPlanReadyView: View {
    let displayName: String
    var goal: FitnessGoal = .maintain
    let proteinTarget: Int
    let calorieMin: Int
    let calorieMax: Int
    var onContinue: () -> Void

    @State private var showContent = false

    private var headline: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "You're all set!" }
        let first = trimmed.split(separator: " ").first.map(String.init) ?? trimmed
        return "You're all set, \(first)!"
    }

    private var energyMinLabel: String { formatCalories(calorieMin) }
    private var energyMaxLabel: String { formatCalories(calorieMax) }

    private var coachInsight: String {
        switch goal {
        case .loseFat:
            return "Your protein target is set high to protect muscle while you cut — we'll coach you meal by meal."
        case .buildMuscle:
            return "Extra protein and a slight calorie surplus should support recovery and lean gains."
        case .maintain:
            return "Balanced protein and maintenance calories to keep your progress steady."
        case .eatMoreProtein:
            return "We'll nudge you toward high-protein choices so hitting your goal feels easy."
        case .understandMeals:
            return "Start scanning meals — we'll show protein, calories, and what to eat next."
        }
    }

    var body: some View {
        ZStack {
            AppBackground(showsAmbientGlow: true)

            VStack(spacing: 0) {
                BoundedScrollView {
                    VStack(spacing: 28) {
                        celebrationHero
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 12)

                        VStack(spacing: 10) {
                            Text(headline)
                                .font(AppTypography.displayLGMobile)
                                .foregroundStyle(AppTheme.inkBlack)
                                .multilineTextAlignment(.center)
                            Text("Your daily targets are ready. Log your first meal to start tracking.")
                                .font(AppTypography.body)
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 16)

                        planSummaryCard
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                    }
                    .padding(.horizontal, AppTheme.marginMain)
                    .padding(.top, 32)
                    .padding(.bottom, 16)
                }

                bottomActionBar
            }
        }
        .onAppear {
            withAnimation(.nsBouncySpring.delay(0.05)) {
                showContent = true
            }
        }
    }

    private var celebrationHero: some View {
        ZStack {
            Circle()
                .fill(AppTheme.coachOrange.opacity(0.12))
                .frame(width: 140, height: 140)
                .blur(radius: 8)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primaryFixed, AppTheme.warmSun.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 88, height: 88)
                .shadow(color: AppTheme.coachOrange.opacity(0.2), radius: 20, y: 8)
                .overlay {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.coachOrange)
                }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var planSummaryCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    LabelCapsText(text: "Daily protein goal", color: AppTheme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(proteinTarget)")
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.coachOrange)
                            .monospacedDigit()
                        Text("g")
                            .font(AppTypography.title2.weight(.bold))
                            .foregroundStyle(AppTheme.coachOrange.opacity(0.75))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                Rectangle()
                    .fill(AppTheme.outlineVariant.opacity(0.35))
                    .frame(height: 1)

                HStack(spacing: 12) {
                    metricTile(
                        icon: "flame.fill",
                        label: "Energy range",
                        value: "\(energyMinLabel)–\(energyMaxLabel)",
                        suffix: "kcal / day"
                    )
                }
            }
            .padding(20)

            coachInsightBlock
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous))
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [AppTheme.coachOrange, AppTheme.warmSun],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: AppTheme.cornerRadiusXL,
                    topTrailingRadius: AppTheme.cornerRadiusXL
                )
            )
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous)
                .strokeBorder(AppTheme.outlineVariant.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: AppTheme.coachOrange.opacity(0.1), radius: 24, y: 10)
    }

    private func metricTile(icon: String, label: String, value: String, suffix: String) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(AppTheme.surfaceMuted)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(AppTheme.coachOrange)
                }

            VStack(alignment: .leading, spacing: 4) {
                LabelCapsText(text: label, color: AppTheme.textSecondary)
                Text(value)
                    .font(AppTypography.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .monospacedDigit()
                Text(suffix)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var coachInsightBlock: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(AppTheme.coachOrange)
                .frame(width: 3)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.coachOrange)
                    Text("Nutriscope AI")
                        .font(AppTypography.labelCaps)
                        .foregroundStyle(AppTheme.coachOrange)
                }
                Text(coachInsight)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceBright)
    }

    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            LinearGradient(
                colors: [AppTheme.background.opacity(0), AppTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)

            Button(action: onContinue) {
                HStack(spacing: 8) {
                    Text("Let's Go")
                        .font(AppTypography.title3.weight(.bold))
                    Image(systemName: "arrow.right")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.coachOrange)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous))
                .shadow(color: AppTheme.coachOrange.opacity(0.28), radius: 14, y: 6)
            }
            .buttonStyle(.plain)

            Text("Adjust targets anytime in Profile.")
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppTheme.marginMain)
        .padding(.bottom, 28)
        .background(AppTheme.background)
    }

    private func formatCalories(_ value: Int) -> String {
        let k = Double(value) / 1000
        if k >= 10 { return value.formatted() }
        if k.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0fk", k)
        }
        return String(format: "%.1fk", k)
    }
}

#Preview {
    OnboardingPlanReadyView(
        displayName: "",
        goal: .maintain,
        proteinTarget: 120,
        calorieMin: 2200,
        calorieMax: 2500,
        onContinue: {}
    )
}
