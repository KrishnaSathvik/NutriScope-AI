import SwiftData
import SwiftUI

struct WeightTrackingSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightLog.loggedAt, order: .reverse) private var logs: [WeightLog]
    @Query(sort: \MealRecord.scannedAt, order: .reverse) private var meals: [MealRecord]
    @Query private var settings: [UserSettings]

    @State private var weightInput = ""

    private var latest: WeightLog? { logs.first }
    private var trendLogs: [WeightLog] {
        Array(logs.prefix(30).reversed())
    }

    private var weightChangeKg: Double? {
        guard logs.count >= 2 else { return nil }
        let recent = logs.prefix(7).map(\.weightKg)
        let older = logs.dropFirst(7).prefix(7).map(\.weightKg)
        guard !recent.isEmpty, !older.isEmpty else { return nil }
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)
        return recentAvg - olderAvg
    }

    private var avgProteinWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let weekMeals = meals.filter { $0.scannedAt >= weekAgo }
        guard !weekMeals.isEmpty else { return 0 }
        return weekMeals.reduce(0) { $0 + $1.proteinMidpoint } / max(1, Set(weekMeals.map { Calendar.current.startOfDay(for: $0.scannedAt) }).count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weight Tracking")
                    .font(AppTypography.title3.weight(.semibold))
                Text("Log your morning weight consistently for the best insights.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            currentWeightCard
            logWeightCard

            if trendLogs.count >= 2 {
                trendChartCard
                coachInsightCard
            }
        }
    }

    private var currentWeightCard: some View {
        SurfaceCard {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(AppTheme.coachOrange.opacity(0.12))
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)
                    .offset(x: 20, y: -20)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        LabelCapsText(text: "Current", color: AppTheme.textTertiary)
                        Spacer()
                        if let change = weightChangeKg {
                            HStack(spacing: 4) {
                                Image(systemName: change <= 0 ? "arrow.down.right" : "arrow.up.right")
                                    .font(.caption2.weight(.bold))
                                Text(String(format: "%+.1f kg", change))
                                    .font(AppTypography.labelCaps)
                            }
                            .foregroundStyle(change <= 0 ? AppTheme.proteinTeal : AppTheme.coachOrange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.surfaceMuted)
                            .clipShape(Capsule())
                        }
                    }

                    if let latest {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", latest.weightKg))
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                            Text("kg")
                                .font(AppTypography.body)
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        Text("Last logged: \(latest.loggedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        Text("—")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                        Text("No entries yet")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
    }

    private var logWeightCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Log Today's Weight")
                    .font(AppTypography.subheadline.weight(.semibold))
                HStack(spacing: 10) {
                    TextField("000.0", text: $weightInput)
                        .keyboardType(.decimalPad)
                        .padding(14)
                        .background(AppTheme.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Text("kg")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.textTertiary)
                    Button("Log") { logWeight() }
                        .buttonStyle(PrimaryButtonStyle(pill: true))
                }
            }
        }
    }

    private var trendChartCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("30-Day Trend")
                        .font(AppTypography.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(trendLogs.count) entries")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.coachOrange)
                }
                KineticWeightAreaChart(logs: trendLogs)
                    .frame(height: 160)
                HStack {
                    if let first = trendLogs.first {
                        LabelCapsText(text: first.loggedAt.formatted(.dateTime.month(.abbreviated).day()), color: AppTheme.textTertiary)
                    }
                    Spacer()
                    if let last = trendLogs.last {
                        LabelCapsText(text: last.loggedAt.formatted(.dateTime.month(.abbreviated).day()), color: AppTheme.textTertiary)
                    }
                }
            }
        }
    }

    private var coachInsightCard: some View {
        SurfaceCard {
            HStack(alignment: .top, spacing: 14) {
                Circle()
                    .fill(AppTheme.coachOrange.opacity(0.12))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(AppTheme.coachOrange)
                    }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Coach's Insight")
                        .font(AppTypography.subheadline.weight(.semibold))
                    Text(coachInsightText)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var coachInsightText: String {
        let target = settings.first?.dailyProteinTarget ?? 135
        if avgProteinWeek >= target - 10 {
            return "Your weight trend and protein intake (\(avgProteinWeek)g/day avg) look aligned — you're likely maintaining muscle while adjusting body weight."
        }
        if let change = weightChangeKg, change < -0.3 {
            return "Weight is trending down. Prioritize \(target)g protein daily to protect lean mass during the cut."
        }
        return "Consistent morning weigh-ins plus hitting \(target)g protein will give clearer trend signals next week."
    }

    private func logWeight() {
        guard let value = Double(weightInput.replacingOccurrences(of: ",", with: ".")), value > 0 else { return }
        modelContext.insert(WeightLog(weightKg: value))
        try? modelContext.save()
        weightInput = ""
    }
}

#Preview {
    WeightTrackingSection()
        .padding()
        .modelContainer(for: [WeightLog.self, MealRecord.self, UserSettings.self], inMemory: true)
}
