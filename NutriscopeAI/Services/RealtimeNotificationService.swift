import Foundation
import UserNotifications

struct RealtimeNotificationContext: Equatable {
    let proteinRemaining: Int
    let proteinTarget: Int
    let proteinToday: Int
    let mealsLoggedToday: Int
    let hour: Int
    let workoutMinutes: Int
    let lastWorkoutEnded: Date?
    let settings: ReminderSettings
}

/// Context-aware local notifications fired when meals, workouts, or app state change.
enum RealtimeNotificationService {
    private static let lastSmartAlertKey = "realtime.lastSmartAlert"
    private static let minInterval: TimeInterval = 30 * 60

    static func evaluate(_ context: RealtimeNotificationContext) async {
        guard context.settings.enabled, context.settings.smartAlertsEnabled else { return }
        guard await NotificationManager.authorizationGranted() else { return }
        guard !isDebounced else { return }

        if context.proteinRemaining <= 0, context.mealsLoggedToday > 0 {
            await deliver(
                id: "smart.goal.hit",
                title: "Protein goal hit!",
                body: "You reached \(context.proteinTarget)g today. Your coach is proud.",
                delay: 1
            )
            return
        }

        if context.hour >= 17, context.proteinRemaining > 0, context.proteinRemaining <= 20 {
            await deliver(
                id: "smart.gap.close",
                title: "Almost at your goal",
                body: "Only \(context.proteinRemaining)g protein left — one quick snack closes the gap.",
                delay: 2
            )
            return
        }

        if context.hour >= 18, context.proteinRemaining >= 35 {
            await deliver(
                id: "smart.gap.large",
                title: "Protein gap alert",
                body: "\(context.proteinRemaining)g still to go today. Open Coach for your best next meal.",
                delay: 3
            )
            return
        }

        if context.settings.workoutRecoveryAlerts,
           context.workoutMinutes >= 20,
           context.proteinRemaining > 15 {
            await deliver(
                id: "smart.workout.recovery",
                title: "Post-workout fuel",
                body: "Great session. Aim for 25–35g protein in the next 2 hours to recover well.",
                delay: 4
            )
        }
    }

    static func notifyAfterMealsChanged(
        meals: [MealRecord],
        settings: UserSettings,
        health: DailyHealthSnapshot
    ) async {
        let todayMeals = meals.filter { Calendar.current.isDateInToday($0.scannedAt) }
        let proteinToday = todayMeals.reduce(0) { $0 + $1.proteinMidpoint }
        let target = settings.dailyProteinTarget
        let remaining = max(0, target - proteinToday)

        await evaluateAfterMealSaved(
            proteinRemaining: remaining,
            proteinTarget: target,
            proteinToday: proteinToday,
            mealsLoggedToday: todayMeals.count,
            settings: settings.reminderSettings,
            health: health
        )
    }

    static func evaluateAfterMealSaved(
        proteinRemaining: Int,
        proteinTarget: Int,
        proteinToday: Int,
        mealsLoggedToday: Int,
        settings: ReminderSettings,
        health: DailyHealthSnapshot
    ) async {
        let hour = Calendar.current.component(.hour, from: .now)
        await evaluate(
            RealtimeNotificationContext(
                proteinRemaining: proteinRemaining,
                proteinTarget: proteinTarget,
                proteinToday: proteinToday,
                mealsLoggedToday: mealsLoggedToday,
                hour: hour,
                workoutMinutes: health.workoutMinutes,
                lastWorkoutEnded: nil,
                settings: settings
            )
        )
    }

    static func scheduleBackgroundGapCheck(proteinRemaining: Int, proteinTarget: Int, settings: ReminderSettings) async {
        guard settings.enabled, settings.smartAlertsEnabled else { return }
        guard proteinRemaining > 25 else { return }
        guard await NotificationManager.authorizationGranted() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Check your protein gap"
        content.body = "You still need ~\(proteinRemaining)g of \(proteinTarget)g today. Tap to see coach picks."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: "smart.background.gap", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancelBackgroundGapCheck() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["smart.background.gap"])
    }

    private static var isDebounced: Bool {
        guard let last = UserDefaults.standard.object(forKey: lastSmartAlertKey) as? Date else { return false }
        return Date.now.timeIntervalSince(last) < minInterval
    }

    private static func deliver(id: String, title: String, body: String, delay: TimeInterval) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "NUTRISCOPE_SMART"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 1), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
        UserDefaults.standard.set(Date.now, forKey: lastSmartAlertKey)
    }
}
