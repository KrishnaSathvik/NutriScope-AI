import SwiftUI

struct ConfidenceBadge: View {
    let level: ConfidenceLevel

    private var color: Color {
        switch level {
        case .high: AppTheme.proteinTeal
        case .medium: AppTheme.warmSun
        case .low: AppTheme.textTertiary
        }
    }

    var body: some View {
        Label("\(level.shortLabel) confidence", systemImage: "checkmark.seal.fill")
            .font(AppTypography.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color)
            .clipShape(Capsule())
            .shadow(color: color.opacity(0.3), radius: 6, y: 2)
    }
}
