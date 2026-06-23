import PhotosUI
import SwiftData
import SwiftUI

struct ScanMealView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]

    @Query(sort: \MealRecord.scannedAt, order: .reverse) private var meals: [MealRecord]

    var skipsFlowTutorial = false
    var opensCameraOnAppear = false
    var onFirstMealSaved: (() -> Void)? = nil

    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var mealNote = ""
    @State private var isAnalyzing = false
    @State private var loadingStep = 0
    @State private var analysis: MealAnalysis?
    @State private var showScanFailed = false
    @State private var lastScanError: String?
    @State private var showVoiceOverlay = false
    @State private var showCamera = false
    @State private var showFoodSearch = false
    @State private var showFirstScanTutorial = false
    @State private var showCameraPrompt = false
    @State private var showMicPrompt = false
    @State private var selectedMealType = MealType.inferred()
    @State private var speechService = SpeechTranscriptionService()

    private let quickAddItems: [(emoji: String, label: String, snippet: String)] = [
        ("🥚", "Boiled Egg", "1 boiled egg"),
        ("🥤", "Whey Scoop", "1 scoop whey protein"),
        ("🍗", "Chicken Breast", "grilled chicken breast"),
        ("🍚", "White Rice", "1 cup white rice")
    ]

    private let loadingMessages = [
        "Looking at portion size…",
        "Checking protein sources…",
        "Estimating hidden oils and sauces…",
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
                        onRetry: {
                            showScanFailed = false
                            lastScanError = nil
                            openCamera()
                        },
                        onDescribeManually: {
                            showScanFailed = false
                            lastScanError = nil
                            imageData = nil
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
                    scanContent
                }
            }
        .background(AppTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if analysis == nil && !isAnalyzing && !showScanFailed {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        Text("Manual Log")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.coachOrange)
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    ToolbarItem(placement: .principal) {
                        Text("Scan meal")
                            .font(.headline)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraImagePicker { data in
                    imageData = data
                    showScanFailed = false
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showFirstScanTutorial) {
                FirstScanTutorialView {
                    ScanFlowFlags.hasSeenFirstScanTutorial = true
                    showFirstScanTutorial = false
                    if !ScanFlowFlags.hasSeenCameraPrompt {
                        showCameraPrompt = true
                    }
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showCameraPrompt) {
                CameraPermissionPromptView(
                    onAllow: {
                        ScanFlowFlags.hasSeenCameraPrompt = true
                        showCameraPrompt = false
                        Task {
                            _ = await CameraPermissionPromptView.requestAccess()
                            showCamera = true
                        }
                    },
                    onSkip: {
                        ScanFlowFlags.hasSeenCameraPrompt = true
                        showCameraPrompt = false
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showMicPrompt) {
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
                .presentationDetents([.medium, .large])
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
            .onAppear {
                if skipsFlowTutorial {
                    if opensCameraOnAppear {
                        openCamera()
                    }
                } else {
                    presentScanOnboardingIfNeeded()
                }
            }
        }
    }

    private func presentScanOnboardingIfNeeded() {
        if !ScanFlowFlags.hasSeenFirstScanTutorial {
            showFirstScanTutorial = true
        }
    }

    private func openCamera() {
        if !ScanFlowFlags.hasSeenCameraPrompt {
            showCameraPrompt = true
        } else {
            showCamera = true
        }
    }

    private func resetForAnotherLog() {
        analysis = nil
        mealNote = ""
        imageData = nil
        selectedItem = nil
        selectedMealType = MealType.inferred()
    }

    private var scanContent: some View {
        BoundedScrollView {

            VStack(alignment: .leading, spacing: 24) {
                if imageData != nil || !recentMealNames.isEmpty {
                    proteinContextCard
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What did you have?")
                        .font(.title3.weight(.semibold))
                    Text("Describe your meal as naturally as you'd tell a friend. Our AI will handle the math.")
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                ManualLogPaperCard {
                    VStack(alignment: .leading, spacing: 12) {
                        if let imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        TextField("e.g., 2 rotis, a bowl of chicken curry, and some rice…", text: $mealNote, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.body)
                            .padding(12)
                            .background(AppTheme.surfaceMuted)
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
                            QuickAddTile(emoji: item.emoji, label: item.label) {
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
                        Label("Upload", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button { openCamera() } label: {
                        Label("Camera", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(OutlineButtonStyle())

                    Button { openFoodSearch() } label: {
                        Image(systemName: "magnifyingglass")
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

    private var proteinContextCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                LabelCapsText(text: "Today", color: AppTheme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(todaysProtein)")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.proteinTeal)
                    Text("/ \(proteinTarget)g protein")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                LabelCapsText(text: "Calories", color: AppTheme.textSecondary)
                Text("\(todaysCalories) kcal")
                    .font(AppTypography.headline)
            }
        }
        .padding(16)
        .background(AppTheme.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
    }

    private func appendQuickAdd(_ snippet: String) {
        if mealNote.isEmpty {
            mealNote = snippet
        } else if !mealNote.localizedCaseInsensitiveContains(snippet) {
            mealNote += ", \(snippet)"
        }
    }

    private var analyzingView: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(AppTheme.coachOrange.opacity(0.2), lineWidth: 8)
                    .frame(width: 88, height: 88)
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(AppTheme.coachOrange)
            }
            Text(loadingMessages[min(loadingStep, loadingMessages.count - 1)])
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: loadingStep)
                .padding(.horizontal, 32)
            Text("This usually takes a few seconds")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
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
    ScanMealView()
        .environment(AppState())
        .modelContainer(for: [UserSettings.self, MealRecord.self], inMemory: true)
}
