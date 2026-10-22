import Foundation

/// Analytics events (S1.5). The provider (PostHog or Mixpanel) is still Milan's call,
/// so events go through `Analytics.track` and are only logged in debug builds until then.
enum AnalyticsEvent {
    // Onboarding funnel (S2.13): one event per screen, plus skips.
    case onboardingStepViewed(step: String)
    case onboardingStepSkipped(step: String)
    case onboardingCompleted
    // Paywall
    case paywallViewed
    case paywallPlanSelected(plan: String)
    case paywallPurchased(plan: String)
    case paywallDismissed
    case purchasesRestored(success: Bool)
    // Program
    case programDayStarted(day: String)
    case programDayCompleted(day: String)
    // Cravings and slips
    case cravingSessionStarted(source: String)
    case cravingSessionEnded(outcome: String, seconds: Int)
    case slipLogged(source: String)
    // Sharing
    case shareCardCreated(milestone: String)
    case shareCardShared(destination: String)

    var name: String {
        switch self {
        case .onboardingStepViewed: "onboarding_step_viewed"
        case .onboardingStepSkipped: "onboarding_step_skipped"
        case .onboardingCompleted: "onboarding_completed"
        case .paywallViewed: "paywall_viewed"
        case .paywallPlanSelected: "paywall_plan_selected"
        case .paywallPurchased: "paywall_purchased"
        case .paywallDismissed: "paywall_dismissed"
        case .purchasesRestored: "purchases_restored"
        case .programDayStarted: "program_day_started"
        case .programDayCompleted: "program_day_completed"
        case .cravingSessionStarted: "craving_session_started"
        case .cravingSessionEnded: "craving_session_ended"
        case .slipLogged: "slip_logged"
        case .shareCardCreated: "share_card_created"
        case .shareCardShared: "share_card_shared"
        }
    }

    /// Properties never include free text the user typed (reasons, notes) or anything health-identifying beyond the event.
    var properties: [String: String] {
        switch self {
        case let .onboardingStepViewed(step), let .onboardingStepSkipped(step): ["step": step]
        case let .paywallPlanSelected(plan), let .paywallPurchased(plan): ["plan": plan]
        case let .purchasesRestored(success): ["success": String(success)]
        case let .programDayStarted(day), let .programDayCompleted(day): ["day": day]
        case let .cravingSessionStarted(source), let .slipLogged(source): ["source": source]
        case let .cravingSessionEnded(outcome, seconds): ["outcome": outcome, "seconds": String(seconds)]
        case let .shareCardCreated(milestone): ["milestone": milestone]
        case let .shareCardShared(destination): ["destination": destination]
        case .onboardingCompleted, .paywallViewed, .paywallDismissed: [:]
        }
    }
}

enum Analytics {
    static func track(_ event: AnalyticsEvent) {
        #if DEBUG
        print("[analytics] \(event.name) \(event.properties)")
        #endif
    }
}
