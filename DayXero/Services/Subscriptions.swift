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
    /// The usual yearly price, e.g. "$39.99", when today's yearly row is the day 4 / day 6 offer (BET-1); nil otherwise.
    var regularPriceText: String? = nil

    var id: String { plan.rawValue }
    /// The yearly row is today's offer.
    var isOffer: Bool { regularPriceText != nil }
}

/// Product identifiers, as set up in App Store Connect and RevenueCat.
enum Plan: String, CaseIterable, Sendable {
    case annual = "dayxero.annual"
    case monthly = "dayxero.monthly"
    case lifetime = "dayxero.lifetime"

    /// The yearly plan at the offer price ($29.99 with the same 7-day trial, renewing at $29.99; India ₹2,249), sold on
    /// days 4 and 6 after download (BET-1). Same subscription group and `pro` entitlement as `annual`; it shows as Yearly.
    static let annualOfferProductId = "dayxero.annual.offer"

    /// The plan a store product belongs to; the offer counts as Yearly.
    init?(productId: String) {
        if productId == Self.annualOfferProductId { self = .annual; return }
        self.init(rawValue: productId)
    }
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
    /// - Parameter offer: today is an offer day, so the yearly row is the offer product when the store has it.
    func loadPlans(offer: Bool) async throws -> [PlanOption]
    func purchase(_ plan: Plan) async throws -> PurchaseOutcome
    /// True when a restore found an active purchase.
    func restore() async throws -> Bool
    func hasPro() async -> Bool
    /// The active plan for Settings (S15.2), or nil when there isn't one.
    func currentPlan() async -> CurrentPlan?
}

extension PurchaseStore {
    func currentPlan() async -> CurrentPlan? { nil }
    func loadPlans() async throws -> [PlanOption] { try await loadPlans(offer: false) }
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

    func loadPlans(offer: Bool) async throws -> [PlanOption] {
        guard isConfigured else { throw StoreError.unavailable }
        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.current else { throw StoreError.noPlans }
        var options: [PlanOption] = []
        packages = [:]
        for package in offering.availablePackages {
            let product = package.storeProduct
            guard let plan = Plan(rawValue: product.productIdentifier) else { continue }
            packages[plan] = package
            options.append(Self.option(plan, product))
        }
        // On an offer day the yearly row is the offer product, from whichever offering carries it. Until it's set up
        // in App Store Connect and RevenueCat, the regular yearly plan shows as usual.
        if offer, let regular = options.firstIndex(where: { $0.plan == .annual }),
           let package = offerings.all.values.flatMap(\.availablePackages)
               .first(where: { $0.storeProduct.productIdentifier == Plan.annualOfferProductId }) {
            packages[.annual] = package
            var option = Self.option(.annual, package.storeProduct)
            option.regularPriceText = options[regular].priceText
            options[regular] = option
        }
        guard !options.isEmpty else { throw StoreError.noPlans }
        return Plan.allCases.compactMap { plan in options.first { $0.plan == plan } }
    }

    private static func option(_ plan: Plan, _ product: StoreProduct) -> PlanOption {
        PlanOption(
            plan: plan,
            price: product.price,
            currencyCode: product.currencyCode ?? "USD",
            priceText: product.localizedPriceString,
            perMonthText: plan == .annual ? product.localizedPricePerMonth : nil,
            trialDays: trialDays(product.introductoryDiscount)
        )
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
              let plan = Plan(productId: pro.productIdentifier) else { return nil }
        return CurrentPlan(plan: plan, renews: pro.expirationDate, willRenew: pro.willRenew)
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

    func loadPlans(offer: Bool) async throws -> [PlanOption] {
        if mode == .slow { try await Task.sleep(for: .seconds(60)) }
        if mode == .failing { throw StoreError.unavailable }
        return [
            offer
                ? PlanOption(plan: .annual, price: 29.99, currencyCode: "USD", priceText: "$29.99", perMonthText: "$2.50", trialDays: 7,
                             regularPriceText: "$39.99")
                : PlanOption(plan: .annual, price: 39.99, currencyCode: "USD", priceText: "$39.99", perMonthText: "$3.33", trialDays: 7),
            PlanOption(plan: .monthly, price: 9.99, currencyCode: "USD", priceText: "$9.99", perMonthText: nil, trialDays: nil),
            PlanOption(plan: .lifetime, price: 99.99, currencyCode: "USD", priceText: "$99.99", perMonthText: nil, trialDays: nil),
        ]
    }

    func purchase(_ plan: Plan) async throws -> PurchaseOutcome { .purchased }
    func restore() async throws -> Bool { false }
    func hasPro() async -> Bool { mode == .pro }
    func currentPlan() async -> CurrentPlan? {
        mode == .pro ? CurrentPlan(plan: .annual, renews: Calendar.current.date(byAdding: .year, value: 1, to: .now), willRenew: true) : nil
    }
}
#endif
