import SwiftData
import SwiftUI

@main
struct NutriscopeAIApp: App {
    @State private var appState = AppState()

    init() {
        NotificationManager.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
        .modelContainer(for: [MealRecord.self, UserSettings.self, SavedMeal.self, WeightLog.self, GroceryItem.self])
    }
}
