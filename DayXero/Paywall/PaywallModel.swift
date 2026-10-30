import DayXeroCore
import Foundation
import Observation
import UserNotifications

/// Whether the person has the full program. Checked at launch and after any purchase or restore.
@MainActor
@Observable
final class Entitlement {
    /// Bought, restored or in the trial.
    private(set) var purchased = false
    /// Demo mode unlocks everything without a purchase (TestFlight and debug builds only).
    private(set) var demo = DemoMode.isOn
    let store: PurchaseStore

    var isPro: Bool { purchased || demo }

    init(store: PurchaseStore) {
        self.store = store
    }

    func refresh() async {
        purchased = await store.hasPro()
    }

    func grant() {
        purchased = true
    }

    func setDemo(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: DemoMode.key)
        demo = DemoMode.isOn
    }
}

@MainActor
@Observable
final class PaywallModel {
    enum Phase: Equatable {
        case loading
        case failed
        case ready
        case purchasing
        case pending
        case unlocked
    }

    private(set) var phase: Phase = .loading
    private(set) var plans: [PlanOption] = []
    var selected: Plan = .annual
    /// Banner text after a restore that found nothing, or a purchase error.
    var notice: LocalizedStringResource?
    /// Whether we can keep the "we'll remind you" promise (notifications allowed or not yet asked).
    private(set) var canRemind = true

    private let store: PurchaseStore
    private let entitlement: Entitlement
    private let calendar: Calendar
    private let now: () -> Date

    init(store: PurchaseStore, entitlement: Entitlement, calendar: Calendar = .current, now: @escaping () -> Date = { .now }) {
        self.store = store
        self.entitlement = entitlement
        self.calendar = calendar
        self.now = now
    }

    var selectedOption: PlanOption? { plans.first { $0.plan == selected } }

    /// When a trial on the selected plan ends and the first charge happens.
    var trialEndDate: Date? {
        guard let days = selectedOption?.trialDays else { return nil }
        return calendar.date(byAdding: .day, value: days, to: now())
    }

    /// Yearly's saving against twelve months of monthly, only when it's a real saving in this region.
    var annualSavingPercent: Int? {
        guard let annual = plans.first(where: { $0.plan == .annual }),
              let monthly = plans.first(where: { $0.plan == .monthly }),
              monthly.price > 0 else { return nil }
        let yearOfMonthly = NSDecimalNumber(decimal: monthly.price * 12).doubleValue
        let saving = 1 - NSDecimalNumber(decimal: annual.price).doubleValue / yearOfMonthly
        let percent = Int((saving * 100).rounded(.down))
        return percent >= 5 ? percent : nil
    }

    /// - Parameter trackView: false when only the prices are wanted (the trial screen before the paywall).
    func load(trackView: Bool = true) async {
        phase = .loading
        if trackView { Analytics.track(.paywallViewed) }
        do {
            plans = try await store.loadPlans()
            if !plans.contains(where: { $0.plan == selected }), let first = plans.first { selected = first.plan }
            phase = .ready
        } catch {
            phase = .failed
        }
        #if DEBUG
        applyDebugOverrides()
        #endif
        canRemind = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus != .denied
    }

    #if DEBUG
    /// For screenshots: `-dx.paywallPlan monthly|lifetime` and `-dx.paywallPhase unlocked|pending`.
    func applyDebugOverrides() {
        let defaults = UserDefaults.standard
        if let plan = defaults.string(forKey: "dx.paywallPlan").flatMap({ raw in Plan.allCases.first { "\($0)" == raw } }) {
            selected = plan
        }
        switch defaults.string(forKey: "dx.paywallPhase") {
        case "unlocked": phase = .unlocked
        case "pending": phase = .pending
        case "notice": notice = "No purchases found. Make sure you're signed in with the Apple ID you bought with."
        default: break
        }
    }
    #endif

    func select(_ plan: Plan) {
        selected = plan
        Analytics.track(.paywallPlanSelected(plan: plan.rawValue))
    }

    func purchase() async {
        guard let option = selectedOption else { return }
        phase = .purchasing
        notice = nil
        do {
            switch try await store.purchase(option.plan) {
            case .purchased:
                entitlement.grant()
                if let end = trialEndDate, TrialReminder.wanted {
                    await TrialReminder.schedule(trialEndsAt: end, price: option.priceText, now: now())
                }
                Analytics.track(.paywallPurchased(plan: option.plan.rawValue))
                phase = .unlocked
            case .pending:
                phase = .pending
            case .cancelled:
                phase = .ready
            }
        } catch {
            notice = "The purchase didn't go through. You haven't been charged."
            phase = .ready
        }
    }

    func restore() async {
        notice = nil
        do {
            let found = try await store.restore()
            Analytics.track(.purchasesRestored(success: found))
            if found {
                entitlement.grant()
                phase = .unlocked
            } else {
                notice = "No purchases found. Make sure you're signed in with the Apple ID you bought with."
            }
        } catch {
            notice = "Couldn't reach the App Store. Check your connection and try again."
        }
    }

    func dismissed() {
        Analytics.track(.paywallDismissed)
    }
}

/// The reminder before a free trial ends (S22: two days before, as the trial screen promises).
enum TrialReminder {
    static let identifier = "trial-reminder"
    /// Whether they kept "Remind me 2 days before my trial ends" on. On unless they turned it off.
    static let wantedKey = "dx.trialReminder"

    static var wanted: Bool { UserDefaults.standard.object(forKey: wantedKey) as? Bool ?? true }

    /// Days before the end the reminder comes: two, or one for a trial too short for that.
    static func leadDays(trialEndsAt end: Date, now: Date, calendar: Calendar = .current) -> Int {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: end)).day ?? 0
        return days >= 3 ? 2 : 1
    }

    static func schedule(trialEndsAt end: Date, price: String, now: Date = .now, calendar: Calendar = .current) async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        if status == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
        let lead = leadDays(trialEndsAt: end, now: now, calendar: calendar)
        guard let remindOn = calendar.date(byAdding: .day, value: -lead, to: end) else { return }
        var components = calendar.dateComponents([.year, .month, .day], from: remindOn)
        components.hour = 10
        let content = UNMutableNotificationContent()
        content.title = lead == 2 ? String(localized: "Your free trial ends in 2 days") : String(localized: "Your free trial ends tomorrow")
        content.body = String(localized: "You'll be charged \(price) for a year on \(end.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))) unless you cancel. Cancel in Settings › Apple ID › Subscriptions.")
        let request = UNNotificationRequest(identifier: identifier, content: content,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
        try? await center.add(request)
    }
}
