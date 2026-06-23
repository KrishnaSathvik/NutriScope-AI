import Foundation
import SwiftData

@Model
final class MealRecord {
    @Attribute(.unique) var id: UUID
    var mealName: String
    var caloriesMin: Int
    var caloriesMax: Int
    var proteinMin: Int
    var proteinMax: Int
    var carbsMin: Int
    var carbsMax: Int
    var fatMin: Int
    var fatMax: Int
    var confidenceRaw: String
    var coachMessage: String
    var adviceHeadline: String
    var suggestionsJSON: String
    var balanceScore: Int
    var scannedAt: Date
    var mealNote: String
    var mealTypeRaw: String = MealType.lunch.rawValue
    @Attribute(.externalStorage) var imageData: Data?

    init(from analysis: MealAnalysis, mealNote: String = "", mealType: MealType = MealType.inferred()) {
        id = UUID()
        mealName = analysis.mealName
        self.mealNote = mealNote
        mealTypeRaw = mealType.rawValue
        caloriesMin = analysis.calories.min
        caloriesMax = analysis.calories.max
        proteinMin = analysis.protein.min
        proteinMax = analysis.protein.max
        carbsMin = analysis.carbs.min
        carbsMax = analysis.carbs.max
        fatMin = analysis.fat.min
        fatMax = analysis.fat.max
        confidenceRaw = analysis.confidence.rawValue
        coachMessage = analysis.advice.coachMessage
        adviceHeadline = analysis.advice.headline
        suggestionsJSON = (try? JSONEncoder().encode(analysis.advice.suggestions))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        balanceScore = analysis.advice.balanceScore
        scannedAt = analysis.scannedAt
        imageData = analysis.imageData
    }

    init(cloning source: MealRecord) {
        id = UUID()
        mealName = source.mealName
        mealNote = source.mealNote
        caloriesMin = source.caloriesMin
        caloriesMax = source.caloriesMax
        proteinMin = source.proteinMin
        proteinMax = source.proteinMax
        carbsMin = source.carbsMin
        carbsMax = source.carbsMax
        fatMin = source.fatMin
        fatMax = source.fatMax
        confidenceRaw = source.confidenceRaw
        coachMessage = source.coachMessage
        adviceHeadline = source.adviceHeadline
        suggestionsJSON = source.suggestionsJSON
        balanceScore = source.balanceScore
        scannedAt = .now
        imageData = source.imageData
        mealTypeRaw = source.mealTypeRaw
    }

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .lunch }
        set { mealTypeRaw = newValue.rawValue }
    }

    var analysis: MealAnalysis {
        MealAnalysis(
            id: id,
            mealName: mealName,
            calories: MacroRange(min: caloriesMin, max: caloriesMax),
            protein: MacroRange(min: proteinMin, max: proteinMax),
            carbs: MacroRange(min: carbsMin, max: carbsMax),
            fat: MacroRange(min: fatMin, max: fatMax),
            confidence: ConfidenceLevel(rawValue: confidenceRaw) ?? .medium,
            followUpQuestions: [],
            advice: MealAdvice(
                headline: adviceHeadline,
                proteinGapGrams: 0,
                suggestions: decodedSuggestions,
                coachMessage: coachMessage,
                balanceScore: balanceScore
            ),
            scannedAt: scannedAt,
            imageData: imageData
        )
    }

    private var decodedSuggestions: [String] {
        guard
            let data = suggestionsJSON.data(using: .utf8),
            let items = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return items
    }
}
