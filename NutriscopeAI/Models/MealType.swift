import Foundation

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }

    var label: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "leaf.fill"
        }
    }

    /// Guess meal type from time of day.
    static func inferred(from date: Date = .now) -> MealType {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return .breakfast
        case 11..<15: return .lunch
        case 15..<17: return .snack
        default: return .dinner
        }
    }
}

enum LoggingStreakCalculator {
    struct Result: Equatable {
        let currentStreak: Int
        let longestStreak: Int
        let loggedToday: Bool
    }

    static func compute(from meals: [MealRecord], referenceDate: Date = .now) -> Result {
        let calendar = Calendar.current
        let loggedDays: Set<Date> = Set(
            meals.map { calendar.startOfDay(for: $0.scannedAt) }
        )

        guard !loggedDays.isEmpty else {
            return Result(currentStreak: 0, longestStreak: 0, loggedToday: false)
        }

        let today = calendar.startOfDay(for: referenceDate)
        let loggedToday = loggedDays.contains(today)

        var current = 0
        var cursor = loggedToday ? today : calendar.date(byAdding: .day, value: -1, to: today) ?? today
        while loggedDays.contains(cursor) {
            current += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        let sortedDays = loggedDays.sorted()
        var longest = 0
        var run = 0
        var previousDay: Date?

        for day in sortedDays {
            if let previousDay,
               let expected = calendar.date(byAdding: .day, value: 1, to: previousDay),
               calendar.isDate(day, inSameDayAs: expected) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
            previousDay = day
        }

        return Result(currentStreak: current, longestStreak: longest, loggedToday: loggedToday)
    }
}

enum WeeklyProteinSummaryCalculator {
    struct Result: Equatable {
        let daysLogged: Int
        let daysHitGoal: Int
        let averageProtein: Int
    }

    static func compute(from meals: [MealRecord], proteinTarget: Int, referenceDate: Date = .now) -> Result {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)) else {
            return Result(daysLogged: 0, daysHitGoal: 0, averageProtein: 0)
        }

        var dayTotals: [Date: Int] = [:]
        for meal in meals where meal.scannedAt >= weekStart {
            let day = calendar.startOfDay(for: meal.scannedAt)
            dayTotals[day, default: 0] += meal.analysis.proteinMidpoint
        }

        let daysLogged = dayTotals.count
        let daysHitGoal = dayTotals.values.filter { $0 >= proteinTarget }.count
        let averageProtein = daysLogged > 0
            ? dayTotals.values.reduce(0, +) / daysLogged
            : 0

        return Result(daysLogged: daysLogged, daysHitGoal: daysHitGoal, averageProtein: averageProtein)
    }
}
