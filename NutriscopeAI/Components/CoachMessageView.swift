import SwiftUI

struct CoachMessageView: View {
    let message: String
    var headline: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.proteinTeal.opacity(0.4), AppTheme.coachOrange.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 3)
            HStack(alignment: .top, spacing: 14) {
                Circle()
                    .fill(AppTheme.coachOrange)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(.white)
                    }
                VStack(alignment: .leading, spacing: 8) {
                    Text(headline ?? "COACH INSIGHT")
                        .font(AppTypography.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.proteinTeal)
                    Text(message)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(AppTheme.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceContainerHighest, lineWidth: 1)
        )
        .shadow(color: AppTheme.cardShadow, radius: 8, y: 3)
    }
}
