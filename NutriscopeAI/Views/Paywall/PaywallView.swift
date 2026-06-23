import SwiftUI

struct PaywallView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var paywallChoice: PaywallPlanChoice = .yearly

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppTheme.coachOrange.opacity(0.08), AppTheme.background, AppTheme.background],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                BoundedScrollView {

                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textPrimary)
                                LabelCapsText(text: "Nutriscope Pro", color: AppTheme.textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.warmSun.opacity(0.45))
                            .clipShape(Capsule())

                            Text("Hit your protein goal without manual tracking.")
                                .font(AppTypography.title.weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .padding(.top, 8)

                        SurfaceCard {
                            VStack(spacing: 4) {
                                KineticPaywallFeatureRow(
                                    icon: "camera.viewfinder",
                                    title: "Unlimited Scans",
                                    subtitle: "Log meals instantly with your camera."
                                )
                                KineticPaywallFeatureRow(
                                    icon: "brain.head.profile",
                                    title: "Smart Questions",
                                    subtitle: "Ask the AI anything about your diet."
                                )
                                KineticPaywallFeatureRow(
                                    icon: "sparkles",
                                    title: "Daily Coaching",
                                    subtitle: "Personalized tips to hit your macros."
                                )
                                KineticPaywallFeatureRow(
                                    icon: "heart.fill",
                                    title: "Saved Meals",
                                    subtitle: "Quickly re-log your go-to favorites."
                                )
                            }
                        }

                        VStack(spacing: 10) {
                            SubscriptionPlansSection(choice: $paywallChoice)
                        }

                        SubscriptionPaywallActions(
                            choice: paywallChoice,
                            isLoading: appState.subscriptionManager.isLoading,
                            errorMessage: appState.subscriptionManager.errorMessage,
                            onStartTrial: {
                                Task {
                                    await appState.subscriptionManager.purchase(paywallChoice.subscriptionPlan)
                                    await appState.completePurchaseSuccess()
                                }
                            },
                            onRestore: {
                                Task {
                                    if await appState.restorePurchases() {
                                        await appState.completePurchaseSuccess()
                                    }
                                }
                            },
                            onContinueFree: { dismiss() }
                        )
                        .padding(.top, 8)
                    }
                    .padding(AppTheme.marginMain)
                    .padding(.bottom, 32)
                
        }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .task { await appState.subscriptionManager.loadProducts() }
        }
    }
}

#Preview {
    PaywallView()
        .environment(AppState())
}
