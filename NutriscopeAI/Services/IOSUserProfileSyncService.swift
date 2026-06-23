import Foundation

enum IOSUserProfileSyncError: LocalizedError {
    case notConfigured
    case unauthorized
    case invalidUserID
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Supabase is not configured."
        case .unauthorized:
            "Sign in required to sync your profile."
        case .invalidUserID:
            "Could not read your account id for profile sync."
        case .network(let message):
            message
        }
    }
}

/// Upserts `ios_user_profiles` in the dedicated iOS Supabase project after account creation / sign-in.
enum IOSUserProfileSyncService {
  static func upsertAfterAuthentication(settings: UserSettings?) async {
        do {
            try await upsert(settings: settings)
        } catch {
            #if DEBUG
            print("IOSUserProfileSyncService: \(error.localizedDescription)")
            #endif
        }
    }

    static func upsert(settings: UserSettings?) async throws {
        guard BackendConfig.isSupabaseConfigured else { throw IOSUserProfileSyncError.notConfigured }
        guard SupabaseAuthClient.hasLinkedAccount else { throw IOSUserProfileSyncError.unauthorized }

        let session = try await SupabaseAuthClient.validSession()
        guard UUID(uuidString: session.userID) != nil else {
            throw IOSUserProfileSyncError.invalidUserID
        }

        let account = AuthSessionManager.currentAccount
        let displayName = settings?.displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty
            ?? account?.displayName
            ?? "Nutriscope User"
        let email = session.email
            ?? account?.email
            ?? ""

        let payload: [String: Any] = [
            "id": session.userID,
            "display_name": displayName,
            "email": email,
            "daily_protein_target": settings?.dailyProteinTarget ?? 135,
            "calorie_range_min": settings?.calorieRangeMin ?? 1900,
            "calorie_range_max": settings?.calorieRangeMax ?? 2200,
        ]

        let base = BackendConfig.supabaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/rest/v1/ios_user_profiles") else {
            throw IOSUserProfileSyncError.network("Invalid Supabase URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(BackendConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw IOSUserProfileSyncError.network("Profile sync failed")
        }

        if http.statusCode == 401 {
            SupabaseAuthClient.signOut()
            throw IOSUserProfileSyncError.unauthorized
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = Self.errorMessage(from: data, statusCode: http.statusCode)
            throw IOSUserProfileSyncError.network(message)
        }
    }

    private static func errorMessage(from data: Data, statusCode: Int) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = json["message"] as? String, !message.isEmpty {
                return friendly(message, statusCode: statusCode)
            }
            if let hint = json["hint"] as? String, !hint.isEmpty {
                return friendly(hint, statusCode: statusCode)
            }
        }
        let raw = String(data: data, encoding: .utf8) ?? ""
        if !raw.isEmpty { return friendly(raw, statusCode: statusCode) }
        return "Profile sync failed (HTTP \(statusCode))."
    }

    private static func friendly(_ message: String, statusCode: Int) -> String {
        let lower = message.lowercased()
        if lower.contains("ios_user_profiles") && (lower.contains("does not exist") || lower.contains("relation")) {
            return "ios_user_profiles table missing. Run supabase/migrations/001_ios_user_profiles.sql in the Supabase SQL editor."
        }
        if statusCode == 404 {
            return "Profile table not found. Apply migration 001_ios_user_profiles.sql."
        }
        return message
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
