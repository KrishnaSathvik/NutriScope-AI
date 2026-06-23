import Foundation

struct ProxyMealAnalysisService: MealAnalysisServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func analyzeMeal(_ request: MealAnalysisRequest) async throws -> MealAnalysis {
        guard request.isValid else { throw MealAnalysisError.missingInput }
        guard let url = BackendConfig.analyzeMealURL else {
            throw MealAnalysisError.missingBackendConfiguration
        }

        let accessToken = try await SupabaseAuthClient.accessToken

        var body: [String: Any] = [
            "dailyProteinTarget": request.dailyProteinTarget,
            "dietPreferences": request.dietPreferences.map(\.label),
            "userContext": request.userContext,
            "proteinConsumedToday": request.proteinConsumedToday,
            "caloriesConsumedToday": request.caloriesConsumedToday,
        ]

        if !request.trimmedDescription.isEmpty {
            body["mealDescription"] = request.trimmedDescription
        }
        if let imageData = request.imageData {
            body["imageBase64"] = imageData.base64EncodedString()
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(BackendConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw MealAnalysisError.network("Request failed")
        }

        if http.statusCode == 401 {
            SupabaseAuthClient.signOut()
            throw MealAnalysisError.unauthorized
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = Self.errorMessage(from: data, statusCode: http.statusCode)
            throw MealAnalysisError.network(message)
        }

        let dto = try JSONDecoder().decode(MealAnalysisDTO.self, from: data)
        return dto.toAnalysis(imageData: request.imageData)
    }

    private static func errorMessage(from data: Data, statusCode: Int) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let error = json["error"] as? String, !error.isEmpty {
                return friendlyError(error, statusCode: statusCode)
            }
            if let message = json["message"] as? String, !message.isEmpty {
                return friendlyError(message, statusCode: statusCode)
            }
        }
        let raw = String(data: data, encoding: .utf8) ?? ""
        if !raw.isEmpty { return friendlyError(raw, statusCode: statusCode) }
        return "Meal analysis failed (HTTP \(statusCode))."
    }

    private static func friendlyError(_ message: String, statusCode: Int) -> String {
        let lower = message.lowercased()
        if statusCode == 404 || lower.contains("not found") {
            return "analyze-meal function not found. Deploy it: supabase functions deploy analyze-meal"
        }
        if lower.contains("openai not configured") {
            return "OpenAI key missing on Supabase. Run: supabase secrets set OPENAI_API_KEY=sk-..."
        }
        if statusCode == 401 || lower.contains("unauthorized") {
            return "Supabase auth failed. Profile → Account → Save & test connection, and enable Anonymous sign-ins."
        }
        return message
    }
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
