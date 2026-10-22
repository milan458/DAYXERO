import Foundation
import RevenueCat

/// RevenueCat plumbing (S1.6). Prices come from RevenueCat offerings, never hard-coded.
@MainActor
final class Subscriptions {
    static let shared = Subscriptions()

    /// Entitlement that unlocks the full program.
    static let entitlement = "pro"

    enum Plan: String, CaseIterable {
        case monthly = "dayxero.monthly"
        case annual = "dayxero.annual"
        case lifetime = "dayxero.lifetime"
    }

    private(set) var isConfigured = false

    private init() {}

    /// Configures RevenueCat when an API key is present in Info.plist (DXRevenueCatAPIKey).
    /// Without a key (local builds, CI) purchases are simply unavailable.
    func configure() {
        guard !isConfigured,
              let key = Bundle.main.object(forInfoDictionaryKey: "DXRevenueCatAPIKey") as? String,
              !key.isEmpty
        else { return }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: key)
        isConfigured = true
    }

    func hasPro() async -> Bool {
        guard isConfigured else { return false }
        let info = try? await Purchases.shared.customerInfo()
        return info?.entitlements[Self.entitlement]?.isActive == true
    }

    func currentOffering() async throws -> Offering? {
        guard isConfigured else { return nil }
        return try await Purchases.shared.offerings().current
    }

    func purchase(_ package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        return !result.userCancelled && result.customerInfo.entitlements[Self.entitlement]?.isActive == true
    }

    /// Restore purchases (also offered in Settings, S15.2).
    func restore() async throws -> Bool {
        guard isConfigured else { return false }
        let info = try await Purchases.shared.restorePurchases()
        return info.entitlements[Self.entitlement]?.isActive == true
    }
}
