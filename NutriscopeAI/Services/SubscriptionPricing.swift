import Foundation

/// Fallback copy when StoreKit products are not loaded yet (simulator / pre-ASC setup).
enum SubscriptionPricing {
    static var monthlyFallback: String { "—" }
    static var yearlyFallback: String { "—" }
}

enum PaywallPlanChoice: Equatable {
    case yearly
    case monthly

    var subscriptionPlan: SubscriptionPlan {
        switch self {
        case .yearly: .yearly
        case .monthly: .monthly
        }
    }
}
