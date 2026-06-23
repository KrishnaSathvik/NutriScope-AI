import SwiftUI

struct MealAdviceCard: View {
    let advice: MealAdvice
    var proteinRemaining: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(advice.headline)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    if let proteinRemaining, proteinRemaining > 0 {
                        Text("~\(proteinRemaining)g protein still to go today")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                Spacer()
                balanceRing(score: advice.balanceScore)
            }

            if !advice.suggestions.isEmpty {
                Text("WHAT NOW?")
                    .font(AppTypography.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                ForEach(Array(advice.suggestions.prefix(3).enumerated()), id: \.offset) { index, suggestion in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(AppTypography.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(AppTheme.coachOrange)
                            .clipShape(Circle())
                        Text(suggestion)
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceContainerHighest, lineWidth: 1)
        )
    }

    private func balanceRing(score: Int) -> some View {
        ZStack {
            Circle()
                .stroke(AppTheme.surfaceContainerHighest, lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(AppTheme.proteinTeal, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(AppTypography.caption.weight(.bold))
        }
        .frame(width: 44, height: 44)
    }
}
