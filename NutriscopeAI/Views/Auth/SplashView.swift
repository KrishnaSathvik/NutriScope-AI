import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.85
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.coachOrange)
                    .frame(width: 88, height: 88)
                    .overlay {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: AppTheme.coachOrange.opacity(0.3), radius: 16, y: 8)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("Nutriscope AI")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(AppTheme.textPrimary)
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
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
