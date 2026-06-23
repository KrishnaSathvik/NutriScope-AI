import Foundation
import Observation
import SwiftUI

enum AppSheet: Identifiable {
    case scan
    case paywall
    case scanQuota
    case subscriptionSuccess
    case saveProgress

    var id: String {
        switch self {
        case .scan: "scan"
        case .paywall: "paywall"
        case .scanQuota: "scanQuota"
        case .subscriptionSuccess: "subscriptionSuccess"
        case .saveProgress: "saveProgress"
        }
    }
}

@Observable
@MainActor
final class AppState {
    private static let onboardingKey = "hasCompletedOnboarding"

    var activeSheet: AppSheet?
    var pendingAnalysis: MealAnalysis?
    var selectedTab: AppTab = .today
    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Self.onboardingKey) }
    }

    /// When true, the next scan sheet opens with the keyboard ready for typing.
    var scanStartsInTextMode = false

    let quotaManager: ScanQuotaManager
    let subscriptionManager: SubscriptionManager

    init(
        quotaManager: ScanQuotaManager? = nil,
        subscriptionManager: SubscriptionManager? = nil
    ) {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        self.quotaManager = quotaManager ?? ScanQuotaManager()
        self.subscriptionManager = subscriptionManager ?? SubscriptionManager()
    }

    func mealAnalysisService() -> any MealAnalysisServiceProtocol {
        MealAnalysisServiceFactory.make(hasProAccess: hasProAccess)
    }

    var hasProAccess: Bool {
        subscriptionManager.isSubscribed
    }

    func presentScanIfAllowed() {
        Task { @MainActor in
            try? await BackendAuthBootstrap.ensureBackendSession()
            if quotaManager.canScan(isSubscribed: hasProAccess) {
                scanStartsInTextMode = false
                activeSheet = .scan
            } else {
                activeSheet = .scanQuota
            }
        }
    }

    func presentPaywall() {
        activeSheet = .paywall
    }

    func consumeScanIfNeeded() {
        guard !hasProAccess else { return }
        quotaManager.consumeScan()
    }

    func showSubscriptionSuccess() {
        activeSheet = .subscriptionSuccess
    }

    /// After StoreKit purchase/restore — refresh entitlements first, then celebrate. Pro access is live before any signup prompt.
    func completePurchaseSuccess() async {
        await subscriptionManager.refreshEntitlements()
        guard subscriptionManager.isSubscribed else { return }
        activeSheet = .subscriptionSuccess
    }

    func promptSaveProgressIfNeeded() {
        guard !AuthSessionManager.isSignedIn else { return }
        activeSheet = .saveProgress
    }

    func restorePurchases() async -> Bool {
        await subscriptionManager.restore()
        await subscriptionManager.refreshEntitlements()
        return subscriptionManager.isSubscribed
    }
}
