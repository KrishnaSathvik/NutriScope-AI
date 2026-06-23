import SwiftUI

struct SubscriptionPlansSection: View {
    @Environment(AppState.self) private var appState
    @Binding var choice: PaywallPlanChoice

    private var manager: SubscriptionManager { appState.subscriptionManager }

    var body: some View {
        VStack(spacing: 10) {
            KineticPlanOptionCard(
                title: "Yearly",
                subtitle: yearlySubtitle,
                price: manager.yearlyMonthlyEquivalentPrice() ?? manager.displayPrice(for: .yearly),
                priceSuffix: manager.yearlyMonthlyEquivalentPrice() != nil ? "/mo" : "/yr",
                badge: "Best value",
                isSelected: choice == .yearly
            ) {
                choice = .yearly
            }

            KineticPlanOptionCard(
                title: "Monthly",
                subtitle: monthlySubtitle,
                price: manager.displayPrice(for: .monthly),
                priceSuffix: "/mo",
                isSelected: choice == .monthly
            ) {
                choice = .monthly
            }
        }
    }

    private var yearlySubtitle: String {
        if let savings = manager.yearlySavingsPercent() {
            return "Save \(savings)% vs monthly"
        }
        if let intro = manager.introductoryOfferDescription(for: .yearly) {
            return intro
        }
        return "Billed \(manager.displayPrice(for: .yearly)) every year"
    }

    private var monthlySubtitle: String {
        if let intro = manager.introductoryOfferDescription(for: .monthly) {
            return intro
        }
        return "Billed \(manager.displayPrice(for: .monthly)) every month"
    }
}

struct SubscriptionPaywallActions: View {
    @Environment(AppState.self) private var appState

    let choice: PaywallPlanChoice
    let isLoading: Bool
    let errorMessage: String?
    let onStartTrial: () -> Void
    let onRestore: () -> Void
    var onContinueFree: (() -> Void)? = nil

    private var manager: SubscriptionManager { appState.subscriptionManager }

    private var primaryTitle: String {
        if manager.hasIntroductoryOffer(for: choice.subscriptionPlan) {
            return "Start Free Trial"
        }
        return "Subscribe"
    }

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onStartTrial) {
                Group {
                    if isLoading {
                        ProgressView().tint(.white).frame(maxWidth: .infinity)
                    } else {
                        Text(primaryTitle)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle(pill: true))
            .disabled(isLoading)

            RestorePurchasesButton(isLoading: isLoading, action: onRestore)

            Text(manager.renewalDisclosure(for: choice))
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)

            SubscriptionLegalLinksView()

            if let onContinueFree {
                Button("Continue with free plan", action: onContinueFree)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var choice: PaywallPlanChoice = .yearly
        var body: some View {
            VStack(spacing: 24) {
                SubscriptionPlansSection(choice: $choice)
                SubscriptionPaywallActions(
                    choice: choice,
                    isLoading: false,
                    errorMessage: nil,
                    onStartTrial: {},
                    onRestore: {}
                )
            }
            .padding()
            .environment(AppState())
        }
    }
    return PreviewHost()
}
