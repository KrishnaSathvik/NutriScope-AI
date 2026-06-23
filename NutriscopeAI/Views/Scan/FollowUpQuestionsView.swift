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
            BoundedScrollView {

                VStack(alignment: .leading, spacing: 20) {
                    Text("Quick check")
                        .font(.title3.weight(.bold))
                    Text("Help us tighten the range — hidden oil and portions matter most.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    ForEach($questions) { $question in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(question.prompt)
                                .font(.subheadline.weight(.semibold))
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
                        .padding(16)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(20)
            
        }
        .background(AppTheme.background)
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
