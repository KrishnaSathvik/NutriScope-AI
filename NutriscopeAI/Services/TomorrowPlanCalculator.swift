import Foundation

enum TomorrowPlanCalculator {
    struct MealSuggestion: Identifiable, Equatable {
        let id = UUID()
        let slot: MealSlot
        let name: String
        let protein: Int
        let calories: Int
        let carbs: Int
        let fat: Int
        let systemImage: String

        enum MealSlot: String, CaseIterable {
            case breakfast = "Breakfast"
            case lunch = "Lunch"
            case dinner = "Dinner"
        }
    }

    struct Plan: Equatable {
        let targetProtein: Int
        let plannedProtein: Int
        let meals: [MealSuggestion]
        let tomorrowLabel: String
    }

    static func tomorrowLabel(referenceDate: Date = .now) -> String {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
        return tomorrow.formatted(.dateTime.weekday(.wide))
    }
}
