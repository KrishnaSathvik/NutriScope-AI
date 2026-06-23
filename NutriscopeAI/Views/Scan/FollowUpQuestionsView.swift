import SwiftUI

struct FollowUpQuestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var questions: [FollowUpQuestion]

    let onComplete: ([FollowUpQuestion]) -> Void

    init(questions: [FollowUpQuestion], onComplete: @escaping ([FollowUpQuestion]) -> Void) {
        _questions = State(initialValue: questions)
        self.onComplete = onComplete
    }

    private var allAnswered: Bool {
        questions.allSatisfy { $0.selectedOption != nil }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(showsAmbientGlow: true)

                BoundedScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Stumped by this one?")
                        .font(AppTypography.headlineLG)
                    Text("Help us tighten the range — hidden oil and portions matter most.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.textSecondary)

                    ForEach($questions) { $question in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(question.prompt)
                                    .font(AppTypography.subheadline.weight(.semibold))
                                ForEach(question.options, id: \.self) { option in
                                Button {
                                    question.selectedOption = option
                                } label: {
                                    HStack {
                                        Image(systemName: question.selectedOption == option ? "largecircle.fill.circle" : "circle")
                                            .foregroundStyle(AppTheme.coachOrange)
                                        Text(option)
                                            .font(.subheadline)
                                        Spacer()
                                    }
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                            }
                            }
                        }
                    }
                }
                .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update Estimate") {
                        onComplete(questions)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!allAnswered)
                }
            }
        }
    }
}
