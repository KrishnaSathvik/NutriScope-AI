import SwiftData
import SwiftUI

struct InsightsTrendsView: View {
    @Query(sort: \MealRecord.scannedAt, order: .reverse) private var meals: [MealRecord]
    @Query private var settings: [UserSettings]
    @State private var healthService = HealthKitService.shared

    private var user: UserSettings? { settings.first }
    private var proteinTarget: Int { user?.dailyProteinTarget ?? 135 }

    private var proteinToday: Int {
        meals.filter { Calendar.current.isDateInToday($0.scannedAt) }
            .reduce(0) { $0 + $1.analysis.proteinMidpoint }
    }

    private var report: InsightsTrendsCalculator.Report {
        var base = InsightsTrendsCalculator.build(
            from: meals,
            proteinTarget: proteinTarget
        )
        let healthObservations = HealthInsightsBuilder.observations(
            snapshot: healthService.todaySnapshot,
            proteinTarget: proteinTarget,
            proteinToday: proteinToday
        )
        if !healthObservations.isEmpty {
            base = InsightsTrendsCalculator.Report(
                weeklyPoints: base.weeklyPoints,
                macroSplit: base.macroSplit,
                scatterPoints: base.scatterPoints,
                observations: Array((healthObservations + base.observations).prefix(4)),
                proteinTarget: base.proteinTarget
            )
        }
        return base
    }

    var body: some View {
        BoundedScrollView {

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Trends")
                        .font(AppTypography.largeTitle)
                        .foregroundStyle(AppTheme.inkBlack)
                    Text("Deep nutritional insights powered by your coach.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                progressOverTimeCard
                macroSplitCard
                observationsSection
                proteinDensityCard
            }
            .padding(AppTheme.marginMain)
            .padding(.bottom, 32)
        
        }
        .background(AppBackground())
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if healthService.isAuthorized {
                await healthService.refreshToday()
            }
        }
    }

    private var progressOverTimeCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progress Over Time")
                            .font(AppTypography.title3.weight(.semibold))
                        Text("Daily protein vs. \(proteinTarget)g goal")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Circle()
                        .fill(AppTheme.coachOrange.opacity(0.12))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(AppTheme.coachOrange)
                        }
                }
                WeeklyProteinAreaChart(points: report.weeklyPoints, target: proteinTarget)
            }
        }
    }

    private var macroSplitCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Macro Split")
                    .font(AppTypography.title3.weight(.semibold))
                Text("Current week average")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                MacroDonutChart(split: report.macroSplit)

                VStack(spacing: 10) {
                    macroRow(color: AppTheme.coachOrange, label: "Protein", grams: report.macroSplit.proteinGrams)
                    macroRow(color: AppTheme.warmSun, label: "Carbs", grams: report.macroSplit.carbsGrams)
                    macroRow(color: AppTheme.proteinTeal, label: "Fats", grams: report.macroSplit.fatGrams)
                }
            }
        }
    }

    private func macroRow(color: Color, label: String, grams: Int) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(label)
                    .font(AppTypography.subheadline)
            }
            Spacer()
            Text("\(grams)g")
                .font(AppTypography.subheadline.weight(.semibold))
        }
    }

    private var observationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(AppTheme.warmSun)
                Text("Coach AI Observations")
                    .font(AppTypography.title3.weight(.semibold))
            }
            .padding(.horizontal, 4)

            SurfaceCard {
                VStack(spacing: 12) {
                    ForEach(report.observations) { observation in
                        HStack(alignment: .top, spacing: 14) {
                            Circle()
                                .fill(AppTheme.coachOrange.opacity(0.12))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Image(systemName: observation.icon)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppTheme.coachOrange)
                                }
                            VStack(alignment: .leading, spacing: 6) {
                                Text(observation.title)
                                    .font(AppTypography.subheadline.weight(.semibold))
                                Text(observation.message)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let tag = observation.tag {
                                    LabelCapsText(text: tag, color: AppTheme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.surfaceMuted)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        if observation.id != report.observations.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var proteinDensityCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Protein Density")
                    .font(AppTypography.title3.weight(.semibold))
                Text("Calories vs. protein per meal (last 7 days)")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                ProteinDensityScatterChart(points: report.scatterPoints)
            }
        }
    }
}

// MARK: - Charts

private struct WeeklyProteinAreaChart: View {
    let points: [InsightsTrendsCalculator.WeeklyPoint]
    let target: Int

    private var maxProtein: Int {
        max(points.map(\.protein).max() ?? target, target, 1)
    }

    var body: some View {
        GeometryReader { geo in
            let goalY = geo.size.height * (1 - CGFloat(target) / CGFloat(maxProtein))
            let barWidth = max(8, (geo.size.width - CGFloat(points.count - 1) * 8) / CGFloat(max(points.count, 1)))

            ZStack(alignment: .bottom) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: goalY))
                    path.addLine(to: CGPoint(x: geo.size.width, y: goalY))
                }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(AppTheme.warmSun.opacity(0.7))

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(points) { point in
                        let height = max(8, geo.size.height * CGFloat(point.protein) / CGFloat(maxProtein))
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: point.hitGoal
                                            ? [AppTheme.warmSun, AppTheme.coachOrange]
                                            : [AppTheme.surfaceContainerHighest, AppTheme.outlineVariant.opacity(0.6)],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: barWidth, height: height)
                            LabelCapsText(text: point.label, color: AppTheme.textTertiary)
                        }
                    }
                }
            }
        }
        .frame(height: 180)
    }
}

private struct MacroDonutChart: View {
    let split: InsightsTrendsCalculator.MacroSplit

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.surfaceMuted, lineWidth: 14)
            Circle()
                .trim(from: 0, to: CGFloat(split.proteinPercent) / 100)
                .stroke(AppTheme.coachOrange, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0, to: CGFloat(split.carbsPercent) / 100)
                .stroke(AppTheme.warmSun, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90 + Double(split.proteinPercent) * 3.6))
            Circle()
                .trim(from: 0, to: CGFloat(split.fatPercent) / 100)
                .stroke(AppTheme.proteinTeal, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90 + Double(split.proteinPercent + split.carbsPercent) * 3.6))

            VStack(spacing: 0) {
                Text("\(split.proteinPercent)%")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                LabelCapsText(text: "Protein", color: AppTheme.textSecondary)
            }
        }
        .frame(width: 128, height: 128)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct ProteinDensityScatterChart: View {
    let points: [InsightsTrendsCalculator.ScatterPoint]

    private var maxCalories: Int { max(points.map(\.calories).max() ?? 800, 400) }
    private var maxProtein: Int { max(points.map(\.protein).max() ?? 60, 30) }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.surfaceMuted.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppTheme.outlineVariant.opacity(0.5))
                    )

                ForEach(0..<3, id: \.self) { index in
                    let y = geo.size.height * CGFloat(index + 1) / 4
                    Path { path in
                        path.move(to: CGPoint(x: 12, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width - 12, y: y))
                    }
                    .stroke(AppTheme.outlineVariant.opacity(0.25), lineWidth: 1)
                }

                ForEach(points) { point in
                    let x = 12 + (geo.size.width - 24) * CGFloat(point.calories) / CGFloat(maxCalories)
                    let y = geo.size.height - 12 - (geo.size.height - 24) * CGFloat(point.protein) / CGFloat(maxProtein)
                    Circle()
                        .fill(color(for: point.density))
                        .frame(width: size(for: point.density), height: size(for: point.density))
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        .position(x: x, y: y)
                }

                LabelCapsText(text: "Calories →", color: AppTheme.textTertiary)
                    .position(x: geo.size.width - 44, y: geo.size.height - 8)
            }
        }
        .frame(height: 180)
    }

    private func color(for density: InsightsTrendsCalculator.ScatterPoint.Density) -> Color {
        switch density {
        case .high: AppTheme.proteinTeal.opacity(0.85)
        case .medium: AppTheme.coachOrange.opacity(0.85)
        case .low: AppTheme.coachOrange.opacity(0.35)
        }
    }

    private func size(for density: InsightsTrendsCalculator.ScatterPoint.Density) -> CGFloat {
        switch density {
        case .high: 12
        case .medium: 16
        case .low: 20
        }
    }
}

#Preview {
    NavigationStack { InsightsTrendsView() }
        .modelContainer(for: [MealRecord.self, UserSettings.self], inMemory: true)
}
