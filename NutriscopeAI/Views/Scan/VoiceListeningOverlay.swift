import SwiftUI

struct VoiceListeningOverlay: View {
    let partialText: String
    var onCancel: () -> Void
    var onDone: () -> Void

    @State private var pulse = false

    var body: some View {
        ZStack {
            AppTheme.background.opacity(0.35)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.surfaceContainerHighest)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Label("Voice Entry", systemImage: "mic.fill")
                        .font(AppTypography.labelCaps)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, AppTheme.marginMain)
                .padding(.top, 16)

                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.coachOrange.opacity(pulse ? 0.22 : 0.12))
                        .frame(width: pulse ? 132 : 112, height: pulse ? 132 : 112)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.coachOrange, AppTheme.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                        .shadow(color: AppTheme.coachOrange.opacity(0.4), radius: 16, y: 8)
                        .overlay {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white)
                        }
                }
                .padding(.bottom, 28)

                VoiceWaveformView()
                    .frame(height: 48)
                    .padding(.bottom, 20)

                listeningTitle
                    .padding(.bottom, 16)

                Text(partialText.isEmpty ? "Speak your meal…" : partialText)
                    .font(AppTypography.body)
                    .italic(partialText.isEmpty)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .top)
                    .padding(20)
                    .background(AppTheme.surface.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                            .strokeBorder(AppTheme.outlineVariant.opacity(0.5), lineWidth: 1)
                    )
                    .padding(.horizontal, AppTheme.marginMain)

                Spacer()

                HStack(spacing: 12) {
                    Button("Cancel", action: onCancel)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)

                    Button("Done", action: onDone)
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(maxWidth: 200)
                }
                .padding(.horizontal, AppTheme.marginMain)
                .padding(.bottom, 32)
                .background(
                    LinearGradient(
                        colors: [AppTheme.background.opacity(0), AppTheme.background.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .offset(y: -40)
                )
            }
        }
        .onAppear { pulse = true }
    }

    private var listeningTitle: some View {
        HStack(spacing: 2) {
            Text("Listening")
                .font(AppTypography.title2.weight(.bold))
            TypingDotsView()
        }
        .foregroundStyle(AppTheme.textPrimary)
    }
}

private struct VoiceWaveformView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<9, id: \.self) { index in
                    let height = 12 + abs(sin(phase * 3 + Double(index) * 0.45)) * 28
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.coachOrange)
                        .frame(width: 6, height: height)
                }
            }
        }
    }
}

private struct TypingDotsView: View {
    @State private var step = 0

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Text(".")
                    .opacity(step == index ? 1 : 0.25)
            }
        }
        .font(AppTypography.title2.weight(.bold))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                step = (step + 1) % 3
            }
        }
    }
}

#Preview {
    VoiceListeningOverlay(partialText: "Grilled chicken with rice", onCancel: {}, onDone: {})
}
