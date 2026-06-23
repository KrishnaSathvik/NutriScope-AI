import Foundation

/// Backend configuration for the **dedicated iOS Supabase project**.
/// This is separate from the nutriscope web app — only URL/key values are stored here.
enum BackendConfig {
    private static let offlineDemoKey = "offlineDemoMode"
    private static let useDirectOpenAIKey = "useDirectOpenAIInDebug"

    /// When true, meal scans use MockMealAnalysisService (no network). For App Store screenshots / airplane mode.
    static var offlineDemoMode: Bool {
        get {
            if ProcessInfo.processInfo.arguments.contains("-OfflineDemo") {
                return true
            }
            return UserDefaults.standard.bool(forKey: offlineDemoKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: offlineDemoKey) }
    }

    #if DEBUG
    /// Debug-only: bypass proxy and call OpenAI directly when a dev API key is set.
    static var useDirectOpenAIInDebug: Bool {
        get { UserDefaults.standard.object(forKey: useDirectOpenAIKey) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: useDirectOpenAIKey) }
    }
    #endif

    static var supabaseURL: String {
        if let env = ProcessInfo.processInfo.environment["SUPABASE_URL"], !env.isEmpty {
            return env.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return UserDefaults.standard.string(forKey: "supabaseURL") ?? ""
    }

    static var supabaseAnonKey: String {
        if let env = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !env.isEmpty {
            return env.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return UserDefaults.standard.string(forKey: "supabaseAnonKey") ?? ""
    }

    static var isSupabaseConfigured: Bool {
        let url = supabaseURL
        let key = supabaseAnonKey
        return url.hasPrefix("https://") && url.contains("supabase") && !key.isEmpty
    }

    static var analyzeMealURL: URL? {
        guard isSupabaseConfigured else { return nil }
        let trimmed = supabaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(trimmed)/functions/v1/analyze-meal")
    }

    static var isReleaseBuild: Bool {
        #if DEBUG
        false
        #else
        true
        #endif
    }
}
