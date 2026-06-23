import Foundation

/// Keeps one stable coach insight per calendar day until today's nutrition context changes.
enum DailyCoachTipCache {
    private static let tipKey = "dailyCoachTip.text"
    private static let dayKey = "dailyCoachTip.day"
    private static let fingerprintKey = "dailyCoachTip.fingerprint"

    static func fingerprint(for context: CoachAIContext) -> String {
        let mealNames = context.recentMealNames.sorted().joined(separator: "|")
        let diets = context.dietPreferences.sorted().joined(separator: "|")
        let health = context.healthNote ?? ""
        return [
            dayToken(),
            "\(context.proteinToday)",
            "\(context.proteinRemaining)",
            "\(context.mealsLoggedToday)",
            mealNames,
            diets,
            health,
        ].joined(separator: "·")
    }

    static func cachedTip(matching fingerprint: String) -> String? {
        guard UserDefaults.standard.string(forKey: dayKey) == dayToken(),
              UserDefaults.standard.string(forKey: fingerprintKey) == fingerprint,
              let tip = UserDefaults.standard.string(forKey: tipKey),
              !tip.isEmpty
        else { return nil }
        return tip
    }

    static func store(tip: String, fingerprint: String) {
        let trimmed = tip.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        UserDefaults.standard.set(dayToken(), forKey: dayKey)
        UserDefaults.standard.set(fingerprint, forKey: fingerprintKey)
        UserDefaults.standard.set(trimmed, forKey: tipKey)
    }

    private static func dayToken() -> String {
        let day = Calendar.current.startOfDay(for: .now)
        return ISO8601DateFormatter().string(from: day)
    }
}
