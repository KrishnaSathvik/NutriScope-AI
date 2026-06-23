import Foundation

/// Backend configuration for the **dedicated iOS Supabase project**.
/// This is separate from the nutriscope web app — only URL/key values are stored here.
enum BackendConfig {
    private static let useDirectOpenAIKey = "useDirectOpenAIInDebug"

    static let passwordResetRedirectURL = "com.nutriscopeai.app://auth-callback"

    /// Launch-only mock scans for screenshots (`-OfflineDemo`). Not exposed in the app UI.
    static var offlineDemoMode: Bool {
        ProcessInfo.processInfo.arguments.contains("-OfflineDemo")
    }

    #if DEBUG
    /// Debug-only: bypass proxy and call OpenAI directly when a dev API key is set.
    static var useDirectOpenAIInDebug: Bool {
        get { UserDefaults.standard.object(forKey: useDirectOpenAIKey) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: useDirectOpenAIKey) }
    }
    #endif

  /// Resolution order: Scheme env vars → Info.plist (from `Backend.xcconfig` at build time) → UserDefaults (Debug panel).
    static var supabaseURL: String {
        if let env = ProcessInfo.processInfo.environment["SUPABASE_URL"], !env.isEmpty {
            return env.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !plist.isEmpty {
            return plist.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return UserDefaults.standard.string(forKey: "supabaseURL") ?? ""
    }

    static var supabaseAnonKey: String {
        if let env = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !env.isEmpty {
            return env.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !plist.isEmpty {
            return plist.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return UserDefaults.standard.string(forKey: "supabaseAnonKey") ?? ""
    }

    static var isSupabaseConfigured: Bool {
        let url = supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard url.hasPrefix("https://"), url.contains("supabase"), !key.isEmpty else {
            return false
        }
        // xcconfig accidentally truncates https://… to "https:" when // is unescaped
        if url == "https:" || url == "http:" {
            return false
        }
        return true
    }

    /// Human-readable hint when Supabase URL looks broken (common xcconfig `//` comment trap).
    static var supabaseConfigurationHint: String? {
        let url = supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if url == "https:" || url == "http:" {
            return "Supabase URL is truncated in Backend.xcconfig. Use https:/$()/your-project.supabase.co, then clean build."
        }
        if !isSupabaseConfigured, supabaseAnonKey.isEmpty, url.isEmpty {
            return nil
        }
        if !isSupabaseConfigured {
            return "Add Supabase URL + anon key in Profile → Developer, or fix Backend.xcconfig and rebuild."
        }
        return nil
    }

    static var analyzeMealURL: URL? {
        guard isSupabaseConfigured else { return nil }
        let trimmed = supabaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(trimmed)/functions/v1/analyze-meal")
    }

    static var aiProxyURL: URL? {
        guard isSupabaseConfigured else { return nil }
        let trimmed = supabaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(trimmed)/functions/v1/ai-proxy")
    }

    /// When true, coach/tips/grocery use device OpenAI (Debug only).
    static var usesDeviceOpenAIForCoach: Bool {
        #if DEBUG
        if useDirectOpenAIInDebug {
            let key = Secrets.openAIAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty { return true }
        }
        if !isSupabaseConfigured {
            let key = Secrets.openAIAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
            return !key.isEmpty
        }
        return false
        #else
        return false
        #endif
    }

    static var isReleaseBuild: Bool {
        #if DEBUG
        false
        #else
        true
        #endif
    }
}
