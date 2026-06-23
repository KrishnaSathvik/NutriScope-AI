import Foundation

enum WeeklyReportCalculator {
    struct DaySummary: Identifiable, Equatable {
        let id: Date
        let label: String
        let protein: Int
        let calories: Int
        let mealCount: Int
        let hitGoal: Bool
    }

    struct Report: Equatable {
        let daysLogged: Int
        let daysHitGoal: Int
        let averageProtein: Int
        let averageCalories: Int
        let bestDay: DaySummary?
        let lowestProteinDay: DaySummary?
        let dailySummaries: [DaySummary]
        let coachSummary: String
    }

    static func build(from meals: [MealRecord], proteinTarget: Int, calorieMin: Int, calorieMax: Int, referenceDate: Date = .now) -> Report {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)) else {
            return emptyReport
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        var dayTotals: [Date: (protein: Int, calories: Int, count: Int)] = [:]
        for meal in meals where meal.scannedAt >= weekStart {
            let day = calendar.startOfDay(for: meal.scannedAt)
            var entry = dayTotals[day, default: (0, 0, 0)]
            entry.protein += meal.analysis.proteinMidpoint
            entry.calories += (meal.caloriesMin + meal.caloriesMax) / 2
            entry.count += 1
            dayTotals[day] = entry
        }

        let summaries: [DaySummary] = dayTotals.keys.sorted().map { day in
            let totals = dayTotals[day]!
            return DaySummary(
                id: day,
                label: formatter.string(from: day),
                protein: totals.protein,
                calories: totals.calories,
                mealCount: totals.count,
                hitGoal: totals.protein >= proteinTarget
            )
        }

        let daysLogged = summaries.count
        let daysHitGoal = summaries.filter(\.hitGoal).count
        let averageProtein = daysLogged > 0 ? summaries.map(\.protein).reduce(0, +) / daysLogged : 0
        let averageCalories = daysLogged > 0 ? summaries.map(\.calories).reduce(0, +) / daysLogged : 0
        let bestDay = summaries.max(by: { $0.protein < $1.protein })
        let lowestProteinDay = summaries.min(by: { $0.protein < $1.protein })

        let hitRate = daysLogged > 0 ? Int((Double(daysHitGoal) / Double(daysLogged)) * 100) : 0
        let coachSummary: String
        if daysLogged == 0 {
            coachSummary = "No meals logged this week yet. One scan a day builds the habit."
        } else if hitRate >= 70 {
            coachSummary = "Strong week — you hit protein on \(daysHitGoal) of \(daysLogged) days (\(hitRate)%). Keep the same rhythm next week."
        } else if let bestDay {
            coachSummary = "You logged \(daysLogged) days with ~\(averageProtein)g avg protein. Your best day was \(bestDay.label) (\(bestDay.protein)g). Aim to repeat that pattern."
        } else {
            coachSummary = "Average protein this week: \(averageProtein)g. Small improvements at lunch or dinner add up."
        }

        return Report(
            daysLogged: daysLogged,
            daysHitGoal: daysHitGoal,
            averageProtein: averageProtein,
            averageCalories: averageCalories,
            bestDay: bestDay,
            lowestProteinDay: lowestProteinDay,
            dailySummaries: summaries,
            coachSummary: coachSummary
        )
    }

    private static var emptyReport: Report {
        Report(daysLogged: 0, daysHitGoal: 0, averageProtein: 0, averageCalories: 0, bestDay: nil, lowestProteinDay: nil, dailySummaries: [], coachSummary: "No data yet.")
    }
}

enum RecipeMacroCalculator {
    struct Ingredient: Identifiable, Equatable {
        let id = UUID()
        var name: String
        var calories: Int
        var protein: Int
        var carbs: Int
        var fat: Int
    }

    struct Totals: Equatable {
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
        let perServing: TotalsPerServing?
    }

    struct TotalsPerServing: Equatable {
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
    }

    static func totals(for ingredients: [Ingredient], servings: Int) -> Totals {
        let calories = ingredients.map(\.calories).reduce(0, +)
        let protein = ingredients.map(\.protein).reduce(0, +)
        let carbs = ingredients.map(\.carbs).reduce(0, +)
        let fat = ingredients.map(\.fat).reduce(0, +)
        let safeServings = max(1, servings)
        return Totals(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            perServing: TotalsPerServing(
                calories: calories / safeServings,
                protein: protein / safeServings,
                carbs: carbs / safeServings,
                fat: fat / safeServings
            )
        )
    }

    static func parseQuickAdd(_ line: String) -> Ingredient? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let segments = trimmed.split(separator: ",", omittingEmptySubsequences: false).map {
            String($0).trimmingCharacters(in: .whitespaces)
        }
        let name = segments.first ?? trimmed

        func value(after key: String, in text: String) -> Int? {
            guard let range = text.range(of: key, options: .caseInsensitive) else { return nil }
            let tail = text[range.upperBound...]
            let digits = tail.prefix(while: { $0.isNumber || $0 == "." })
            return Int(digits.filter(\.isNumber))
        }

        let macroText = segments.dropFirst().joined(separator: ",")
        return Ingredient(
            name: name,
            calories: value(after: "cal", in: macroText) ?? value(after: "kcal", in: macroText) ?? 0,
            protein: value(after: "protein", in: macroText) ?? value(after: "p", in: macroText) ?? 0,
            carbs: value(after: "carb", in: macroText) ?? value(after: "c", in: macroText) ?? 0,
            fat: value(after: "fat", in: macroText) ?? value(after: "f", in: macroText) ?? 0
        )
    }
}
enum DataExportService {
    struct ExportPayload: Codable {
        let exportedAt: Date
        let settings: ExportSettings?
        let meals: [ExportMeal]
        let weightLogs: [ExportWeight]
    }

    struct ExportSettings: Codable {
        let displayName: String
        let dailyProteinTarget: Int
        let calorieRangeMin: Int
        let calorieRangeMax: Int
        let goal: String
    }

    struct ExportMeal: Codable {
        let mealName: String
        let proteinMin: Int
        let proteinMax: Int
        let caloriesMin: Int
        let caloriesMax: Int
        let scannedAt: Date
    }

    struct ExportWeight: Codable {
        let weightKg: Double
        let loggedAt: Date
    }

    static func exportJSON(settings: UserSettings?, meals: [MealRecord], weights: [WeightLog]) throws -> Data {
        let payload = ExportPayload(
            exportedAt: .now,
            settings: settings.map {
                ExportSettings(
                    displayName: $0.displayName,
                    dailyProteinTarget: $0.dailyProteinTarget,
                    calorieRangeMin: $0.calorieRangeMin,
                    calorieRangeMax: $0.calorieRangeMax,
                    goal: $0.goal.label
                )
            },
            meals: meals.map {
                ExportMeal(
                    mealName: $0.mealName,
                    proteinMin: $0.proteinMin,
                    proteinMax: $0.proteinMax,
                    caloriesMin: $0.caloriesMin,
                    caloriesMax: $0.caloriesMax,
                    scannedAt: $0.scannedAt
                )
            },
            weightLogs: weights.map { ExportWeight(weightKg: $0.weightKg, loggedAt: $0.loggedAt) }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }
}
