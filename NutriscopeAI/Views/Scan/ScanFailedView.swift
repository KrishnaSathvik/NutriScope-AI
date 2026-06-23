import SwiftUI

struct ScanFailedView: View {
    var errorMessage: String?
    var onRetry: () -> Void
    var onDescribeManually: () -> Void
    var onFoodDatabase: () -> Void
    var onDismiss: (() -> Void)?

    private var isLikelyBackendError: Bool {
        guard let errorMessage else { return false }
        let lower = errorMessage.lowercased()
        return lower.contains("supabase")
            || lower.contains("openai")
            || lower.contains("analyze-meal")
            || lower.contains("http")
            || lower.contains("auth")
            || lower.contains("configured")
            || lower.contains("network")
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.surfaceMuted)
                    .frame(width: 256, height: 256)
                    .overlay {
                        Image("scan-failed-illustration")
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 4)

                VStack(spacing: 12) {
                    Text(isLikelyBackendError ? "Couldn’t reach meal AI" : "Stumped by this one")
                        .font(AppTypography.title2.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(isLikelyBackendError
                         ? "The scan didn’t complete because of a setup or network issue — not your photo."
                         : "The lighting or angle made it hard for our AI to be sure. Would you like to try again or just describe it?")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)

                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(AppTheme.primary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(.horizontal, AppTheme.marginMain)

            Spacer()

            VStack(spacing: 16) {
                Button(action: onRetry) {
                    Label("Retry Photo", systemImage: "camera.fill")
                }
                .buttonStyle(PrimaryButtonStyle(pill: true))

                Button(action: onDescribeManually) {
                    Text("Describe Manually")
                }
                .buttonStyle(OutlineButtonStyle())

                Button(action: onFoodDatabase) {
                    Text("Add from Database")
                        .font(AppTypography.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .underline(color: AppTheme.textTertiary.opacity(0.5))
                }
                .buttonStyle(.plain)

                if let onDismiss {
                    Button("Dismiss", action: onDismiss)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            .padding(.horizontal, AppTheme.marginMain)
            .padding(.bottom, 32)
        }
        .background(AppBackground(showsAmbientGlow: true))
    }
}

#Preview {
    ScanFailedView(
        onRetry: {},
        onDescribeManually: {},
        onFoodDatabase: {}
    )
}
