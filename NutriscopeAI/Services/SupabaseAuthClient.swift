import Foundation

struct SupabaseSession: Codable, Equatable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var userID: String
    var email: String?
    var isAnonymous: Bool

    var isExpired: Bool {
        expiresAt <= Date().addingTimeInterval(60)
    }

    init(
        accessToken: String,
        refreshToken: String,
        expiresAt: Date,
        userID: String,
        email: String?,
        isAnonymous: Bool = false
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.userID = userID
        self.email = email
        self.isAnonymous = isAnonymous
    }
}

enum SupabaseAuthError: LocalizedError {
    case notConfigured
    case invalidResponse
    case unauthorized
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Supabase is not configured. Add URL and anon key in Profile → Developer."
        case .invalidResponse:
            "Could not read the auth response."
        case .unauthorized:
            "Sign in required. Create an account or use Sign in with Apple."
        case .network(let message):
            message
        }
    }
}

enum SupabaseAuthClient {
    private static let sessionKey = "supabaseSession"

    static var currentSession: SupabaseSession? {
        get {
            guard let data = UserDefaults.standard.data(forKey: sessionKey) else { return nil }
            return try? JSONDecoder().decode(SupabaseSession.self, from: data)
        }
        set {
            if let newValue {
                let data = try? JSONEncoder().encode(newValue)
                UserDefaults.standard.set(data, forKey: sessionKey)
            } else {
                UserDefaults.standard.removeObject(forKey: sessionKey)
            }
        }
    }

    static var isSignedIn: Bool { currentSession != nil }

    static var isAnonymousSession: Bool {
        currentSession?.isAnonymous == true
    }

    static var hasLinkedAccount: Bool {
        guard let session = currentSession else { return false }
        return !session.isAnonymous
    }

    static var accessToken: String {
        get async throws {
            let session = try await validSession()
            return session.accessToken
        }
    }

    static func validSession() async throws -> SupabaseSession {
        guard BackendConfig.isSupabaseConfigured else { throw SupabaseAuthError.notConfigured }
        guard let session = currentSession else { throw SupabaseAuthError.unauthorized }
        if session.isExpired {
            return try await refresh(session: session)
        }
        return session
    }

    static func signUpWithEmail(email: String, password: String) async throws -> SupabaseSession {
        if isAnonymousSession {
            return try await linkEmailPassword(email: email, password: password)
        }

        let response = try await authRequest(
            path: "signup",
            body: ["email": email, "password": password]
        )
        return try parseSession(from: response)
    }

    static func signInWithEmail(email: String, password: String) async throws -> SupabaseSession {
        let response = try await authRequest(
            path: "token?grant_type=password",
            body: ["email": email, "password": password]
        )
        return try parseSession(from: response)
    }

    static func signInWithApple(identityToken: String, nonce: String) async throws -> SupabaseSession {
        if isAnonymousSession, let session = currentSession {
            return try await linkAppleIdentity(
                identityToken: identityToken,
                nonce: nonce,
                session: session
            )
        }

        let response = try await authRequest(
            path: "token?grant_type=id_token",
            body: [
                "provider": "apple",
                "id_token": identityToken,
                "nonce": nonce,
            ]
        )
        return try parseSession(from: response)
    }

    /// Silent guest session — requires Anonymous sign-ins enabled in Supabase Auth.
    static func signInAnonymously() async throws -> SupabaseSession {
        let response = try await authRequest(path: "signup", body: [:])
        return try parseSession(from: response)
    }

    static func linkEmailPassword(email: String, password: String) async throws -> SupabaseSession {
        let session = try await validSession()
        let response = try await authenticatedAuthRequest(
            path: "user",
            method: "PUT",
            body: [
                "email": email,
                "password": password,
            ],
            session: session
        )
        if response["access_token"] != nil {
            return try parseSession(from: response)
        }

        var linked = session
        linked.email = email
        linked.isAnonymous = false
        currentSession = linked
        return linked
    }

    static func signOut() {
        currentSession = nil
    }

    /// Sends a password recovery email via Supabase Auth (no in-app password change).
    static func requestPasswordReset(email: String, redirectTo: String? = nil) async throws {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { throw SupabaseAuthError.invalidResponse }

        var body: [String: Any] = ["email": normalized]
        if let redirectTo, !redirectTo.isEmpty {
            body["redirect_to"] = redirectTo
        }

        _ = try await authRequest(path: "recover", body: body)
    }

    /// Self-service account deletion (GoTrue). Cascades to `ios_user_profiles` via FK.
    static func deleteCurrentUser() async throws {
        let session = try await validSession()

        let base = BackendConfig.supabaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/auth/v1/user") else {
            throw SupabaseAuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(BackendConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseAuthError.invalidResponse
        }

        if !(200..<300).contains(http.statusCode) {
            let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
            let message = (json["error_description"] as? String)
                ?? (json["msg"] as? String)
                ?? (json["message"] as? String)
                ?? String(data: data, encoding: .utf8)
                ?? "Could not delete account"
            throw SupabaseAuthError.network(message)
        }

        currentSession = nil
    }

    private static func refresh(session: SupabaseSession) async throws -> SupabaseSession {
        let response = try await authRequest(
            path: "token?grant_type=refresh_token",
            body: ["refresh_token": session.refreshToken]
        )
        return try parseSession(from: response)
    }

    private static func linkAppleIdentity(
        identityToken: String,
        nonce: String,
        session: SupabaseSession
    ) async throws -> SupabaseSession {
        let response = try await authenticatedAuthRequest(
            path: "token?grant_type=id_token",
            method: "POST",
            body: [
                "provider": "apple",
                "id_token": identityToken,
                "nonce": nonce,
            ],
            session: session
        )
        return try parseSession(from: response)
    }

    private static func authenticatedAuthRequest(
        path: String,
        method: String,
        body: [String: Any],
        session: SupabaseSession
    ) async throws -> [String: Any] {
        guard BackendConfig.isSupabaseConfigured else { throw SupabaseAuthError.notConfigured }

        let base = BackendConfig.supabaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/auth/v1/\(path)") else {
            throw SupabaseAuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(BackendConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseAuthError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SupabaseAuthError.invalidResponse
        }

        if !(200..<300).contains(http.statusCode) {
            let message = (json["error_description"] as? String)
                ?? (json["msg"] as? String)
                ?? (json["message"] as? String)
                ?? String(data: data, encoding: .utf8)
                ?? "Auth failed"
            throw SupabaseAuthError.network(message)
        }

        return json
    }

    private static func authRequest(path: String, body: [String: Any]) async throws -> [String: Any] {
        guard BackendConfig.isSupabaseConfigured else { throw SupabaseAuthError.notConfigured }

        let base = BackendConfig.supabaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/auth/v1/\(path)") else {
            throw SupabaseAuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(BackendConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(BackendConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseAuthError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SupabaseAuthError.invalidResponse
        }

        if !(200..<300).contains(http.statusCode) {
            let message = (json["error_description"] as? String)
                ?? (json["msg"] as? String)
                ?? (json["message"] as? String)
                ?? String(data: data, encoding: .utf8)
                ?? "Auth failed"
            throw SupabaseAuthError.network(message)
        }

        return json
    }

    private static func parseSession(from json: [String: Any]) throws -> SupabaseSession {
        guard
            let accessToken = json["access_token"] as? String,
            let refreshToken = json["refresh_token"] as? String,
            let expiresIn = json["expires_in"] as? Int
        else {
            throw SupabaseAuthError.invalidResponse
        }

        let user = json["user"] as? [String: Any]
        let userID = user?["id"] as? String ?? UUID().uuidString
        let email = user?["email"] as? String
        let isAnonymous = user?["is_anonymous"] as? Bool ?? false

        let session = SupabaseSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn)),
            userID: userID,
            email: email,
            isAnonymous: isAnonymous
        )
        currentSession = session
        return session
    }
}
