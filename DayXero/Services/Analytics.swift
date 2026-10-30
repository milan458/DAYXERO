import Foundation
import PostHog

/// Analytics events (S1.5), sent to PostHog.
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
    // Program v2 (handoff 8): IDs and buckets only; never answers, reasons or how someone felt.
    case programSessionUnlocked(sessionId: String)
    case programSessionStarted(sessionId: String, variant: String)
    case programAudioProgress(sessionId: String, bucket: Int)
    case programBeatCompleted(sessionId: String, beatId: String, type: String, skipped: Bool)
    case programQuizAnswered(beatId: String, firstTryCorrect: Bool)
    case programSessionCompleted(sessionId: String, minutesBucket: String)
    case programMissionFollowupDone(sessionId: String)
    case programGraduated(daysSinceQuit: Int)
    case programReplayStarted(sessionId: String)
    case sosTrackPlayed(trackId: String, completed: Bool)
    // Cravings and slips
    case cravingSessionStarted(source: String)
    case cravingSessionEnded(outcome: String, seconds: Int)
    case slipLogged(source: String)
    // Sharing
    case shareCardCreated(milestone: String)
    case shareCardShared(destination: String)

    /// Water (handoff B7): the goal as a bucket only; never height or weight.
    case waterGoalSet(source: String, goalBucket: String)
    case waterLogged(source: String, drink: String)
    case waterGoalMet
    /// Settings (S18.17): the currency code only.
    case currencyChanged(code: String)
    /// A Superwall paywall or purchase event (S20), by Superwall's own name, e.g. "paywall_open".
    case superwallEvent(name: String)

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
        case .programSessionUnlocked: "program_session_unlocked"
        case .programSessionStarted: "program_session_started"
        case .programAudioProgress: "program_audio_progress"
        case .programBeatCompleted: "program_beat_completed"
        case .programQuizAnswered: "program_quiz_answered"
        case .programSessionCompleted: "program_session_completed"
        case .programMissionFollowupDone: "program_mission_followup_done"
        case .programGraduated: "program_graduated"
        case .programReplayStarted: "program_replay_started"
        case .sosTrackPlayed: "sos_track_played"
        case .cravingSessionStarted: "craving_session_started"
        case .cravingSessionEnded: "craving_session_ended"
        case .slipLogged: "slip_logged"
        case .shareCardCreated: "share_card_created"
        case .shareCardShared: "share_card_shared"
        case .waterGoalSet: "water_goal_set"
        case .waterLogged: "water_logged"
        case .waterGoalMet: "water_goal_met"
        case .currencyChanged: "currency_changed"
        case .superwallEvent: "superwall_event"
        }
    }

    /// Properties never include free text the user typed (reasons, notes) or anything health-identifying beyond the event.
    var properties: [String: String] {
        switch self {
        case let .onboardingStepViewed(step), let .onboardingStepSkipped(step): ["step": step]
        case let .paywallPlanSelected(plan), let .paywallPurchased(plan): ["plan": plan]
        case let .purchasesRestored(success): ["success": String(success)]
        case let .programDayStarted(day), let .programDayCompleted(day): ["day": day]
        case let .programSessionUnlocked(id), let .programMissionFollowupDone(id), let .programReplayStarted(id): ["session_id": id]
        case let .programSessionStarted(id, variant): ["session_id": id, "variant": variant]
        case let .programAudioProgress(id, bucket): ["session_id": id, "bucket": String(bucket)]
        case let .programBeatCompleted(id, beat, type, skipped): ["session_id": id, "beat_id": beat, "type": type, "skipped": String(skipped)]
        case let .programQuizAnswered(beat, correct): ["beat_id": beat, "first_try_correct": String(correct)]
        case let .programSessionCompleted(id, minutes): ["session_id": id, "minutes": minutes]
        case let .programGraduated(days): ["days_since_quit": String(days)]
        case let .sosTrackPlayed(track, completed): ["track_id": track, "completed": String(completed)]
        case let .cravingSessionStarted(source), let .slipLogged(source): ["source": source]
        case let .cravingSessionEnded(outcome, seconds): ["outcome": outcome, "seconds": String(seconds)]
        case let .shareCardCreated(milestone): ["milestone": milestone]
        case let .shareCardShared(destination): ["destination": destination]
        case let .waterGoalSet(source, goalBucket): ["source": source, "goal_bucket": goalBucket]
        case let .waterLogged(source, drink): ["source": source, "drink": drink]
        case let .currencyChanged(code): ["code": code]
        case let .superwallEvent(name): ["event": name]
        case .onboardingCompleted, .paywallViewed, .paywallDismissed, .waterGoalMet: [:]
        }
    }
}

@MainActor
enum Analytics {
    private static var isConfigured = false

    /// Sets up PostHog when an API key is present in Info.plist (DXPostHogAPIKey).
    /// Without a key (local builds, CI) events are only printed in debug builds.
    /// Only the explicit events above are sent: no autocapture, no screen views, no session replay.
    static func configure() {
        guard !isConfigured,
              let key = Bundle.main.object(forInfoDictionaryKey: "DXPostHogAPIKey") as? String,
              !key.isEmpty
        else { return }
        let host = (Bundle.main.object(forInfoDictionaryKey: "DXPostHogHost") as? String)
            .flatMap { $0.isEmpty ? nil : $0 } ?? "https://us.i.posthog.com"
        let config = PostHogConfig(projectToken: key, host: host)
        config.captureScreenViews = false
        config.captureApplicationLifecycleEvents = true
        PostHogSDK.shared.setup(config)
        // Nothing at all is sent, lifecycle events included, until there's consent (S15.4).
        if !AnalyticsConsent.isOn { PostHogSDK.shared.optOut() }
        isConfigured = true
    }

    /// Minutes as a coarse bucket, so a session's length never pins down a person.
    static func minutesBucket(_ minutes: Int) -> String {
        switch minutes {
        case ..<3: "0-2"
        case ..<6: "3-5"
        case ..<11: "6-10"
        case ..<31: "11-30"
        default: "30+"
        }
    }

    static func track(_ event: AnalyticsEvent) {
        #if DEBUG
        print("[analytics] \(event.name) \(event.properties)")
        #endif
        guard isConfigured, AnalyticsConsent.isOn else { return }
        PostHogSDK.shared.capture(event.name, properties: event.properties)
    }
}

/// Anonymous usage data consent (S15.4, Milan's rule): off until people opt in for the EU and EEA, on elsewhere.
/// Changeable any time in Settings → Privacy.
enum AnalyticsConsent {
    static let key = "dx.analyticsConsent"
    /// EU member states plus Iceland, Liechtenstein and Norway.
    static let optInRegions: Set<String> = [
        "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT",
        "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "IS", "LI", "NO",
    ]

    static func defaultValue(region: String?) -> Bool {
        !optInRegions.contains(region?.uppercased() ?? "")
    }

    static var isOn: Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? defaultValue(region: Locale.current.region?.identifier)
    }

    @MainActor
    static func set(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: key)
        if on { PostHogSDK.shared.optIn() } else { PostHogSDK.shared.optOut() }
    }
}
