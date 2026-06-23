import PhotosUI
import SwiftData
import SwiftUI

struct ManualMealLogView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]
    @Query(sort: \MealRecord.scannedAt, order: .reverse) private var meals: [MealRecord]

    var onFirstMealSaved: (() -> Void)? = nil
    var onSwitchToScan: (() -> Void)? = nil

    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var mealNote = ""
    @State private var isAnalyzing = false
    @State private var loadingStep = 0
    @State private var analysis: MealAnalysis?
    @State private var showScanFailed = false
    @State private var lastScanError: String?
    @State private var showVoiceOverlay = false
    @State private var showFoodSearch = false
    @State private var showMicPrompt = false
    @State private var selectedMealType = MealType.inferred()
    @State private var speechService = SpeechTranscriptionService()

    private let quickAddItems: [(icon: String, label: String, snippet: String)] = [
        ("oval.portrait.fill", "Boiled Egg", "1 boiled egg"),
        ("bolt.fill", "Whey Scoop", "1 scoop whey protein"),
        ("fork.knife", "Chicken Breast", "grilled chicken breast"),
        ("leaf.fill", "White Rice", "1 cup white rice")
    ]

    private let loadingMessages = [
        "Reading your description…",
        "Checking protein sources…",
        "Estimating portions…",
        "Building your meal summary…"
    ]

    private var userSettings: UserSettings? { settings.first }
    private var proteinTarget: Int { userSettings?.dailyProteinTarget ?? 135 }
    private var dietPreferences: Set<DietPreference> { userSettings?.dietPreferences ?? [] }
    private var canAnalyze: Bool {
        imageData != nil || !mealNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var todaysProtein: Int {
        meals
            .filter { Calendar.current.isDateInToday($0.scannedAt) }
            .reduce(0) { $0 + $1.analysis.proteinMidpoint }
    }

    private var todaysCalories: Int {
        meals
            .filter { Calendar.current.isDateInToday($0.scannedAt) }
            .reduce(0) { $0 + ($1.caloriesMin + $1.caloriesMax) / 2 }
    }

    private var recentMealNames: [String] {
        meals
            .filter { Calendar.current.isDateInToday($0.scannedAt) }
            .prefix(3)
            .map(\.mealName)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let analysis {
                    MealResultView(
                        analysis: analysis,
                        isNewScan: true,
                        mealNote: mealNote,
                        saveButtonTitle: onFirstMealSaved == nil ? "Looks right — Save meal" : "Add to Today",
                        onResetForAnother: resetForAnotherLog,
                        onMealSaved: onFirstMealSaved
                    )
                } else if showScanFailed {
                    ScanFailedView(
                        errorMessage: lastScanError,
                        onRetry: { Task { await analyze() } },
                        onDescribeManually: {
                            showScanFailed = false
                            lastScanError = nil
                        },
                        onFoodDatabase: {
                            showScanFailed = false
                            lastScanError = nil
                            openFoodSearch()
                        },
                        onDismiss: {
                            showScanFailed = false
                            lastScanError = nil
                        }
                    )
                } else if isAnalyzing {
                    analyzingView
                } else {
                    manualContent
                }
            }
            .background(AppBackground(showsAmbientGlow: true))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if analysis == nil && !isAnalyzing && !showScanFailed {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppTheme.coachOrange)
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        Text("Manual Log")
                            .font(AppTypography.title2.weight(.bold))
                            .foregroundStyle(AppTheme.coachOrange)
                    }
                    if let onSwitchToScan {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Scan instead") {
                                dismiss()
                                onSwitchToScan()
                            }
                            .font(AppTypography.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.coachOrange)
                        }
                    }
                } else if analysis != nil || isAnalyzing || showScanFailed {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showMicPrompt) {
                MicrophonePermissionPromptView(
                    onAllow: {
                        ScanFlowFlags.hasSeenMicrophonePrompt = true
                        showMicPrompt = false
                        Task { await startVoiceAfterPrompt() }
                    },
                    onSkip: {
                        ScanFlowFlags.hasSeenMicrophonePrompt = true
                        showMicPrompt = false
                    }
                )
            }
            .sheet(isPresented: $showFoodSearch) {
                FoodSearchView { selected in
                    appState.consumeScanIfNeeded()
                    analysis = selected
                }
            }
            .overlay {
                if showVoiceOverlay {
                    VoiceListeningOverlay(
                        partialText: speechService.partialText.isEmpty ? mealNote : speechService.partialText,
                        onCancel: { stopVoice() },
                        onDone: { stopVoice() }
                    )
                }
            }
            .onChange(of: speechService.partialText) { _, text in
                if !text.isEmpty { mealNote = text }
            }
        }
    }

    private var manualContent: some View {
        BoundedScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What did you have?")
                        .font(AppTypography.title3.weight(.bold))
                    Text("Describe your meal as naturally as you'd tell a friend. Our AI will handle the math.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField(
                            "e.g., 2 rotis, a bowl of chicken curry, and some rice…",
                            text: $mealNote,
                            axis: .vertical
                        )
                        .lineLimit(4...8)
                        .font(.body)
                        .padding(12)
                        .background(AppTheme.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        HStack {
                            Button {
                                Task { await toggleVoice() }
                            } label: {
                                Image(systemName: "mic.fill")
                                    .foregroundStyle(AppTheme.coachOrange)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Text("\(mealNote.count)/500")
                                .font(AppTypography.labelCaps)
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }
                }
                .shadow(color: AppTheme.coachOrange.opacity(0.08), radius: 24, y: 8)

                if imageData != nil {
                    uploadedPhotoPreview
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("Quick Add")
                            .font(.title3.weight(.semibold))
                    } icon: {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(AppTheme.coachOrange)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(quickAddItems, id: \.label) { item in
                            QuickAddTile(icon: item.icon, label: item.label) {
                                appendQuickAdd(item.snippet)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    LabelCapsText(text: "Meal Type (Optional)", color: AppTheme.textSecondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MealType.allCases) { type in
                                KineticFilterChip(
                                    title: type.label,
                                    isSelected: selectedMealType == type
                                ) {
                                    selectedMealType = type
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 10) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Upload photo", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button { openFoodSearch() } label: {
                        Label("Search", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
            }
            .padding(AppTheme.marginMain)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [AppTheme.background.opacity(0), AppTheme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
                Button { Task { await analyze() } } label: {
                    Label("Analyze & Log", systemImage: "sparkles")
                }
                .buttonStyle(PrimaryButtonStyle(enabled: canAnalyze))
                .disabled(!canAnalyze)
                .padding(.horizontal, AppTheme.marginMain)
                .padding(.bottom, 16)
                .background(AppTheme.background)
            }
        }
        .onChange(of: selectedItem) { _, item in
            Task { await loadImage(from: item) }
        }
        .onChange(of: mealNote) { _, newValue in
            if newValue.count > 500 {
                mealNote = String(newValue.prefix(500))
            }
        }
    }

    private var uploadedPhotoPreview: some View {
        HStack(spacing: 12) {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Photo attached")
                    .font(AppTypography.subheadline.weight(.semibold))
                Text("We'll combine it with your description")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Button {
                imageData = nil
                selectedItem = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppTheme.glassBg)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(AppTheme.glassBorder, lineWidth: 1)
        )
    }

    private var analyzingView: some View {
        MealAnalyzingView(
            image: nil,
            statusMessage: loadingMessages[loadingStep]
        )
    }

    private func appendQuickAdd(_ snippet: String) {
        if mealNote.isEmpty {
            mealNote = snippet
        } else if !mealNote.localizedCaseInsensitiveContains(snippet) {
            mealNote += ", \(snippet)"
        }
    }

    private func resetForAnotherLog() {
        analysis = nil
        mealNote = ""
        imageData = nil
        selectedItem = nil
        selectedMealType = MealType.inferred()
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            imageData = data
            showScanFailed = false
        }
    }

    private func analyze() async {
        guard canAnalyze else { return }
        isAnalyzing = true
        showScanFailed = false
        loadingStep = 0

        do {
            try await BackendAuthBootstrap.ensureBackendSession()
        } catch {
            isAnalyzing = false
            lastScanError = error.localizedDescription
            showScanFailed = true
            return
        }

        let timer = Task {
            for i in 0..<loadingMessages.count {
                loadingStep = i
                try? await Task.sleep(for: .milliseconds(800))
            }
        }

        let compressedImage = imageData.map { ImageCompression.compressForAnalysis($0) }

        let request = MealAnalysisRequest(
            imageData: compressedImage,
            mealDescription: mealNote,
            dailyProteinTarget: proteinTarget,
            dietPreferences: dietPreferences,
            userContext: AIContextBuilder.mealAnalysisContext(
                settings: userSettings,
                proteinConsumedToday: todaysProtein,
                caloriesConsumedToday: todaysCalories,
                recentMealNames: Array(recentMealNames)
            ),
            proteinConsumedToday: todaysProtein,
            caloriesConsumedToday: todaysCalories
        )

        do {
            let result = try await appState.mealAnalysisService().analyzeMeal(request)
            timer.cancel()
            appState.consumeScanIfNeeded()
            analysis = result
        } catch {
            timer.cancel()
            lastScanError = error.localizedDescription
            showScanFailed = true
        }
        isAnalyzing = false
    }

    private func openFoodSearch() {
        if appState.quotaManager.canScan(isSubscribed: appState.hasProAccess) {
            showFoodSearch = true
        } else {
            appState.activeSheet = .scanQuota
        }
    }

    private func toggleVoice() async {
        if speechService.isRecording {
            stopVoice()
            return
        }
        if !ScanFlowFlags.hasSeenMicrophonePrompt {
            showMicPrompt = true
            return
        }
        await startVoiceAfterPrompt()
    }

    private func startVoiceAfterPrompt() async {
        do {
            try await speechService.startRecording()
            showVoiceOverlay = true
        } catch {
            showMicPrompt = true
        }
    }

    private func stopVoice() {
        speechService.stopRecording()
        showVoiceOverlay = false
    }
}

#Preview {
    ManualMealLogView()
        .environment(AppState())
        .modelContainer(for: [UserSettings.self, MealRecord.self], inMemory: true)
}
