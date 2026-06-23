import SwiftUI

struct FirstScanTutorialView: View {
    var onContinue: () -> Void

    private let tips: [(String, String, String)] = [
        ("camera.fill", "Fill the frame", "Get the whole plate in view — top-down works best."),
        ("sun.max.fill", "Good lighting", "Bright, even light helps the AI read portions."),
        ("square.and.pencil", "Or just describe", "No photo? Type or speak what you ate instead.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.coachOrange.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 36))
                        .foregroundStyle(AppTheme.coachOrange)
                }
                LabelCapsText(text: "Your First Scan", color: AppTheme.textSecondary)
                Text("Quick tips")
                    .font(AppTypography.title.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Three habits that make AI meal logging more accurate.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)

            VStack(spacing: 12) {
                ForEach(tips, id: \.1) { icon, title, detail in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(AppTheme.coachOrange)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.coachOrange.opacity(0.12))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(AppTypography.subheadline.weight(.semibold))
                            Text(detail)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                            .strokeBorder(AppTheme.outlineVariant.opacity(0.35), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, AppTheme.marginMain)

            Spacer()

            Button("Got it — let's scan", action: onContinue)
                .buttonStyle(PrimaryButtonStyle(pill: true))
                .padding(.horizontal, AppTheme.marginMain)
                .padding(.bottom, 32)
        }
        .background(AppTheme.background)
    }
}

#Preview {
    FirstScanTutorialView(onContinue: {})
}
