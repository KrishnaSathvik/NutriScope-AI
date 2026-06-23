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
    @State private var isAnalyzing = false
    @State private var loadingStep = 0
    @State private var analysis: MealAnalysis?
    @State private var showScanFailed = false
    @State private var lastScanError: String?
    @State private var showCamera = false
    @State private var showFirstScanTutorial = false
    @State private var showCameraPrompt = false
    @State private var showManualLog = false
    @State private var selectedMealType = MealType.inferred()

    private let loadingMessages = [
        "Looking at portion size…",
        "Checking protein sources…",
        "Estimating hidden oils and sauces…",
        "Building your meal summary…"
    ]

    private var userSettings: UserSettings? { settings.first }
    private var proteinTarget: Int { userSettings?.dailyProteinTarget ?? 135 }
    private var dietPreferences: Set<DietPreference> { userSettings?.dietPreferences ?? [] }
    private var canAnalyze: Bool { imageData != nil }

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
                        mealNote: "",
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
                            showManualLog = true
                        },
                        onFoodDatabase: {
                            showScanFailed = false
                            lastScanError = nil
                            showManualLog = true
                        },
                        onDismiss: {
                            showScanFailed = false
                            lastScanError = nil
                        }
                    )
                } else if isAnalyzing {
                    analyzingView
                } else {
                    cameraScanContent
                }
            }
            .background(AppBackground(showsAmbientGlow: true))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if analysis == nil && !isAnalyzing && !showScanFailed {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        Text("Scan Meal")
                            .font(AppTypography.title2.weight(.bold))
                            .foregroundStyle(AppTheme.coachOrange)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Type instead") {
                            showManualLog = true
                        }
                        .font(AppTypography.subheadline.weight(.semibold))
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
            .fullScreenCover(isPresented: $showFirstScanTutorial) {
                FirstScanTutorialView {
                    ScanFlowFlags.hasSeenFirstScanTutorial = true
                    showFirstScanTutorial = false
                    if !ScanFlowFlags.hasSeenCameraPrompt {
                        showCameraPrompt = true
                    } else if opensCameraOnAppear {
                        showCamera = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showCameraPrompt) {
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
            }
            .fullScreenCover(isPresented: $showManualLog) {
                ManualMealLogView(
                    onFirstMealSaved: onFirstMealSaved,
                    onSwitchToScan: {
                        showManualLog = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            openCamera()
                        }
                    }
                )
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
        imageData = nil
        selectedItem = nil
        selectedMealType = MealType.inferred()
    }

    private var cameraScanContent: some View {
        BoundedScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScanMealViewport(
                    image: imageData.flatMap { UIImage(data: $0) },
                    placeholderAction: { openCamera() }
                )

                if imageData != nil {
                    proteinContextCard
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(imageData == nil ? "Point at your meal" : "Ready to analyze")
                        .font(AppTypography.title3.weight(.bold))
                    Text(imageData == nil
                         ? "Shoot from above with good lighting. We'll estimate protein and calories from the photo."
                         : "Looks good — analyze when you're ready, or retake for a clearer shot.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.textSecondary)
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
                        Label("Gallery", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(OutlineButtonStyle())

                    if imageData != nil {
                        Button {
                            imageData = nil
                            selectedItem = nil
                        } label: {
                            Label("Retake", systemImage: "arrow.triangle.2.circlepath.camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    } else {
                        Button { openCamera() } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
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
                Button {
                    if imageData == nil {
                        openCamera()
                    } else {
                        Task { await analyze() }
                    }
                } label: {
                    Label(
                        imageData == nil ? "Open Camera" : "Analyze Photo",
                        systemImage: imageData == nil ? "camera.viewfinder" : "sparkles"
                    )
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, AppTheme.marginMain)
                .padding(.bottom, 16)
                .background(AppTheme.background)
            }
        }
        .onChange(of: selectedItem) { _, item in
            Task { await loadImage(from: item) }
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
        .background(AppTheme.glassBg)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous)
                .strokeBorder(AppTheme.glassBorder, lineWidth: 1)
        )
    }

    private var analyzingView: some View {
        MealAnalyzingView(
            image: imageData.flatMap { UIImage(data: $0) },
            statusMessage: loadingMessages[loadingStep]
        )
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
            mealDescription: "",
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
}

#Preview {
    ScanMealView()
        .environment(AppState())
        .modelContainer(for: [UserSettings.self, MealRecord.self], inMemory: true)
}
