import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \MealRecord.scannedAt, order: .reverse) private var meals: [MealRecord]
    @Query private var settings: [UserSettings]
    @State private var healthService = HealthKitService.shared
    @State private var coachTip = ""

    private var user: UserSettings? { settings.first }
    private var proteinTarget: Int { user?.dailyProteinTarget ?? 135 }
    private var showCalories: Bool { user?.showCalories ?? true }

    private var todaysMeals: [MealRecord] {
        meals.filter { Calendar.current.isDateInToday($0.scannedAt) }
    }

    private var proteinToday: Int {
        todaysMeals.reduce(0) { $0 + $1.analysis.proteinMidpoint }
    }

    private var carbsToday: Int {
        todaysMeals.reduce(0) { $0 + ($1.carbsMin + $1.carbsMax) / 2 }
    }

    private var fatToday: Int {
        todaysMeals.reduce(0) { $0 + ($1.fatMin + $1.fatMax) / 2 }
    }

    private var caloriesToday: Int {
        todaysMeals.reduce(0) { $0 + ($1.caloriesMin + $1.caloriesMax) / 2 }
    }

    private var proteinRemaining: Int { max(0, proteinTarget - proteinToday) }

    private var streak: LoggingStreakCalculator.Result {
        LoggingStreakCalculator.compute(from: meals)
    }

    private var calorieRemaining: (min: Int, max: Int) {
        let minTarget = user?.calorieRangeMin ?? 1900
        let maxTarget = user?.calorieRangeMax ?? 2200
        return (max(0, minTarget - caloriesToday), max(0, maxTarget - caloriesToday))
    }

    private var quickAction: (title: String, gap: Int)? {
        let gap = proteinRemaining
        guard gap > 0 else { return nil }
        if gap <= 15 {
            return ("Log Quick Snack (+\(min(gap, 15))g)", gap)
        }
        return ("Log Quick Shake (+\(min(gap, 25))g)", gap)
    }

    var body: some View {
        VStack(spacing: 0) {
            NutriscopeTopBar(displayName: user?.displayName ?? "")

            BoundedScrollView {

                VStack(alignment: .leading, spacing: 24) {
                    todayHeader
                    ProteinArcRing(
                        current: proteinToday,
                        target: proteinTarget,
                        carbs: carbsToday,
                        fat: fatToday,
                        calories: caloriesToday
                    )
                    CoachInsightCard(
                        message: coachTip.isEmpty ? "Loading coach insight…" : coachTip,
                        actionTitle: quickAction.map(\.title),
                        onAction: quickAction != nil ? { appState.presentScanIfAllowed() } : nil
                    )

                    if healthService.isAvailable {
                        DailyHealthCard(snapshot: healthService.todaySnapshot) {
                            Task { try? await healthService.requestAuthorization() }
                        }
                    }

                    if appState.hasProAccess {
                        tomorrowPlanLink
                    }

                    mealsSection
                }
                .padding(.horizontal, AppTheme.marginMain)
                .padding(.bottom, 24)
            
        }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
        .navigationBarHidden(true)
        .task {
            if healthService.isAuthorized {
                await healthService.refreshToday()
            }
            await loadCoachTip()
        }
        .onChange(of: proteinToday) { _, _ in
            syncWidgetData()
            Task { await loadCoachTip() }
        }
        .onChange(of: coachTip) { _, _ in syncWidgetData() }
    }

    private func loadCoachTip() async {
        let context = OpenAICoachService.makeContext(
            settings: user,
            proteinToday: proteinToday,
            calorieRemaining: calorieRemaining,
            mealsLoggedToday: todaysMeals.count,
            recentMealNames: todaysMeals.map(\.mealName),
            healthNote: HealthInsightsBuilder.coachNote(
                snapshot: healthService.todaySnapshot,
                proteinRemaining: proteinRemaining
            )
        )

        do {
            coachTip = try await OpenAICoachService.dailyTip(context: context)
        } catch {
            coachTip = (error as? LocalizedError)?.errorDescription
                ?? "Add your OpenAI API key in Profile → Developer for personalized coaching."
        }
    }

    private func syncWidgetData() {
        WidgetDataStore.save(
            proteinCurrent: proteinToday,
            proteinTarget: proteinTarget,
            proteinRemaining: proteinRemaining,
            health: healthService.todaySnapshot,
            coachTip: coachTip
        )
    }

    private var todayHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            if streak.currentStreak > 0 || streak.loggedToday {
                StreakPill(days: max(streak.currentStreak, streak.loggedToday ? 1 : 0))
            }
        }
    }

    private var tomorrowPlanLink: some View {
        NavigationLink {
            TomorrowProteinPlanView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(AppTheme.coachOrange)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.coachOrange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tomorrow's protein plan")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Coach-picked meals to hit your target")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.surfaceContainerHighest, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var mealsSection: some View {
        Text("Today's Meals")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppTheme.textPrimary)

        if todaysMeals.isEmpty {
            logMealPlaceholder(title: "Log Your First Meal")
        } else {
            ForEach(todaysMeals, id: \.id) { meal in
                NavigationLink {
                    MealResultView(analysis: meal.analysis, isNewScan: false, mealNote: meal.mealNote, showsLogAgain: true)
                } label: {
                    KineticMealRow(meal: meal)
                }
                .buttonStyle(.plain)
            }
            logMealPlaceholder(title: nextMealLabel)
        }
    }

    private var nextMealLabel: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case ..<11: return "Log Lunch"
        case ..<16: return "Log Dinner"
        default: return "Log Snack"
        }
    }

    private func logMealPlaceholder(title: String) -> some View {
        Button { appState.presentScanIfAllowed() } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.title)
                Text(title.uppercased())
                    .font(AppTypography.labelCaps)
                    .tracking(0.5)
            }
            .foregroundStyle(AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .background(AppTheme.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.outlineVariant, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { TodayView() }
        .environment(AppState())
        .modelContainer(for: [MealRecord.self, UserSettings.self], inMemory: true)
}
