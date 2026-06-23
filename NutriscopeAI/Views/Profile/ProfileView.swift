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
        ZStack {
            AppBackground(showsAmbientGlow: true)

            VStack(spacing: 0) {
                profileHeader

                BoundedScrollView(bottomPadding: 56) {
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
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarHidden(true)
    }

    private var profileHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Profile")
                    .font(AppTypography.displayLGMobile)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(displayName)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, AppTheme.marginMain)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var goalsSection: some View {
        ProfileMenuSection(title: "Goals & Preferences") {
            NavigationLink { ProfileGoalsSettingsView() } label: {
                ProfileMenuRow(
                    icon: "flag.fill",
                    iconColor: AppTheme.primary,
                    title: "Protein Target",
                    trailingValue: "\(user.dailyProteinTarget)g / day"
                )
            }
            .buttonStyle(.plain)
            ProfileMenuDivider()
            NavigationLink { ProfileGoalsSettingsView() } label: {
                ProfileMenuRow(
                    icon: "figure.strengthtraining.traditional",
                    iconColor: AppTheme.proteinTeal,
                    title: "Fitness Goal",
                    trailingValue: user.goal.label
                )
            }
            .buttonStyle(.plain)
            ProfileMenuDivider()
            NavigationLink { ProfileGoalsSettingsView() } label: {
                ProfileMenuRow(
                    icon: "fork.knife",
                    iconColor: AppTheme.warmSun,
                    title: "Diet Preferences",
                    trailingValue: dietSummary
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var toolsSection: some View {
        ProfileMenuSection(title: "Tools") {
            profileToolLink(
                "Recipe Calculator",
                icon: "function",
                iconColor: AppTheme.primary,
                destination: RecipeCalculatorView()
            )
            ProfileMenuDivider()
            profileToolLink(
                "Grocery List",
                icon: "cart.fill",
                iconColor: AppTheme.coachOrange,
                destination: GroceryListView()
            )
            ProfileMenuDivider()
            profileToolLink(
                "Reminders",
                icon: "bell.fill",
                iconColor: AppTheme.textTertiary,
                destination: ReminderSettingsView()
            )
            ProfileMenuDivider()
            profileToolLink(
                "Weekly Report",
                icon: "chart.bar.fill",
                iconColor: AppTheme.proteinTeal,
                destination: WeeklyReportView()
            )
            ProfileMenuDivider()
            NavigationLink {
                ProFeatureGate(feature: "Insights & Trends") { InsightsTrendsView() }
            } label: {
                ProfileMenuRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: AppTheme.proteinTeal,
                    title: "Insights & Trends"
                )
            }
            .buttonStyle(.plain)
            ProfileMenuDivider()
            profileToolLink(
                "Tomorrow's Plan",
                icon: "calendar.badge.clock",
                iconColor: AppTheme.coachOrange,
                destination: ProFeatureGate(feature: "Tomorrow's Plan") { TomorrowProteinPlanView() }
            )
        }
    }

    private var accountSection: some View {
        ProfileMenuSection(title: "Account") {
            NavigationLink { ProfileAccountView() } label: {
                ProfileMenuRow(
                    icon: "person.fill",
                    iconColor: AppTheme.primary,
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
                    iconColor: .red,
                    title: "Sign Out",
                    isDestructive: true,
                    showsChevron: false
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func profileToolLink<D: View>(
        _ title: String,
        icon: String,
        iconColor: Color,
        destination: D
    ) -> some View {
        NavigationLink { destination } label: {
            ProfileMenuRow(
                icon: icon,
                iconColor: iconColor,
                title: title
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
