import Foundation

enum OpenAIClientError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case network(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Add your OpenAI API key in Profile → Developer to use AI features."
        case .invalidResponse:
            "Could not read the AI response. Try again."
        case .network(let message):
            message
        }
    }
}

enum OpenAIClient {
    static var apiKey: String { Secrets.openAIAPIKey }

    static func requireAPIKey() throws -> String {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw OpenAIClientError.missingAPIKey }
        return key
    }

    static func chatCompletion(
        messages: [[String: String]],
        model: String = "gpt-4o-mini",
        maxTokens: Int = 800,
        jsonObject: Bool = false
    ) async throws -> String {
        let key = try requireAPIKey()

        var body: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": maxTokens
        ]
        if jsonObject {
            body["response_format"] = ["type": "json_object"]
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Request failed"
            throw OpenAIClientError.network(message)
        }

        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw OpenAIClientError.invalidResponse
        }
        return content
    }

    static func decodeJSON<T: Decodable>(_ type: T.Type, from content: String) throws -> T {
        let trimmed = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
        guard let data = trimmed.data(using: .utf8) else {
            throw OpenAIClientError.invalidResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
