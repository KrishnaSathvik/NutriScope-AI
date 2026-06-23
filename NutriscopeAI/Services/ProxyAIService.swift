import Foundation

enum ProxyAIError: LocalizedError {
    case notConfigured
    case unauthorized
    case invalidResponse
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Supabase backend is not configured for AI features."
        case .unauthorized:
            "Guest sign-in failed. Enable Anonymous sign-ins in Supabase, then try again."
        case .invalidResponse:
            "Could not read the AI response. Try again."
        case .network(let message):
            message
        }
    }
}

enum ProxyAIService {
    static func invoke(action: String, payload: [String: Any]) async throws -> [String: Any] {
        guard let url = BackendConfig.aiProxyURL else {
            throw ProxyAIError.notConfigured
        }

        let accessToken = try await SupabaseAuthClient.accessToken

        var body = payload
        body["action"] = action

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(BackendConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ProxyAIError.network("Request failed")
        }

        if http.statusCode == 401 {
            SupabaseAuthClient.signOut()
            throw ProxyAIError.unauthorized
        }

        guard (200..<300).contains(http.statusCode) else {
            throw ProxyAIError.network(Self.errorMessage(from: data, statusCode: http.statusCode))
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ProxyAIError.invalidResponse
        }
        return json
    }

    static func text(action: String, payload: [String: Any]) async throws -> String {
        let json = try await invoke(action: action, payload: payload)
        guard let text = json["text"] as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw ProxyAIError.invalidResponse
        }
        return text
    }

    static func contextPayload(_ context: CoachAIContext) -> [String: Any] {
        var payload: [String: Any] = [
            "displayName": context.displayName,
            "proteinTarget": context.proteinTarget,
            "proteinToday": context.proteinToday,
            "proteinRemaining": context.proteinRemaining,
            "calorieRemainingMin": context.calorieRemainingMin,
            "calorieRemainingMax": context.calorieRemainingMax,
            "mealsLoggedToday": context.mealsLoggedToday,
            "dietPreferences": context.dietPreferences,
            "recentMealNames": context.recentMealNames,
            "preferredCoachStyle": context.preferredCoachStyle,
        ]
        if let healthNote = context.healthNote {
            payload["healthNote"] = healthNote
        }
        return ["context": payload]
    }

    private static func errorMessage(from data: Data, statusCode: Int) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let error = json["error"] as? String, !error.isEmpty {
                return friendlyError(error, statusCode: statusCode)
            }
        }
        let raw = String(data: data, encoding: .utf8) ?? ""
        if !raw.isEmpty { return friendlyError(raw, statusCode: statusCode) }
        return "AI request failed (HTTP \(statusCode))."
    }

    private static func friendlyError(_ message: String, statusCode: Int) -> String {
        let lower = message.lowercased()
        if statusCode == 404 || lower.contains("not found") {
            return "ai-proxy function not found. Deploy it: supabase functions deploy ai-proxy"
        }
        if lower.contains("openai not configured") {
            return "OpenAI key missing on Supabase. Run: supabase secrets set OPENAI_API_KEY=sk-..."
        }
        if statusCode == 401 || lower.contains("unauthorized") {
            return "Supabase auth failed. Enable Anonymous sign-ins and try again."
        }
        return message
    }
}
