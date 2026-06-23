import Foundation

enum DietPreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case vegetarian
    case nonVeg
    case indianFood
    case highProtein
    case lowCalorie
    case restaurantMeals

    var id: String { rawValue }

    var label: String {
        switch self {
        case .vegetarian: "Vegetarian"
        case .nonVeg: "Non-veg"
        case .indianFood: "Indian food"
        case .highProtein: "High-protein"
        case .lowCalorie: "Low-calorie"
        case .restaurantMeals: "Restaurant meals"
        }
    }

    var coachStyleLabel: String {
        switch self {
        case .vegetarian: "Vegetarian"
        case .nonVeg: "Quick"
        case .indianFood: "Indian"
        case .highProtein: "High protein"
        case .lowCalorie: "Low calorie"
        case .restaurantMeals: "Restaurant"
        }
    }
}

enum DietPreferenceStorage {
    static func decode(from json: String) -> Set<DietPreference> {
        guard
            let data = json.data(using: .utf8),
            let rawValues = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return Set(rawValues.compactMap(DietPreference.init(rawValue:)))
    }

    static func encode(_ preferences: Set<DietPreference>) -> String {
        let rawValues = preferences.map(\.rawValue).sorted()
        guard let data = try? JSONEncoder().encode(rawValues) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}
