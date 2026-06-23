import Foundation
import SwiftData

enum GroceryCategory: String, Codable, CaseIterable, Identifiable {
    case produce
    case protein
    case dairy
    case pantry
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .produce: "Produce"
        case .protein: "Protein"
        case .dairy: "Dairy"
        case .pantry: "Pantry"
        case .other: "Other"
        }
    }

    static func infer(from name: String) -> GroceryCategory {
        let lower = name.lowercased()
        if lower.contains("chicken") || lower.contains("fish") || lower.contains("egg") || lower.contains("tofu") || lower.contains("paneer") {
            return .protein
        }
        if lower.contains("yogurt") || lower.contains("milk") || lower.contains("cheese") {
            return .dairy
        }
        if lower.contains("rice") || lower.contains("dal") || lower.contains("oats") || lower.contains("bread") {
            return .pantry
        }
        if lower.contains("spinach") || lower.contains("tomato") || lower.contains("onion") || lower.contains("fruit") {
            return .produce
        }
        return .other
    }
}

@Model
final class GroceryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String
    var isChecked: Bool
    var createdAt: Date

    init(name: String, category: GroceryCategory = .other) {
        id = UUID()
        self.name = name
        categoryRaw = category.rawValue
        isChecked = false
        createdAt = .now
    }

    var category: GroceryCategory {
        get { GroceryCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
