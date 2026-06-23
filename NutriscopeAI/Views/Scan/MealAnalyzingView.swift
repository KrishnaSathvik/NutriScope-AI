import SwiftUI

struct MealAnalyzingView: View {
    let image: UIImage?
    let statusMessage: String
    @State private var pulse = false
    @State private var rotate = false

    var body: some View {
        ZStack {
            AppBackground(showsAmbientGlow: true)

            if image != nil {
                VStack(spacing: 0) {
                    if let image {
                        ScanMealViewport(
                            image: image,
                            showsAnalyzingBadge: true,
                            animateScanLine: true
                        )
                        .padding(.horizontal, AppTheme.marginMain)
                        .padding(.top, 16)
                    }

                    Spacer(minLength: 24)

                    analyzingContent

                    Spacer()

                    Text("This usually takes a few seconds")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(.bottom, 32)
                }
            } else {
                VStack(spacing: 0) {
                    Spacer()
                    analyzingContent
                    Spacer()
                    Text("This usually takes a few seconds")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(.bottom, 48)
                }
            }
        }
        .onAppear {
            pulse = true
            rotate = true
        }
    }

    private var analyzingContent: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .stroke(AppTheme.gaugeTrack, lineWidth: 3)
                    .frame(width: 132, height: 132)

                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(
                        AppTheme.coachOrange,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 132, height: 132)
                    .rotationEffect(.degrees(rotate ? 360 : 0))
                    .animation(.linear(duration: 1.6).repeatForever(autoreverses: false), value: rotate)

                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: 80, height: 80)
                    .shadow(color: AppTheme.coachOrange.opacity(0.12), radius: 12, y: 4)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(AppTheme.coachOrange)
                            .scaleEffect(pulse ? 1.06 : 1)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                    }
            }

            VStack(spacing: 10) {
                Text("Analyzing your meal")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(statusMessage)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 44)
                    .padding(.horizontal, AppTheme.marginMain)
                    .animation(.easeInOut, value: statusMessage)
            }
        }
    }
}

#Preview {
    MealAnalyzingView(image: nil, statusMessage: "Building your meal summary…")
}
