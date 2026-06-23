import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]

    private var user: UserSettings {
        if let s = settings.first { return s }
        let created = UserSettings()
        modelContext.insert(created)
        return created
    }

    private var displayEmail: String {
        if let email = AuthSessionManager.currentAccount?.email { return email }
        if GuestModeManager.isGuest { return "Guest on this device" }
        return ""
    }

    private var displayName: String {
        if let name = AuthSessionManager.currentAccount?.displayName, !name.isEmpty { return name }
        if !user.displayName.isEmpty { return user.displayName }
        return "Nutriscope User"
    }

    private var dietSummary: String {
        let prefs = user.dietPreferences.map(\.label)
        return prefs.isEmpty ? "None selected" : prefs.prefix(2).joined(separator: ", ")
    }

    private var proSubtitle: String {
        if appState.subscriptionManager.isSubscribed {
            return "Active subscription"
        }
        return "\(appState.quotaManager.scansRemaining) free scans left this week"
    }

    var body: some View {
        VStack(spacing: 0) {
            NutriscopeTopBar(displayName: displayName)

            BoundedScrollView {

                VStack(spacing: 24) {
                    ProfileHeroHeader(displayName: displayName, email: displayEmail)

                    if appState.subscriptionManager.isSubscribed {
                        NavigationLink { ManageSubscriptionView() } label: {
                            ProfileProCard(isPro: true, subtitle: proSubtitle)
                        }
                        .buttonStyle(.plain)
                    } else {
                        ProfileProCard(
                            isPro: false,
                            subtitle: proSubtitle,
                            onUpgrade: { appState.presentPaywall() }
                        )
                    }

                    goalsSection
                    toolsSection
                    accountSection
                }
                .padding(.horizontal, AppTheme.marginMain)
                .padding(.bottom, 24)
            
        }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
        .navigationBarHidden(true)
    }

    private var goalsSection: some View {
        ProfileMenuSection(title: "Goals & Preferences") {
            NavigationLink { ProfileGoalsSettingsView() } label: {
                ProfileMenuRow(
                    icon: "flag.fill",
                    iconColor: AppTheme.coachOrange,
                    title: "Protein Target",
                    subtitle: "\(user.dailyProteinTarget)g / day"
                )
            }
            .buttonStyle(.plain)
            ProfileMenuDivider()
            NavigationLink { ProfileGoalsSettingsView() } label: {
                ProfileMenuRow(
                    icon: "dumbbell.fill",
                    iconColor: AppTheme.proteinTeal,
                    title: "Fitness Goal",
                    subtitle: user.goal.label
                )
            }
            .buttonStyle(.plain)
            ProfileMenuDivider()
            NavigationLink { ProfileGoalsSettingsView() } label: {
                ProfileMenuRow(
                    icon: "leaf.fill",
                    iconColor: AppTheme.warmSun,
                    title: "Diet Preferences",
                    subtitle: dietSummary
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var toolsSection: some View {
        ProfileMenuSection(title: "Tools") {
            profileToolLink("Recipe Calculator", subtitle: "Analyze custom meals", icon: "function", destination: RecipeCalculatorView())
            ProfileMenuDivider()
            profileToolLink("Grocery List", subtitle: "Auto-generated from plans", icon: "cart.fill", destination: GroceryListView())
            ProfileMenuDivider()
            profileToolLink("Reminders", subtitle: "Meal & protein nudges", icon: "bell.fill", destination: ReminderSettingsView())
            ProfileMenuDivider()
            profileToolLink("Weekly Report", subtitle: "Your logging trends", icon: "chart.bar.fill", destination: WeeklyReportView())
            ProfileMenuDivider()
            NavigationLink {
                ProFeatureGate(feature: "Insights & Trends") { InsightsTrendsView() }
            } label: {
                ProfileMenuRow(
                    icon: "chart.xyaxis.line",
                    iconColor: AppTheme.proteinTeal,
                    title: "Insights & Trends",
                    subtitle: "Deep nutrition analysis"
                )
            }
            .buttonStyle(.plain)
            ProfileMenuDivider()
            profileToolLink("Tomorrow's Plan", subtitle: "Coach meal prep", icon: "calendar.badge.clock", destination:
                ProFeatureGate(feature: "Tomorrow's Plan") { TomorrowProteinPlanView() }
            )
        }
    }

    private var accountSection: some View {
        ProfileMenuSection(title: "Account") {
            NavigationLink { ProfileAccountView() } label: {
                ProfileMenuRow(
                    icon: "person.crop.circle",
                    iconColor: AppTheme.textSecondary,
                    title: "Account Information"
                )
            }
            .buttonStyle(.plain)
            ProfileMenuDivider()
            Button {
                AuthSessionManager.signOut()
                if !appState.subscriptionManager.isSubscribed {
                    GuestModeManager.isGuest = true
                }
            } label: {
                ProfileMenuRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    iconColor: AppTheme.primary,
                    title: "Sign Out",
                    isDestructive: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func profileToolLink<D: View>(
        _ title: String,
        subtitle: String,
        icon: String,
        destination: D
    ) -> some View {
        NavigationLink { destination } label: {
            ProfileMenuRow(
                icon: icon,
                iconColor: AppTheme.textSecondary,
                title: title,
                subtitle: subtitle
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { ProfileView() }
        .environment(AppState())
        .modelContainer(for: UserSettings.self, inMemory: true)
}
