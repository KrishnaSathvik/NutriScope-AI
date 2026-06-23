import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Top app bar (Today dashboard)

struct NutriscopeTopBar: View {
    var displayName: String = ""

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Circle()
                    .fill(AppTheme.surfaceMuted)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.coachOrange)
                    }
                Text("Nutriscope AI")
                    .font(.title3.weight(.black))
                    .foregroundStyle(AppTheme.coachOrange)
            }
            Spacer()
            Button {} label: {
                Image(systemName: "bell")
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.surfaceMuted)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.marginMain)
        .padding(.vertical, 8)
        .background(AppTheme.background)
    }
}

// MARK: - Protein arc ring

struct ProteinArcRing: View {
    let current: Int
    let target: Int
    let carbs: Int
    let fat: Int
    let calories: Int

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [AppTheme.coachOrange.opacity(0.06), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                LabelCapsText(text: "Daily Protein")
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .stroke(AppTheme.surfaceContainerHighest.opacity(0.5), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(AppTheme.coachOrange, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(current)")
                                .font(.system(size: 44, weight: .heavy, design: .rounded))
                            Text("g")
                                .font(.title3.weight(.semibold))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                        .monospacedDigit()
                        Text("of \(target)g goal")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .frame(width: 180, height: 180)
                .padding(.vertical, 8)

                HStack {
                    macroStat(value: "\(carbs)g", label: "Carbs")
                    divider
                    macroStat(value: "\(fat)g", label: "Fat")
                    divider
                    macroStat(value: calories.formatted(), label: "Kcal")
                }
            }
            .padding(16)
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow, radius: 16, y: 6)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.surfaceContainerHighest)
            .frame(width: 1, height: 36)
    }

    private func macroStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Coach insight card (Fix My Day)

struct CoachInsightCard: View {
    let message: String
    let actionTitle: String?
    var onAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(AppTheme.coachOrange)
                .frame(width: 48, height: 48)
                .shadow(color: AppTheme.coachOrange.opacity(0.3), radius: 8, y: 4)
                .overlay {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text("Coach Insight")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let actionTitle, let onAction {
                    Button(actionTitle, action: onAction)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.coachOrange)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(AppTheme.coachOrange, lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [AppTheme.surfaceMuted, AppTheme.background],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .strokeBorder(AppTheme.outlineVariant, lineWidth: 1)
        )
    }
}

// MARK: - Daily gap (Coach screen)

struct DailyGapCard: View {
    let proteinCurrent: Int
    let proteinTarget: Int
    let message: String

    private var remaining: Int { max(0, proteinTarget - proteinCurrent) }
    private var progress: Double {
        guard proteinTarget > 0 else { return 0 }
        return min(Double(proteinCurrent) / Double(proteinTarget), 1)
    }

    var body: some View {
        SurfaceCard {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(AppTheme.coachOrange.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .blur(radius: 24)
                    .offset(x: 40, y: -40)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(remaining)g")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.primary)
                            Text("Protein remaining")
                                .font(AppTypography.body)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        LabelCapsText(text: "Goal: \(proteinTarget)g", color: AppTheme.proteinTeal)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppTheme.surfaceMuted)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.warmSun, AppTheme.coachOrange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(12, geo.size.width * progress))
                        }
                    }
                    .frame(height: 14)

                    Text(message)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct NextBestMealCard: View {
    let name: String
    let protein: String
    let calories: String
    let description: String
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.proteinTeal.opacity(0.35), AppTheme.surfaceMuted, AppTheme.outlineVariant.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 2)
                .padding(.bottom, 2)

            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.coachOrange.opacity(0.25), AppTheme.warmSun.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 140)
                        .overlay {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(AppTheme.coachOrange.opacity(0.45))
                        }

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.coachOrange)
                        LabelCapsText(text: protein, color: AppTheme.primary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(12)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(name)
                        .font(AppTypography.title3.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(description)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(AppTypography.caption2.weight(.semibold))
                                .foregroundStyle(AppTheme.proteinTeal)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.proteinTeal.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        Text(calories)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(16)
            }
        .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .strokeBorder(AppTheme.outlineVariant.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: AppTheme.coachOrange.opacity(0.08), radius: 16, y: 8)
    }
}

struct DailyHealthCard: View {
    let snapshot: DailyHealthSnapshot
    var onConnect: (() -> Void)?

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    LabelCapsText(text: "Apple Health", color: AppTheme.textSecondary)
                    Spacer()
                    if snapshot.hasAnyData {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                    }
                }

                if snapshot.hasAnyData {
                    HStack(spacing: 12) {
                        healthMetric(
                            icon: "bed.double.fill",
                            title: "Sleep",
                            value: snapshot.hasSleepData ? snapshot.sleepSummary : "—"
                        )
                        healthMetric(
                            icon: "figure.run",
                            title: "Workouts",
                            value: snapshot.hasWorkoutData ? snapshot.workoutSummary : "—"
                        )
                    }
                    HStack(spacing: 12) {
                        healthMetric(
                            icon: "flame.fill",
                            title: "Active",
                            value: snapshot.activeCalories > 0 ? "\(snapshot.activeCalories) kcal" : "—"
                        )
                        healthMetric(
                            icon: "shoeprints.fill",
                            title: "Steps",
                            value: snapshot.steps > 0 ? snapshot.steps.formatted() : "—"
                        )
                    }
                } else if let onConnect {
                    Text("Connect Apple Health to include sleep and workouts in your daily coaching.")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Button("Connect Apple Health", action: onConnect)
                        .buttonStyle(OutlineButtonStyle())
                }
            }
        }
    }

    private func healthMetric(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(AppTheme.coachOrange)
                .frame(width: 32, height: 32)
                .background(AppTheme.coachOrange.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                LabelCapsText(text: title, color: AppTheme.textTertiary)
                Text(value)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Streak pill

struct StreakPill: View {
    let days: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(AppTheme.coachOrange)
            Text("\(days) Day Streak!")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(AppTheme.warmSun.opacity(0.2))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(AppTheme.warmSun.opacity(0.35), lineWidth: 1))
    }
}

// MARK: - Meal row (dashboard)

struct KineticMealRow: View {
    let meal: MealRecord

    var body: some View {
        HStack(spacing: 16) {
            mealThumb
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.mealName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                if !meal.mealNote.isEmpty {
                    Text(meal.mealNote)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                if meal.proteinMidpoint >= 30 {
                    LabelCapsText(text: "High Protein", color: AppTheme.proteinTeal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.proteinTeal.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(meal.proteinMidpoint)g")
                    .font(.title2.weight(.black))
                    .foregroundStyle(AppTheme.proteinTeal)
                    .monospacedDigit()
                LabelCapsText(text: "Protein", color: AppTheme.textSecondary)
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceContainerHighest, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var mealThumb: some View {
        Group {
            if let data = meal.imageData, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                AppTheme.surfaceMuted.overlay {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(AppTheme.coachOrange)
                }
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

extension MealRecord {
    var proteinMidpoint: Int { (proteinMin + proteinMax) / 2 }
    var carbsMidpoint: Int { (carbsMin + carbsMax) / 2 }
    var fatMidpoint: Int { (fatMin + fatMax) / 2 }
    var caloriesMidpoint: Int { (caloriesMin + caloriesMax) / 2 }
}

// MARK: - Onboarding

struct OnboardingChrome: View {
    let step: Int
    let totalSteps: Int
    var showsFinalizing: Bool = false
    var onBack: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                if let onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(showsFinalizing ? AppTheme.warmSun : AppTheme.coachOrange)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.surfaceMuted)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 40, height: 40)
                }
                Spacer()
                Text("Nutriscope AI")
                    .font(.title3.weight(.black))
                    .foregroundStyle(AppTheme.coachOrange)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, AppTheme.marginMain)

            if showsFinalizing {
                HStack {
                    LabelCapsText(text: "Step \(step) of \(totalSteps)", color: AppTheme.outline)
                    Spacer()
                    LabelCapsText(text: "Finalizing", color: AppTheme.coachOrange)
                }
                .padding(.horizontal, AppTheme.marginMain)
            } else {
                LabelCapsText(text: "Step \(step) of \(totalSteps)", color: AppTheme.outline)
            }

            HStack(spacing: 8) {
                ForEach(1...totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? AppTheme.coachOrange : AppTheme.surfaceContainerHighest)
                        .frame(height: 6)
                        .overlay {
                            if index == step && showsFinalizing {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.warmSun, AppTheme.coachOrange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                }
            }
            .padding(.horizontal, 48)
        }
        .padding(.top, 8)
    }
}

struct KineticGoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(goal.accentColor.opacity(isSelected ? 0.14 : 0.08))
                    .frame(width: 120, height: 120)
                    .blur(radius: 28)
                    .offset(x: 36, y: -36)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: goal.icon)
                            .font(.title3)
                            .foregroundStyle(isSelected ? .white : goal.accentColor)
                            .frame(width: 48, height: 48)
                            .background(isSelected ? goal.accentColor : goal.accentColor.opacity(0.12))
                            .clipShape(Circle())
                        Spacer()
                        ZStack {
                            Circle()
                                .strokeBorder(isSelected ? AppTheme.coachOrange : AppTheme.surfaceContainerHighest, lineWidth: 2)
                                .frame(width: 24, height: 24)
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(AppTheme.coachOrange)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    Text(goal.label)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(goal.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .strokeBorder(isSelected ? AppTheme.coachOrange : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: isSelected ? AppTheme.coachOrange.opacity(0.15) : AppTheme.coachOrange.opacity(0.05),
                radius: isSelected ? 16 : 10,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

struct KineticDietChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? AppTheme.coachOrange : AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? AppTheme.coachOrange.opacity(0.12) : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isSelected ? AppTheme.coachOrange : AppTheme.outlineVariant.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct KineticActivityCard: View {
    let level: ActivityLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: level.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
                    .frame(width: 48, height: 48)
                    .background(isSelected ? AppTheme.coachOrange : AppTheme.surfaceMuted)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.label)
                        .font(.body.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(level.subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? AppTheme.coachOrange : AppTheme.surfaceContainerHighest, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(AppTheme.coachOrange)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(14)
            .background(isSelected ? AppTheme.coachOrange.opacity(0.08) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? AppTheme.coachOrange : AppTheme.outlineVariant.opacity(0.5), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingTargetHero: View {
    let proteinTarget: Int
    let goal: FitnessGoal

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.surfaceMuted)
                .frame(width: 240, height: 240)
                .shadow(color: AppTheme.coachOrange.opacity(0.2), radius: 24, y: 8)
            Circle()
                .stroke(AppTheme.background, lineWidth: 4)
                .frame(width: 220, height: 220)
            Circle()
                .fill(AppTheme.surfaceMuted.opacity(0.5))
                .frame(width: 200, height: 200)

            VStack(spacing: 8) {
                LabelCapsText(text: "Daily Protein Goal", color: AppTheme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(proteinTarget)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.coachOrange)
                    Text("g")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.primary.opacity(0.7))
                }
                HStack(spacing: 4) {
                    Image(systemName: goal == .loseFat ? "arrow.down.right" : "arrow.up.right")
                        .font(.caption)
                    Text(goal.targetBadgeText)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.warmSun.opacity(0.45))
                .clipShape(Capsule())
                .padding(.top, 4)
            }
        }
        .frame(height: 260)
    }
}

struct ManualLogPaperCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .shadow(color: AppTheme.coachOrange.opacity(0.08), radius: 16, y: 6)
    }
}

struct QuickAddTile: View {
    let emoji: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 28))
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppTheme.outlineVariant.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct KineticFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? AppTheme.coachOrange : AppTheme.surfaceMuted)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct KineticMacroHero: View {
    let protein: String
    let calories: String
    let confidence: ConfidenceLevel

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PROTEIN")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(protein)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.proteinTeal)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("CALORIES")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(calories)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceContainerHighest, lineWidth: 1)
        )
    }
}

// MARK: - Auth & forms

struct KineticAuthHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.coachOrange)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                }
                .shadow(color: AppTheme.coachOrange.opacity(0.25), radius: 8, y: 4)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct KineticAuthField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .padding(14)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppTheme.surfaceContainerHighest, lineWidth: 1)
            )
        }
    }
}

struct KineticAuthIconField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.coachOrange)
                .frame(width: 24)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                        .autocorrectionDisabled(keyboardType == .emailAddress)
                }
            }
        }
        .padding(14)
        .background(AppTheme.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppTheme.outlineVariant.opacity(0.5), lineWidth: 1)
        )
    }
}

struct KineticAuthFormCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
        }
        .shadow(color: AppTheme.coachOrange.opacity(0.08), radius: 16, y: 8)
    }
}

// MARK: - Stitch auth (sign_in / sign_up designs)

struct StitchAuthOrDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(AppTheme.surfaceContainerHighest)
                .frame(height: 1)
            Text("OR CONTINUE WITH")
                .font(AppTypography.labelCaps)
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(0.8)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Rectangle()
                .fill(AppTheme.surfaceContainerHighest)
                .frame(height: 1)
        }
    }
}

struct StitchSignInLogoHeader: View {
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.primaryContainer)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                }
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)

            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Sign in to access your protein data and coaching.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct StitchSignInField: View {
    let label: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var keyboardType: UIKeyboardType = .default
    var trailing: AnyView?

    init(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        trailing: (any View)? = nil
    ) {
        self.label = label
        self.icon = icon
        self.placeholder = placeholder
        _text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.trailing = trailing.map { AnyView($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
            HStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(AppTheme.outline)
                    .frame(width: 44)
                field
                if let trailing {
                    trailing
                        .padding(.trailing, 8)
                }
            }
            .padding(.vertical, 4)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(AppTheme.surfaceContainerHighest, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var field: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        } else {
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .sentences)
                .autocorrectionDisabled(keyboardType == .emailAddress)
        }
    }
}

struct StitchCoachTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(AppTypography.labelCaps)
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(0.6)
                .padding(.leading, 4)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                        .autocorrectionDisabled(keyboardType == .emailAddress)
                }
            }
            .font(AppTypography.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(AppTheme.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct StitchAuthTopBar: View {
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.coachOrange)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Nutriscope AI")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.coachOrange)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, AppTheme.marginMain)
        .frame(height: 56)
    }
}

struct StitchAuthPrimaryButton: View {
    let title: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.body.weight(.semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.coachOrange)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: AppTheme.coachOrange.opacity(0.25), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

struct StitchAppleSignInRow: View {
    var onSuccess: () -> Void
    var onError: (String) -> Void

    var body: some View {
        SignInWithAppleButton(onSuccess: onSuccess, onError: onError)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
    }
}

struct StitchCircularAppleButton: View {
    var onSuccess: () -> Void
    var onError: (String) -> Void

    var body: some View {
        SignInWithAppleButton(onSuccess: onSuccess, onError: onError)
            .frame(width: 64, height: 64)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(AppTheme.surfaceContainerHighest, lineWidth: 1)
            )
    }
}

struct KineticToolHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title2.weight(.black))
                .foregroundStyle(AppTheme.coachOrange)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct KineticEmptyState: View {
    var imageName: String?
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.coachOrange.opacity(0.7))
            }
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceContainerHighest.opacity(0.5), lineWidth: 1)
        )
    }
}

struct MealMacroBentoGrid: View {
    let protein: String
    let carbs: String
    let fat: String

    var body: some View {
        HStack(spacing: 10) {
            bentoCell(title: "Protein", value: protein, highlight: true)
            bentoCell(title: "Carbs", value: carbs, highlight: false)
            bentoCell(title: "Fat", value: fat, highlight: false)
        }
    }

    private func bentoCell(title: String, value: String, highlight: Bool) -> some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(AppTypography.caption2.weight(.bold))
                .foregroundStyle(highlight ? AppTheme.primary.opacity(0.8) : AppTheme.textSecondary)
            Text(value)
                .font(AppTypography.headline.weight(.bold))
                .foregroundStyle(highlight ? AppTheme.primary : AppTheme.textPrimary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(highlight ? AppTheme.coachOrange.opacity(0.12) : AppTheme.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(highlight ? AppTheme.coachOrange.opacity(0.25) : AppTheme.surfaceContainerHighest, lineWidth: 1)
        )
    }
}

struct KineticAccountOptionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let background: Color
    var border: Color?
    var isRecommended = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isRecommended {
                Text("RECOMMENDED")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.coachOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.coachOrange.opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.bottom, 10)
            }

            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 48, height: 48)
                    .background(iconColor.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .padding(18)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .overlay {
            if let border {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            }
        }
        .shadow(color: AppTheme.cardShadow, radius: 8, y: 3)
    }
}

// MARK: - Profile (user_profile_settings)

struct ProfileHeroHeader: View {
    let displayName: String
    let email: String

    private var initials: String {
        let parts = displayName.split(separator: " ").prefix(2).map { String($0.prefix(1)) }
        if parts.isEmpty, !email.isEmpty { return String(email.prefix(1)).uppercased() }
        return parts.joined().uppercased()
    }

    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.coachOrange.opacity(0.25), AppTheme.warmSun.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)
                .overlay {
                    Text(initials.isEmpty ? "?" : initials)
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.primary)
                }
                .overlay(Circle().strokeBorder(AppTheme.surface, lineWidth: 4))
                .shadow(color: AppTheme.coachOrange.opacity(0.15), radius: 12, y: 6)

            Text(displayName.isEmpty ? "Your Profile" : displayName)
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppTheme.textPrimary)

            if !email.isEmpty {
                Text(email)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

struct ProfileProCard: View {
    let isPro: Bool
    let subtitle: String
    var manageLabel: String = "Manage"
    var onUpgrade: (() -> Void)?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(AppTheme.coachOrange.opacity(0.12))
                .frame(width: 120, height: 120)
                .blur(radius: 24)
                .offset(x: 36, y: -36)

            HStack(spacing: 14) {
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.coachOrange)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.coachOrange.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(isPro ? "Nutriscope Pro" : "Subscription required")
                        .font(AppTypography.title3.weight(.bold))
                    Text(subtitle)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer(minLength: 0)

                if isPro {
                    Text(manageLabel)
                        .font(AppTypography.labelCaps)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppTheme.coachOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else if let onUpgrade {
                    Button("Upgrade", action: onUpgrade)
                        .font(AppTypography.labelCaps)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppTheme.coachOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [AppTheme.surface, AppTheme.surfaceMuted.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppTheme.outlineVariant.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: AppTheme.coachOrange.opacity(0.08), radius: 16, y: 8)
    }
}

struct ProfileMenuSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LabelCapsText(text: title, color: AppTheme.textSecondary)
                .padding(.leading, 8)

            VStack(spacing: 0) {
                content()
            }
            .padding(8)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.03), radius: 12, y: 4)
        }
    }
}

struct ProfileMenuRow: View {
    let icon: String
    var iconColor: Color = AppTheme.textSecondary
    let title: String
    var subtitle: String?
    var isDestructive = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(isDestructive ? AppTheme.primary : iconColor)
                .frame(width: 40, height: 40)
                .background((isDestructive ? AppTheme.coachOrange : iconColor).opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(isDestructive ? AppTheme.primary : AppTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer(minLength: 0)

            if !isDestructive {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .padding(10)
        .contentShape(Rectangle())
    }
}

struct ProfileMenuDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 64)
            .padding(.trailing, 8)
    }
}

// MARK: - Meals history (meal_history_redesign)

struct KineticPeriodPills<Item: Hashable & Identifiable>: View where Item: RawRepresentable, Item.RawValue == String {
    let items: [Item]
    @Binding var selection: Item

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    Button {
                        selection = item
                    } label: {
                        Text(item.rawValue.uppercased())
                            .font(AppTypography.labelCaps)
                            .foregroundStyle(selection == item ? .white : AppTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selection == item ? AppTheme.coachOrange : AppTheme.surfaceMuted)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: selection == item ? AppTheme.coachOrange.opacity(0.2) : .clear, radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct KineticFrequentMealCard: View {
    let name: String
    let proteinLabel: String
    var imageData: Data?
    var onLog: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Group {
                    if let imageData, let img = UIImage(data: imageData) {
                        Image(uiImage: img).resizable().scaledToFill()
                    } else {
                        AppTheme.surfaceMuted.overlay {
                            Image(systemName: "fork.knife")
                                .foregroundStyle(AppTheme.coachOrange.opacity(0.6))
                        }
                    }
                }
                .frame(width: 120, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(name)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                LabelCapsText(text: proteinLabel, color: AppTheme.coachOrange)
            }
            .padding(12)
            .frame(width: 132)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.surfaceContainerHighest, lineWidth: 1)
            )
            .shadow(color: AppTheme.coachOrange.opacity(0.06), radius: 12, y: 4)

            Button(action: onLog) {
                Image(systemName: "plus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.coachOrange)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.coachOrange.opacity(0.3), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: 6)
        }
        .padding(.bottom, 6)
    }
}

struct KineticMealHistoryRow: View {
    let meal: MealRecord
    var isHighProtein: Bool { meal.proteinMidpoint >= 30 }

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: meal.scannedAt)
    }

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let data = meal.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    AppTheme.surfaceMuted.overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(AppTheme.coachOrange)
                    }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(meal.mealName)
                        .font(AppTypography.body.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Text(timeLabel)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Text("\(meal.caloriesMidpoint) kcal")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                HStack(spacing: 6) {
                    macroChip(
                        "\(meal.proteinMidpoint)g Protein",
                        highlight: isHighProtein,
                        teal: isHighProtein
                    )
                    macroChip("\(meal.carbsMidpoint)g C", highlight: false, teal: false)
                    macroChip("\(meal.fatMidpoint)g F", highlight: false, teal: false)
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .leading) {
            if isHighProtein {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.proteinTeal)
                    .frame(width: 4)
            }
        }
        .shadow(color: AppTheme.coachOrange.opacity(isHighProtein ? 0.08 : 0.04), radius: 12, y: 4)
    }

    private func macroChip(_ text: String, highlight: Bool, teal: Bool) -> some View {
        Text(text.uppercased())
            .font(AppTypography.caption2.weight(.semibold))
            .foregroundStyle(teal ? AppTheme.proteinTeal : (highlight ? AppTheme.coachOrange : AppTheme.textSecondary))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                teal ? AppTheme.proteinTeal.opacity(0.1) :
                    (highlight ? AppTheme.coachOrange.opacity(0.1) : AppTheme.surfaceMuted)
            )
            .clipShape(Capsule())
            .overlay {
                if highlight || teal {
                    Capsule().strokeBorder((teal ? AppTheme.proteinTeal : AppTheme.coachOrange).opacity(0.2), lineWidth: 1)
                }
            }
    }
}

// MARK: - Weekly report (weekly_progress_report)

struct KineticReportStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var suffix: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor.opacity(0.85))
                LabelCapsText(text: title, color: AppTheme.textSecondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(iconColor == AppTheme.proteinTeal ? AppTheme.proteinTeal : AppTheme.textPrimary)
                    .monospacedDigit()
                if let suffix {
                    Text(suffix)
                        .font(AppTypography.title3)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.coachOrange.opacity(0.08), radius: 12, y: 4)
    }
}

struct KineticWeeklyProteinChart: View {
    let summaries: [WeeklyReportCalculator.DaySummary]
    let proteinTarget: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Protein vs Goal")
                    .font(AppTypography.title3.weight(.semibold))
                Spacer()
                HStack(spacing: 6) {
                    Capsule().fill(AppTheme.warmSun).frame(width: 16, height: 3)
                    LabelCapsText(text: "Goal: \(proteinTarget)g", color: AppTheme.textSecondary)
                }
            }

            GeometryReader { geo in
                let maxProtein = max(proteinTarget, summaries.map(\.protein).max() ?? proteinTarget, 1)
                ZStack(alignment: .bottom) {
                    Path { path in
                        let y = geo.size.height * (1 - CGFloat(proteinTarget) / CGFloat(maxProtein))
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .foregroundStyle(AppTheme.warmSun.opacity(0.8))

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(summaries) { day in
                            VStack(spacing: 8) {
                                ZStack(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(AppTheme.surfaceMuted)
                                        .frame(height: geo.size.height * 0.85)
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(day.hitGoal ? AppTheme.coachOrange : AppTheme.proteinTeal)
                                        .frame(height: max(8, geo.size.height * CGFloat(day.protein) / CGFloat(maxProtein)))
                                        .opacity(day.hitGoal ? 0.95 : 0.85)
                                }
                                LabelCapsText(text: day.label, color: AppTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.coachOrange.opacity(0.08), radius: 12, y: 4)
    }
}

// MARK: - Paywall (nutriscope_pro_paywall)

struct KineticPaywallFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(AppTheme.surfaceMuted)
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.coachOrange)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

struct KineticPlanOptionCard: View {
    let title: String
    let subtitle: String
    let price: String
    let priceSuffix: String
    var badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let badge, isSelected {
                        Text(badge.uppercased())
                            .font(AppTypography.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.warmSun)
                            .clipShape(Capsule())
                    }
                    Text(title)
                        .font(AppTypography.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(AppTypography.subheadline.weight(.bold))
                        .foregroundStyle(isSelected ? AppTheme.coachOrange : AppTheme.textPrimary)
                    Text(priceSuffix)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(16)
            .background(isSelected ? AppTheme.surface : AppTheme.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? AppTheme.coachOrange : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? AppTheme.coachOrange.opacity(0.12) : .clear, radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct KineticMacroStatCell: View {
    let label: String
    let value: String
    var highlight = false

    var body: some View {
        VStack(spacing: 6) {
            LabelCapsText(text: label, color: AppTheme.textTertiary)
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(highlight ? AppTheme.coachOrange : AppTheme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct KineticMacroProgressBar: View {
    let label: String
    let value: String
    let progress: Double
    let color: Color
    var thick = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(value)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.surfaceMuted)
                    Capsule()
                        .fill(color)
                        .frame(width: max(4, geo.size.width * min(max(progress, 0), 1)))
                }
            }
            .frame(height: thick ? 12 : 8)
        }
    }
}

struct KineticIngredientRow: View {
    let name: String
    let detail: String
    let macroHighlight: String
    let calories: String
    let icon: String
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppTheme.surfaceMuted)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(AppTheme.textTertiary)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(AppTypography.subheadline.weight(.semibold))
                Text(detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(macroHighlight)
                    .font(AppTypography.caption.weight(.bold))
                    .foregroundStyle(AppTheme.proteinTeal)
                Text(calories)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppTheme.outlineVariant.opacity(0.4), lineWidth: 1)
        )
    }
}

struct KineticWeightAreaChart: View {
    let logs: [WeightLog]

    private var sortedLogs: [WeightLog] { logs.sorted { $0.loggedAt < $1.loggedAt } }
    private var minWeight: Double { sortedLogs.map(\.weightKg).min() ?? 0 }
    private var maxWeight: Double { sortedLogs.map(\.weightKg).max() ?? 1 }
    private var span: Double { max(maxWeight - minWeight, 0.5) }

    var body: some View {
        GeometryReader { geo in
            let inset: CGFloat = 24
            let chartW = geo.size.width - inset
            let chartH = geo.size.height - inset

            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    let y = inset / 2 + chartH * CGFloat(i) / 2
                    Path { path in
                        path.move(to: CGPoint(x: inset / 2, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width - 8, y: y))
                    }
                    .stroke(AppTheme.outlineVariant.opacity(0.35), lineWidth: 1)
                }

                if sortedLogs.count >= 2 {
                    let points: [CGPoint] = sortedLogs.enumerated().map { index, log in
                        let x = inset / 2 + chartW * CGFloat(index) / CGFloat(max(sortedLogs.count - 1, 1))
                        let normalized = (log.weightKg - minWeight) / span
                        let y = inset / 2 + chartH * (1 - CGFloat(normalized))
                        return CGPoint(x: x, y: y)
                    }

                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: geo.size.height - inset / 2))
                        path.addLine(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: points.last!.x, y: geo.size.height - inset / 2))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.coachOrange.opacity(0.25), AppTheme.coachOrange.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(AppTheme.coachOrange, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(AppTheme.coachOrange)
                            .frame(width: 8, height: 8)
                            .position(point)
                    }
                }
            }
        }
    }
}

// MARK: - Coach chat (coach_chat_2)

struct KineticChatDateDivider: View {
    let label: String

    var body: some View {
        Text(label.uppercased())
            .font(AppTypography.labelCaps)
            .foregroundStyle(AppTheme.textSecondary)
            .tracking(1.2)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppTheme.surfaceMuted)
            .clipShape(Capsule())
            .frame(maxWidth: .infinity)
    }
}

struct KineticCoachChatBubble: View {
    let role: CoachChatRole
    let text: String

    var body: some View {
        switch role {
        case .coach:
            HStack(alignment: .bottom, spacing: 8) {
                coachAvatar
                Text(text)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.surfaceMuted)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 16,
                            bottomLeadingRadius: 4,
                            bottomTrailingRadius: 16,
                            topTrailingRadius: 16
                        )
                    )
                    .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
                Spacer(minLength: 40)
            }
        case .user:
            HStack(alignment: .bottom, spacing: 8) {
                Spacer(minLength: 40)
                Text(text)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.coachOrange.opacity(0.14))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 16,
                            bottomLeadingRadius: 16,
                            bottomTrailingRadius: 4,
                            topTrailingRadius: 16
                        )
                    )
                    .shadow(color: AppTheme.coachOrange.opacity(0.08), radius: 8, y: 4)
            }
        case .suggestion:
            EmptyView()
        }
    }

    private var coachAvatar: some View {
        Circle()
            .fill(AppTheme.surfaceMuted)
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundStyle(AppTheme.coachOrange)
            }
    }
}

struct KineticCoachSuggestionCard: View {
    let proteinGrams: Int
    var onAccept: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text("Coach Suggestion")
                    .font(AppTypography.headline)
            } icon: {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(AppTheme.coachOrange)
            }

            Text("Try adding \(proteinGrams)g protein to your next meal to stabilize energy and close today's gap.")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 10) {
                Button("Add Protein Focus", action: onAccept)
                    .buttonStyle(PrimaryButtonStyle())
                Button("Skip", action: onSkip)
                    .buttonStyle(OutlineButtonStyle())
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.outlineVariant.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: AppTheme.coachOrange.opacity(0.05), radius: 16, y: 6)
        .padding(.leading, 40)
    }
}

struct KineticCoachChatInputBar: View {
    @Binding var text: String
    var onSend: () -> Void
    var onQuickPrompts: () -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onQuickPrompts) {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.surfaceContainerHighest)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            TextField("Ask your coach...", text: $text, axis: .vertical)
                .lineLimit(1...4)
                .font(AppTypography.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(AppTheme.outlineVariant.opacity(0.6), lineWidth: 1)
                )

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(canSend ? AppTheme.coachOrange : AppTheme.surfaceContainerHighest)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.coachOrange.opacity(canSend ? 0.3 : 0), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, AppTheme.marginMain)
        .padding(.vertical, 12)
        .background(AppTheme.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.outlineVariant.opacity(0.35))
                .frame(height: 1)
        }
    }
}
