import Foundation

enum ConfidenceLevel: String, Codable, CaseIterable, Sendable {
    case high
    case medium
    case low

    var label: String {
        switch self {
        case .high: "High confidence"
        case .medium: "Medium confidence"
        case .low: "Low confidence"
        }
    }

    var shortLabel: String {
        switch self {
        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"
        }
    }
}

struct MacroRange: Codable, Hashable, Sendable {
    var min: Int
    var max: Int

    var midpoint: Int { (min + max) / 2 }

    var formatted: String { "\(min)–\(max)" }

    func adjusted(by factor: Double) -> MacroRange {
        MacroRange(
            min: Int(Double(min) * factor),
            max: Int(Double(max) * factor)
        )
    }
}

struct FollowUpQuestion: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var prompt: String
    var options: [String]
    var selectedOption: String?

    init(id: UUID = UUID(), prompt: String, options: [String], selectedOption: String? = nil) {
        self.id = id
        self.prompt = prompt
        self.options = options
        self.selectedOption = selectedOption
    }
}

struct MealAdvice: Codable, Hashable, Sendable {
    var headline: String
    var proteinGapGrams: Int
    var suggestions: [String]
    var coachMessage: String
    var balanceScore: Int
}

struct MealAnalysis: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var mealName: String
    var calories: MacroRange
    var protein: MacroRange
    var carbs: MacroRange
    var fat: MacroRange
    var confidence: ConfidenceLevel
    var followUpQuestions: [FollowUpQuestion]
    var advice: MealAdvice
    var scannedAt: Date
    var imageData: Data?

    var proteinMidpoint: Int { protein.midpoint }

    init(
        id: UUID = UUID(),
        mealName: String,
        calories: MacroRange,
        protein: MacroRange,
        carbs: MacroRange,
        fat: MacroRange,
        confidence: ConfidenceLevel,
        followUpQuestions: [FollowUpQuestion],
        advice: MealAdvice,
        scannedAt: Date = .now,
        imageData: Data? = nil
    ) {
        self.id = id
        self.mealName = mealName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.confidence = confidence
        self.followUpQuestions = followUpQuestions
        self.advice = advice
        self.scannedAt = scannedAt
        self.imageData = imageData
    }

    func refined(with answers: [FollowUpQuestion]) -> MealAnalysis {
        var copy = self
        copy.followUpQuestions = answers

        let adjustment = Self.adjustmentFactor(for: answers)
        guard adjustment != 1.0 else { return copy }

        copy.calories = calories.adjusted(by: adjustment)
        copy.protein = protein.adjusted(by: adjustment)
        copy.carbs = carbs.adjusted(by: adjustment)
        copy.fat = fat.adjusted(by: adjustment)
        copy.confidence = .high
        return copy
    }

    private static func adjustmentFactor(for answers: [FollowUpQuestion]) -> Double {
        var factor = 1.0
        for answer in answers {
            guard let selected = answer.selectedOption?.lowercased() else { continue }
            if selected.contains("extra") || selected.contains("large") || selected.contains("fried") || selected.contains("heavy") {
                factor += 0.12
            }
            if selected.contains("light") || selected.contains("small") || selected.contains("none") || selected.contains("steamed") {
                factor -= 0.08
            }
        }
        return max(0.75, min(1.35, factor))
    }
}
