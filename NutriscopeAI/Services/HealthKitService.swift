import Foundation
import HealthKit
import Observation

struct DailyHealthSnapshot: Equatable {
    var sleepHours: Double = 0
    var workoutMinutes: Int = 0
    var workoutCount: Int = 0
    var lastWorkoutName: String?
    var activeCalories: Int = 0
    var steps: Int = 0

    var hasSleepData: Bool { sleepHours > 0 }
    var hasWorkoutData: Bool { workoutMinutes > 0 || workoutCount > 0 }
    var hasAnyData: Bool { hasSleepData || hasWorkoutData || activeCalories > 0 || steps > 0 }

    var sleepSummary: String {
        guard hasSleepData else { return "No sleep logged" }
        let hours = Int(sleepHours)
        let minutes = Int((sleepHours - Double(hours)) * 60)
        if minutes > 0 {
            return "\(hours)h \(minutes)m last night"
        }
        return "\(hours)h last night"
    }

    var workoutSummary: String {
        guard hasWorkoutData else { return "No workouts today" }
        if let name = lastWorkoutName {
            return "\(name) · \(workoutMinutes) min"
        }
        return "\(workoutCount) workout\(workoutCount == 1 ? "" : "s") · \(workoutMinutes) min"
    }
}

@MainActor
@Observable
final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()
    private(set) var isAuthorized = false
    private(set) var todaySnapshot = DailyHealthSnapshot()
    private(set) var lastRefresh: Date?

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private init() {
        isAuthorized = UserDefaults.standard.bool(forKey: Self.authorizedKey)
    }

    private static let authorizedKey = "healthKitAuthorized"

    func requestAuthorization() async throws {
        guard isAvailable else { return }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
        ]

        try await store.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
        UserDefaults.standard.set(true, forKey: Self.authorizedKey)
        await refreshToday()
    }

    func refreshToday() async {
        guard isAvailable, isAuthorized else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? .now

        async let sleep = fetchSleepHours(from: startOfDay.addingTimeInterval(-12 * 3600), to: end)
        async let workouts = fetchWorkouts(from: startOfDay, to: end)
        async let calories = fetchSum(
            identifier: .activeEnergyBurned,
            unit: .kilocalorie(),
            from: startOfDay,
            to: end
        )
        async let steps = fetchSum(
            identifier: .stepCount,
            unit: .count(),
            from: startOfDay,
            to: end
        )

        let workoutResult = await workouts
        todaySnapshot = DailyHealthSnapshot(
            sleepHours: await sleep,
            workoutMinutes: workoutResult.totalMinutes,
            workoutCount: workoutResult.count,
            lastWorkoutName: workoutResult.lastName,
            activeCalories: Int(await calories),
            steps: Int(await steps)
        )
        lastRefresh = .now
        WidgetDataStore.save(from: todaySnapshot)
    }

    private func fetchSleepHours(from start: Date, to end: Date) async -> Double {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }

        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]
                let total = (samples as? [HKCategorySample])?
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } ?? 0
                continuation.resume(returning: total / 3600)
            }
            store.execute(query)
        }
    }

    private struct WorkoutSummary {
        var totalMinutes: Int = 0
        var count: Int = 0
        var lastName: String?
    }

    private func fetchWorkouts(from start: Date, to end: Date) async -> WorkoutSummary {
        await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, _ in
                let workouts = samples as? [HKWorkout] ?? []
                let minutes = workouts.reduce(0) { $0 + Int($1.duration / 60) }
                let lastName = workouts.first.map { self.workoutDisplayName($0.workoutActivityType) }
                continuation.resume(returning: WorkoutSummary(
                    totalMinutes: minutes,
                    count: workouts.count,
                    lastName: lastName
                ))
            }
            store.execute(query)
        }
    }

    private func fetchSum(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        from start: Date,
        to end: Date
    ) async -> Double {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else { return 0 }

        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func workoutDisplayName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: "Run"
        case .walking: "Walk"
        case .cycling: "Cycle"
        case .traditionalStrengthTraining, .functionalStrengthTraining: "Strength"
        case .yoga: "Yoga"
        case .swimming: "Swim"
        case .highIntensityIntervalTraining: "HIIT"
        default: "Workout"
        }
    }
}

enum HealthInsightsBuilder {
    static func coachNote(snapshot: DailyHealthSnapshot, proteinRemaining: Int) -> String? {
        guard snapshot.hasAnyData else { return nil }

        if snapshot.hasWorkoutData, proteinRemaining > 25 {
            return "You logged \(snapshot.workoutSummary.lowercased()). Aim for 25–35g protein in the next 2 hours to support recovery."
        }
        if snapshot.hasSleepData, snapshot.sleepHours < 6.5 {
            return "Sleep was short (\(snapshot.sleepSummary)). Prioritize protein at breakfast to help appetite control today."
        }
        if snapshot.hasSleepData, snapshot.sleepHours >= 7.5, proteinRemaining > 0 {
            return "Solid rest (\(snapshot.sleepSummary)). You're set up well — \(proteinRemaining)g protein left to close today's gap."
        }
        return "Activity today: \(snapshot.steps.formatted()) steps · \(snapshot.activeCalories) active kcal."
    }

    static func observations(
        snapshot: DailyHealthSnapshot,
        proteinTarget: Int,
        proteinToday: Int
    ) -> [InsightsTrendsCalculator.Observation] {
        var results: [InsightsTrendsCalculator.Observation] = []

        if snapshot.hasWorkoutData {
            results.append(.init(
                icon: "figure.run",
                title: "Training day pattern",
                message: "\(snapshot.workoutSummary). Post-workout meals with 30g+ protein help you recover and hit your \(proteinTarget)g goal.",
                tag: "Recovery"
            ))
        }

        if snapshot.hasSleepData {
            let quality = snapshot.sleepHours >= 7 ? "well-rested" : "under-slept"
            results.append(.init(
                icon: "bed.double.fill",
                title: "Sleep & protein",
                message: "You were \(quality) (\(snapshot.sleepSummary)). \(proteinToday)g protein logged so far today.",
                tag: snapshot.sleepHours < 6.5 ? "Focus area" : "Habit win"
            ))
        }

        return results
    }
}
