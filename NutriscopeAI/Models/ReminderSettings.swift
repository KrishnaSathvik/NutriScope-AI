import Foundation

struct ReminderSettings: Codable, Equatable {
    var enabled: Bool
    var breakfastReminder: Bool
    var breakfastHour: Int
    var lunchReminder: Bool
    var lunchHour: Int
    var dinnerReminder: Bool
    var dinnerHour: Int
    var proteinGapReminder: Bool
    var proteinGapHour: Int
    var smartAlertsEnabled: Bool
    var workoutRecoveryAlerts: Bool

    static let `default` = ReminderSettings(
        enabled: false,
        breakfastReminder: true,
        breakfastHour: 8,
        lunchReminder: true,
        lunchHour: 12,
        dinnerReminder: true,
        dinnerHour: 19,
        proteinGapReminder: true,
        proteinGapHour: 20,
        smartAlertsEnabled: true,
        workoutRecoveryAlerts: true
    )

    init(
        enabled: Bool,
        breakfastReminder: Bool,
        breakfastHour: Int,
        lunchReminder: Bool,
        lunchHour: Int,
        dinnerReminder: Bool,
        dinnerHour: Int,
        proteinGapReminder: Bool,
        proteinGapHour: Int,
        smartAlertsEnabled: Bool = true,
        workoutRecoveryAlerts: Bool = true
    ) {
        self.enabled = enabled
        self.breakfastReminder = breakfastReminder
        self.breakfastHour = breakfastHour
        self.lunchReminder = lunchReminder
        self.lunchHour = lunchHour
        self.dinnerReminder = dinnerReminder
        self.dinnerHour = dinnerHour
        self.proteinGapReminder = proteinGapReminder
        self.proteinGapHour = proteinGapHour
        self.smartAlertsEnabled = smartAlertsEnabled
        self.workoutRecoveryAlerts = workoutRecoveryAlerts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        breakfastReminder = try container.decodeIfPresent(Bool.self, forKey: .breakfastReminder) ?? true
        breakfastHour = try container.decodeIfPresent(Int.self, forKey: .breakfastHour) ?? 8
        lunchReminder = try container.decodeIfPresent(Bool.self, forKey: .lunchReminder) ?? true
        lunchHour = try container.decodeIfPresent(Int.self, forKey: .lunchHour) ?? 12
        dinnerReminder = try container.decodeIfPresent(Bool.self, forKey: .dinnerReminder) ?? true
        dinnerHour = try container.decodeIfPresent(Int.self, forKey: .dinnerHour) ?? 19
        proteinGapReminder = try container.decodeIfPresent(Bool.self, forKey: .proteinGapReminder) ?? true
        proteinGapHour = try container.decodeIfPresent(Int.self, forKey: .proteinGapHour) ?? 20
        smartAlertsEnabled = try container.decodeIfPresent(Bool.self, forKey: .smartAlertsEnabled) ?? true
        workoutRecoveryAlerts = try container.decodeIfPresent(Bool.self, forKey: .workoutRecoveryAlerts) ?? true
    }
}

enum ReminderSettingsStorage {
    static func decode(from json: String) -> ReminderSettings {
        guard
            let data = json.data(using: .utf8),
            let settings = try? JSONDecoder().decode(ReminderSettings.self, from: data)
        else { return .default }
        return settings
    }

    static func encode(_ settings: ReminderSettings) -> String {
        guard let data = try? JSONEncoder().encode(settings) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
