import SwiftData
import SwiftUI

struct ProfileGoalsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]

    @State private var proteinTargetText = ""
    @State private var calorieMinText = ""
    @State private var calorieMaxText = ""
    @State private var healthService = HealthKitService.shared
    @State private var savedConfirmation = false

    private var user: UserSettings {
        if let s = settings.first { return s }
        let created = UserSettings()
        modelContext.insert(created)
        return created
    }

    var body: some View {
        ZStack {
            AppBackground(showsAmbientGlow: true)

            BoundedScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    KineticToolHeader(
                        title: "Goals & Preferences",
                        subtitle: "Protein targets, fitness goal, diet, and body stats."
                    )

                    proteinTargetCard
                    fitnessGoalSection
                    dietPreferencesSection
                    bodyStatsSection
                    coachPreferencesSection
                    weightSection
                    healthSection

                    if savedConfirmation {
                        Label("Goals saved", systemImage: "checkmark.circle.fill")
                            .font(AppTypography.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.proteinTeal)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(AppTheme.marginMain)
            }
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { syncGoalFields() }
    }

    // MARK: - Sections

    private var proteinTargetCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                LabelCapsText(text: "Daily protein target", color: AppTheme.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("150", text: $proteinTargetText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.coachOrange)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: 120)
                    Text("g / day")
                        .font(AppTypography.bodyLG)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                ProfileMenuDivider()

                HStack {
                    Text("Calorie range")
                        .font(AppTypography.bodyLG)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    HStack(spacing: 6) {
                        TextField("min", text: $calorieMinText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 56)
                            .padding(8)
                            .background(AppTheme.surfaceMuted)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text("–")
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("max", text: $calorieMaxText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 56)
                            .padding(8)
                            .background(AppTheme.surfaceMuted)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text("kcal")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                HStack(spacing: 12) {
                    Button("Save targets") { applyGoals() }
                        .buttonStyle(PrimaryButtonStyle())
                    Button("Recalculate") { recalculateFromProfile() }
                        .buttonStyle(OutlineButtonStyle())
                }
            }
        }
    }

    private var fitnessGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Fitness goal")
            ForEach(FitnessGoal.allCases) { goal in
                KineticGoalCard(goal: goal, isSelected: user.goal == goal) {
                    user.goal = goal
                    recalculateFromProfile()
                    save()
                }
            }
        }
    }

    private var dietPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Diet preferences")
            SurfaceCard {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(DietPreference.allCases) { pref in
                        KineticDietChip(
                            title: pref.label,
                            isSelected: user.dietPreferences.contains(pref)
                        ) {
                            toggleDietPreference(pref)
                        }
                    }
                }
            }
        }
    }

    private var bodyStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Body stats")
            SurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    OnboardingGenderSegment(gender: Binding(
                        get: { user.genderRaw },
                        set: { user.genderRaw = $0; save() }
                    ))

                    OnboardingProfileMetricField(
                        label: "Age",
                        text: Binding(
                            get: { "\(user.age)" },
                            set: { user.age = Int($0.filter(\.isNumber)) ?? user.age; save() }
                        ),
                        suffix: "years",
                        placeholder: "e.g. 28"
                    )

                    HStack(spacing: 12) {
                        OnboardingProfileMetricField(
                            label: "Height",
                            text: Binding(
                                get: { "\(user.heightCm)" },
                                set: { user.heightCm = Int($0.filter(\.isNumber)) ?? user.heightCm; save() }
                            ),
                            suffix: "cm",
                            placeholder: "170"
                        )
                        OnboardingProfileMetricField(
                            label: "Weight",
                            text: Binding(
                                get: { "\(user.weightKg)" },
                                set: { user.weightKg = Int($0.filter(\.isNumber)) ?? user.weightKg; save() }
                            ),
                            suffix: "kg",
                            placeholder: "65"
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Activity level")
                            .font(AppTypography.subheadline.weight(.bold))
                        ForEach(ActivityLevel.allCases) { level in
                            OnboardingActivityRadioRow(
                                level: level,
                                isSelected: user.activity == level
                            ) {
                                user.activity = level
                                recalculateFromProfile()
                                save()
                            }
                        }
                    }
                }
            }
        }
    }

    private var coachPreferencesSection: some View {
        ProfileMenuSection(title: "Coach preferences") {
            ProfileSettingsToggleRow(
                title: "Show calories",
                isOn: Binding(
                    get: { user.showCalories },
                    set: { user.showCalories = $0; save() }
                )
            )
            ProfileMenuDivider()
            ProfileSettingsPickerRow(title: "Focus mode", value: user.focusMode.label) {
                Picker("", selection: Binding(
                    get: { user.focusMode },
                    set: { user.focusMode = $0; save() }
                )) {
                    ForEach(FocusMode.allCases) { Text($0.label).tag($0) }
                }
                .labelsHidden()
                .tint(AppTheme.coachOrange)
            }
            ProfileMenuDivider()
            ProfileSettingsPickerRow(title: "Tone", value: user.tone.label) {
                Picker("", selection: Binding(
                    get: { user.tone },
                    set: { user.tone = $0; save() }
                )) {
                    ForEach(CoachTone.allCases) { Text($0.label).tag($0) }
                }
                .labelsHidden()
                .tint(AppTheme.coachOrange)
            }
        }
    }

    @ViewBuilder
    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Weight tracking")
            SurfaceCard {
                WeightTrackingSection()
            }
        }
    }

    @ViewBuilder
    private var healthSection: some View {
        if healthService.isAvailable {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("Apple Health")
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
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
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AppTypography.labelCaps)
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.leading, 4)
    }

    // MARK: - Actions

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
        savedConfirmation = true
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
        savedConfirmation = true
    }

    private func save() {
        try? modelContext.save()
    }
}

struct ProfileSettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .font(AppTypography.bodyLG)
            .tint(AppTheme.coachOrange)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
    }
}

struct ProfileSettingsPickerRow<PickerContent: View>: View {
    let title: String
    let value: String
    @ViewBuilder let picker: () -> PickerContent

    var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.bodyLG)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            picker()
                .frame(maxWidth: 180)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview {
    NavigationStack { ProfileGoalsSettingsView() }
        .modelContainer(for: UserSettings.self, inMemory: true)
}
