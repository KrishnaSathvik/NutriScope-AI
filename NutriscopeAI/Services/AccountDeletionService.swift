import Foundation
import SwiftData

enum AccountDeletionError: LocalizedError {
    case remoteDeletionFailed(String)

    var errorDescription: String? {
        switch self {
        case .remoteDeletionFailed(let message):
            message
        }
    }
}

@MainActor
enum AccountDeletionService {
    /// Deletes the Supabase auth user (cascades `ios_user_profiles`), wipes local app data, and returns to Welcome.
    static func deleteAccount(appState: AppState, modelContext: ModelContext) async throws {
        if BackendConfig.isSupabaseConfigured, SupabaseAuthClient.isSignedIn {
            do {
                try await SupabaseAuthClient.deleteCurrentUser()
            } catch {
                throw AccountDeletionError.remoteDeletionFailed(error.localizedDescription)
            }
        }

        AuthSessionManager.clearLocalSession()
        try wipeLocalUserData(modelContext: modelContext)

        GuestModeManager.isGuest = false
        appState.activeSheet = nil
        appState.hasCompletedOnboarding = false
    }

    private static func wipeLocalUserData(modelContext: ModelContext) throws {
        let meals = try modelContext.fetch(FetchDescriptor<MealRecord>())
        meals.forEach { modelContext.delete($0) }

        let savedMeals = try modelContext.fetch(FetchDescriptor<SavedMeal>())
        savedMeals.forEach { modelContext.delete($0) }

        let weights = try modelContext.fetch(FetchDescriptor<WeightLog>())
        weights.forEach { modelContext.delete($0) }

        let settings = try modelContext.fetch(FetchDescriptor<UserSettings>())
        settings.forEach { modelContext.delete($0) }

        let groceries = try modelContext.fetch(FetchDescriptor<GroceryItem>())
        groceries.forEach { modelContext.delete($0) }

        try modelContext.save()
    }
}
