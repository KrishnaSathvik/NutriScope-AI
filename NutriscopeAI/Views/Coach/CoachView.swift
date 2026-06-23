import SwiftData
import SwiftUI

struct CoachView: View {
    @Environment(AppState.self) private var appState
    @Query private var settings: [UserSettings]
    @Query(sort: \MealRecord.scannedAt, order: .reverse) private var meals: [MealRecord]

    @State private var draftMessage = ""
    @State private var messages: [CoachChatMessage] = []
    @State private var showQuickPrompts = false
    @State private var isReplying = false
    @State private var didSeedConversation = false
    @State private var healthService = HealthKitService.shared

    private var user: UserSettings? { settings.first }
    private var proteinTarget: Int { user?.dailyProteinTarget ?? 135 }

    private var proteinToday: Int {
        meals.filter { Calendar.current.isDateInToday($0.scannedAt) }
            .reduce(0) { $0 + $1.analysis.proteinMidpoint }
    }

    private var proteinRemaining: Int {
        max(0, proteinTarget - proteinToday)
    }

    private var calorieRemaining: (min: Int, max: Int) {
        let today = meals.filter { Calendar.current.isDateInToday($0.scannedAt) }
        let eaten = today.reduce(0) { $0 + ($1.caloriesMin + $1.caloriesMax) / 2 }
        let minTarget = user?.calorieRangeMin ?? 1900
        let maxTarget = user?.calorieRangeMax ?? 2200
        return (max(0, minTarget - eaten), max(0, maxTarget - eaten))
    }

    private var coachContext: CoachAIContext {
        OpenAICoachService.makeContext(
            settings: user,
            proteinToday: proteinToday,
            calorieRemaining: calorieRemaining,
            mealsLoggedToday: meals.filter { Calendar.current.isDateInToday($0.scannedAt) }.count,
            recentMealNames: meals.prefix(3).map(\.mealName),
            healthNote: HealthInsightsBuilder.coachNote(
                snapshot: healthService.todaySnapshot,
                proteinRemaining: proteinRemaining
            )
        )
    }

    private let quickPrompts = [
        "What should I eat for dinner?",
        "Quick high-protein snack ideas",
        "Help me hit my protein goal",
        "Post-workout meal suggestion"
    ]

    var body: some View {
        ZStack {
            AppBackground(showsAmbientGlow: true)

            VStack(spacing: 0) {
                coachHeader

                ScrollViewReader { proxy in
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            DailyGapCard(
                                proteinCurrent: proteinToday,
                                proteinTarget: proteinTarget,
                                message: proteinRemaining > 0
                                    ? "You're \(proteinRemaining)g from your goal today."
                                    : "You've hit your protein goal — nice work!"
                            )

                            KineticChatDateDivider(label: "Today")
                                .padding(.bottom, 4)

                            ForEach(messages) { message in
                                messageView(for: message)
                                    .id(message.id)
                            }

                            if isReplying {
                                KineticCoachChatBubble(role: .coach, text: "Thinking…")
                                    .id("coach-typing")
                            }
                        }
                        .padding(.horizontal, AppTheme.marginMain)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onChange(of: messages.count) { _, _ in
                        scrollToBottom(proxy)
                    }
                    .onChange(of: isReplying) { _, replying in
                        if replying { scrollToBottom(proxy, anchor: "coach-typing") }
                    }
                }
                }

            KineticCoachChatInputBar(
                text: $draftMessage,
                onSend: sendMessage,
                onQuickPrompts: { showQuickPrompts = true }
            )
            .disabled(isReplying)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarHidden(true)
        .sheet(isPresented: $showQuickPrompts) {
            quickPromptsSheet
                .presentationDetents([.medium])
        }
        .task {
            if healthService.isAuthorized {
                await healthService.refreshToday()
            }
        }
        .task {
            guard !didSeedConversation else { return }
            didSeedConversation = true
            await seedConversation()
        }
    }

    private var coachHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Protein Coach")
                    .font(AppTypography.displayLGMobile)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Your next move")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Circle()
                .fill(AppTheme.coachOrange)
                .frame(width: 44, height: 44)
                .shadow(color: AppTheme.coachOrange.opacity(0.3), radius: 8, y: 4)
                .overlay {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
        }
        .padding(.horizontal, AppTheme.marginMain)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func messageView(for message: CoachChatMessage) -> some View {
        switch message.role {
        case .coach, .user:
            KineticCoachChatBubble(role: message.role, text: message.text)
        case .suggestion:
            KineticCoachSuggestionCard(
                proteinGrams: message.suggestionProtein ?? min(proteinRemaining, 25),
                onAccept: { acceptSuggestion(message) },
                onSkip: { skipSuggestion(message) }
            )
        }
    }

    private var quickPromptsSheet: some View {
        NavigationStack {
            List {
                Section("Quick prompts") {
                    ForEach(quickPrompts, id: \.self) { prompt in
                        Button(prompt) {
                            draftMessage = prompt
                            showQuickPrompts = false
                            sendMessage()
                        }
                    }
                }
            }
            .navigationTitle("Ask your coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showQuickPrompts = false }
                }
            }
        }
    }

    private func seedConversation() async {
        do {
            let greeting = try await OpenAICoachService.greeting(context: coachContext)
            messages.append(CoachChatMessage(role: .coach, text: greeting))

            if proteinRemaining >= 20 {
                let proteinGrams = try await OpenAICoachService.suggestionCardProtein(context: coachContext)
                messages.append(
                    CoachChatMessage(
                        role: .suggestion,
                        text: "",
                        suggestionProtein: proteinGrams
                    )
                )
            }
        } catch {
            messages.append(CoachChatMessage(role: .coach, text: aiErrorMessage(error)))
        }
    }

    private func sendMessage() {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isReplying else { return }

        messages.append(CoachChatMessage(role: .user, text: trimmed))
        draftMessage = ""
        isReplying = true

        Task {
            defer { isReplying = false }
            do {
                let history = messages.filter { $0.role != .suggestion }
                let answer = try await OpenAICoachService.chatReply(
                    history: history,
                    userMessage: trimmed,
                    context: coachContext
                )
                messages.append(CoachChatMessage(role: .coach, text: answer))

                if proteinRemaining >= 15, shouldOfferSuggestion(for: trimmed) {
                    let proteinGrams = try await OpenAICoachService.suggestionCardProtein(context: coachContext)
                    messages.append(
                        CoachChatMessage(
                            role: .suggestion,
                            text: "",
                            suggestionProtein: proteinGrams
                        )
                    )
                }
            } catch {
                messages.append(CoachChatMessage(role: .coach, text: aiErrorMessage(error)))
            }
        }
    }

    private func shouldOfferSuggestion(for question: String) -> Bool {
        let normalized = question.lowercased()
        return normalized.contains("dinner")
            || normalized.contains("snack")
            || normalized.contains("protein")
            || normalized.contains("eat")
            || normalized.contains("workout")
    }

    private func acceptSuggestion(_ message: CoachChatMessage) {
        messages.removeAll { $0.id == message.id }
        let grams = message.suggestionProtein ?? 20
        messages.append(
            CoachChatMessage(
                role: .coach,
                text: "Got it — I'll prioritize ~\(grams)g protein in your next meal suggestions. Check the Meals tab when you're ready to log."
            )
        )
    }

    private func skipSuggestion(_ message: CoachChatMessage) {
        messages.removeAll { $0.id == message.id }
    }

    private func aiErrorMessage(_ error: Error) -> String {
        (error as? LocalizedError)?.errorDescription
            ?? "Couldn't reach the coach right now. Check your connection and try again."
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, anchor: AnyHashable? = nil) {
        let target: AnyHashable
        if let anchor {
            target = anchor
        } else if let last = messages.last {
            target = last.id
        } else {
            return
        }
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(target, anchor: .bottom)
        }
    }
}

#Preview {
    NavigationStack { CoachView() }
        .environment(AppState())
        .modelContainer(for: [MealRecord.self, UserSettings.self], inMemory: true)
}
