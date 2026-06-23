import Foundation

/// Offline demo only — used when `BackendConfig.offlineDemoMode` is enabled.
struct MockMealAnalysisService: MealAnalysisServiceProtocol {
    func analyzeMeal(_ request: MealAnalysisRequest) async throws -> MealAnalysis {
        guard request.isValid else { throw MealAnalysisError.missingInput }

        try await Task.sleep(for: .milliseconds(900))

        let name = request.trimmedDescription.isEmpty ? "Scanned meal" : request.trimmedDescription
        let proteinMid = 38
        let remaining = max(0, request.dailyProteinTarget - request.proteinConsumedToday - proteinMid)

        return MealAnalysis(
            mealName: name,
            calories: MacroRange(min: 520, max: 680),
            protein: MacroRange(min: 32, max: 44),
            carbs: MacroRange(min: 45, max: 65),
            fat: MacroRange(min: 18, max: 28),
            confidence: .medium,
            followUpQuestions: [
                FollowUpQuestion(prompt: "Portion size?", options: ["Smaller", "As shown", "Larger"]),
                FollowUpQuestion(prompt: "Cooking oil/butter?", options: ["None/light", "Medium", "Heavy"]),
            ],
            advice: MealAdvice(
                headline: "Demo analysis (offline)",
                proteinGapGrams: remaining,
                suggestions: [],
                coachMessage: "Offline demo mode — connect Supabase for live AI meal analysis.",
                balanceScore: 62
            ),
            imageData: request.imageData
        )
    }
}
