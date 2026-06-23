import Foundation

struct MealAnalysisRequest: Sendable {
    var imageData: Data?
    var mealDescription: String
    var dailyProteinTarget: Int
    var dietPreferences: Set<DietPreference>
    var userContext: String = ""
    var proteinConsumedToday: Int = 0
    var caloriesConsumedToday: Int = 0

    var trimmedDescription: String {
        mealDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasImage: Bool { imageData != nil }
    var hasDescription: Bool { !trimmedDescription.isEmpty }

    var isValid: Bool { hasImage || hasDescription }
}

protocol MealAnalysisServiceProtocol: Sendable {
    func analyzeMeal(_ request: MealAnalysisRequest) async throws -> MealAnalysis
}

enum MealAnalysisError: LocalizedError {
    case missingAPIKey
    case missingBackendConfiguration
    case unauthorized
    case invalidResponse
    case missingInput
    case network(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Add your OpenAI API key in Profile → Developer to use live AI scans."
        case .missingBackendConfiguration:
            "Supabase backend is not configured. Add URL and anon key in Profile → Developer."
        case .unauthorized:
            "Guest sign-in failed. In Supabase enable Anonymous sign-ins, then Profile → Account → Save & test connection."
        case .invalidResponse:
            "Could not read the meal analysis. Try another photo or description."
        case .missingInput:
            "Add a photo or describe your meal to analyze."
        case .network(let message):
            message
        }
    }
}

enum MealAnalysisServiceFactory {
    /// Resolves the meal analysis backend for the current build configuration.
    /// Release builds always use the Supabase proxy unless offline demo mode is on.
    static func make(hasProAccess _: Bool = false) -> any MealAnalysisServiceProtocol {
        if BackendConfig.offlineDemoMode {
            return MockMealAnalysisService()
        }

        #if DEBUG
        if BackendConfig.useDirectOpenAIInDebug {
            let key = Secrets.openAIAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty {
                return OpenAIMealAnalysisService(apiKey: key)
            }
        }
        #endif

        if BackendConfig.isSupabaseConfigured {
            return ProxyMealAnalysisService()
        }

        #if DEBUG
        let key = Secrets.openAIAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty {
            return OpenAIMealAnalysisService(apiKey: key)
        }
        #endif

        if BackendConfig.isReleaseBuild {
            return UnconfiguredMealAnalysisService(reason: .missingBackendConfiguration)
        }

        return UnconfiguredMealAnalysisService(reason: .missingAPIKey)
    }
}

private struct UnconfiguredMealAnalysisService: MealAnalysisServiceProtocol {
    let reason: MealAnalysisError

    func analyzeMeal(_ request: MealAnalysisRequest) async throws -> MealAnalysis {
        throw reason
    }
}

enum Secrets {
    static var openAIAPIKey: String {
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !env.isEmpty {
            return env
        }
        return UserDefaults.standard.string(forKey: "openAIAPIKey") ?? ""
    }

    static var usdaAPIKey: String {
        if let env = ProcessInfo.processInfo.environment["USDA_API_KEY"], !env.isEmpty {
            return env
        }
        return UserDefaults.standard.string(forKey: "usdaAPIKey") ?? ""
    }

    static var supabaseURL: String { BackendConfig.supabaseURL }
    static var supabaseAnonKey: String { BackendConfig.supabaseAnonKey }
}
