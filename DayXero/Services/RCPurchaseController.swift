// From Superwall's RevenueCat example (Superwall-iOS, Examples/Advanced, MIT licence, © Nest22), as their
// RevenueCat guide asks: copied rather than hand-rolled. RevenueCat stays the source of truth for purchases (S20).

import Combine
import RevenueCat
import StoreKit
import SuperwallKit

enum PurchasingError: LocalizedError {
    case sk2ProductNotFound

    var errorDescription: String? {
        switch self {
        case .sk2ProductNotFound:
            "Superwall didn't pass a StoreKit 2 product to purchase. Are you sure you're not "
                + "configuring Superwall with a SuperwallOption to use StoreKit 1?"
        }
    }
}

/// Buys and restores through RevenueCat for Superwall's paywalls, and keeps Superwall's subscription status in step
/// with RevenueCat's entitlements (plus any web entitlements Superwall holds). Main-actor isolated, like
/// Superwall's `PurchaseController` requirements.
@MainActor
final class RCPurchaseController: PurchaseController {
    // MARK: Sync subscription status

    /// Call once, after both Superwall and RevenueCat are configured.
    func syncSubscriptionStatus() {
        assert(Purchases.isConfigured, "You must configure RevenueCat before calling this method.")

        // RevenueCat customer info changes.
        Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                let rcEntitlements = Set(customerInfo.entitlements.activeInCurrentEnvironment.keys.map { SuperwallKit.Entitlement(id: $0) })
                updateSubscriptionStatus(with: rcEntitlements)
            }
        }

        // Superwall customer info changes (web entitlements).
        Task {
            for await _ in Superwall.shared.customerInfoStream {
                guard let currentRCCustomerInfo = try? await Purchases.shared.customerInfo() else { continue }
                let rcEntitlements = Set(currentRCCustomerInfo.entitlements.activeInCurrentEnvironment.keys.map { SuperwallKit.Entitlement(id: $0) })
                updateSubscriptionStatus(with: rcEntitlements)
            }
        }
    }

    /// Merges RevenueCat's entitlements with Superwall's web entitlements. An empty set reads as inactive.
    /// (DayXero has its own `Entitlement`, hence the module prefix.)
    private func updateSubscriptionStatus(with rcEntitlements: Set<SuperwallKit.Entitlement>) {
        let webEntitlements = Superwall.shared.entitlements.web
        Superwall.shared.subscriptionStatus = .active(rcEntitlements.union(webEntitlements))
    }

    // MARK: Purchases

    func purchase(product: SuperwallKit.StoreProduct) async -> PurchaseResult {
        do {
            guard let sk2Product = product.sk2Product else { throw PurchasingError.sk2ProductNotFound }
            let storeProduct = RevenueCat.StoreProduct(sk2Product: sk2Product)
            let revenueCatResult = try await Purchases.shared.purchase(product: storeProduct)
            return revenueCatResult.userCancelled ? .cancelled : .purchased
        } catch let error as ErrorCode {
            return error == .paymentPendingError ? .pending : .failed(error)
        } catch {
            return .failed(error)
        }
    }

    // MARK: Restores

    func restorePurchases() async -> RestorationResult {
        do {
            _ = try await Purchases.shared.restorePurchases()
            return .restored
        } catch {
            return .failed(error)
        }
    }
}
