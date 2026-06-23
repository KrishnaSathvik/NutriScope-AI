import SwiftData
import SwiftUI

enum AuthFlowStep: Equatable {
    case splash
    case welcome
    case goals
    case diet
    case profile
    case planReady
    case firstMeal
    case createAccount
    case signIn
    case resetPassword
}

struct AuthFlowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var step: AuthFlowStep = .splash
    @State private var selectedGoal: FitnessGoal = .loseFat
    @State private var selectedDietPrefs: Set<DietPreference> = []
    @State private var name = ""
    @State private var age = 30
    @State private var gender = "Prefer not to say"
    @State private var heightCm = 170
    @State private var weightKg = 75
    @State private var activity: ActivityLevel = .moderate
    @State private var proteinTarget = 135
    @State private var calorieMin = 1900
    @State private var calorieMax = 2200
    @State private var targetExplanation = ""
    @State private var isSaving = false

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var authError: String?
    @State private var signInCameFromWelcome = false
    @State private var showOnboardingScan = false
    @State private var showOnboardingManualLog = false
    @State private var restoreMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if let stepNum = onboardingStepNumber {
                OnboardingChrome(
                    step: stepNum,
                    totalSteps: 3,
                    onBack: goBackFromOnboarding
                )
            }

            Group {
                switch step {
                case .splash:
                    SplashView {
                        withAnimation { step = .welcome }
                    }
                case .welcome: welcomePage
                case .goals: goalPage
                case .diet: dietPage
                case .profile: profilePage
                case .planReady:
                    OnboardingPlanReadyView(
                        displayName: name,
                        goal: selectedGoal,
                        proteinTarget: proteinTarget,
                        calorieMin: calorieMin,
                        calorieMax: calorieMax,
                        onContinue: {
                            persistProfileDraft()
                            withAnimation { step = .firstMeal }
                        }
                    )
                case .firstMeal:
                    AddFirstMealView(
                        onScanPhoto: {
                            showOnboardingScan = true
                        },
                        onTypeMeal: {
                            showOnboardingManualLog = true
                        },
                        onBack: { withAnimation { step = .planReady } }
                    )
                case .createAccount:
                    SignUpView(
                        name: $name,
                        email: $email,
                        password: $password,
                        authError: authError,
                        isLoading: isSaving,
                        onCreateAccount: { submitCreateAccount() },
                        onSignIn: {
                            authError = nil
                            signInCameFromWelcome = false
                            withAnimation { step = .signIn }
                        },
                        onBack: {
                            withAnimation { step = signInCameFromWelcome ? .welcome : .signIn }
                        },
                        onAppleSuccess: {
                            GuestModeManager.isGuest = false
                            completeReturningSignIn()
                        },
                        onAppleError: { authError = $0 }
                    )
                case .signIn:
                    SignInView(
                        email: $email,
                        password: $password,
                        authError: authError,
                        isLoading: isSaving,
                        onSignIn: { submitSignIn() },
                        onForgotPassword: {
                            withAnimation { step = .resetPassword }
                        },
                        onSignUp: {
                            authError = nil
                            withAnimation { step = .createAccount }
                        },
                        onBack: {
                            withAnimation {
                                step = signInCameFromWelcome ? .welcome : .createAccount
                            }
                        },
                        onAppleSuccess: { completeReturningSignIn() },
                        onAppleError: { authError = $0 },
                        onRestorePurchases: { Task { await restorePurchasesFromAuth() } },
                        isRestoringPurchases: appState.subscriptionManager.isLoading
                    )
                case .resetPassword: resetPasswordPage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsBottomButton {
                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(AppTheme.background)
            }
        }
        .background(AppTheme.background)
        .fullScreenCover(isPresented: $showOnboardingScan) {
            ScanMealView(
                skipsFlowTutorial: true,
                opensCameraOnAppear: true,
                onFirstMealSaved: finishOnboardingAfterFirstMeal
            )
        }
        .fullScreenCover(isPresented: $showOnboardingManualLog) {
            ManualMealLogView(onFirstMealSaved: finishOnboardingAfterFirstMeal)
        }
        .onAppear {
            recalculateTargets()
            resumeFlowIfNeeded()
        }
    }

    private func finishOnboardingAfterFirstMeal() {
        if !AuthSessionManager.isSignedIn {
            GuestModeManager.isGuest = true
        }
        appState.hasCompletedOnboarding = true
        showOnboardingScan = false
        showOnboardingManualLog = false
    }

    private func resumeFlowIfNeeded() {
        guard !appState.hasCompletedOnboarding else { return }
        loadExistingProfileIfNeeded()
        if hasLocalProfile {
            withAnimation { step = .firstMeal }
        }
    }

    private var showsProgress: Bool {
        onboardingStepNumber != nil
    }

    private var onboardingStepNumber: Int? {
        switch step {
        case .goals: 1
        case .diet: 2
        case .profile: 3
        default: nil
        }
    }

    private func goBackFromOnboarding() {
        withAnimation(.nsStandardSpring) {
            switch step {
            case .goals: step = .welcome
            case .diet: step = .goals
            case .profile: step = .diet
            default: break
            }
        }
    }

    private var showsBottomButton: Bool {
        switch step {
        case .splash, .welcome, .firstMeal, .createAccount, .signIn, .resetPassword,
             .planReady: false
        default: true
        }
    }

    private var progressHeader: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(progressIndex >= index ? AppTheme.coachOrange : AppTheme.surfaceMuted)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var progressIndex: Int {
        switch step {
        case .goals: 0
        case .diet: 1
        default: 0
        }
    }

    // MARK: - Welcome

    private var welcomePage: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Image("welcome-hero")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .accessibilityLabel("Healthy high-protein meal")

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.06),
                        AppTheme.background.opacity(0.5),
                        AppTheme.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "fork.knife")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.coachOrange)
                            .clipShape(Circle())
                            .shadow(color: AppTheme.coachOrange.opacity(0.35), radius: 8, y: 4)
                        Text("Nutriscope AI")
                            .font(AppTypography.title3.weight(.semibold))
                            .foregroundStyle(AppTheme.inkBlack)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppTheme.marginMain)
                    .padding(.top, geo.safeAreaInsets.top + 12)

                    Spacer()

                    VStack(spacing: 24) {
                        VStack(spacing: 10) {
                            (
                                Text("Eat smarter.\n")
                                    .foregroundStyle(AppTheme.inkBlack)
                                + Text("Live stronger.")
                                    .foregroundStyle(AppTheme.coachOrange)
                            )
                            .font(AppTypography.headlineXL)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                            Text("Your personal nutrition coach. Track protein, build habits, and feel your best without the stress.")
                                .font(AppTypography.bodyLG)
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 8)
                        }

                        VStack(spacing: 14) {
                            Button {
                                withAnimation(.nsStandardSpring) { step = .goals }
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Get Started")
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle(pill: false))

                            Button {
                                authError = nil
                                signInCameFromWelcome = true
                                withAnimation(.nsStandardSpring) { step = .signIn }
                            } label: {
                                Text("I already have an account")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle(pill: false))

                            RestorePurchasesButton(
                                isLoading: appState.subscriptionManager.isLoading
                            ) {
                                Task { await restorePurchasesFromAuth() }
                            }

                            if let restoreMessage {
                                Text(restoreMessage)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.proteinTeal)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.marginMain)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 24) + 16)
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Onboarding pages

    private var goalPage: some View {
        BoundedScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your goal?")
                        .font(AppTypography.displayLGMobile)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("We'll tailor your daily targets based on your choice.")
                        .font(AppTypography.bodyLG)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 4)

                ForEach(FitnessGoal.allCases) { goal in
                    KineticGoalCard(goal: goal, isSelected: selectedGoal == goal) {
                        selectedGoal = goal
                        recalculateTargets()
                    }
                }
            }
            .padding(.horizontal, AppTheme.marginMain)
            .padding(.bottom, 24)
        }
    }

    private var dietPage: some View {
        BoundedScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your diet style?")
                        .font(AppTypography.displayLGMobile)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Pick all that apply — we'll tailor meal estimates and coaching.")
                        .font(AppTypography.bodyLG)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(DietPreference.allCases) { pref in
                        KineticDietChip(
                            title: pref.label,
                            isSelected: selectedDietPrefs.contains(pref)
                        ) {
                            if selectedDietPrefs.contains(pref) {
                                selectedDietPrefs.remove(pref)
                            } else {
                                selectedDietPrefs.insert(pref)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.marginMain)
            .padding(.bottom, 24)
        }
    }

    private var profilePage: some View {
        BoundedScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Let's get personal.")
                        .font(AppTypography.displayLGMobile)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("We need a few details to calibrate your nutritional engine accurately.")
                        .font(AppTypography.bodyLG)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 4)

                profileCalibrationSection
            }
            .padding(.horizontal, AppTheme.marginMain)
            .padding(.bottom, 24)
        }
    }

    private var profileCalibrationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingGenderSegment(gender: $gender)

            OnboardingProfileMetricField(
                label: "Age",
                text: Binding(
                    get: { "\(age)" },
                    set: { age = Int($0.filter(\.isNumber)) ?? age; recalculateTargets() }
                ),
                suffix: "years",
                placeholder: "e.g. 28"
            )

            HStack(spacing: 12) {
                OnboardingProfileMetricField(
                    label: "Height",
                    text: Binding(
                        get: { "\(heightCm)" },
                        set: { heightCm = Int($0.filter(\.isNumber)) ?? heightCm; recalculateTargets() }
                    ),
                    suffix: "cm",
                    placeholder: "170"
                )
                OnboardingProfileMetricField(
                    label: "Weight",
                    text: Binding(
                        get: { "\(weightKg)" },
                        set: { weightKg = Int($0.filter(\.isNumber)) ?? weightKg; recalculateTargets() }
                    ),
                    suffix: "kg",
                    placeholder: "65"
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Activity Level")
                    .font(AppTypography.subheadline.weight(.bold))

                VStack(spacing: 10) {
                    ForEach(ActivityLevel.allCases) { level in
                        OnboardingActivityRadioRow(
                            level: level,
                            isSelected: activity == level
                        ) {
                            activity = level
                            recalculateTargets()
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Name (optional)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("e.g. Taylor Smith", text: $name)
                    .font(AppTypography.body)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(AppTheme.outlineVariant.opacity(0.35), lineWidth: 1)
                    )
            }
        }
        .onChange(of: gender) { _, _ in recalculateTargets() }
    }

    // MARK: - Reset password

    private var resetPasswordPage: some View {
        BoundedScrollView {

            ResetPasswordView(onBack: {
                withAnimation { step = .signIn }
            })
            .padding(.horizontal, AppTheme.marginMain)
            .padding(.bottom, 24)
        
        }
    }

    // MARK: - Helpers

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            content()
        }
    }

    private func feature(_ text: String) -> some View {
        Label {
            Text(text).font(.subheadline)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.coachOrange)
        }
        .foregroundStyle(AppTheme.textPrimary)
    }

    private var bottomButton: some View {
        Button {
            handlePrimaryAction()
        } label: {
            Group {
                if isSaving { ProgressView().tint(.white) }
                else { Text(buttonTitle) }
            }
        }
        .buttonStyle(PrimaryButtonStyle(enabled: !isSaving))
        .disabled(isSaving)
    }

    private var buttonTitle: String {
        switch step {
        case .welcome: "Continue" // unused
        case .goals, .diet, .profile: "Continue"
        case .createAccount: "Create account"
        case .signIn: "Sign in"
        default: "Continue"
        }
    }

    private func handlePrimaryAction() {
        authError = nil
        switch step {
        case .welcome:
            withAnimation { step = .goals }
        case .goals:
            withAnimation { step = .diet }
        case .diet:
            withAnimation { step = .profile }
        case .profile:
            recalculateTargets()
            withAnimation { step = .planReady }
        case .createAccount:
            submitCreateAccount()
        case .signIn:
            submitSignIn()
        default:
            break
        }
    }

    private func submitCreateAccount() {
        isSaving = true
        Task {
            do {
                let displayName = name.isEmpty ? email.components(separatedBy: "@").first ?? "User" : name
                _ = try AuthSessionManager.signUp(email: email, password: password, displayName: displayName)
                if BackendConfig.isSupabaseConfigured {
                    _ = try await SupabaseAuthClient.signUpWithEmail(email: email, password: password)
                }
                let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first
                await IOSUserProfileSyncService.upsertAfterAuthentication(settings: settings)
                isSaving = false
                GuestModeManager.isGuest = false
                completeReturningSignIn()
            } catch {
                authError = error.localizedDescription
                isSaving = false
            }
        }
    }

    private func submitSignIn() {
        isSaving = true
        Task {
            do {
                _ = try AuthSessionManager.signIn(email: email, password: password)
                if BackendConfig.isSupabaseConfigured {
                    _ = try await SupabaseAuthClient.signInWithEmail(email: email, password: password)
                }
                let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first
                await IOSUserProfileSyncService.upsertAfterAuthentication(settings: settings)
                isSaving = false
                completeReturningSignIn()
            } catch {
                authError = error.localizedDescription
                isSaving = false
            }
        }
    }

    private func completeReturningSignIn() {
        GuestModeManager.isGuest = false
        loadExistingProfileIfNeeded()
        if appState.hasCompletedOnboarding {
            return
        }
        if hasLocalProfile {
            withAnimation { step = .firstMeal }
        } else {
            withAnimation { step = .goals }
        }
    }

    private func restorePurchasesFromAuth() async {
        if await appState.restorePurchases() {
            restoreMessage = "Pro subscription restored."
        } else {
            restoreMessage = appState.subscriptionManager.errorMessage ?? "No active subscription found."
        }
    }

    private func loadExistingProfileIfNeeded() {
        guard let existing = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first else { return }
        name = existing.displayName
        proteinTarget = existing.dailyProteinTarget
        calorieMin = existing.calorieRangeMin
        calorieMax = existing.calorieRangeMax
        selectedGoal = existing.goal
        age = existing.age
        gender = existing.genderRaw
        heightCm = existing.heightCm
        weightKg = existing.weightKg
        activity = existing.activity
        selectedDietPrefs = existing.dietPreferences
    }

    private var hasLocalProfile: Bool {
        (try? modelContext.fetch(FetchDescriptor<UserSettings>()))?.isEmpty == false
    }

    private func persistProfileDraft() {
        isSaving = true
        defer { isSaving = false }

        let existing = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first
        if let existing {
            existing.displayName = name.isEmpty ? existing.displayName : name
            existing.goalRaw = selectedGoal.rawValue
            existing.dailyProteinTarget = proteinTarget
            existing.calorieRangeMin = calorieMin
            existing.calorieRangeMax = calorieMax
            existing.age = age
            existing.genderRaw = gender
            existing.heightCm = heightCm
            existing.weightKg = weightKg
            existing.activity = activity
            existing.dietPreferences = selectedDietPrefs
        } else {
            let settings = UserSettings(
                displayName: name,
                dailyProteinTarget: proteinTarget,
                calorieRangeMin: calorieMin,
                calorieRangeMax: calorieMax,
                goal: selectedGoal,
                age: age,
                gender: gender,
                heightCm: heightCm,
                weightKg: weightKg,
                activity: activity
            )
            settings.goalRaw = selectedGoal.rawValue
            settings.dailyProteinTarget = proteinTarget
            settings.calorieRangeMin = calorieMin
            settings.calorieRangeMax = calorieMax
            settings.dietPreferences = selectedDietPrefs
            modelContext.insert(settings)
        }
        try? modelContext.save()
    }

    private func recalculateTargets() {
        let targets = PersonalizedTargetCalculator.calculate(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            gender: gender,
            goal: selectedGoal,
            activity: activity
        )
        proteinTarget = targets.proteinTarget
        calorieMin = targets.calorieRangeMin
        calorieMax = targets.calorieRangeMax
        targetExplanation = targets.explanation
    }
}

#Preview {
    AuthFlowView()
        .environment(AppState())
        .modelContainer(for: UserSettings.self, inMemory: true)
}
