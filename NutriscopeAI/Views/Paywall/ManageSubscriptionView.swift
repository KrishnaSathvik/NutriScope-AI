import SwiftUI

struct ManageSubscriptionView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var cancelStep: CancelStep?
    @State private var selectedReason: String?
    @State private var showCancelConfirm = false

    private let cancelReasons = [
        "Too expensive",
        "Not using it enough",
        "Found an alternative",
        "Hard to use",
        "Other"
    ]

    var body: some View {
        BoundedScrollView {

            Group {
                if let cancelStep {
                    cancelFlowContent(step: cancelStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    overviewContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: cancelStep)
            .padding(AppTheme.marginMain)
            .padding(.bottom, 32)
        
        }
        .background(AppBackground())
        .navigationTitle(cancelStep == nil ? "Manage subscription" : "Cancel Pro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if cancelStep != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { goBackInCancelFlow() }
                }
            }
        }
        .alert("Cancel via App Store", isPresented: $showCancelConfirm) {
            Button("Open App Store") {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    openURL(url)
                }
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("Subscriptions are managed through your Apple ID. Cancellation takes effect at the end of the billing period.")
        }
    }

    // MARK: - Overview

    private var overviewContent: some View {
        VStack(spacing: 24) {
            if appState.subscriptionManager.isSubscribed || appState.hasProAccess {
                activePlanSection
            } else {
                inactivePlanSection
            }

            if appState.hasProAccess {
                Button("Cancel Pro plan") {
                    withAnimation { cancelStep = .intro }
                }
                .buttonStyle(OutlineButtonStyle())

                Button("Manage in App Store") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        openURL(url)
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            Button {
                Task { await appState.subscriptionManager.restore() }
            } label: {
                Label("Restore purchases", systemImage: "arrow.clockwise")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    // MARK: - Cancel flow

    @ViewBuilder
    private func cancelFlowContent(step: CancelStep) -> some View {
        VStack(spacing: 24) {
            switch step {
            case .intro:
                cancelIntroSection
                Button("Continue") { advanceCancelFlow(from: .intro) }
                    .buttonStyle(PrimaryButtonStyle())
            case .feedback:
                feedbackSection
                Button("Continue") { advanceCancelFlow(from: .feedback) }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(selectedReason == nil)
                    .opacity(selectedReason == nil ? 0.5 : 1)
            case .retention:
                retentionSection
            case .confirm:
                confirmSection
            }
        }
    }

    private var cancelIntroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.minus")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.coachOrange)
                .frame(width: 64, height: 64)
                .background(AppTheme.coachOrange.opacity(0.12))
                .clipShape(Circle())

            Text("Cancel Pro Plan?")
                .font(AppTypography.title2.weight(.bold))

            Text("You'll lose unlimited scans, advanced insights, and personalized coaching when your current period ends.")
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var feedbackSection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Why are you leaving?")
                    .font(AppTypography.headline)
                Text("Your feedback helps us improve the coach.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                FlowLayout(spacing: 8) {
                    ForEach(cancelReasons, id: \.self) { reason in
                        Button { selectedReason = reason } label: {
                            Text(reason)
                                .font(AppTypography.caption.weight(.semibold))
                                .foregroundStyle(selectedReason == reason ? .white : AppTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(selectedReason == reason ? AppTheme.coachOrange : AppTheme.surfaceMuted)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var retentionSection: some View {
        VStack(spacing: 20) {
            SurfaceCard {
                VStack(spacing: 12) {
                    Image(systemName: "gift.fill")
                        .font(.title)
                        .foregroundStyle(AppTheme.warmSun)
                    Text("Wait, let's keep going!")
                        .font(AppTypography.title3.weight(.bold))
                    Text("Building habits takes time. Stay on Pro to keep unlimited scans and coaching.")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("Keep Pro") { dismissCancelFlow() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .frame(maxWidth: .infinity)
            }

            Button("No thanks, continue canceling") {
                advanceCancelFlow(from: .retention)
            }
            .font(AppTypography.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var confirmSection: some View {
        VStack(spacing: 16) {
            Text("Ready to cancel?")
                .font(AppTypography.title3.weight(.bold))

            Button("Open App Store to cancel") {
                showCancelConfirm = true
            }
            .buttonStyle(OutlineButtonStyle())

            LabelCapsText(
                text: "Cancellation takes effect at the end of your billing cycle",
                color: AppTheme.outline
            )
            .multilineTextAlignment(.center)
            .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private func advanceCancelFlow(from step: CancelStep) {
        withAnimation {
            switch step {
            case .intro: cancelStep = .feedback
            case .feedback: cancelStep = .retention
            case .retention: cancelStep = .confirm
            case .confirm: break
            }
        }
    }

    private func goBackInCancelFlow() {
        withAnimation {
            guard let cancelStep else { return }
            switch cancelStep {
            case .intro: self.cancelStep = nil
            case .feedback: self.cancelStep = .intro
            case .retention: self.cancelStep = .feedback
            case .confirm: self.cancelStep = .retention
            }
        }
    }

    private func dismissCancelFlow() {
        withAnimation {
            cancelStep = nil
            selectedReason = nil
        }
    }

    private enum CancelStep: Equatable {
        case intro
        case feedback
        case retention
        case confirm
    }

    private var activePlanSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.proteinTeal)
            Text("Nutriscope Pro")
                .font(AppTypography.title2.weight(.bold))
            Text("Active subscription")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var inactivePlanSection: some View {
        VStack(spacing: 12) {
            Text("No active subscription")
                .font(AppTypography.title2.weight(.bold))
            Text("Subscribe to continue using Nutriscope AI.")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Button("Subscribe to Pro") {
                dismiss()
                appState.activeSheet = .paywall
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
    }
}

/// Simple flow layout for feedback chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

#Preview {
    NavigationStack {
        ManageSubscriptionView()
            .environment(AppState())
    }
}
