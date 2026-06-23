import Foundation

enum InsightsTrendsCalculator {
    struct WeeklyPoint: Identifiable, Equatable {
        let id: Date
        let label: String
        let protein: Int
        let hitGoal: Bool
    }

    struct MacroSplit: Equatable {
        let proteinGrams: Int
        let carbsGrams: Int
        let fatGrams: Int
        let proteinPercent: Int
        let carbsPercent: Int
        let fatPercent: Int
    }

    struct ScatterPoint: Identifiable, Equatable {
        let id: UUID
        let calories: Int
        let protein: Int
        let density: Density

        enum Density {
            case high, medium, low
        }
    }

    struct Observation: Identifiable, Equatable {
        let id = UUID()
        let icon: String
        let title: String
        let message: String
        let tag: String?
    }

    struct Report: Equatable {
        let weeklyPoints: [WeeklyPoint]
        let macroSplit: MacroSplit
        let scatterPoints: [ScatterPoint]
        let observations: [Observation]
        let proteinTarget: Int
    }

    static func build(
        from meals: [MealRecord],
        proteinTarget: Int,
        referenceDate: Date = .now
    ) -> Report {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        var weeklyPoints: [WeeklyPoint] = []
        for offset in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: referenceDate)) else { continue }
            let dayMeals = meals.filter { calendar.isDate($0.scannedAt, inSameDayAs: day) }
            let protein = dayMeals.reduce(0) { $0 + $1.analysis.proteinMidpoint }
            weeklyPoints.append(WeeklyPoint(id: day, label: formatter.string(from: day), protein: protein, hitGoal: protein >= proteinTarget))
        }

        let weekMeals = meals.filter {
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: referenceDate) else { return false }
            return $0.scannedAt >= weekAgo
        }

        let proteinGrams = weekMeals.reduce(0) { $0 + $1.analysis.proteinMidpoint }
        let carbsGrams = weekMeals.reduce(0) { $0 + ($1.carbsMin + $1.carbsMax) / 2 }
        let fatGrams = weekMeals.reduce(0) { $0 + ($1.fatMin + $1.fatMax) / 2 }
        let macroTotal = max(proteinGrams + carbsGrams + fatGrams, 1)
        let macroSplit = MacroSplit(
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            proteinPercent: proteinGrams * 100 / macroTotal,
            carbsPercent: carbsGrams * 100 / macroTotal,
            fatPercent: fatGrams * 100 / macroTotal
        )

        let scatterPoints = weekMeals.prefix(20).map { meal -> ScatterPoint in
            let protein = meal.analysis.proteinMidpoint
            let calories = (meal.caloriesMin + meal.caloriesMax) / 2
            let ratio = calories > 0 ? Double(protein) / Double(calories) : 0
            let density: ScatterPoint.Density = ratio >= 0.08 ? .high : ratio >= 0.05 ? .medium : .low
            return ScatterPoint(id: meal.id, calories: calories, protein: protein, density: density)
        }

        let observations = makeObservations(
            weeklyPoints: weeklyPoints,
            weekMeals: weekMeals,
            proteinTarget: proteinTarget,
            macroSplit: macroSplit
        )

        return Report(
            weeklyPoints: weeklyPoints,
            macroSplit: macroSplit,
            scatterPoints: scatterPoints,
            observations: observations,
            proteinTarget: proteinTarget
        )
    }

    private static func makeObservations(
        weeklyPoints: [WeeklyPoint],
        weekMeals: [MealRecord],
        proteinTarget: Int,
        macroSplit: MacroSplit
    ) -> [Observation] {
        var results: [Observation] = []

        let morningMeals = weekMeals.filter { Calendar.current.component(.hour, from: $0.scannedAt) < 10 }
        let otherMeals = weekMeals.filter { Calendar.current.component(.hour, from: $0.scannedAt) >= 10 }
        if !morningMeals.isEmpty && !otherMeals.isEmpty {
            let morningAvg = morningMeals.reduce(0) { $0 + $1.analysis.proteinMidpoint } / morningMeals.count
            let otherAvg = otherMeals.reduce(0) { $0 + $1.analysis.proteinMidpoint } / otherMeals.count
            if morningAvg > otherAvg {
                results.append(Observation(
                    icon: "sun.max.fill",
                    title: "Protein power mornings",
                    message: "Days with a logged meal before 10 AM average \(morningAvg)g protein per meal — \(max(morningAvg - otherAvg, 1))g more than later meals.",
                    tag: "Habit win"
                ))
            }
        }

        let hitDays = weeklyPoints.filter(\.hitGoal).count
        if hitDays >= 4 {
            results.append(Observation(
                icon: "chart.line.uptrend.xyaxis",
                title: "Strong weekly rhythm",
                message: "You hit your \(proteinTarget)g protein goal on \(hitDays) of the last 7 days. Keep the same meal logging pattern.",
                tag: nil
            ))
        } else if weekMeals.count >= 3 {
            results.append(Observation(
                icon: "target",
                title: "Room to grow",
                message: "You logged \(weekMeals.count) meals this week. Adding one high-protein snack could push more days over goal.",
                tag: "Focus area"
            ))
        }

        if macroSplit.proteinPercent < 25, weekMeals.count >= 2 {
            results.append(Observation(
                icon: "bolt.fill",
                title: "Boost protein density",
                message: "Protein is \(macroSplit.proteinPercent)% of your logged macros this week. Try swapping one meal for a lean protein + veg plate.",
                tag: "Focus area"
            ))
        }

        if results.isEmpty {
            results.append(Observation(
                icon: "lightbulb.fill",
                title: "Keep logging",
                message: "Log a few more meals to unlock personalized trend insights from your coach.",
                tag: nil
            ))
        }

        return Array(results.prefix(3))
    }
}
