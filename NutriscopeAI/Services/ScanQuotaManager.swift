import Foundation
import Observation

@Observable
@MainActor
final class ScanQuotaManager {
    static let weeklyFreeLimit = 5

    private let weekKey = "scanQuotaWeekStart"
    private let usedKey = "scanQuotaUsed"

    var scansRemaining: Int {
        resetIfNeeded()
        return max(0, Self.weeklyFreeLimit - usedThisWeek)
    }

    var usedThisWeek: Int {
        resetIfNeeded()
        return UserDefaults.standard.integer(forKey: usedKey)
    }

    var daysUntilWeeklyReset: Int {
        let calendar = Calendar.current
        let now = Date.now
        guard let weekEnd = calendar.dateInterval(of: .weekOfYear, for: now)?.end else { return 0 }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: weekEnd)).day ?? 0
        return max(0, days)
    }

    func canScan(isSubscribed: Bool) -> Bool {
        isSubscribed || scansRemaining > 0
    }

    func consumeScan() {
        resetIfNeeded()
        let used = UserDefaults.standard.integer(forKey: usedKey)
        UserDefaults.standard.set(used + 1, forKey: usedKey)
    }

    private func resetIfNeeded() {
        let calendar = Calendar.current
        let now = Date.now
        let stored = UserDefaults.standard.object(forKey: weekKey) as? Date ?? .distantPast

        if !calendar.isDate(stored, equalTo: now, toGranularity: .weekOfYear) {
            UserDefaults.standard.set(now, forKey: weekKey)
            UserDefaults.standard.set(0, forKey: usedKey)
        }
    }
}
