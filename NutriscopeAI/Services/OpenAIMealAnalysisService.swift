import Foundation

struct OpenAIMealAnalysisService: MealAnalysisServiceProtocol {
    let apiKey: String
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func analyzeMeal(_ request: MealAnalysisRequest) async throws -> MealAnalysis {
        guard request.isValid else { throw MealAnalysisError.missingInput }

        let dietNote = request.dietPreferences.isEmpty
            ? ""
            : "Diet preferences: \(request.dietPreferences.map(\.label).joined(separator: ", "))."

        let descriptionNote = request.trimmedDescription.isEmpty
            ? ""
            : "User meal description: \"\(request.trimmedDescription)\"."

        let contextBlock = request.userContext.isEmpty ? "" : "\n\(request.userContext)\n"

        let prompt = """
        You are a protein-first meal coach. Analyze this meal and return ONLY valid JSON with this schema:
        {
          "mealName": "string",
          "calories": {"min": int, "max": int},
          "protein": {"min": int, "max": int},
          "carbs": {"min": int, "max": int},
          "fat": {"min": int, "max": int},
          "confidence": "high|medium|low",
          "followUpQuestions": [{"prompt":"string","options":["a","b","c"]}],
          "advice": {
            "headline": "string",
            "proteinGapGrams": int,
            "suggestions": ["string"],
            "coachMessage": "string",
            "balanceScore": int
          }
        }
        \(contextBlock)
        \(NutritionPrompts.textExtractionRules)
        User daily protein target: \(request.dailyProteinTarget)g.
        Protein eaten today before this meal: \(request.proteinConsumedToday)g.
        \(descriptionNote)
        \(dietNote)
        Use ranges, not exact numbers. Ask 2 follow-up questions about hidden calories (oil, butter, sauces, portion size, fried vs grilled). Be coach-like, not judgmental. No medical claims. Set advice.proteinGapGrams based on remaining daily protein after this meal.
        """

        var content: [[String: Any]] = [["type": "text", "text": prompt]]
        if let imageData = request.imageData {
            let base64 = imageData.base64EncodedString()
            content.append([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(base64)"]
            ])
        }

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "user",
                    "content": content
                ]
            ],
            "max_tokens": 800,
            "response_format": ["type": "json_object"]
        ]

        var urlRequest = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Request failed"
            throw MealAnalysisError.network(message)
        }

        let completion = try JSONDecoder().decode(OpenAICompletion.self, from: data)
        guard
            let content = completion.choices.first?.message.content,
            let jsonData = content.data(using: .utf8)
        else {
            throw MealAnalysisError.invalidResponse
        }

        let dto = try JSONDecoder().decode(MealAnalysisDTO.self, from: jsonData)
        return dto.toAnalysis(imageData: request.imageData)
    }
}

private struct OpenAICompletion: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

private struct MacroRangeDTO: Decodable {
    let min: Int
    let max: Int
}

private struct FollowUpQuestionDTO: Decodable {
    let prompt: String
    let options: [String]
}

private struct MealAdviceDTO: Decodable {
    let headline: String
    let proteinGapGrams: Int
    let suggestions: [String]
    let coachMessage: String
    let balanceScore: Int
}

private struct MealAnalysisDTO: Decodable {
    let mealName: String
    let calories: MacroRangeDTO
    let protein: MacroRangeDTO
    let carbs: MacroRangeDTO
    let fat: MacroRangeDTO
    let confidence: String
    let followUpQuestions: [FollowUpQuestionDTO]
    let advice: MealAdviceDTO

    func toAnalysis(imageData: Data?) -> MealAnalysis {
        MealAnalysis(
            mealName: mealName,
            calories: MacroRange(min: calories.min, max: calories.max),
            protein: MacroRange(min: protein.min, max: protein.max),
            carbs: MacroRange(min: carbs.min, max: carbs.max),
            fat: MacroRange(min: fat.min, max: fat.max),
            confidence: ConfidenceLevel(rawValue: confidence) ?? .medium,
            followUpQuestions: followUpQuestions.map {
                FollowUpQuestion(prompt: $0.prompt, options: $0.options)
            },
            advice: MealAdvice(
                headline: advice.headline,
                proteinGapGrams: advice.proteinGapGrams,
                suggestions: advice.suggestions,
                coachMessage: advice.coachMessage,
                balanceScore: advice.balanceScore
            ),
            imageData: imageData
        )
    }
}
