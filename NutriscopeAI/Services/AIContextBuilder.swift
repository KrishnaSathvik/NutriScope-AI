import Foundation

enum AIContextBuilder {
    static func mealAnalysisContext(
        settings: UserSettings?,
        proteinConsumedToday: Int,
        caloriesConsumedToday: Int,
        recentMealNames: [String]
    ) -> String {
        guard let settings else {
            return "No profile yet. Use conservative macro ranges."
        }

        let proteinRemaining = max(0, settings.dailyProteinTarget - proteinConsumedToday)
        let calorieMid = (settings.calorieRangeMin + settings.calorieRangeMax) / 2
        let caloriesRemaining = max(0, calorieMid - caloriesConsumedToday)

        var lines: [String] = [
            "User profile:",
            "- Goal: \(settings.goal.label)",
            "- Daily protein target: \(settings.dailyProteinTarget)g (eaten today: \(proteinConsumedToday)g, remaining: \(proteinRemaining)g)",
            "- Calorie range: \(settings.calorieRangeFormatted) (around \(caloriesConsumedToday) kcal eaten, ~\(caloriesRemaining) kcal room left)",
            "- Activity: \(settings.activity.label)",
            "- Age: \(settings.age), weight: \(settings.weightKg)kg, height: \(settings.heightCm)cm"
        ]

        if !settings.dietPreferences.isEmpty {
            let prefs = settings.dietPreferences.map(\.label).joined(separator: ", ")
            lines.append("- Diet preferences: \(prefs)")
        }

        if !recentMealNames.isEmpty {
            lines.append("- Recent meals today: \(recentMealNames.prefix(3).joined(separator: "; "))")
        }

        if proteinRemaining > 30 {
            lines.append("- Coach note: protein is still low today — suggest higher-protein follow-ups when relevant.")
        }

        return lines.joined(separator: "\n")
    }
}

enum NutritionPrompts {
    static let textExtractionRules = """
    Text parsing rules:
    - If the user gives exact calories or protein for an item, use those values.
    - If only portions are given (e.g. "2 rotis", "100g chicken"), estimate with standard values.
    - Assume reasonable single servings when amounts are missing.
    - Be conservative; prefer ranges over exact numbers.
    - For Indian/home meals, account for hidden oil, ghee, and rice/roti portions.
    - Return mealName that reflects the user's description when text is provided.
    """
}
