import SwiftUI

struct ProteinProgressCard: View {
    let proteinCurrent: Int
    let proteinTarget: Int
    let caloriesCurrent: Int
    let calorieMin: Int
    let calorieMax: Int
    let showCalories: Bool

    private var proteinProgress: Double {
        guard proteinTarget > 0 else { return 0 }
        return min(Double(proteinCurrent) / Double(proteinTarget), 1)
    }

    private var proteinPercent: Int { Int(proteinProgress * 100) }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Protein Goal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.emerald)
                    Text("\(proteinCurrent)g / \(proteinTarget)g")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .monospacedDigit()
                    Text("You're \(proteinPercent)% there.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(AppTheme.emeraldSoft)
                            Capsule()
                                .fill(AppTheme.emerald)
                                .frame(width: geo.size.width * proteinProgress)
                        }
                    }
                    .frame(height: 10)
                }

                if showCalories {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calories")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("Around \(caloriesCurrent.formatted()) so far")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Target: \(calorieMin.formatted())–\(calorieMax.formatted())")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
    }
}

struct FixMyDayCard: View {
    let proteinRemaining: Int
    let suggestions: [String]

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(AppTheme.energy)
                    Text("Fix My Day")
                        .font(.headline.weight(.bold))
                }
                if proteinRemaining > 0 {
                    Text("You need ~\(proteinRemaining)g more protein today.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    Text("Protein goal hit — nice work today.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.emerald)
                }
                ForEach(suggestions.prefix(3), id: \.self) { item in
                    HStack(spacing: 8) {
                        Circle().fill(AppTheme.emerald).frame(width: 6, height: 6)
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
        }
    }
}

struct WhatNowCard: View {
    let proteinRemaining: Int
    let suggestions: [String]
    var onPlanNext: (() -> Void)?

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("WHAT NOW?", systemImage: "sparkles")
                    .font(AppTypography.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.coachOrange)
                Text("Meal saved.")
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.proteinTeal)
                if proteinRemaining > 0 {
                    Text("You still need about \(proteinRemaining)g protein today.")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Text("Best next options:")
                    .font(AppTypography.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                ForEach(Array(suggestions.prefix(3).enumerated()), id: \.offset) { index, item in
                    Text("\(index + 1). \(item)")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                if let onPlanNext {
                    Button("Plan My Next Meal", action: onPlanNext)
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }
}

struct CoachTipCard: View {
    let message: String

    var body: some View {
        SurfaceCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.emerald)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Coach tip")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.textTertiary)
                        .textCase(.uppercase)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
    }
}

struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int

    var body: some View {
        SurfaceCard {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Logging streak")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("\(currentStreak) day\(currentStreak == 1 ? "" : "s")")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.emerald)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Best")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("\(longestStreak)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
    }
}

struct WeeklyProteinCard: View {
    let daysLogged: Int
    let daysHitGoal: Int
    let averageProtein: Int

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("This week")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .textCase(.uppercase)
                HStack {
                    stat(label: "Days logged", value: "\(daysLogged)")
                    Spacer()
                    stat(label: "Goal hit", value: "\(daysHitGoal)")
                    Spacer()
                    stat(label: "Avg protein", value: "\(averageProtein)g")
                }
            }
        }
    }

    private func stat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ProteinProgressCard(proteinCurrent: 72, proteinTarget: 135, caloriesCurrent: 1250, calorieMin: 1900, calorieMax: 2200, showCalories: true)
        FixMyDayCard(proteinRemaining: 63, suggestions: ["Greek yogurt bowl", "Grilled chicken salad", "Protein smoothie"])
    }
    .padding()
    .background(AppTheme.background)
}
