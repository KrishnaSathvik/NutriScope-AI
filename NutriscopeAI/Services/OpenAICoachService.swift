import Foundation

struct CoachAIContext: Sendable {
    var displayName: String
    var proteinTarget: Int
    var proteinToday: Int
    var proteinRemaining: Int
    var calorieRemainingMin: Int
    var calorieRemainingMax: Int
    var mealsLoggedToday: Int
    var dietPreferences: [String]
    var recentMealNames: [String]
    var healthNote: String?
    var preferredCoachStyle: String
}

enum OpenAICoachService {
    static func chatReply(
        history: [CoachChatMessage],
        userMessage: String,
        context: CoachAIContext
    ) async throws -> String {
        let system = """
        You are Nutriscope AI, a protein-first nutrition coach. Be warm, concise, and actionable.
        Use the user's real numbers. Suggest meals with approximate protein grams. No medical claims.
        \(contextBlock(context))
        """

        var messages: [[String: String]] = [["role": "system", "content": system]]
        for message in history where message.role != .suggestion {
            let role = message.role == .user ? "user" : "assistant"
            messages.append(["role": role, "content": message.text])
        }
        messages.append(["role": "user", "content": userMessage])

        return try await OpenAIClient.chatCompletion(messages: messages, maxTokens: 500)
    }

    static func greeting(context: CoachAIContext) async throws -> String {
        let prompt = """
        Write a short coach greeting (1-2 sentences) for a check-in chat.
        Mention protein remaining if > 0. Reference time of day naturally.
        \(contextBlock(context))
        Return plain text only.
        """
        return try await OpenAIClient.chatCompletion(
            messages: [
                ["role": "system", "content": "You are a protein-first nutrition coach."],
                ["role": "user", "content": prompt]
            ],
            maxTokens: 120
        )
    }

    static func dailyTip(context: CoachAIContext) async throws -> String {
        let prompt = """
        Write one short coach tip (max 2 sentences) for the Today dashboard.
        \(contextBlock(context))
        Return plain text only.
        """
        return try await OpenAIClient.chatCompletion(
            messages: [
                ["role": "system", "content": "You are a protein-first nutrition coach."],
                ["role": "user", "content": prompt]
            ],
            maxTokens: 120
        )
    }

    static func proteinSuggestions(
        proteinRemaining: Int,
        context: CoachAIContext
    ) async throws -> [String] {
        let prompt = """
        Return JSON: {"suggestions": ["string", "string", "string"]}
        Give 3 specific meal/snack ideas to close \(proteinRemaining)g protein remaining today.
        \(contextBlock(context))
        """
        let content = try await OpenAIClient.chatCompletion(
            messages: [["role": "user", "content": prompt]],
            maxTokens: 300,
            jsonObject: true
        )
        let dto = try OpenAIClient.decodeJSON(SuggestionsDTO.self, from: content)
        return dto.suggestions
    }

    static func suggestionCardProtein(context: CoachAIContext) async throws -> Int {
        let prompt = """
        Return JSON: {"proteinGrams": int}
        How many grams of protein should the user aim for in their next meal? Remaining today: \(context.proteinRemaining)g.
        """
        let content = try await OpenAIClient.chatCompletion(
            messages: [["role": "user", "content": prompt]],
            maxTokens: 80,
            jsonObject: true
        )
        let dto = try OpenAIClient.decodeJSON(SuggestionProteinDTO.self, from: content)
        return max(10, min(dto.proteinGrams, 60))
    }

    static func buildTomorrowPlan(
        proteinTarget: Int,
        dietPreferences: Set<DietPreference>,
        eatingOutTomorrow: Bool,
        tomorrowLabel: String
    ) async throws -> TomorrowPlanCalculator.Plan {
        let prefs = dietPreferences.map(\.label).joined(separator: ", ")
        let prompt = """
        Return JSON:
        {
          "meals": [
            {"slot": "breakfast|lunch|dinner", "name": "string", "protein": int, "calories": int, "carbs": int, "fat": int}
          ]
        }
        Plan 3 meals for tomorrow (\(tomorrowLabel)) totaling ~\(proteinTarget)g protein.
        Diet preferences: \(prefs.isEmpty ? "none" : prefs).
        Eating out tomorrow: \(eatingOutTomorrow ? "yes — include a flexible restaurant-style dinner" : "no").
        Use realistic home-cook or restaurant names with accurate macro estimates.
        """
        let content = try await OpenAIClient.chatCompletion(
            messages: [["role": "user", "content": prompt]],
            maxTokens: 700,
            jsonObject: true
        )
        let dto = try OpenAIClient.decodeJSON(TomorrowPlanDTO.self, from: content)
        let meals = dto.meals.compactMap { $0.toSuggestion() }
        let plannedProtein = meals.reduce(0) { $0 + $1.protein }
        return TomorrowPlanCalculator.Plan(
            targetProtein: proteinTarget,
            plannedProtein: min(plannedProtein, proteinTarget),
            meals: meals,
            tomorrowLabel: tomorrowLabel
        )
    }

    static func grocerySuggestions(
        proteinGap: Int,
        dietPreferences: Set<DietPreference>
    ) async throws -> [String] {
        let prefs = dietPreferences.map(\.label).joined(separator: ", ")
        let prompt = """
        Return JSON: {"items": ["string"]}
        Suggest 6-8 grocery items to help close \(proteinGap)g protein gap.
        Diet: \(prefs.isEmpty ? "none" : prefs). Short item names only.
        """
        let content = try await OpenAIClient.chatCompletion(
            messages: [["role": "user", "content": prompt]],
            maxTokens: 250,
            jsonObject: true
        )
        let dto = try OpenAIClient.decodeJSON(GroceryDTO.self, from: content)
        return dto.items
    }

    static func groceryItemsForMeals(_ mealNames: [String]) async throws -> [String] {
        let prompt = """
        Return JSON: {"items": ["string"]}
        Grocery ingredients needed for: \(mealNames.joined(separator: ", ")).
        4-8 items, short names.
        """
        let content = try await OpenAIClient.chatCompletion(
            messages: [["role": "user", "content": prompt]],
            maxTokens: 200,
            jsonObject: true
        )
        let dto = try OpenAIClient.decodeJSON(GroceryDTO.self, from: content)
        return dto.items
    }

    static func updatedAdvice(
        analysis: MealAnalysis,
        answers: [FollowUpQuestion],
        dailyProteinTarget: Int,
        proteinConsumedToday: Int
    ) async throws -> MealAdvice {
        let answerText = answers.compactMap { q -> String? in
            guard let selected = q.selectedOption else { return nil }
            return "\(q.prompt): \(selected)"
        }.joined(separator: "; ")

        let prompt = """
        Return JSON matching:
        {"headline":"string","proteinGapGrams":int,"suggestions":["string"],"coachMessage":"string","balanceScore":int}
        Meal: \(analysis.mealName). Protein \(analysis.protein.formatted)g. Calories \(analysis.calories.formatted).
        Follow-up answers: \(answerText)
        Daily protein target: \(dailyProteinTarget)g. Protein before this meal today: \(proteinConsumedToday)g.
        """
        let content = try await OpenAIClient.chatCompletion(
            messages: [["role": "user", "content": prompt]],
            maxTokens: 400,
            jsonObject: true
        )
        let dto = try OpenAIClient.decodeJSON(AdviceDTO.self, from: content)
        return dto.toAdvice()
    }

    static func makeContext(
        settings: UserSettings?,
        proteinToday: Int,
        calorieRemaining: (min: Int, max: Int),
        mealsLoggedToday: Int,
        recentMealNames: [String],
        healthNote: String?
    ) -> CoachAIContext {
        let target = settings?.dailyProteinTarget ?? 135
        return CoachAIContext(
            displayName: settings?.displayName.components(separatedBy: " ").first ?? "there",
            proteinTarget: target,
            proteinToday: proteinToday,
            proteinRemaining: max(0, target - proteinToday),
            calorieRemainingMin: calorieRemaining.min,
            calorieRemainingMax: calorieRemaining.max,
            mealsLoggedToday: mealsLoggedToday,
            dietPreferences: settings?.dietPreferences.map(\.label) ?? [],
            recentMealNames: recentMealNames,
            healthNote: healthNote,
            preferredCoachStyle: settings?.preferredCoachStyle ?? "Quick"
        )
    }

    private static func contextBlock(_ context: CoachAIContext) -> String {
        var lines = [
            "User: \(context.displayName)",
            "Protein target: \(context.proteinTarget)g",
            "Protein today: \(context.proteinToday)g",
            "Protein remaining: \(context.proteinRemaining)g",
            "Calorie room: ~\(context.calorieRemainingMin)–\(context.calorieRemainingMax) kcal",
            "Meals logged today: \(context.mealsLoggedToday)",
            "Coach style: \(context.preferredCoachStyle)"
        ]
        if !context.dietPreferences.isEmpty {
            lines.append("Diet: \(context.dietPreferences.joined(separator: ", "))")
        }
        if !context.recentMealNames.isEmpty {
            lines.append("Recent meals: \(context.recentMealNames.joined(separator: "; "))")
        }
        if let healthNote = context.healthNote {
            lines.append("Health context: \(healthNote)")
        }
        return lines.joined(separator: "\n")
    }
}

private struct SuggestionsDTO: Decodable {
    let suggestions: [String]
}

private struct SuggestionProteinDTO: Decodable {
    let proteinGrams: Int
}

private struct GroceryDTO: Decodable {
    let items: [String]
}

private struct AdviceDTO: Decodable {
    let headline: String
    let proteinGapGrams: Int
    let suggestions: [String]
    let coachMessage: String
    let balanceScore: Int

    func toAdvice() -> MealAdvice {
        MealAdvice(
            headline: headline,
            proteinGapGrams: proteinGapGrams,
            suggestions: suggestions,
            coachMessage: coachMessage,
            balanceScore: balanceScore
        )
    }
}

private struct TomorrowPlanDTO: Decodable {
    struct MealDTO: Decodable {
        let slot: String
        let name: String
        let protein: Int
        let calories: Int
        let carbs: Int
        let fat: Int

        func toSuggestion() -> TomorrowPlanCalculator.MealSuggestion? {
            let mealSlot: TomorrowPlanCalculator.MealSuggestion.MealSlot?
            switch slot.lowercased() {
            case "breakfast": mealSlot = .breakfast
            case "lunch": mealSlot = .lunch
            case "dinner": mealSlot = .dinner
            default: mealSlot = nil
            }
            guard let mealSlot else { return nil }
            let icon: String
            switch mealSlot {
            case .breakfast: icon = "sun.max.fill"
            case .lunch: icon = "flame.fill"
            case .dinner: icon = "moon.stars.fill"
            }
            return TomorrowPlanCalculator.MealSuggestion(
                slot: mealSlot,
                name: name,
                protein: protein,
                calories: calories,
                carbs: carbs,
                fat: fat,
                systemImage: icon
            )
        }
    }
    let meals: [MealDTO]
}
