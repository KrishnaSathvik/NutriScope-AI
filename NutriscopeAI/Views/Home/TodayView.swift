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
        ZStack {
            AppBackground(showsAmbientGlow: true)

            BoundedScrollView {
                VStack(alignment: .leading, spacing: AppTheme.stackMD) {
                    todayHeader
                    ProteinArcRing(
                        current: proteinToday,
                        target: proteinTarget
                    )
                    DashboardSecondaryMacroGrid(carbs: carbsToday, fat: fatToday)
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
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarHidden(true)
        .onAppear {
            restoreCachedCoachTip()
        }
        .task {
            if healthService.isAuthorized {
                await healthService.refreshToday()
            }
            await loadCoachTipIfNeeded()
        }
        .onChange(of: proteinToday) { _, _ in
            syncWidgetData()
            Task { await loadCoachTipIfNeeded() }
        }
        .onChange(of: coachTip) { _, _ in syncWidgetData() }
    }

    private func restoreCachedCoachTip() {
        let context = coachContext
        let fingerprint = DailyCoachTipCache.fingerprint(for: context)
        if let cached = DailyCoachTipCache.cachedTip(matching: fingerprint) {
            coachTip = cached
        }
    }

    private var coachContext: CoachAIContext {
        OpenAICoachService.makeContext(
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
    }

    private func loadCoachTipIfNeeded() async {
        let context = coachContext
        let fingerprint = DailyCoachTipCache.fingerprint(for: context)

        if let cached = DailyCoachTipCache.cachedTip(matching: fingerprint) {
            coachTip = cached
            return
        }

        do {
            let tip = try await OpenAICoachService.dailyTip(context: context)
            DailyCoachTipCache.store(tip: tip, fingerprint: fingerprint)
            coachTip = tip
        } catch {
            coachTip = (error as? LocalizedError)?.errorDescription
                ?? "Couldn't load your coach tip. Check your connection and try again."
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
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.textSecondary)
                Text("Today")
                    .font(AppTypography.displayLGMobile)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Spacer()
            if streak.currentStreak > 0 || streak.loggedToday {
                StreakPill(days: max(streak.currentStreak, streak.loggedToday ? 1 : 0))
            }
        }
        .padding(.top, 4)
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
        HStack {
            Text("Meals")
                .font(AppTypography.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            if !todaysMeals.isEmpty {
                Button("See All") {
                    appState.selectedTab = .meals
                }
                .font(AppTypography.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.primary)
            }
        }

        if todaysMeals.isEmpty {
            emptyMealsCard
        } else {
            ForEach(MealType.allCases) { type in
                let mealsForType = todaysMeals
                    .filter { $0.mealType == type }
                    .sorted { $0.scannedAt < $1.scannedAt }
                if !mealsForType.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        LabelCapsText(text: type.label, color: AppTheme.textSecondary)
                        ForEach(mealsForType, id: \.id) { meal in
                            NavigationLink {
                                MealResultView(
                                    analysis: meal.analysis,
                                    isNewScan: false,
                                    mealNote: meal.mealNote,
                                    showsLogAgain: true
                                )
                            } label: {
                                KineticMealRow(meal: meal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var emptyMealsCard: some View {
        Button { appState.presentScanIfAllowed() } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("No meals logged yet")
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Scan or describe your first meal to start tracking protein.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
}

#Preview {
    NavigationStack { TodayView() }
        .environment(AppState())
        .modelContainer(for: [MealRecord.self, UserSettings.self], inMemory: true)
}
