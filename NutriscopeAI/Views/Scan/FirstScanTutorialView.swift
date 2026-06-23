import SwiftUI

struct FirstScanTutorialView: View {
    var onContinue: () -> Void

    private let tips: [(String, String, String)] = [
        ("camera.fill", "Fill the frame", "Get the whole plate in view — top-down works best."),
        ("sun.max.fill", "Good lighting", "Bright, even light helps the AI read portions."),
        ("square.and.pencil", "Or just describe", "No photo? Type or speak what you ate instead.")
    ]

    var body: some View {
        ZStack {
            AppBackground(showsAmbientGlow: true)

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.coachOrange.opacity(0.12))
                            .frame(width: 96, height: 96)
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 40))
                            .foregroundStyle(AppTheme.coachOrange)
                    }
                    LabelCapsText(text: "Let's Scan", color: AppTheme.textSecondary)
                    Text("Quick tips")
                        .font(AppTypography.headlineLG)
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
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous)
                                .strokeBorder(AppTheme.glassBorder, lineWidth: 1)
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
        }
    }
}

#Preview {
    FirstScanTutorialView(onContinue: {})
}
