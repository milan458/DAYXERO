import DayXeroCore
import Foundation
import RevenueCat
import SuperwallKit

/// Superwall (S20): paywalls run from the Superwall dashboard (app 58855), bought through RevenueCat.
///
/// Each paywall moment registers a placement. When a campaign shows a paywall there, Superwall presents it; when
/// none does (no campaign or audience, a holdout, offline, an error), or Superwall isn't running at all (tests,
/// screenshots, builds without a key), DayXero's own paywall shows exactly as before (Milan, 28 Oct).
@MainActor
enum Paywalls {
    /// Placement names are routing keys shared with dashboard campaigns: never rename one.
    enum Placement: String {
        /// The end of onboarding, where the full paywall shows once (S3.1).
        case onboardingComplete = "onboarding_complete"
        /// A program day that's part of the full program (S3.5, S5.9).
        case unlockProgramDay = "unlock_program_day"
        /// "Unlock the full program" in Settings › DayXero Pro (S15.2).
        case upgradeFromSettings = "upgrade_from_settings"
    }

    enum Outcome {
        /// They bought or restored on Superwall's paywall.
        case unlocked
        /// They closed Superwall's paywall without buying.
        case closed
        /// Superwall had nothing to show: show DayXero's own paywall.
        case fallback
    }

    private(set) static var isEnabled = false
    private static let purchaseController = RCPurchaseController()
    private static let events = PaywallEvents()

    /// Configures Superwall, once, before RevenueCat. Skipped without a key and whenever a stand-in store is in use.
    static func configure(usingStandInStore: Bool) {
        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        guard !isEnabled, !isTesting, !usingStandInStore,
              let key = Bundle.main.object(forInfoDictionaryKey: "DXSuperwallAPIKey") as? String,
              key.hasPrefix("pk_")
        else { return }
        Superwall.configure(apiKey: key, purchaseController: purchaseController)
        Superwall.shared.delegate = events
        isEnabled = true
    }

    /// Keeps Superwall's subscription status in step with RevenueCat's. Call once RevenueCat is configured;
    /// until then Superwall's status is unknown and it won't present.
    static func syncWithRevenueCat() {
        guard isEnabled, Purchases.isConfigured else { return }
        purchaseController.syncSubscriptionStatus()
    }

    /// Shows the placement's Superwall paywall, if a campaign has one for this person, and reports back once.
    static func present(_ placement: Placement, params: [String: Any] = [:], completion: @escaping (Outcome) -> Void) {
        guard isEnabled else {
            completion(.fallback)
            return
        }
        var reported = false
        let report: (Outcome) -> Void = { outcome in
            guard !reported else { return }
            reported = true
            completion(outcome)
        }
        let handler = PaywallPresentationHandler()
        handler.onSkip { _ in report(.fallback) }
        handler.onError { _ in report(.fallback) }
        handler.onDismiss { info, result in
            switch result {
            case .purchased, .restored: report(.unlocked)
            case .declined:
                // Another paywall follows; wait for that one.
                if info.closeReason == .forNextPaywall { return }
                // A gated paywall that couldn't load also reports an error; ours shows instead.
                if info.closeReason == .webViewFailedToLoad { report(.fallback) } else { report(.closed) }
            }
        }
        Superwall.shared.register(placement: placement.rawValue, params: params, handler: handler)
    }

    /// Paywall previews and web-checkout redemption links from the dashboard. True when Superwall took the link.
    static func handleDeepLink(_ url: URL) -> Bool {
        guard isEnabled else { return false }
        return Superwall.handleDeepLink(url)
    }

    /// What audience filters and paywall text can use. Plan facts only: no name, reasons or health details.
    static func setAttributes(for profile: UserProfile, now: Date = .now) {
        guard isEnabled else { return }
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: profile.products.map(\.baseline), clock: clock)
        let isPrep = stats.isPrep(at: now)
        Superwall.shared.setUserAttributes([
            "primary_product": profile.primaryProduct?.product.rawValue,
            "products": profile.products.map(\.product.rawValue).sorted().joined(separator: ","),
            "quit_day": clock.startOfDate(profile.quitDay),
            "phase": isPrep ? "prep" : "quit",
            "days_to_quit_day": isPrep ? stats.daysUntilQuitDay(at: now) : 0,
            "days_clear": stats.daysClear(at: now),
            "nrt_interest": profile.nrtInterest?.rawValue,
            "currency": profile.currencyCode,
        ])
    }
}

/// Sends Superwall's paywall and purchase events to PostHog next to DayXero's own (S1.5).
private final class PaywallEvents: SuperwallDelegate {
    private static let forwarded: Set<String> = [
        "paywall_open", "paywall_close", "paywall_decline", "transaction_start", "transaction_complete",
        "transaction_abandon", "transaction_fail", "subscription_start", "freeTrial_start", "transaction_restore",
    ]

    @MainActor
    func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        let name = eventInfo.event.description
        guard Self.forwarded.contains(name) else { return }
        Analytics.track(.superwallEvent(name: name))
    }
}
