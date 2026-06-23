import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.85
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            AppBackground(showsAmbientGlow: true)

            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.coachOrange, AppTheme.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .overlay {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: AppTheme.coachOrange.opacity(0.35), radius: 20, y: 10)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                VStack(spacing: 6) {
                    Text("Nutriscope AI")
                        .font(AppTypography.displayLGMobile)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Protein-first meal tracking")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.nsBouncySpring) {
                logoScale = 1
                logoOpacity = 1
            }
            Task {
                try? await Task.sleep(for: .milliseconds(1200))
                await MainActor.run { onFinished() }
            }
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
