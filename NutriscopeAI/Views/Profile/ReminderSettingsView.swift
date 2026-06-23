import SwiftData
import SwiftUI

struct ReminderSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]

    @State private var reminderSettings = ReminderSettings.default
    @State private var permissionDenied = false
    @State private var savedConfirmation = false
    @State private var showNotificationPrompt = false

    private var user: UserSettings {
        settings.first ?? UserSettings()
    }

    var body: some View {
        BoundedScrollView {

            VStack(alignment: .leading, spacing: 24) {
                KineticToolHeader(
                    title: "Reminders",
                    subtitle: "Scheduled meal nudges plus real-time smart alerts when your protein gap changes."
                )

                SurfaceCard {
                    Toggle("Enable reminders", isOn: $reminderSettings.enabled)
                        .tint(AppTheme.coachOrange)
                    Text("Uses Apple’s local notification system on this device.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                if reminderSettings.enabled {
                    ProfileMenuSection(title: "Smart alerts") {
                        Toggle("Real-time gap alerts", isOn: $reminderSettings.smartAlertsEnabled)
                            .tint(AppTheme.coachOrange)
                            .padding(10)
                        ProfileMenuDivider()
                        Toggle("Post-workout recovery nudges", isOn: $reminderSettings.workoutRecoveryAlerts)
                            .tint(AppTheme.proteinTeal)
                            .padding(10)
                        Text("Fires when you log meals, finish workouts, or background with a large protein gap.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 8)
                    }

                    ProfileMenuSection(title: "Meal nudges") {
                        reminderToggleRow("Breakfast", isOn: $reminderSettings.breakfastReminder, hour: $reminderSettings.breakfastHour)
                        ProfileMenuDivider()
                        reminderToggleRow("Lunch", isOn: $reminderSettings.lunchReminder, hour: $reminderSettings.lunchHour)
                        ProfileMenuDivider()
                        reminderToggleRow("Dinner", isOn: $reminderSettings.dinnerReminder, hour: $reminderSettings.dinnerHour)
                        ProfileMenuDivider()
                        reminderToggleRow("Protein check-in", isOn: $reminderSettings.proteinGapReminder, hour: $reminderSettings.proteinGapHour)
                    }
                }

                if permissionDenied {
                    SurfaceCard {
                        Label("Notifications are off in iOS Settings → Nutriscope AI.", systemImage: "exclamationmark.triangle.fill")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.primary)
                    }
                }

                if savedConfirmation {
                    Text("Reminders saved. Smart alerts will update as you log meals and workouts.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.proteinTeal)
                }

                Button("Save reminders") {
                    if reminderSettings.enabled && reminderSettings.smartAlertsEnabled {
                        showNotificationPrompt = true
                    } else {
                        Task { await saveReminders() }
                    }
                }
                .buttonStyle(PrimaryButtonStyle(pill: true))
            }
            .padding(AppTheme.marginMain)
            .padding(.bottom, 32)
        
        }
        .background(AppBackground())
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let s = settings.first {
                reminderSettings = s.reminderSettings
            }
        }
        .sheet(isPresented: $showNotificationPrompt) {
            NotificationPermissionPromptView(
                onAllow: {
                    showNotificationPrompt = false
                    Task { await saveReminders() }
                },
                onSkip: {
                    showNotificationPrompt = false
                    reminderSettings.smartAlertsEnabled = false
                    Task { await saveReminders() }
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func reminderToggleRow(_ title: String, isOn: Binding<Bool>, hour: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(title, isOn: isOn)
                .tint(AppTheme.coachOrange)
            if isOn.wrappedValue {
                Stepper("Notify at \(hour.wrappedValue):00", value: hour, in: 6...22)
                    .font(AppTypography.subheadline)
            }
        }
        .padding(10)
    }

    private func saveReminders() async {
        guard let stored = settings.first else { return }
        let granted = await NotificationManager.requestAuthorization()
        permissionDenied = !granted && reminderSettings.enabled
        stored.reminderSettings = reminderSettings
        try? modelContext.save()
        if granted {
            await NotificationManager.scheduleReminders(reminderSettings, proteinTarget: stored.dailyProteinTarget)
            savedConfirmation = true
        }
    }
}

#Preview {
    NavigationStack { ReminderSettingsView() }
        .modelContainer(for: UserSettings.self, inMemory: true)
}
