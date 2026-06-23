import SwiftData
import SwiftUI

enum AuthFlowStep: Equatable {
    case splash
    case welcome
    case introTrackFast
    case introProteinProgress
    case introSmartMeals
    case goals
    case diet
    case target
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
    @State private var opensCameraForFirstMeal = false
    @State private var restoreMessage: String?

    private let genders = ["Female", "Male", "Non-binary", "Prefer not to say"]

    var body: some View {
        VStack(spacing: 0) {
            if let stepNum = onboardingStepNumber {
                OnboardingChrome(
                    step: stepNum,
                    totalSteps: 3,
                    showsFinalizing: step == .target,
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
                case .introTrackFast:
                    OnboardingIntroView(
                        page: OnboardingIntroPage.pages[0],
                        pageIndex: 0,
                        totalPages: 3,
                        onBack: { withAnimation { step = .welcome } },
                        onContinue: { withAnimation { step = .introProteinProgress } }
                    )
                case .introProteinProgress:
                    OnboardingIntroView(
                        page: OnboardingIntroPage.pages[1],
                        pageIndex: 1,
                        totalPages: 3,
                        onBack: { withAnimation { step = .introTrackFast } },
                        onContinue: { withAnimation { step = .introSmartMeals } }
                    )
                case .introSmartMeals:
                    OnboardingIntroView(
                        page: OnboardingIntroPage.pages[2],
                        pageIndex: 2,
                        totalPages: 3,
                        onBack: { withAnimation { step = .introProteinProgress } },
                        onContinue: { withAnimation { step = .goals } }
                    )
                case .goals: goalPage
                case .diet: dietPage
                case .target: targetPage
                case .firstMeal:
                    AddFirstMealView(
                        onScanPhoto: {
                            opensCameraForFirstMeal = true
                            showOnboardingScan = true
                        },
                        onTypeMeal: {
                            opensCameraForFirstMeal = false
                            showOnboardingScan = true
                        },
                        onBack: { withAnimation { step = .target } }
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
                opensCameraOnAppear: opensCameraForFirstMeal,
                onFirstMealSaved: finishOnboardingAfterFirstMeal
            )
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
        case .target: 3
        default: nil
        }
    }

    private func goBackFromOnboarding() {
        withAnimation {
            switch step {
            case .goals: step = .introSmartMeals
            case .diet: step = .goals
            case .target: step = .diet
            default: break
            }
        }
    }

    private var showsBottomButton: Bool {
        switch step {
        case .splash, .welcome, .introTrackFast, .introProteinProgress, .introSmartMeals,
             .firstMeal, .createAccount, .signIn, .resetPassword: false
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
        case .target: 2
        default: 0
        }
    }

    // MARK: - Welcome

    private var welcomePage: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    Image("welcome-hero")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height * 0.58)
                        .clipped()
                        .overlay {
                            LinearGradient(
                                colors: [
                                    AppTheme.background.opacity(0.05),
                                    AppTheme.background.opacity(0.6),
                                    AppTheme.background
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    Spacer(minLength: 0)
                }
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("Track protein without overthinking calories.")
                            .font(.system(size: 34, weight: .heavy))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Scan meals, see your progress, and get smart next-meal suggestions.")
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        Button {
                            withAnimation { step = .introTrackFast }
                        } label: {
                            HStack(spacing: 8) {
                                Text("Get Started")
                                Image(systemName: "arrow.right")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(pill: true))

                        Button {
                            authError = nil
                            signInCameFromWelcome = true
                            withAnimation { step = .signIn }
                        } label: {
                            Text("I already have an account")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(OutlineButtonStyle())

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

                    Text("No shame. No perfect logging. Just better choices.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.outline)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, AppTheme.marginMain)
            }
        }
    }

    // MARK: - Onboarding pages

    private var goalPage: some View {
        BoundedScrollView {

            VStack(spacing: 16) {
                Text("What is your goal?")
                    .font(.system(size: 34, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.top, 8)

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
                Text("What's your diet style?")
                    .font(.system(size: 34, weight: .heavy))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                Text("Pick all that apply — we'll tailor meal estimates and coaching.")
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

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

    private var targetPage: some View {
        BoundedScrollView {

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Target Locked")
                        .font(.system(size: 28, weight: .heavy))
                        .multilineTextAlignment(.center)
                    Text("Your personalized nutritional baseline.")
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                profileCalibrationSection

                OnboardingTargetHero(proteinTarget: proteinTarget, goal: selectedGoal)

                HStack(spacing: 14) {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.outline)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.surfaceContainerHighest)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Energy Range")
                            .font(.headline)
                        Text("Daily caloric intake")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(calorieMin.formatted())–\(calorieMax.formatted())")
                            .font(.headline)
                        Text("kcal")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppTheme.surfaceContainerHighest, lineWidth: 1)
                )

                if !targetExplanation.isEmpty {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.coachOrange)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Coach's Note")
                                .font(.headline)
                            Text(targetExplanation)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Text("You can adjust targets anytime in Profile.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppTheme.marginMain)
            .padding(.bottom, 24)
        
        }
        .onAppear { recalculateTargets() }
    }

    private var profileCalibrationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("About you")
                .font(.headline)
            Text("We use this to calculate your protein and calorie targets.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Name (optional)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("e.g. Taylor Smith", text: $name)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppTheme.outlineVariant.opacity(0.5), lineWidth: 1)
                    )
            }

            HStack(spacing: 12) {
                profileStatField(title: "Age", value: Binding(
                    get: { "\(age)" },
                    set: { age = Int($0.filter(\.isNumber)) ?? age; recalculateTargets() }
                ), suffix: "yrs")
                VStack(spacing: 12) {
                    profileStatField(title: "Height", value: Binding(
                        get: { "\(heightCm)" },
                        set: { heightCm = Int($0.filter(\.isNumber)) ?? heightCm; recalculateTargets() }
                    ), suffix: "cm")
                    profileStatField(title: "Weight", value: Binding(
                        get: { "\(weightKg)" },
                        set: { weightKg = Int($0.filter(\.isNumber)) ?? weightKg; recalculateTargets() }
                    ), suffix: "kg")
                }
            }

            Picker("Gender", selection: $gender) {
                ForEach(genders, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .onChange(of: gender) { _, _ in recalculateTargets() }

            Text("Activity level")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            ForEach(ActivityLevel.allCases) { level in
                KineticActivityCard(level: level, isSelected: activity == level) {
                    activity = level
                    recalculateTargets()
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.outlineVariant.opacity(0.4), lineWidth: 1)
        )
    }

    private func profileStatField(title: String, value: Binding<String>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", text: value)
                    .keyboardType(.numberPad)
                    .font(.title2.weight(.bold))
                Text(suffix)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
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
        case .goals, .diet: "Continue"
        case .target: "Add first meal"
        case .createAccount: "Create account"
        case .signIn: "Sign in"
        default: "Continue"
        }
    }

    private func handlePrimaryAction() {
        authError = nil
        switch step {
        case .welcome:
            withAnimation { step = .introTrackFast }
        case .goals:
            withAnimation { step = .diet }
        case .diet:
            withAnimation { step = .target }
        case .target:
            persistProfileDraft()
            withAnimation { step = .firstMeal }
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
