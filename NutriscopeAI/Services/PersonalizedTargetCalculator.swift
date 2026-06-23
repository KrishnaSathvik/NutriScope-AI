import Foundation

struct PersonalizedTargets: Sendable, Equatable {
    let bmr: Int
    let tdee: Int
    let proteinTarget: Int
    let calorieTarget: Int
    let calorieRangeMin: Int
    let calorieRangeMax: Int
    let explanation: String
}

enum PersonalizedTargetCalculator {
    /// Mifflin-St Jeor BMR with optional sex; uses midpoint when unknown.
    static func bmr(weightKg: Int, heightCm: Int, age: Int, gender: String) -> Int {
        let base = 10.0 * Double(weightKg) + 6.25 * Double(heightCm) - 5.0 * Double(age)
        switch gender.lowercased() {
        case "male":
            return Int((base + 5).rounded())
        case "female":
            return Int((base - 161).rounded())
        default:
            return Int(((base - 78).rounded())) // midpoint between +5 and -161
        }
    }

    static func tdee(bmr: Int, activity: ActivityLevel) -> Int {
        let multiplier: Double
        switch activity {
        case .sedentary: multiplier = 1.2
        case .light: multiplier = 1.375
        case .moderate: multiplier = 1.55
        case .active: multiplier = 1.725
        }
        return Int((Double(bmr) * multiplier).rounded())
    }

    static func calculate(
        weightKg: Int,
        heightCm: Int,
        age: Int,
        gender: String,
        goal: FitnessGoal,
        activity: ActivityLevel
    ) -> PersonalizedTargets {
        let bmrValue = bmr(weightKg: weightKg, heightCm: heightCm, age: age, gender: gender)
        let tdeeValue = tdee(bmr: bmrValue, activity: activity)
        let calorieTarget = targetCalories(tdee: tdeeValue, goal: goal)
        let proteinTarget = targetProtein(weightKg: weightKg, goal: goal, activity: activity)
        let rangePadding = 175
        let calorieMin = max(1_200, calorieTarget - rangePadding)
        let calorieMax = calorieTarget + rangePadding

        return PersonalizedTargets(
            bmr: bmrValue,
            tdee: tdeeValue,
            proteinTarget: proteinTarget,
            calorieTarget: calorieTarget,
            calorieRangeMin: calorieMin,
            calorieRangeMax: calorieMax,
            explanation: explanation(
                goal: goal,
                proteinTarget: proteinTarget,
                calorieTarget: calorieTarget,
                tdee: tdeeValue
            )
        )
    }

    static func calculate(from settings: UserSettings) -> PersonalizedTargets {
        calculate(
            weightKg: settings.weightKg,
            heightCm: settings.heightCm,
            age: settings.age,
            gender: settings.genderRaw,
            goal: settings.goal,
            activity: settings.activity
        )
    }

    static func apply(_ targets: PersonalizedTargets, to settings: UserSettings) {
        settings.dailyProteinTarget = targets.proteinTarget
        settings.calorieRangeMin = targets.calorieRangeMin
        settings.calorieRangeMax = targets.calorieRangeMax
    }

    private static func targetCalories(tdee: Int, goal: FitnessGoal) -> Int {
        let adjustment: Int
        switch goal {
        case .loseFat: adjustment = -500
        case .buildMuscle: adjustment = 300
        case .maintain: adjustment = 0
        case .eatMoreProtein: adjustment = 100
        case .understandMeals: adjustment = 0
        }
        return max(1_200, tdee + adjustment)
    }

    private static func targetProtein(weightKg: Int, goal: FitnessGoal, activity: ActivityLevel) -> Int {
        let gramsPerKg: Double
        switch goal {
        case .loseFat: gramsPerKg = 2.2
        case .buildMuscle: gramsPerKg = 2.0
        case .maintain: gramsPerKg = 1.6
        case .eatMoreProtein: gramsPerKg = 2.1
        case .understandMeals: gramsPerKg = 1.6
        }
        let activityBoost = activity == .active ? 1.1 : 1.0
        return Int((Double(weightKg) * gramsPerKg * activityBoost).rounded())
    }

    private static func explanation(
        goal: FitnessGoal,
        proteinTarget: Int,
        calorieTarget: Int,
        tdee: Int
    ) -> String {
        let delta = calorieTarget - tdee
        let calorieNote: String
        if delta < -200 {
            calorieNote = "a moderate calorie deficit for fat loss"
        } else if delta > 200 {
            calorieNote = "a slight surplus to support muscle gain"
        } else {
            calorieNote = "maintenance-level calories"
        }
        return "Based on your stats and \(goal.label.lowercased()) goal: ~\(proteinTarget)g protein/day and \(calorieNote) (~\(calorieTarget) kcal)."
    }
}
