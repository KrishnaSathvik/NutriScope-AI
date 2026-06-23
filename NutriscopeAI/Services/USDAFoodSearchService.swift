import Foundation

struct USDAFoodItem: Identifiable, Sendable, Equatable {
    let id: Int
    let description: String
    let brandName: String?
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let servingDescription: String

    var mealDescription: String {
        if let brandName, !brandName.isEmpty {
            return "\(description) (\(brandName)) — \(servingDescription)"
        }
        return "\(description) — \(servingDescription)"
    }
}

enum USDAFoodSearchService {
    static func search(query: String, page: Int = 1) async throws -> [USDAFoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        let apiKey = Secrets.usdaAPIKey
        var urlString = "https://api.nal.usda.gov/fdc/v1/foods/search"
        if !apiKey.isEmpty {
            urlString += "?api_key=\(apiKey)"
        }

        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "query": trimmed,
            "pageNumber": page,
            "pageSize": 20,
            "dataType": ["Foundation", "SR Legacy", "Branded"]
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MealAnalysisError.network("Food search failed. Add a USDA API key in Profile → Developer.")
        }

        let decoded = try JSONDecoder().decode(USDASearchResponse.self, from: data)
        return decoded.foods.compactMap(parseFood)
    }

    static func makeAnalysis(from food: USDAFoodItem, imageData: Data? = nil) -> MealAnalysis {
        let padding = 0.12
        return MealAnalysis(
            mealName: food.description,
            calories: range(around: food.calories, padding: padding),
            protein: range(around: food.protein, padding: padding),
            carbs: range(around: food.carbs, padding: padding),
            fat: range(around: food.fat, padding: padding),
            confidence: .high,
            followUpQuestions: [
                FollowUpQuestion(prompt: "Portion size vs label?", options: ["Smaller", "As listed", "Larger"])
            ],
            advice: MealAdvice(
                headline: "Database match",
                proteinGapGrams: max(0, 40 - food.protein),
                suggestions: [],
                coachMessage: "Matched from USDA FoodData Central. Confirm portion size if you ate more or less than the listed serving.",
                balanceScore: min(100, 50 + food.protein)
            ),
            imageData: imageData
        )
    }

    private static func range(around value: Int, padding: Double) -> MacroRange {
        let delta = max(1, Int((Double(value) * padding).rounded()))
        return MacroRange(min: max(0, value - delta), max: value + delta)
    }

    private static func parseFood(_ food: USDAFoodDTO) -> USDAFoodItem? {
        let nutrients = food.foodNutrients ?? []
        let calories = nutrientValue(nutrients, ids: [1008, 2047])
        let protein = nutrientValue(nutrients, ids: [1003])
        let carbs = nutrientValue(nutrients, ids: [1005])
        let fat = nutrientValue(nutrients, ids: [1004])
        guard calories > 0 || protein > 0 else { return nil }

        let serving = food.servingSize.map { "\(Int($0))\(food.servingSizeUnit ?? "g")" } ?? "1 serving"
        return USDAFoodItem(
            id: food.fdcId,
            description: food.description,
            brandName: food.brandOwner ?? food.brandName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            servingDescription: serving
        )
    }

    private static func nutrientValue(_ nutrients: [USDANutrientDTO], ids: [Int]) -> Int {
        for id in ids {
            if let match = nutrients.first(where: { $0.nutrientId == id || $0.nutrient?.id == id }) {
                return Int((match.value ?? match.amount ?? 0).rounded())
            }
        }
        return 0
    }
}

private struct USDASearchResponse: Decodable {
    let foods: [USDAFoodDTO]
}

private struct USDAFoodDTO: Decodable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let brandName: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let foodNutrients: [USDANutrientDTO]?
}

private struct USDANutrientDTO: Decodable {
    let nutrientId: Int?
    let value: Double?
    let amount: Double?
    let nutrient: USDANutrientMeta?

    struct USDANutrientMeta: Decodable { let id: Int? }
}
