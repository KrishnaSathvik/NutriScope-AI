import Foundation
import UserNotifications

enum NotificationManager {
    static func configure() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationGranted() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    /// Re-schedule saved meal reminders after app launch (local Apple notifications).
    static func syncFromStoredSettings(_ reminderSettings: ReminderSettings, proteinTarget: Int) async {
        guard reminderSettings.enabled else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            return
        }
        guard await authorizationGranted() else { return }
        await scheduleReminders(reminderSettings, proteinTarget: proteinTarget)
    }

    static func scheduleReminders(_ settings: ReminderSettings, proteinTarget: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard settings.enabled else { return }

        if settings.breakfastReminder {
            await schedule(
                id: "meal.breakfast",
                title: "Log breakfast",
                body: "Start your protein day — scan or describe what you ate.",
                hour: settings.breakfastHour,
                minute: 0
            )
        }
        if settings.lunchReminder {
            await schedule(
                id: "meal.lunch",
                title: "Log lunch",
                body: "Quick meal log keeps your protein on track.",
                hour: settings.lunchHour,
                minute: 0
            )
        }
        if settings.dinnerReminder {
            await schedule(
                id: "meal.dinner",
                title: "Log dinner",
                body: "Scan dinner to see if you're hitting \(proteinTarget)g protein today.",
                hour: settings.dinnerHour,
                minute: 0
            )
        }
        if settings.proteinGapReminder {
            await schedule(
                id: "protein.gap",
                title: "Protein check-in",
                body: "Open Nutriscope AI to see what's left for your \(proteinTarget)g goal.",
                hour: settings.proteinGapHour,
                minute: 0
            )
        }
    }

    /// Fires once ~30s after enabling reminders so users can verify permissions in Settings.
    static func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Nutriscope reminders are on"
        content.body = "You'll get meal and protein check-ins at the times you chose."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test.notification", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    private static func schedule(id: String, title: String, body: String, hour: Int, minute: Int) async {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "NUTRISCOPE_MEAL"

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}
