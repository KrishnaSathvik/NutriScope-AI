import SwiftUI

struct ScanQuotaPaywallView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private var used: Int { appState.quotaManager.usedThisWeek }
    private var limit: Int { ScanQuotaManager.weeklyFreeLimit }
    private var resetDescription: String {
        let days = appState.quotaManager.daysUntilWeeklyReset
        if days <= 0 { return "Your quota resets soon." }
        if days == 1 { return "Your quota resets in 1 day." }
        return "Your quota resets in \(days) days."
    }

    var body: some View {
        ZStack {
            AppTheme.surface.ignoresSafeArea()

            Circle()
                .fill(AppTheme.coachOrange.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: 120, y: -200)
            Circle()
                .fill(AppTheme.warmSun.opacity(0.1))
                .frame(width: 500, height: 500)
                .blur(radius: 100)
                .offset(x: -140, y: 280)

            BoundedScrollView {

                VStack(spacing: 0) {
                    Spacer(minLength: 40)

                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Circle()
                                .stroke(Color.red.opacity(0.2), lineWidth: 4)
                                .frame(width: 80, height: 80)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.red)
                        }

                        VStack(spacing: 8) {
                            Text("Scan Limit Reached")
                                .font(AppTypography.title2.weight(.bold))
                                .foregroundStyle(AppTheme.inkBlack)
                            Text("You've used \(used)/\(limit) AI scans this week. \(resetDescription)")
                                .font(AppTypography.body)
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        VStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(AppTheme.surfaceContainerHighest)
                                    Capsule()
                                        .fill(Color.red)
                                        .frame(width: geo.size.width * CGFloat(used) / CGFloat(max(limit, 1)))
                                }
                            }
                            .frame(height: 12)
                            HStack {
                                Text("0")
                                Spacer()
                                Text("\(used)/\(limit) USED")
                                    .font(AppTypography.caption.weight(.bold))
                                    .foregroundStyle(.red)
                            }
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Nutriscope Pro Benefits")
                                .font(AppTypography.headline)
                                .padding(.bottom, 4)
                            Divider()
                            KineticPaywallFeatureRow(
                                icon: "checkmark.circle.fill",
                                title: "Unlimited AI Scans",
                                subtitle: "Log meals instantly without limits."
                            )
                            KineticPaywallFeatureRow(
                                icon: "checkmark.circle.fill",
                                title: "Proactive Coaching",
                                subtitle: "Get personalized feedback before you eat."
                            )
                            KineticPaywallFeatureRow(
                                icon: "checkmark.circle.fill",
                                title: "Deep Macro Analysis",
                                subtitle: "Detailed breakdowns of every ingredient."
                            )
                        }
                        .padding(16)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                                .strokeBorder(AppTheme.outlineVariant.opacity(0.5), lineWidth: 1)
                        )

                        VStack(spacing: 12) {
                            Button {
                                appState.activeSheet = .paywall
                            } label: {
                                Label("Get Unlimited Scans with Pro", systemImage: "crown.fill")
                            }
                            .buttonStyle(PrimaryButtonStyle())

                            RestorePurchasesButton(isLoading: appState.subscriptionManager.isLoading) {
                                Task {
                                    if await appState.restorePurchases() {
                                        await appState.completePurchaseSuccess()
                                    }
                                }
                            }

                            SubscriptionLegalLinksView()

                            Button("Maybe Later") { dismiss() }
                                .font(AppTypography.body)
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: AppTheme.coachOrange.opacity(0.08), radius: 32, y: 12)
                    .padding(.horizontal, AppTheme.marginMain)

                    Spacer(minLength: 40)
                }
            
        }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ScanQuotaPaywallView()
        .environment(AppState())
}
