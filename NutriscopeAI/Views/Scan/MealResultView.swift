import SwiftData
import SwiftUI

struct MealResultView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]
    @Query(sort: \MealRecord.scannedAt, order: .reverse) private var meals: [MealRecord]
    @Query private var savedMeals: [SavedMeal]

    @State private var healthService = HealthKitService.shared

    @State private var analysis: MealAnalysis
    @State private var showFollowUp = false
    @State private var didSave = false
    @State private var didSaveForQuickLog = false
    @State private var showPaywallPrompt = false
    @State private var selectedMealType = MealType.inferred()
    @State private var hasConfirmedEstimate = false

    @State private var showPostScanCelebration = false

    let isNewScan: Bool
    var mealNote: String = ""
    var showsLogAgain: Bool = false
    var saveButtonTitle: String = "Looks right — Save meal"
    var onResetForAnother: (() -> Void)?
    var onMealSaved: (() -> Void)?

    init(
        analysis: MealAnalysis,
        isNewScan: Bool,
        mealNote: String = "",
        showsLogAgain: Bool = false,
        saveButtonTitle: String = "Looks right — Save meal",
        onResetForAnother: (() -> Void)? = nil,
        onMealSaved: (() -> Void)? = nil
    ) {
        _analysis = State(initialValue: analysis)
        self.isNewScan = isNewScan
        self.mealNote = mealNote
        self.showsLogAgain = showsLogAgain
        self.saveButtonTitle = saveButtonTitle
        self.onResetForAnother = onResetForAnother
        self.onMealSaved = onMealSaved
    }

    private var proteinTarget: Int { settings.first?.dailyProteinTarget ?? 135 }
    private var proteinRemaining: Int {
        max(0, proteinTarget - analysis.proteinMidpoint)
    }

    private var isAlreadySavedForQuickLog: Bool {
        savedMeals.contains { $0.mealName == analysis.mealName && $0.proteinMin == analysis.protein.min }
    }

    var body: some View {
        BoundedScrollView {

            VStack(alignment: .leading, spacing: 20) {
                heroSection

                VStack(alignment: .leading, spacing: 8) {
                    Text(analysis.mealName)
                        .font(AppTypography.title2)
                    Text("Estimated \(analysis.calories.formatted) kcal")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    if !mealNote.isEmpty {
                        Text("Note: \(mealNote)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                MealMacroBentoGrid(
                    protein: "\(analysis.protein.formatted)g",
                    carbs: "\(analysis.carbs.formatted)g",
                    fat: "\(analysis.fat.formatted)g"
                )

                if isNewScan && !didSave && !hasConfirmedEstimate {
                    confirmationCard
                }

                if isNewScan || showsLogAgain {
                    mealTypePicker
                }

                if !analysis.followUpQuestions.isEmpty {
                    unsureSection
                }

                CoachMessageView(message: analysis.advice.coachMessage, headline: "COACH INSIGHT")

                MealAdviceCard(advice: analysis.advice, proteinRemaining: didSave ? proteinRemaining : nil)

                actionButtons

                if didSave {
                    successBanner
                    WhatNowCard(
                        proteinRemaining: proteinRemaining,
                        suggestions: analysis.advice.suggestions,
                        onPlanNext: {
                            appState.selectedTab = .coach
                            appState.activeSheet = nil
                        }
                    )
                }
            }
            .padding(AppTheme.marginMain)
            .padding(.bottom, 32)
        
        }
        .background(AppBackground(showsAmbientGlow: true))
        .navigationTitle("Scan Results")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFollowUp) {
            FollowUpQuestionsView(questions: analysis.followUpQuestions) { updated in
                showFollowUp = false
                applyFollowUpAnswers(updated)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPaywallPrompt) {
            PaywallView()
        }
        .fullScreenCover(isPresented: $showPostScanCelebration) {
            PostScanSuccessView(
                mealName: analysis.mealName,
                mealType: selectedMealType,
                protein: analysis.proteinMidpoint,
                calories: analysis.calories.midpoint,
                onViewToday: {
                    showPostScanCelebration = false
                    dismiss()
                    appState.activeSheet = nil
                    appState.selectedTab = .today
                },
                onLogAnother: {
                    showPostScanCelebration = false
                    onResetForAnother?()
                },
                onDismiss: {
                    showPostScanCelebration = false
                    dismiss()
                    appState.activeSheet = nil
                }
            )
        }
    }

    @ViewBuilder
    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let data = analysis.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    AppTheme.surfaceMuted.overlay {
                        Image(systemName: "fork.knife")
                            .font(.largeTitle)
                            .foregroundStyle(AppTheme.coachOrange.opacity(0.5))
                    }
                }
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous))
            .overlay {
                LinearGradient(
                    colors: [.clear, AppTheme.background.opacity(0.5)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous))
            }

            ConfidenceBadge(level: analysis.confidence)
                .padding(12)
        }
    }

    private var successBanner: some View {
        Image("post-scan-success")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
    }

    private var unsureSection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("I'm unsure about:")
                    .font(AppTypography.subheadline.weight(.semibold))
                ForEach(analysis.followUpQuestions, id: \.id) { q in
                    Text("• \(q.prompt)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private var confirmationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sounds right?")
                    .font(AppTypography.headline)
                Text("Review the ranges above before logging.")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                HStack(spacing: 10) {
                    Button { hasConfirmedEstimate = true } label: {
                        Label("Perfect, log it", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Button {
                        hasConfirmedEstimate = true
                        showFollowUp = true
                    } label: {
                        Label("Adjust", systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }

    private var mealTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MEAL TYPE")
                .font(AppTypography.caption2.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
            HStack(spacing: 8) {
                ForEach(MealType.allCases) { type in
                    Button {
                        selectedMealType = type
                    } label: {
                        Label(type.label, systemImage: type.icon)
                            .font(AppTypography.caption.weight(.semibold))
                            .foregroundStyle(selectedMealType == type ? .white : AppTheme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(selectedMealType == type ? AppTheme.coachOrange : AppTheme.surfaceMuted)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if !didSave && (!isNewScan || hasConfirmedEstimate) {
                Button { saveMeal() } label: { Text(saveButtonTitle) }
                    .buttonStyle(PrimaryButtonStyle())
            }
            if !analysis.followUpQuestions.isEmpty {
                Button { showFollowUp = true } label: {
                    Text("Ask me \(analysis.followUpQuestions.count) questions")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            if didSave || showsLogAgain {
                Button { logAgain() } label: {
                    Label("Log again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            if didSave && !didSaveForQuickLog && !isAlreadySavedForQuickLog {
                if appState.hasProAccess {
                    Button { saveForQuickLog() } label: {
                        Label("Save for quick log", systemImage: "bookmark")
                    }
                    .buttonStyle(OutlineButtonStyle())
                } else {
                    Button { appState.presentPaywall() } label: {
                        Label("Save for quick log (Pro)", systemImage: "lock.fill")
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
            }
            if didSaveForQuickLog || isAlreadySavedForQuickLog {
                Label("Saved for quick log", systemImage: "bookmark.fill")
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.coachOrange)
                    .frame(maxWidth: .infinity)
            }
            if didSave {
                Label("Meal saved", systemImage: "checkmark.circle.fill")
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.coachOrange)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func saveMeal() {
        let record = MealRecord(from: analysis, mealNote: mealNote, mealType: selectedMealType)
        modelContext.insert(record)
        try? modelContext.save()
        didSave = true
        triggerSmartNotifications(including: record)
        if isNewScan {
            if onMealSaved != nil {
                onMealSaved?()
            } else {
                showPostScanCelebration = true
            }
        }
        if appState.quotaManager.usedThisWeek >= 4 && !appState.hasProAccess {
            showPaywallPrompt = true
        }
    }

    private func saveForQuickLog() {
        modelContext.insert(SavedMeal(from: analysis, mealNote: mealNote, mealType: selectedMealType))
        try? modelContext.save()
        didSaveForQuickLog = true
    }

    private func logAgain() {
        let record = MealRecord(from: analysis, mealNote: mealNote, mealType: selectedMealType)
        modelContext.insert(record)
        try? modelContext.save()
        didSave = true
        triggerSmartNotifications(including: record)
    }

    private func applyFollowUpAnswers(_ answers: [FollowUpQuestion]) {
        var refined = analysis.refined(with: answers)
        analysis = refined

        let proteinBeforeMeal = meals
            .filter { Calendar.current.isDateInToday($0.scannedAt) }
            .reduce(0) { $0 + $1.analysis.proteinMidpoint }

        Task {
            do {
                let advice = try await OpenAICoachService.updatedAdvice(
                    analysis: refined,
                    answers: answers,
                    dailyProteinTarget: proteinTarget,
                    proteinConsumedToday: proteinBeforeMeal
                )
                refined.advice = advice
                analysis = refined
            } catch {
                // Keep macro-adjusted analysis; advice refresh is best-effort.
            }
        }
    }

    private func triggerSmartNotifications(including newRecord: MealRecord) {
        guard let user = settings.first else { return }
        Task {
            await RealtimeNotificationService.notifyAfterMealsChanged(
                meals: meals + [newRecord],
                settings: user,
                health: healthService.todaySnapshot
            )
        }
    }
}

#Preview {
    NavigationStack {
        MealResultView(
            analysis: MealAnalysis(
                mealName: "Chicken curry + rice + roti",
                calories: MacroRange(min: 780, max: 950),
                protein: MacroRange(min: 38, max: 48),
                carbs: MacroRange(min: 85, max: 110),
                fat: MacroRange(min: 25, max: 40),
                confidence: .medium,
                followUpQuestions: [
                    FollowUpQuestion(prompt: "Oil/butter amount", options: ["Light", "Medium", "Heavy"])
                ],
                advice: MealAdvice(
                    headline: "Protein looks okay",
                    proteinGapGrams: 30,
                    suggestions: ["Greek yogurt + protein shake", "Chicken bowl"],
                    coachMessage: "Rough estimate — confirm portions below.",
                    balanceScore: 62
                )
            ),
            isNewScan: true
        )
    }
    .environment(AppState())
    .modelContainer(for: [MealRecord.self, UserSettings.self, SavedMeal.self], inMemory: true)
}
