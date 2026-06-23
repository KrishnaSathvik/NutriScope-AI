import SwiftData
import SwiftUI

struct WeeklyReportView: View {
    @Query(sort: \MealRecord.scannedAt, order: .reverse) private var meals: [MealRecord]
    @Query private var settings: [UserSettings]

    private var user: UserSettings? { settings.first }
    private var proteinTarget: Int { user?.dailyProteinTarget ?? 135 }

    private var report: WeeklyReportCalculator.Report {
        WeeklyReportCalculator.build(
            from: meals,
            proteinTarget: proteinTarget,
            calorieMin: user?.calorieRangeMin ?? 1900,
            calorieMax: user?.calorieRangeMax ?? 2200
        )
    }

    private var weekRangeLabel: String {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return "This week"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) – \(formatter.string(from: weekEnd))"
    }

    var body: some View {
        BoundedScrollView {

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Report")
                        .font(AppTypography.largeTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(weekRangeLabel)
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    KineticReportStatCard(
                        icon: "calendar.badge.checkmark",
                        iconColor: AppTheme.coachOrange,
                        title: "Days Logged",
                        value: "\(report.daysLogged)",
                        suffix: "/7"
                    )
                    KineticReportStatCard(
                        icon: "target",
                        iconColor: AppTheme.proteinTeal,
                        title: "Goal Hits",
                        value: "\(report.daysHitGoal)",
                        suffix: "/7"
                    )
                    KineticReportStatCard(
                        icon: "figure.strengthtraining.traditional",
                        iconColor: AppTheme.proteinTeal,
                        title: "Avg Protein",
                        value: "\(report.averageProtein)",
                        suffix: "g"
                    )
                    KineticReportStatCard(
                        icon: "flame.fill",
                        iconColor: AppTheme.coachOrange,
                        title: "Avg Cals",
                        value: "\(report.averageCalories)"
                    )
                }

                if !report.dailySummaries.isEmpty {
                    KineticWeeklyProteinChart(summaries: report.dailySummaries, proteinTarget: proteinTarget)
                }

                coachHighlightsSection

                if !report.dailySummaries.isEmpty {
                    Text("Daily breakdown")
                        .font(AppTypography.title3.weight(.semibold))

                    ForEach(report.dailySummaries) { day in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(day.label)
                                    .font(AppTypography.subheadline.weight(.semibold))
                                Text("\(day.protein)g protein · ~\(day.calories) kcal · \(day.mealCount) meals")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            if day.hitGoal {
                                Label("Hit", systemImage: "checkmark.circle.fill")
                                    .font(AppTypography.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.proteinTeal)
                            }
                        }
                        .padding(14)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(AppTheme.marginMain)
        
        }
        .background(AppBackground())
        .navigationTitle("Weekly report")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var coachHighlightsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Circle()
                    .fill(AppTheme.coachOrange.opacity(0.12))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(AppTheme.coachOrange)
                    }
                Text("Coach Highlights")
                    .font(AppTypography.title3.weight(.semibold))
            }

            highlightRow(icon: "checkmark.circle.fill", text: report.coachSummary, accent: AppTheme.proteinTeal)

            if let best = report.bestDay {
                highlightRow(
                    icon: "checkmark.circle.fill",
                    text: "Best day: \(best.label) with \(best.protein)g protein across \(best.mealCount) meals.",
                    accent: AppTheme.proteinTeal
                )
            }

            if let low = report.lowestProteinDay, report.daysLogged > 1, !low.hitGoal {
                highlightRow(
                    icon: "lightbulb.fill",
                    text: "\(low.label) was lighter (\(low.protein)g). Prep a high-protein snack for similar days.",
                    accent: AppTheme.coachOrange
                )
            }
        }
        .padding(16)
        .background(AppTheme.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.outlineVariant.opacity(0.35), lineWidth: 1)
        )
    }

    private func highlightRow(icon: String, text: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(accent)
                .padding(.top, 2)
            Text(text)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack { WeeklyReportView() }
        .modelContainer(for: [MealRecord.self, UserSettings.self], inMemory: true)
}
