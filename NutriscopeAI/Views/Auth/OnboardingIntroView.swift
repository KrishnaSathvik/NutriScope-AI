import SwiftUI

struct OnboardingIntroPage: Identifiable {
    let id: Int
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    static let pages: [OnboardingIntroPage] = [
        OnboardingIntroPage(
            id: 0,
            icon: "camera.viewfinder",
            title: "Track meals fast",
            subtitle: "Snap a photo or type what you ate. No perfect logging required.",
            tint: AppTheme.coachOrange
        ),
        OnboardingIntroPage(
            id: 1,
            icon: "chart.line.uptrend.xyaxis",
            title: "See protein progress daily",
            subtitle: "Know how much protein you've hit and what's left today.",
            tint: AppTheme.proteinTeal
        ),
        OnboardingIntroPage(
            id: 2,
            icon: "sparkles",
            title: "Get smart next-meal suggestions",
            subtitle: "Coach-style tips help you close your protein gap without obsessing.",
            tint: AppTheme.warmSun
        ),
    ]
}

struct OnboardingIntroView: View {
    let page: OnboardingIntroPage
    let pageIndex: Int
    let totalPages: Int
    var onBack: (() -> Void)?
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let onBack {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.coachOrange)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.surfaceMuted)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, AppTheme.marginMain)
                .padding(.top, 8)
            }

            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(page.tint.opacity(0.14))
                        .frame(width: 140, height: 140)
                    Image(systemName: page.icon)
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(page.tint)
                }

                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.system(size: 32, weight: .heavy))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(page.subtitle)
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }

                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index == pageIndex ? AppTheme.coachOrange : AppTheme.surfaceContainerHighest)
                            .frame(width: index == pageIndex ? 24 : 8, height: 8)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, AppTheme.marginMain)

            Spacer()

            Button(action: onContinue) {
                HStack(spacing: 8) {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(PrimaryButtonStyle(pill: true))
            .padding(.horizontal, AppTheme.marginMain)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    OnboardingIntroView(
        page: OnboardingIntroPage.pages[0],
        pageIndex: 0,
        totalPages: 3,
        onBack: {},
        onContinue: {}
    )
}
