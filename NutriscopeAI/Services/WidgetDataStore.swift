import Foundation

/// Shared snapshot for home-screen widgets (App Group).
enum WidgetDataStore {
    static let appGroupID = "group.com.nutriscopeai.app"

    private enum Keys {
        static let proteinCurrent = "widget.proteinCurrent"
        static let proteinTarget = "widget.proteinTarget"
        static let proteinRemaining = "widget.proteinRemaining"
        static let sleepHours = "widget.sleepHours"
        static let workoutMinutes = "widget.workoutMinutes"
        static let coachTip = "widget.coachTip"
        static let updatedAt = "widget.updatedAt"
    }

    struct Snapshot: Codable {
        var proteinCurrent: Int
        var proteinTarget: Int
        var proteinRemaining: Int
        var sleepHours: Double
        var workoutMinutes: Int
        var coachTip: String
        var updatedAt: Date
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func save(
        proteinCurrent: Int,
        proteinTarget: Int,
        proteinRemaining: Int,
        health: DailyHealthSnapshot,
        coachTip: String
    ) {
        let snapshot = Snapshot(
            proteinCurrent: proteinCurrent,
            proteinTarget: proteinTarget,
            proteinRemaining: proteinRemaining,
            sleepHours: health.sleepHours,
            workoutMinutes: health.workoutMinutes,
            coachTip: coachTip,
            updatedAt: .now
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        let store = defaults ?? UserDefaults.standard
        store.set(data, forKey: "widgetSnapshot")
        store.set(proteinCurrent, forKey: Keys.proteinCurrent)
        store.set(proteinTarget, forKey: Keys.proteinTarget)
        store.set(proteinRemaining, forKey: Keys.proteinRemaining)
        store.set(health.sleepHours, forKey: Keys.sleepHours)
        store.set(health.workoutMinutes, forKey: Keys.workoutMinutes)
        store.set(coachTip, forKey: Keys.coachTip)
        store.set(Date.now.timeIntervalSince1970, forKey: Keys.updatedAt)
    }

    static func save(from health: DailyHealthSnapshot) {
        let store = defaults ?? UserDefaults.standard
        store.set(health.sleepHours, forKey: Keys.sleepHours)
        store.set(health.workoutMinutes, forKey: Keys.workoutMinutes)
    }

    static func load() -> Snapshot? {
        let store = defaults ?? UserDefaults.standard
        guard let data = store.data(forKey: "widgetSnapshot") else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }
}
