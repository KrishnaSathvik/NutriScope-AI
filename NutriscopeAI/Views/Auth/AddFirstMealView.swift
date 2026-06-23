import SwiftUI

struct AddFirstMealView: View {
    let onScanPhoto: () -> Void
    let onTypeMeal: () -> Void
    var onBack: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if let onBack {
                HStack {
                    Button(action: onBack) {
                        Label("Back", systemImage: "chevron.left")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.coachOrange)
                    }
                    Spacer()
                }
                .padding(.horizontal, AppTheme.marginMain)
                .padding(.top, 8)
            }

            Spacer()

            VStack(spacing: 20) {
                Text("Add your first meal")
                    .font(.system(size: 32, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("See your protein estimate before the dashboard. Camera permission is only asked when you choose photo scan.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, AppTheme.marginMain)

            VStack(spacing: 12) {
                firstMealOption(
                    icon: "camera.fill",
                    title: "Take photo",
                    subtitle: "Fastest way to log a meal",
                    action: onScanPhoto
                )
                firstMealOption(
                    icon: "text.cursor",
                    title: "Type meal",
                    subtitle: "Describe what you ate",
                    action: onTypeMeal
                )
            }
            .padding(.horizontal, AppTheme.marginMain)
            .padding(.top, 32)

            Spacer()
        }
    }

    private func firstMealOption(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(AppTheme.coachOrange)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.coachOrange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.outlineVariant.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddFirstMealView(onScanPhoto: {}, onTypeMeal: {})
}
