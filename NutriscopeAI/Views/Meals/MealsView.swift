import SwiftData
import SwiftUI

enum MealsPeriod: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
}

enum MealFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case highProtein = "High protein"
    case restaurant = "Restaurant"
    case home = "Home food"
    case saved = "Saved meals"

    var id: String { rawValue }
}

struct MealsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \MealRecord.scannedAt, order: .reverse) private var meals: [MealRecord]
    @Query(sort: \SavedMeal.savedAt, order: .reverse) private var savedMeals: [SavedMeal]
    @Query private var settings: [UserSettings]

    @State private var filter: MealFilter = .all
    @State private var period: MealsPeriod = .week
    @State private var healthService = HealthKitService.shared

    private var periodMeals: [MealRecord] {
        let calendar = Calendar.current
        let now = Date()
        return meals.filter { meal in
            switch period {
            case .today:
                calendar.isDateInToday(meal.scannedAt)
            case .week:
                calendar.isDate(meal.scannedAt, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                calendar.isDate(meal.scannedAt, equalTo: now, toGranularity: .month)
            }
        }
    }

    private var filteredMeals: [MealRecord] {
        switch filter {
        case .all: periodMeals
        case .highProtein: periodMeals.filter { $0.proteinMidpoint >= 35 }
        case .restaurant:
            periodMeals.filter {
                $0.mealName.localizedCaseInsensitiveContains("bowl")
                    || $0.mealName.localizedCaseInsensitiveContains("chipotle")
                    || $0.mealName.localizedCaseInsensitiveContains("pizza")
                    || $0.mealName.localizedCaseInsensitiveContains("restaurant")
            }
        case .home:
            periodMeals.filter {
                !$0.mealName.localizedCaseInsensitiveContains("bowl")
                    && !$0.mealName.localizedCaseInsensitiveContains("chipotle")
                    && !$0.mealName.localizedCaseInsensitiveContains("pizza")
            }
        case .saved: []
        }
    }

    private var groupedMeals: [(String, [MealRecord])] {
        let formatter = DateFormatter()
        formatter.dateFormat = period == .month ? "MMM d, yyyy" : "EEEE, MMM d"
        let groups = Dictionary(grouping: filteredMeals) {
            Calendar.current.startOfDay(for: $0.scannedAt)
        }
        return groups.sorted { $0.key > $1.key }.map { (formatter.string(from: $0.key), $0.value) }
    }

    private var frequentMeals: [SavedMeal] {
        Array(savedMeals.prefix(4))
    }

    var body: some View {
        ZStack {
            AppBackground(showsAmbientGlow: true)

            BoundedScrollView {
                VStack(alignment: .leading, spacing: AppTheme.stackMD) {
                    mealsHeader

                    KineticPeriodPills(items: MealsPeriod.allCases, selection: $period)

                if filter != .saved {
                    frequentMealsSection
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MealFilter.allCases) { item in
                            KineticFilterChip(title: item.rawValue, isSelected: filter == item) {
                                if item == .saved && !appState.hasProAccess {
                                    appState.presentPaywall()
                                } else {
                                    filter = item
                                }
                            }
                        }
                    }
                }

                if filter == .saved {
                    savedMealsSection
                } else if groupedMeals.isEmpty {
                    KineticEmptyState(
                        systemImage: "fork.knife",
                        title: "No meals yet",
                        message: emptyMessage
                    )
                } else {
                    ForEach(groupedMeals, id: \.0) { day, dayMeals in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(day)
                                .font(AppTypography.title3.weight(.semibold))
                                .foregroundStyle(Calendar.current.isDateInToday(dayMeals.first?.scannedAt ?? .distantPast) ? AppTheme.textPrimary : AppTheme.textSecondary)
                            ForEach(dayMeals, id: \.id) { meal in
                                NavigationLink {
                                    MealResultView(
                                        analysis: meal.analysis,
                                        isNewScan: false,
                                        mealNote: meal.mealNote,
                                        showsLogAgain: true
                                    )
                                } label: {
                                    KineticMealHistoryRow(meal: meal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.marginMain)
            .padding(.top, 8)
            .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
    }

    private var mealsHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Meal History")
                .font(AppTypography.displayLGMobile)
                .foregroundStyle(AppTheme.textPrimary)
            Text("Your weekly protein arc")
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var frequentMealsSection: some View {
        if appState.hasProAccess, !frequentMeals.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("Frequent Meals")
                        .font(AppTypography.title3.weight(.semibold))
                } icon: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(AppTheme.warmSun)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(frequentMeals, id: \.id) { saved in
                            KineticFrequentMealCard(
                                name: saved.mealName,
                                proteinLabel: "\((saved.proteinMin + saved.proteinMax) / 2)g P",
                                imageData: saved.imageData
                            ) {
                                logAgain(saved)
                            }
                        }
                    }
                    .padding(.trailing, 8)
                }
            }
        }
    }

    private var emptyMessage: String {
        switch period {
        case .today:
            "No meals logged today. Scan your first meal from the Scan tab."
        case .week:
            "No meals this week. Scan your first meal from the Scan tab."
        case .month:
            "No meals this month. Scan your first meal from the Scan tab."
        }
    }

    private var savedMealsSection: some View {
        Group {
            if savedMeals.isEmpty {
                KineticEmptyState(
                    imageName: "saved-meals-empty",
                    systemImage: "bookmark",
                    title: "No saved meals yet",
                    message: "Save a meal from the result screen for one-tap logging later."
                )
            } else {
                ForEach(savedMeals, id: \.id) { saved in
                    SavedMealCard(savedMeal: saved) {
                        logAgain(saved)
                    }
                }
            }
        }
    }

    private func logAgain(_ saved: SavedMeal) {
        let record = saved.makeMealRecord()
        modelContext.insert(record)
        saved.lastLoggedAt = .now
        try? modelContext.save()
        Task {
            if let user = settings.first {
                await RealtimeNotificationService.notifyAfterMealsChanged(
                    meals: meals + [record],
                    settings: user,
                    health: healthService.todaySnapshot
                )
            }
        }
    }
}

struct SavedMealCard: View {
    let savedMeal: SavedMeal
    var onLogAgain: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let data = savedMeal.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    AppTheme.coachOrange.opacity(0.12)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(savedMeal.mealName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("\(savedMeal.proteinMin)–\(savedMeal.proteinMax)g protein · \(savedMeal.mealType.label)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Button(action: onLogAgain) {
                Text("Log again")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.coachOrange)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.cardShadow, radius: 8, y: 3)
    }
}

#Preview {
    NavigationStack { MealsView() }
        .environment(AppState())
        .modelContainer(for: [MealRecord.self, SavedMeal.self, UserSettings.self], inMemory: true)
}
