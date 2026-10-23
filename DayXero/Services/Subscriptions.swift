import Foundation
import RevenueCat

/// One purchasable plan as the paywall shows it. Every figure comes from the App Store via RevenueCat.
struct PlanOption: Identifiable, Equatable, Sendable {
    let plan: Plan
    let price: Decimal
    let currencyCode: String
    /// Localised, e.g. "$39.99".
    let priceText: String
    /// Localised per-month equivalent for yearly, e.g. "$3.33".
    let perMonthText: String?
    /// Free-trial length, when the App Store offers this person a trial.
    let trialDays: Int?

    var id: String { plan.rawValue }
}

/// Product identifiers, as set up in App Store Connect and RevenueCat.
enum Plan: String, CaseIterable, Sendable {
    case annual = "dayxero.annual"
    case monthly = "dayxero.monthly"
    case lifetime = "dayxero.lifetime"
}

enum PurchaseOutcome: Equatable, Sendable {
    case purchased
    case cancelled
    /// Waiting on approval, e.g. Ask to Buy.
    case pending
}

enum StoreError: Error {
    /// No API key (local and CI builds) or RevenueCat isn't configured.
    case unavailable
    case noPlans
}

/// The paywall talks to this, so previews, tests and screenshots can use a stand-in store.
@MainActor
protocol PurchaseStore: AnyObject {
    func loadPlans() async throws -> [PlanOption]
    func purchase(_ plan: Plan) async throws -> PurchaseOutcome
    /// True when a restore found an active purchase.
    func restore() async throws -> Bool
    func hasPro() async -> Bool
}

/// RevenueCat plumbing (S1.6, S3.6).
@MainActor
final class Subscriptions: PurchaseStore {
    static let shared = Subscriptions()

    /// Entitlement that unlocks the full program.
    static let entitlement = "pro"

    private(set) var isConfigured = false
    private var packages: [Plan: Package] = [:]

    private init() {}

    /// Configures RevenueCat when an API key is present in Info.plist (DXRevenueCatAPIKey).
    /// Without a key (local builds, CI) purchases are unavailable and the paywall shows its error state.
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

    func loadPlans() async throws -> [PlanOption] {
        guard isConfigured else { throw StoreError.unavailable }
        guard let offering = try await Purchases.shared.offerings().current else { throw StoreError.noPlans }
        var options: [PlanOption] = []
        packages = [:]
        for package in offering.availablePackages {
            let product = package.storeProduct
            guard let plan = Plan(rawValue: product.productIdentifier) else { continue }
            packages[plan] = package
            options.append(PlanOption(
                plan: plan,
                price: product.price,
                currencyCode: product.currencyCode ?? "USD",
                priceText: product.localizedPriceString,
                perMonthText: plan == .annual ? product.localizedPricePerMonth : nil,
                trialDays: Self.trialDays(product.introductoryDiscount)
            ))
        }
        guard !options.isEmpty else { throw StoreError.noPlans }
        return Plan.allCases.compactMap { plan in options.first { $0.plan == plan } }
    }

    func purchase(_ plan: Plan) async throws -> PurchaseOutcome {
        guard let package = packages[plan] else { throw StoreError.unavailable }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return .cancelled }
            return result.customerInfo.entitlements[Self.entitlement]?.isActive == true ? .purchased : .pending
        } catch let error as ErrorCode where error == .paymentPendingError {
            return .pending
        } catch let error as ErrorCode where error == .purchaseCancelledError {
            return .cancelled
        }
    }

    /// Restore purchases (also offered in Settings, S15.2).
    func restore() async throws -> Bool {
        guard isConfigured else { throw StoreError.unavailable }
        let info = try await Purchases.shared.restorePurchases()
        return info.entitlements[Self.entitlement]?.isActive == true
    }

    private static func trialDays(_ discount: StoreProductDiscount?) -> Int? {
        guard let discount, discount.paymentMode == .freeTrial else { return nil }
        let period = discount.subscriptionPeriod
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        @unknown default: return nil
        }
    }
}

#if DEBUG
/// Stand-in store for previews and CI screenshots (`-dx.store mock|failing`).
@MainActor
final class MockStore: PurchaseStore {
    enum Mode: String { case mock, failing, slow, pro }
    let mode: Mode

    init(mode: Mode) {
        self.mode = mode
    }

    func loadPlans() async throws -> [PlanOption] {
        if mode == .slow { try await Task.sleep(for: .seconds(60)) }
        if mode == .failing { throw StoreError.unavailable }
        return [
            PlanOption(plan: .annual, price: 39.99, currencyCode: "USD", priceText: "$39.99", perMonthText: "$3.33", trialDays: 3),
            PlanOption(plan: .monthly, price: 9.99, currencyCode: "USD", priceText: "$9.99", perMonthText: nil, trialDays: nil),
            PlanOption(plan: .lifetime, price: 79.99, currencyCode: "USD", priceText: "$79.99", perMonthText: nil, trialDays: nil),
        ]
    }

    func purchase(_ plan: Plan) async throws -> PurchaseOutcome { .purchased }
    func restore() async throws -> Bool { false }
    func hasPro() async -> Bool { mode == .pro }
}
#endif
