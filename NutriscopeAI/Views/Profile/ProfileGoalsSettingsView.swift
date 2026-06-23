import SwiftData
import SwiftUI

struct ProfileGoalsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]

    @State private var proteinTargetText = ""
    @State private var calorieMinText = ""
    @State private var calorieMaxText = ""
    @State private var healthService = HealthKitService.shared

    private var user: UserSettings {
        if let s = settings.first { return s }
        let created = UserSettings()
        modelContext.insert(created)
        return created
    }

    var body: some View {
        BoundedScrollView {

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Goals & Preferences")
                        .font(AppTypography.title2.weight(.black))
                        .foregroundStyle(AppTheme.coachOrange)
                    Text("Protein targets, fitness goal, diet, and body stats.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                ProfileMenuSection(title: "Daily targets") {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Protein")
                            Spacer()
                            TextField("g", text: $proteinTargetText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 72)
                        }
                        HStack {
                            Text("Calorie range")
                            Spacer()
                            TextField("min", text: $calorieMinText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 64)
                            Text("–")
                            TextField("max", text: $calorieMaxText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 64)
                        }
                        Button("Save goals") { applyGoals() }
                            .buttonStyle(PrimaryButtonStyle())
                        Button("Recalculate from profile") { recalculateFromProfile() }
                            .buttonStyle(OutlineButtonStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }

                SurfaceCard {
                    Picker("Fitness goal", selection: Binding(
                        get: { user.goal },
                        set: { user.goal = $0; syncGoalFields(); save() }
                    )) {
                        ForEach(FitnessGoal.allCases) { Text($0.label).tag($0) }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Diet preferences")
                            .font(AppTypography.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                            ForEach(DietPreference.allCases) { pref in
                                let isSelected = user.dietPreferences.contains(pref)
                                Button { toggleDietPreference(pref) } label: {
                                    Text(pref.label)
                                        .font(AppTypography.caption.weight(.semibold))
                                        .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(isSelected ? AppTheme.coachOrange : AppTheme.surfaceMuted)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Coach preferences")
                            .font(AppTypography.headline)
                        Toggle("Show calories", isOn: Binding(
                            get: { user.showCalories },
                            set: { user.showCalories = $0; save() }
                        ))
                        Picker("Focus mode", selection: Binding(
                            get: { user.focusMode },
                            set: { user.focusMode = $0; save() }
                        )) {
                            ForEach(FocusMode.allCases) { Text($0.label).tag($0) }
                        }
                        Picker("Tone", selection: Binding(
                            get: { user.tone },
                            set: { user.tone = $0; save() }
                        )) {
                            ForEach(CoachTone.allCases) { Text($0.label).tag($0) }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Body stats")
                            .font(AppTypography.headline)
                        Stepper("Age: \(user.age)", value: Binding(
                            get: { user.age },
                            set: { user.age = $0; save() }
                        ), in: 16...90)
                        Picker("Gender", selection: Binding(
                            get: { user.genderRaw },
                            set: { user.genderRaw = $0; save() }
                        )) {
                            ForEach(["Female", "Male", "Non-binary", "Prefer not to say"], id: \.self) { Text($0) }
                        }
                        Stepper("Height: \(user.heightCm) cm", value: Binding(
                            get: { user.heightCm },
                            set: { user.heightCm = $0; save() }
                        ), in: 120...220)
                        Stepper("Weight: \(user.weightKg) kg", value: Binding(
                            get: { user.weightKg },
                            set: { user.weightKg = $0; save() }
                        ), in: 35...200)
                        Picker("Activity", selection: Binding(
                            get: { user.activity },
                            set: { user.activity = $0; save() }
                        )) {
                            ForEach(ActivityLevel.allCases) { Text($0.label).tag($0) }
                        }
                    }
                }

                SurfaceCard {
                    WeightTrackingSection()
                }

                if healthService.isAvailable {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Apple Health")
                                .font(AppTypography.headline)
                            if healthService.isAuthorized {
                                DailyHealthCard(snapshot: healthService.todaySnapshot, onConnect: nil)
                                Button("Refresh health data") {
                                    Task { await healthService.refreshToday() }
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            } else {
                                Button("Connect Apple Health") {
                                    Task { try? await healthService.requestAuthorization() }
                                }
                                .buttonStyle(OutlineButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(AppTheme.marginMain)
            .padding(.bottom, 32)
        
        }
        .background(AppBackground())
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { syncGoalFields() }
    }

    private func syncGoalFields() {
        proteinTargetText = "\(user.dailyProteinTarget)"
        calorieMinText = "\(user.calorieRangeMin)"
        calorieMaxText = "\(user.calorieRangeMax)"
    }

    private func applyGoals() {
        if let value = Int(proteinTargetText), value >= 50, value <= 300 {
            user.dailyProteinTarget = value
        }
        if let minVal = Int(calorieMinText), let maxVal = Int(calorieMaxText), minVal > 0, maxVal >= minVal {
            user.calorieRangeMin = minVal
            user.calorieRangeMax = maxVal
        }
        syncGoalFields()
        save()
    }

    private func toggleDietPreference(_ pref: DietPreference) {
        var prefs = user.dietPreferences
        if prefs.contains(pref) { prefs.remove(pref) } else { prefs.insert(pref) }
        user.dietPreferences = prefs
        save()
    }

    private func recalculateFromProfile() {
        let targets = PersonalizedTargetCalculator.calculate(from: user)
        PersonalizedTargetCalculator.apply(targets, to: user)
        syncGoalFields()
        save()
    }

    private func save() {
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack { ProfileGoalsSettingsView() }
        .modelContainer(for: UserSettings.self, inMemory: true)
}
