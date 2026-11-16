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
    case quarterly = "dayxero.quarterly"
    /// No longer sold (16 Nov 2026); kept so someone who bought one still sees their plan in Settings.
    case monthly = "dayxero.monthly"
    /// No longer sold (16 Nov 2026); kept so someone who bought one still sees their plan in Settings.
    case lifetime = "dayxero.lifetime"

    /// What the paywalls sell: yearly with the free trial, and 3 months.
    static let offered: [Plan] = [.annual, .quarterly]
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
    /// The active plan for Settings (S15.2), or nil when there isn't one.
    func currentPlan() async -> CurrentPlan?
    /// When the free trial ends, while the person is in one; nil once they've paid or without a subscription.
    func trialEnd() async -> Date?
}

extension PurchaseStore {
    func currentPlan() async -> CurrentPlan? { nil }
    func trialEnd() async -> Date? { nil }
}

/// What Settings shows about the person's subscription.
struct CurrentPlan: Equatable, Sendable {
    let plan: Plan
    /// Renewal or end date; nil for lifetime.
    let renews: Date?
    let willRenew: Bool
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

    func currentPlan() async -> CurrentPlan? {
        guard isConfigured, let info = try? await Purchases.shared.customerInfo(),
              let pro = info.entitlements[Self.entitlement], pro.isActive,
              let plan = Plan(rawValue: pro.productIdentifier) else { return nil }
        return CurrentPlan(plan: plan, renews: pro.expirationDate, willRenew: pro.willRenew)
    }

    func trialEnd() async -> Date? {
        guard isConfigured, let info = try? await Purchases.shared.customerInfo(),
              let pro = info.entitlements[Self.entitlement], pro.isActive, pro.periodType == .trial else { return nil }
        return pro.expirationDate
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
/// Stand-in store for previews and CI screenshots (`-dx.store mock|failing|slow|pro|trial`).
@MainActor
final class MockStore: PurchaseStore {
    /// `trial` is someone two days into the free trial.
    enum Mode: String { case mock, failing, slow, pro, trial }
    let mode: Mode
    /// What was bought this launch, and when, so a refresh keeps it like the real store would.
    private var bought: (plan: Plan, at: Date)?

    init(mode: Mode) {
        self.mode = mode
    }

    func loadPlans() async throws -> [PlanOption] {
        if mode == .slow { try await Task.sleep(for: .seconds(60)) }
        if mode == .failing { throw StoreError.unavailable }
        return [
            PlanOption(plan: .annual, price: 39.99, currencyCode: "USD", priceText: "$39.99", perMonthText: "$3.33", trialDays: 3),
            PlanOption(plan: .quarterly, price: 19.99, currencyCode: "USD", priceText: "$19.99", perMonthText: nil, trialDays: nil),
        ]
    }

    func purchase(_ plan: Plan) async throws -> PurchaseOutcome {
        bought = (plan, .now)
        return .purchased
    }
    func restore() async throws -> Bool { false }
    func hasPro() async -> Bool { mode == .pro || mode == .trial || bought != nil }
    func currentPlan() async -> CurrentPlan? {
        switch mode {
        case .pro:
            return CurrentPlan(plan: .annual, renews: Calendar.current.date(byAdding: .year, value: 1, to: .now), willRenew: true)
        case .trial:
            let end = await trialEnd()
            return CurrentPlan(plan: .annual, renews: end, willRenew: true)
        default:
            return nil
        }
    }
    func trialEnd() async -> Date? {
        if mode == .trial { return Calendar.current.date(byAdding: .day, value: 1, to: .now) }
        guard let bought, bought.plan == .annual else { return nil }
        return Calendar.current.date(byAdding: .day, value: 3, to: bought.at)
    }
}
#endif
