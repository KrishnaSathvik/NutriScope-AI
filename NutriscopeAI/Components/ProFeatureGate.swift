import SwiftUI

struct ProFeatureGate<Content: View>: View {
    @Environment(AppState.self) private var appState
    let feature: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        if appState.hasProAccess {
            content()
        } else {
            ProUpgradePromptView(feature: feature)
        }
    }
}

struct ProUpgradePromptView: View {
    @Environment(AppState.self) private var appState
    let feature: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.coachOrange)
            Text("\(feature) is Pro")
                .font(AppTypography.title2.weight(.bold))
            Text("Upgrade to unlock advanced coaching, insights, and unlimited scans.")
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Upgrade to Pro") {
                appState.activeSheet = .paywall
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, AppTheme.marginMain)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
        .navigationTitle(feature)
        .navigationBarTitleDisplayMode(.inline)
    }
}
