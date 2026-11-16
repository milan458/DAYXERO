import DayXeroCore
import Foundation
import SwiftData
import Observation
import UserNotifications
import WidgetKit

/// Whether the person has the full program. Checked at launch and after any purchase or restore.
@MainActor
@Observable
final class Entitlement {
    /// Bought, restored or in the trial.
    private(set) var purchased = false
    /// When the free trial ends, while the person is in one. The trial opens Prep 1 to 3 only (16 Nov 2026).
    private(set) var trialEndsAt: Date?
    /// Demo mode unlocks everything without a purchase (TestFlight and debug builds only).
    private(set) var demo = DemoMode.isOn
    let store: PurchaseStore

    var isPro: Bool { purchased || demo }

    /// The latest answer, for code that runs outside the SwiftUI environment, such as a voice cue in Craving SOS
    /// (which can be presented above the app's environment) or the notification plan.
    private(set) static var isProNow = DemoMode.isOn
    /// The trial's end for the same code, and for `ProgramStore`, which holds Prep 4 onwards until then.
    private(set) static var trialEndsNow: Date?

    /// The last answer from the real store, so a subscriber opening the app (or offline) isn't shown the hard
    /// paywall while the store is asked again. Stand-in stores (tests, screenshots) never read or write it.
    private static let rememberedKey = "dx.proRemembered"
    private var remembers: Bool { store is Subscriptions }

    init(store: PurchaseStore) {
        self.store = store
        if store is Subscriptions { purchased = UserDefaults.standard.bool(forKey: Self.rememberedKey) }
        publish()
    }

    func refresh() async {
        purchased = await store.hasPro()
        if purchased {
            trialEndsAt = await store.trialEnd()
        } else {
            trialEndsAt = nil
        }
        publish()
    }

    /// On coming back to the app: picks up a trial that has become a paid plan, or a purchase made elsewhere. It
    /// only takes access away once a trial it knew about is over and the store says nothing is active; anything
    /// else waits for the next launch, so it can't undo a purchase the store is still confirming.
    func refreshOnReturn(now: Date = .now) async {
        guard await store.hasPro() else {
            guard purchased, let end = trialEndsAt, end <= now else { return }
            purchased = false
            trialEndsAt = nil
            publish()
            return
        }
        let end = await store.trialEnd()
        purchased = true
        trialEndsAt = end
        publish()
    }

    /// After a purchase or restore on DayXero's paywall. `trialEndsAt` is the trial's end when it started one.
    func grant(trialEndsAt: Date? = nil) {
        purchased = true
        self.trialEndsAt = trialEndsAt
        publish()
    }

    /// After a purchase or restore somewhere that doesn't say what was bought (Superwall's paywall, Settings):
    /// unlocks at once, then asks the store whether it's a trial.
    func grantFromElsewhere() {
        purchased = true
        publish()
        Task {
            trialEndsAt = await store.trialEnd()
            publish()
        }
    }

    func setDemo(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: DemoMode.key)
        demo = DemoMode.isOn
        publish()
    }

    private func publish() {
        if remembers { UserDefaults.standard.set(purchased, forKey: Self.rememberedKey) }
        Self.isProNow = isPro
        // Siri and widget actions that run without opening the app check this.
        // The widgets blank to their subscribe state without a plan, so they redraw when it changes.
        if PlanGate.isActive != isPro {
            PlanGate.isActive = isPro
            WidgetCenter.shared.reloadAllTimelines()
        }
        Self.trialEndsNow = demo ? nil : trialEndsAt
    }
}

/// Jelli's voice coaching in Craving SOS and the calm tools is free (16 Nov 2026; it was paid under MON-01).
/// Anyone who turned Voice guidance off in Settings stays silent.
@MainActor
enum VoiceCoaching {
    static func speaks(_ voiceGuidance: Bool) -> Bool {
        voiceGuidance && FullProgram.has(.voiceCoaching, isPro: Entitlement.isProNow)
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
    /// The Quit Day, so a paywall can say where the trial ends against it. Every plan is sold whenever the Quit Day is.
    var quitDay: Date?
    /// The person's usual nicotine spend, for the price anchor (MON-03). nil hides it.
    var spend: Spend?

    struct Spend: Equatable {
        let perYear: Decimal
        let currencyCode: String
        let products: [Product]

        @MainActor
        init(perYear: Decimal, currencyCode: String, products: [Product]) {
            self.perYear = perYear
            self.currencyCode = currencyCode
            self.products = products
        }

        @MainActor
        init?(profile: UserProfile?) {
            guard let profile else { return nil }
            let stats = ProgressStats(quitDay: profile.quitDay, baselines: profile.products.map(\.baseline),
                                      clock: DayClock(boundaryHour: profile.dayBoundaryHour))
            self.init(perYear: stats.moneyPerYear, currencyCode: profile.currencyCode, products: profile.products.map(\.product))
        }
    }

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

    /// How many days after the Quit Day the selected plan's trial ends: 0 on the Quit Day, negative before it.
    /// nil without a trial or a Quit Day.
    var trialEndsAfterQuitDay: Int? {
        guard let end = trialEndDate, let quitDay else { return nil }
        return FullProgram.trialEndsDaysAfterQuitDay(trialEnd: end, quitDay: quitDay, calendar: calendar)
    }

    /// "Costs 8 days of smoking" for a plan, from the person's own spend (MON-03). nil when there's nothing honest to say.
    func anchor(for option: PlanOption) -> PriceAnchor? {
        guard let spend else { return nil }
        return PriceAnchor.make(price: option.price, priceCurrency: option.currencyCode, spendPerYear: spend.perYear,
                                spendCurrency: spend.currencyCode, products: spend.products)
    }

    /// Yearly's saving against four lots of 3 months, only when it's a real saving in this region.
    var annualSavingPercent: Int? {
        guard let annual = plans.first(where: { $0.plan == .annual }),
              let quarterly = plans.first(where: { $0.plan == .quarterly }),
              quarterly.price > 0 else { return nil }
        let yearOfQuarters = NSDecimalNumber(decimal: quarterly.price * 4).doubleValue
        let saving = 1 - NSDecimalNumber(decimal: annual.price).doubleValue / yearOfQuarters
        let percent = Int((saving * 100).rounded(.down))
        return percent >= 5 ? percent : nil
    }

    /// - Parameter trackView: false when only the prices are wanted (the trial screen before the paywall).
    func load(trackView: Bool = true) async {
        phase = .loading
        if trackView { Analytics.track(.paywallViewed) }
        do {
            // Only yearly and 3 months are sold; a monthly or lifetime product still in the offering isn't shown.
            plans = try await store.loadPlans().filter { Plan.offered.contains($0.plan) }
            guard !plans.isEmpty else { throw StoreError.noPlans }
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
    /// For screenshots: `-dx.paywallPlan quarterly` and `-dx.paywallPhase unlocked|pending`.
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
                entitlement.grant(trialEndsAt: trialEndDate)
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
                let trialEnd = await store.trialEnd()
                entitlement.grant(trialEndsAt: trialEnd)
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
