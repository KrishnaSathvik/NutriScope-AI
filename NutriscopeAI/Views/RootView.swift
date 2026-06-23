import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    private var showsMainApp: Bool {
        appState.hasCompletedOnboarding
    }

    var body: some View {
        Group {
            if showsMainApp {
                MainTabView()
            } else {
                AuthFlowView()
            }
        }
        .kineticFont()
        .task {
            appState.subscriptionManager.startObservingTransactionUpdates()
            await appState.subscriptionManager.refreshEntitlements()
            try? await BackendAuthBootstrap.ensureBackendSession()
        }
        .sheet(item: Binding(
            get: { appState.activeSheet },
            set: { appState.activeSheet = $0 }
        )) { sheet in
            switch sheet {
            case .scan: ScanMealView()
            case .paywall: PaywallView()
            case .scanQuota: ScanQuotaPaywallView()
            case .subscriptionSuccess: SubscriptionSuccessView()
            case .saveProgress: SaveProgressView()
            }
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settings: [UserSettings]
    @Query(sort: \MealRecord.scannedAt, order: .reverse) private var meals: [MealRecord]
    @State private var lastContentTab: AppTab = .today
    @State private var healthService = HealthKitService.shared

    private var activeTab: AppTab {
        appState.selectedTab == .scan ? lastContentTab : appState.selectedTab
    }

    var body: some View {
        Group {
            switch activeTab {
            case .today:
                NavigationStack { TodayView() }
            case .meals:
                NavigationStack { MealsView() }
            case .scan:
                NavigationStack { TodayView() }
            case .coach:
                NavigationStack {
                    ProFeatureGate(feature: "Protein Coach") { CoachView() }
                }
            case .profile:
                NavigationStack { ProfileView() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            kineticTabBar
        }
        .background(AppTheme.background)
        .onAppear {
            if appState.selectedTab == .scan {
                appState.selectedTab = .today
            }
            lastContentTab = appState.selectedTab == .scan ? .today : appState.selectedTab
            if let user = settings.first {
                Task {
                    await NotificationManager.syncFromStoredSettings(
                        user.reminderSettings,
                        proteinTarget: user.dailyProteinTarget
                    )
                    await healthService.refreshToday()
                    await evaluateSmartNotifications(for: user)
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard let user = settings.first else { return }
            switch phase {
            case .background:
                Task {
                    let todayProtein = meals
                        .filter { Calendar.current.isDateInToday($0.scannedAt) }
                        .reduce(0) { $0 + $1.proteinMidpoint }
                    let remaining = max(0, user.dailyProteinTarget - todayProtein)
                    await RealtimeNotificationService.scheduleBackgroundGapCheck(
                        proteinRemaining: remaining,
                        proteinTarget: user.dailyProteinTarget,
                        settings: user.reminderSettings
                    )
                }
            case .active:
                RealtimeNotificationService.cancelBackgroundGapCheck()
                Task {
                    await healthService.refreshToday()
                    await evaluateSmartNotifications(for: user)
                }
            default:
                break
            }
        }
        .onChange(of: healthService.todaySnapshot) { _, snapshot in
            guard let user = settings.first, snapshot.hasWorkoutData else { return }
            Task { await evaluateSmartNotifications(for: user) }
        }
    }

    private func evaluateSmartNotifications(for user: UserSettings) async {
        let todayMeals = meals.filter { Calendar.current.isDateInToday($0.scannedAt) }
        let proteinToday = todayMeals.reduce(0) { $0 + $1.proteinMidpoint }
        let remaining = max(0, user.dailyProteinTarget - proteinToday)
        let hour = Calendar.current.component(.hour, from: .now)
        await RealtimeNotificationService.evaluate(
            RealtimeNotificationContext(
                proteinRemaining: remaining,
                proteinTarget: user.dailyProteinTarget,
                proteinToday: proteinToday,
                mealsLoggedToday: todayMeals.count,
                hour: hour,
                workoutMinutes: healthService.todaySnapshot.workoutMinutes,
                lastWorkoutEnded: healthService.lastRefresh,
                settings: user.reminderSettings
            )
        )
    }

    private var kineticTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.navigationTabs) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                .fill(AppTheme.surface)
                .shadow(color: AppTheme.coachOrange.opacity(0.12), radius: 20, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = tab == .scan ? false : activeTab == tab

        return Button {
            if tab == .scan {
                appState.presentScanIfAllowed()
            } else {
                lastContentTab = tab
                appState.selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 22))
                    .symbolVariant(isSelected ? .fill : .none)
                Text(tab.title.uppercased())
                    .font(AppTypography.labelCaps)
                    .tracking(0.3)
            }
            .foregroundStyle(isSelected ? AppTheme.coachOrange : AppTheme.textSecondary.opacity(0.7))
            .frame(maxWidth: .infinity)
            .scaleEffect(isSelected ? 1.05 : 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .modelContainer(for: [MealRecord.self, UserSettings.self], inMemory: true)
}
