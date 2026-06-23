import Foundation
import Observation
import StoreKit

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }

    var productID: String {
        switch self {
        case .monthly: "com.nutriscopeai.pro.monthly"
        case .yearly: "com.nutriscopeai.pro.yearly"
        }
    }
}

@Observable
@MainActor
final class SubscriptionManager {
    var isSubscribed = false
    var isLoading = false
    var products: [Product] = []
    var errorMessage: String?

    private var transactionUpdatesTask: Task<Void, Never>?

    func product(for plan: SubscriptionPlan) -> Product? {
        products.first { $0.id == plan.productID }
    }

    func displayPrice(for plan: SubscriptionPlan) -> String {
        product(for: plan)?.displayPrice ?? SubscriptionPricing.monthlyFallback
    }

    func yearlyMonthlyEquivalentPrice() -> String? {
        guard let yearly = product(for: .yearly) else { return nil }
        let yearlyAmount = yearly.price
        guard yearlyAmount > 0 else { return yearly.displayPrice }
        let monthlyEquivalent = yearlyAmount / 12
        return yearly.priceFormatStyle.format(monthlyEquivalent)
    }

    func yearlySavingsPercent() -> Int? {
        guard let monthly = product(for: .monthly), let yearly = product(for: .yearly) else { return nil }
        let monthlyAnnual = monthly.price * 12
        guard monthlyAnnual > 0 else { return nil }
        let savings = ((monthlyAnnual - yearly.price) / monthlyAnnual) * 100
        return Int(NSDecimalNumber(decimal: savings).doubleValue.rounded())
    }

    func hasIntroductoryOffer(for plan: SubscriptionPlan) -> Bool {
        product(for: plan)?.subscription?.introductoryOffer != nil
    }

    func introductoryOfferDescription(for plan: SubscriptionPlan) -> String? {
        guard let offer = product(for: plan)?.subscription?.introductoryOffer else { return nil }
        switch offer.paymentMode {
        case .freeTrial:
            let period = offer.period
            return "\(period.value)-\(period.unit.localizedDescription) free trial"
        case .payAsYouGo, .payUpFront:
            return offer.displayPrice
        default:
            return nil
        }
    }

    func renewalDisclosure(for choice: PaywallPlanChoice) -> String {
        let plan = choice.subscriptionPlan
        guard let product = product(for: plan) else {
            return "Nutriscope Pro auto-renews until canceled in App Store settings."
        }

        if let intro = introductoryOfferDescription(for: plan) {
            return "\(intro), then \(product.displayPrice) until canceled in App Store settings."
        }
        return "Nutriscope Pro auto-renews at \(product.displayPrice) until canceled in App Store settings."
    }

    func startObservingTransactionUpdates() {
        guard transactionUpdatesTask == nil else { return }
        transactionUpdatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified = result {
                    await self.refreshEntitlements()
                }
            }
        }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: SubscriptionPlan.allCases.map(\.productID))
        } catch {
            errorMessage = "Could not load subscription products."
        }
    }

    func purchase(_ plan: SubscriptionPlan) async {
        guard let product = products.first(where: { $0.id == plan.productID }) else {
            errorMessage = "Subscription products are not available. Configure App Store Connect products first."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified = verification {
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        isSubscribed = false
        let activeIDs = Set(SubscriptionPlan.allCases.map(\.productID))
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if activeIDs.contains(transaction.productID) {
                    isSubscribed = true
                    return
                }
            }
        }
    }
}

private extension Product.SubscriptionPeriod.Unit {
    var localizedDescription: String {
        switch self {
        case .day: "day"
        case .week: "week"
        case .month: "month"
        case .year: "year"
        @unknown default: "period"
        }
    }
}
