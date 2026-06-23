import Foundation
import SwiftData
import SwiftUI

enum FitnessGoal: String, Codable, CaseIterable, Identifiable {
    case loseFat
    case buildMuscle
    case maintain
    case eatMoreProtein
    case understandMeals

    var id: String { rawValue }

    var label: String {
        switch self {
        case .loseFat: "Lose fat"
        case .buildMuscle: "Build muscle"
        case .maintain: "Maintain weight"
        case .eatMoreProtein: "Eat more protein"
        case .understandMeals: "Just understand my meals"
        }
    }

    var icon: String {
        switch self {
        case .loseFat: "chart.line.downtrend.xyaxis"
        case .buildMuscle: "dumbbell.fill"
        case .maintain: "scalemass.fill"
        case .eatMoreProtein: "bolt.fill"
        case .understandMeals: "chart.bar.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .loseFat: "Focus on an optimized caloric deficit while maintaining lean mass."
        case .buildMuscle: "Caloric surplus paired with maximum protein synthesis targets."
        case .maintain: "Optimize daily macros to sustain your current physique and energy levels."
        case .eatMoreProtein: "Hit your protein goal without obsessing over everything else."
        case .understandMeals: "No strict daily targets — just log meals and see the data."
        }
    }

    var accentColor: Color {
        switch self {
        case .loseFat: AppTheme.coachOrange
        case .buildMuscle: AppTheme.proteinTeal
        case .maintain: AppTheme.warmSun
        case .eatMoreProtein: AppTheme.coachOrange
        case .understandMeals: AppTheme.textSecondary
        }
    }

    var targetBadgeText: String {
        switch self {
        case .loseFat: "Optimized for fat loss"
        case .buildMuscle: "Optimized for growth"
        case .maintain: "Balanced maintenance"
        case .eatMoreProtein: "Protein-forward"
        case .understandMeals: "Flexible tracking"
        }
    }

    var defaultProteinTarget: Int {
        switch self {
        case .loseFat: 135
        case .buildMuscle: 160
        case .maintain: 120
        case .eatMoreProtein: 140
        case .understandMeals: 100
        }
    }

    var defaultCalorieRange: (min: Int, max: Int) {
        switch self {
        case .loseFat: (1900, 2200)
        case .buildMuscle: (2400, 2800)
        case .maintain: (2000, 2300)
        case .eatMoreProtein: (2000, 2400)
        case .understandMeals: (1800, 2200)
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary
    case light
    case moderate
    case active

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sedentary: "Mainly sitting"
        case .light: "Light activity"
        case .moderate: "Moderate activity"
        case .active: "Very active"
        }
    }

    var subtitle: String {
        switch self {
        case .sedentary: "Desk job, little to no exercise."
        case .light: "Light movement 1–2 days a week."
        case .moderate: "Moderate exercise 3–5 days a week."
        case .active: "Heavy exercise or physical job."
        }
    }

    var icon: String {
        switch self {
        case .sedentary: "chair.fill"
        case .light: "figure.walk"
        case .moderate: "figure.run"
        case .active: "dumbbell.fill"
        }
    }
}

enum CoachTone: String, Codable, CaseIterable, Identifiable {
    case coach
    case gentle
    case strict

    var id: String { rawValue }

    var label: String {
        switch self {
        case .coach: "Coach"
        case .gentle: "Gentle"
        case .strict: "Strict"
        }
    }
}

enum FocusMode: String, Codable, CaseIterable, Identifiable {
    case proteinOnly
    case proteinAndCalories
    case fullMacros

    var id: String { rawValue }

    var label: String {
        switch self {
        case .proteinOnly: "Protein only"
        case .proteinAndCalories: "Protein + calories"
        case .fullMacros: "Full macros"
        }
    }
}

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var dailyProteinTarget: Int
    var calorieRangeMin: Int
    var calorieRangeMax: Int
    var goalRaw: String
    var age: Int
    var genderRaw: String
    var heightCm: Int
    var weightKg: Int
    var activityRaw: String
    var showCalories: Bool
    var focusModeRaw: String
    var toneRaw: String
    var dietPreferencesJSON: String
    var reminderSettingsJSON: String
    var createdAt: Date

    init(
        displayName: String = "",
        dailyProteinTarget: Int = 135,
        calorieRangeMin: Int = 1900,
        calorieRangeMax: Int = 2200,
        goal: FitnessGoal = .loseFat,
        age: Int = 30,
        gender: String = "Prefer not to say",
        heightCm: Int = 170,
        weightKg: Int = 75,
        activity: ActivityLevel = .moderate
    ) {
        id = UUID()
        self.displayName = displayName
        self.dailyProteinTarget = dailyProteinTarget
        self.calorieRangeMin = calorieRangeMin
        self.calorieRangeMax = calorieRangeMax
        goalRaw = goal.rawValue
        self.age = age
        genderRaw = gender
        self.heightCm = heightCm
        self.weightKg = weightKg
        activityRaw = activity.rawValue
        showCalories = true
        focusModeRaw = FocusMode.proteinAndCalories.rawValue
        toneRaw = CoachTone.coach.rawValue
        dietPreferencesJSON = "[]"
        reminderSettingsJSON = ReminderSettingsStorage.encode(.default)
        createdAt = .now
    }

    var reminderSettings: ReminderSettings {
        get { ReminderSettingsStorage.decode(from: reminderSettingsJSON) }
        set { reminderSettingsJSON = ReminderSettingsStorage.encode(newValue) }
    }

    var dietPreferences: Set<DietPreference> {
        get { DietPreferenceStorage.decode(from: dietPreferencesJSON) }
        set { dietPreferencesJSON = DietPreferenceStorage.encode(newValue) }
    }

    var preferredCoachStyle: String {
        if dietPreferences.contains(.indianFood) { return "Indian" }
        if dietPreferences.contains(.vegetarian) { return "Vegetarian" }
        if dietPreferences.contains(.restaurantMeals) { return "Restaurant" }
        if dietPreferences.contains(.highProtein) { return "High protein" }
        if dietPreferences.contains(.lowCalorie) { return "Low calorie" }
        return "Quick"
    }

    var goal: FitnessGoal {
        get { FitnessGoal(rawValue: goalRaw) ?? .loseFat }
        set {
            goalRaw = newValue.rawValue
            dailyProteinTarget = newValue.defaultProteinTarget
            calorieRangeMin = newValue.defaultCalorieRange.min
            calorieRangeMax = newValue.defaultCalorieRange.max
        }
    }

    var activity: ActivityLevel {
        get { ActivityLevel(rawValue: activityRaw) ?? .moderate }
        set { activityRaw = newValue.rawValue }
    }

    var focusMode: FocusMode {
        get { FocusMode(rawValue: focusModeRaw) ?? .proteinAndCalories }
        set { focusModeRaw = newValue.rawValue }
    }

    var tone: CoachTone {
        get { CoachTone(rawValue: toneRaw) ?? .coach }
        set { toneRaw = newValue.rawValue }
    }

    var calorieRangeFormatted: String {
        "\(calorieRangeMin.formatted())–\(calorieRangeMax.formatted())"
    }
}
