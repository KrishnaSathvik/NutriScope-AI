import Foundation

struct LocalUserAccount: Codable, Equatable {
    var id: UUID
    var email: String
    var displayName: String
    var createdAt: Date
    var authProvider: String
}

enum AuthError: LocalizedError {
    case invalidEmail
    case passwordTooShort
    case emailAlreadyInUse
    case invalidCredentials
    case noAccount

    var errorDescription: String? {
        switch self {
        case .invalidEmail: "Enter a valid email address."
        case .passwordTooShort: "Password must be at least 6 characters."
        case .emailAlreadyInUse: "An account with this email already exists."
        case .invalidCredentials: "Email or password is incorrect."
        case .noAccount: "No account found. Create one to continue."
        }
    }
}

enum AuthSessionManager {
    private static let accountKey = "localUserAccount"
    private static let passwordKey = "localUserPassword"
    private static let signedInKey = "isUserSignedIn"

    static var isSignedIn: Bool {
        get {
            guard UserDefaults.standard.bool(forKey: signedInKey) else { return false }
            guard currentAccount != nil else { return false }
            if BackendConfig.isSupabaseConfigured {
                return SupabaseAuthClient.isSignedIn && !SupabaseAuthClient.isAnonymousSession
            }
            return true
        }
        set { UserDefaults.standard.set(newValue, forKey: signedInKey) }
    }

    static var currentAccount: LocalUserAccount? {
        get {
            guard let data = UserDefaults.standard.data(forKey: accountKey) else { return nil }
            return try? JSONDecoder().decode(LocalUserAccount.self, from: data)
        }
        set {
            if let newValue {
                let data = try? JSONEncoder().encode(newValue)
                UserDefaults.standard.set(data, forKey: accountKey)
            } else {
                UserDefaults.standard.removeObject(forKey: accountKey)
            }
        }
    }

    static var hasAccount: Bool { currentAccount != nil }

    static func signUp(email: String, password: String, displayName: String) throws -> LocalUserAccount {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        try validate(email: normalizedEmail, password: password)

        if let existing = currentAccount, existing.email == normalizedEmail {
            throw AuthError.emailAlreadyInUse
        }

        let account = LocalUserAccount(
            id: UUID(),
            email: normalizedEmail,
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: .now,
            authProvider: "email"
        )
        currentAccount = account
        UserDefaults.standard.set(password, forKey: passwordKey)
        isSignedIn = true
        return account
    }

    static func signIn(email: String, password: String) throws -> LocalUserAccount {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        try validateEmail(normalizedEmail)

        guard let account = currentAccount, account.email == normalizedEmail else {
            throw AuthError.invalidCredentials
        }
        guard UserDefaults.standard.string(forKey: passwordKey) == password else {
            throw AuthError.invalidCredentials
        }

        isSignedIn = true
        return account
    }

    static func resetPassword(email: String, newPassword: String) throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        try validateEmail(normalizedEmail)
        guard newPassword.count >= 6 else { throw AuthError.passwordTooShort }
        guard let account = currentAccount, account.email == normalizedEmail else {
            throw AuthError.noAccount
        }
        UserDefaults.standard.set(newPassword, forKey: passwordKey)
    }

    static func signOut() {
        isSignedIn = false
        currentAccount = nil
        UserDefaults.standard.removeObject(forKey: passwordKey)
        SupabaseAuthClient.signOut()
        Task { @MainActor in
            try? await BackendAuthBootstrap.ensureBackendSession()
            GuestModeManager.isGuest = true
        }
    }

    /// Clears local credentials only. Use `AccountDeletionService` for full account deletion.
    static func clearLocalSession() {
        currentAccount = nil
        UserDefaults.standard.removeObject(forKey: passwordKey)
        isSignedIn = false
        SupabaseAuthClient.signOut()
    }

    @available(*, deprecated, message: "Use AccountDeletionService.deleteAccount instead")
    static func deleteAccount() {
        clearLocalSession()
    }

    static func applyAppleSignIn(email: String, displayName: String) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let existing = currentAccount {
            var updated = existing
            if !displayName.isEmpty { updated.displayName = displayName }
            if !normalizedEmail.isEmpty, normalizedEmail.contains("@") {
                updated.email = normalizedEmail
            }
            updated.authProvider = "apple"
            currentAccount = updated
        } else {
            currentAccount = LocalUserAccount(
                id: UUID(),
                email: normalizedEmail.isEmpty ? "apple@privaterelay.appleid.com" : normalizedEmail,
                displayName: displayName.isEmpty ? "Apple User" : displayName,
                createdAt: .now,
                authProvider: "apple"
            )
            UserDefaults.standard.set(UUID().uuidString, forKey: passwordKey)
        }
        isSignedIn = true
    }

    private static func validate(email: String, password: String) throws {
        try validateEmail(email)
        guard password.count >= 6 else { throw AuthError.passwordTooShort }
    }

    private static func validateEmail(_ email: String) throws {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        guard email.range(of: pattern, options: .regularExpression) != nil else {
            throw AuthError.invalidEmail
        }
    }
}
