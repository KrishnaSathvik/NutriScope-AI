import Foundation

/// Ensures a Supabase JWT exists for backend calls without showing signup UI.
/// Guest users get a silent anonymous Supabase session; linked accounts keep their session.
enum BackendAuthBootstrap {
    @MainActor
    static func ensureBackendSession() async throws {
        guard BackendConfig.isSupabaseConfigured else { return }
        guard !BackendConfig.offlineDemoMode else { return }

        if SupabaseAuthClient.currentSession != nil {
            _ = try await SupabaseAuthClient.validSession()
            return
        }

        _ = try await SupabaseAuthClient.signInAnonymously()
    }
}
