import SwiftUI

struct SubscriptionLegalLinksView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 16) {
            Button("Terms of Use") {
                openURL(AppLegalLinks.termsOfUse)
            }
            Text("·")
                .foregroundStyle(AppTheme.textTertiary)
            Button("Privacy Policy") {
                openURL(AppLegalLinks.privacyPolicy)
            }
        }
        .font(.caption)
        .foregroundStyle(AppTheme.coachOrange)
        .frame(maxWidth: .infinity)
    }
}

struct RestorePurchasesButton: View {
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Restore purchases")
                    .frame(maxWidth: .infinity)
            }
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(AppTheme.textSecondary)
        .disabled(isLoading)
    }
}
