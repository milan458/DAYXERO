import DayXeroCore
import StoreKit
import SwiftData
import SwiftUI
import UIKit
import UserNotifications
import WidgetKit

/// Settings (v5, 061): the profile card, then the plan, the day, the data and the account, each its own group, every
/// row pushing its page from the right. Opened from the profile button on Today and the gear on Progress.
struct SettingsSheet: View {
    let profile: UserProfile
    var start: Page?

    enum Page: String, Hashable {
        case reminders, dayEnd, quietHours, products, quitDay, currency, allCurrencies, subscription, privacy, health,
             help, about, display
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(Entitlement.self) private var entitlement
    @AppStorage(DailyReminderSettings.pledgeKey) private var pledge = DailyReminderSettings.defaultPledge
    @AppStorage(DailyReminderSettings.lessonKey) private var lesson = DailyReminderSettings.offUntilChosen
    @AppStorage(DailyReminderSettings.checkInKey) private var checkIn = DailyReminderSettings.defaultCheckIn
    @AppStorage(DailyReminderSettings.milestoneKey) private var milestone = DailyReminderSettings.offUntilChosen
    @State private var path: [Page] = []
    @State private var planName: String?
    private let ground = DX.Ground.reading

    var body: some View {
        NavigationStack(path: $path) {
            home
                .navigationDestination(for: Page.self) { page in
                    switch page {
                    case .reminders: NotificationSettingsView()
                    case .quietHours: QuietHoursView()
                    case .dayEnd: DayEndSettings(profile: profile)
                    case .products: ProductsSettingsView(profile: profile)
                    case .quitDay: QuitDaySettingsView(profile: profile)
                    case .currency: CurrencySettingsView(profile: profile)
                    case .allCurrencies: AllCurrenciesView(profile: profile)
                    case .subscription: SubscriptionSettingsView(profile: profile)
                    case .privacy: PrivacySettingsView(profile: profile, onDeleteAll: {
                        dismiss()
                        DataTools.deleteAll(context: context)
                    })
                    case .health: HealthInfoView()
                    case .help: HelpSettingsView()
                    case .about: AboutSettingsView()
                    case .display: DisplaySettingsView()
                    }
                }
        }
        .dxGround(.reading)
        .onAppear { if let start, path.isEmpty { path = [start] } }
        .task {
            if let plan = await entitlement.store.currentPlan()?.plan {
                planName = switch plan {
                case .annual: String(localized: "Yearly")
                case .monthly: String(localized: "Monthly")
                case .lifetime: String(localized: "Lifetime")
                }
            }
        }
    }

    private var home: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                NavigationLink(value: Page.quitDay) { profileCard }
                    .buttonStyle(.dxPress)
                    .padding(.top, 2)
                    .dxArrive(1)

                SettingsSection("Your plan", top: 14, index: 2)
                DXList {
                    link(.quitDay, "Quit Day", icon: .calendar, value: Text(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())))
                    link(.products, "What you use", icon: .cig, value: Text(verbatim: productNames))
                    link(.currency, "Currency", icon: .globe, value: Text(verbatim: profile.currencyCode))
                }
                .dxArrive(3)

                SettingsSection("Your day", top: 14, index: 4)
                DXList {
                    link(.reminders, "Reminders", icon: .bell, value: Text("\(remindersOn) on"))
                    link(.dayEnd, "Day ends at", icon: .clock, value: Text(verbatim: DayEndSettings.label(profile.dayBoundaryHour)))
                    link(.display, "Sound and display", glyph: SettingsGlyph.display, value: nil)
                }
                .dxArrive(5)

                SettingsSection("Your data", top: 14, index: 6)
                DXList {
                    link(.health, "Health information", icon: .heart, value: nil)
                    link(.privacy, "Privacy", icon: .shield, value: nil)
                }
                .dxArrive(7)

                SettingsSection("Account", top: 14, index: 8)
                DXList {
                    link(.subscription, "Subscription", icon: .card,
                         value: Text(verbatim: planName ?? (entitlement.isPro ? String(localized: "Pro") : String(localized: "Free"))))
                    link(.help, "Help and contact", glyph: SettingsGlyph.help, value: nil)
                    link(.about, "About", glyph: SettingsGlyph.info, value: Text("Version \(AboutSettingsView.version)"))
                }
                .accessibilityLabel(Text("Account and help"))
                .dxArrive(9)

                if DemoMode.isAvailable { demo.dxArrive(10) }
            }
            .padding(.horizontal, DX.Layout.gutter)
            .padding(.bottom, 32)
            .dxReadableColumn()
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) {
            DXNavRow(leading: .close, label: "Close", onLeading: { dismiss() }) {
                Text("Settings").dxFace(.display, 16, weight: 700).foregroundStyle(ground.ink).dxArrive(0)
            }
            .padding(.top, 8)
            .background(ground.background.ignoresSafeArea(edges: .top))
        }
        .background(ground.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toggleStyle(.dx)
    }

    /// Sam, joined when, and the days-free medal (the number shown once, on the medal).
    private var profileCard: some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: clock)
        let prep = stats.isPrep(at: .now)
        return HStack(spacing: 14) {
            SettingsDawn()
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: profile.name.isEmpty ? String(localized: "You") : profile.name)
                    .dxType(.title).foregroundStyle(ground.ink).lineLimit(1)
                Text("Joined \(profile.createdAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))")
                    .dxType(.footnote).foregroundStyle(ground.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                if prep {
                    DXBadge(.prep, n: stats.daysUntilQuitDay(at: .now), state: .next(nil), size: 44,
                            label: String(localized: "To Quit Day"))
                } else {
                    DXBadge(.day, n: stats.daysClear(at: .now), size: 44, label: String(localized: "Days free"))
                }
            }
            .dxStamp(0, delay: 0.7)
            DXIcon(.chev, size: 18).foregroundStyle(ground.muted)
        }
        .padding(.vertical, 12)
        .padding(.leading, 12)
        .padding(.trailing, 14)
        .dxCardChrome(on: .reading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Your profile"))
    }

    private var demo: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSection("Testing", top: 14)
            DXList {
                SettingsSwitchRow("Demo mode", icon: .sparkle, isOn: Binding(get: { entitlement.demo }, set: { on in
                    entitlement.setDemo(on)
                    DailyReminders.isPro = entitlement.isPro
                    WidgetSync.refresh(in: context, isPro: entitlement.isPro)
                }))
                .accessibilityIdentifier("settings.demoMode")
            }
            Text("Unlocks everything, opens every program session at any time, and lets you pick any Quit Day, past ones too. Only in test builds.")
                .dxType(.caption).foregroundStyle(ground.muted)
                .padding(.horizontal, 4)
                .padding(.top, 8)
        }
    }

    private func link(_ page: Page, _ title: LocalizedStringKey, icon: DX.Icon, value: Text?) -> some View {
        NavigationLink(value: page) { SettingsRow(title, icon: icon, value: value) }
            .buttonStyle(.dxPress)
    }

    private func link(_ page: Page, _ title: LocalizedStringKey, glyph: String, value: Text?) -> some View {
        NavigationLink(value: page) { SettingsRow(Text(title), icon: glyph, value: value) }
            .buttonStyle(.dxPress)
    }

    /// The reminders a person has switched on.
    private var remindersOn: Int {
        [pledge, checkIn, lesson, milestone].filter { $0 >= 0 }.count
    }

    /// "Cigarettes, vape".
    private var productNames: String {
        let names = profile.products.sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }.map { String(localized: $0.product.title) }
        guard let first = names.first else { return "" }
        return ([first] + names.dropFirst().map { $0.lowercased() }).joined(separator: ", ")
    }
}


/// The system share sheet, for the export file.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Automatic, Light or Dark (S15.1).
enum AppearanceSetting: String, CaseIterable {
    case automatic, light, dark
    static let key = "dx.appearance"

    var title: LocalizedStringKey {
        switch self {
        case .automatic: "Automatic"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

// MARK: - Export and delete (S15.3)

@MainActor
enum DataTools {
    /// Everything as one JSON file in the temporary folder, for the share sheet.
    static func export(context: ModelContext, profile: UserProfile) -> URL? {
        let iso = ISO8601DateFormatter()
        func date(_ d: Date?) -> String? { d.map(iso.string) }
        // JSON needs NSNull for missing values.
        func n(_ value: Any?) -> Any { value ?? NSNull() }
        let logs = (try? context.fetch(FetchDescriptor<LogEntry>(sortBy: [SortDescriptor(\.timestamp)]))) ?? []
        let checkIns = (try? context.fetch(FetchDescriptor<CheckIn>(sortBy: [SortDescriptor(\.day)]))) ?? []
        let pledges = (try? context.fetch(FetchDescriptor<Pledge>(sortBy: [SortDescriptor(\.day)]))) ?? []
        let plans = (try? context.fetch(FetchDescriptor<IfThenPlan>())) ?? []
        let tools = (try? context.fetch(FetchDescriptor<ToolUse>())) ?? []
        let water = (try? context.fetch(FetchDescriptor<WaterEntry>(sortBy: [SortDescriptor(\.timestamp)]))) ?? []
        let waterGoal = (try? context.fetch(FetchDescriptor<WaterProfile>()))?.first?.effectiveGoalMl
        typealias J = [String: Any]
        let products: [J] = profile.products.map {
            ["product": $0.productRaw, "main": $0.isPrimary, "perDay": $0.unitsPerDay, "price": "\($0.pricePerPurchase)", "perPurchase": $0.unitsPerPurchase]
        }
        let nrt: [J] = profile.nrtPlans.map { plan in
            let steps: [J] = plan.steps.map { ["mg": $0.strengthMg, "weeks": $0.weeks] }
            return ["type": plan.typeRaw, "start": n(date(plan.startDate)), "steps": steps]
        }
        let profileJSON: J = [
            "name": profile.name, "quitDay": n(date(profile.quitDay)), "createdAt": n(date(profile.createdAt)),
            "currency": profile.currencyCode, "dayEndsAtHour": profile.dayBoundaryHour, "triggers": profile.triggersRaw,
            "reasons": profile.reasons.map(\.text), "products": products, "nrt": nrt,
        ]
        let program: [J] = (profile.progress?.completions ?? []).map { ["day": n($0.dayID?.description), "completedAt": n(date($0.completedAt))] }
        let logsJSON: [J] = logs.map {
            ["kind": $0.kindRaw, "at": n(date($0.timestamp)), "product": n($0.productRaw), "trigger": n($0.triggerRaw),
             "strength": n($0.intensity), "outcome": n($0.outcomeRaw), "note": n($0.note), "nextTime": n($0.nextTime)]
        }
        let checkInsJSON: [J] = checkIns.map {
            ["day": n(date($0.day)), "mood": $0.moodRaw, "cravings": $0.cravingCount, "clearDay": $0.clearDay, "note": n($0.note)]
        }
        let plansJSON: [J] = plans.map { ["situation": $0.situation, "action": $0.action] }
        let toolsJSON: [J] = tools.map { ["tool": $0.toolRaw, "at": n(date($0.startedAt)), "calmer": n($0.calmer)] }
        // Water drinks and the goal; height and weight stay out of exports (handoff A4).
        let waterJSON: J = ["goalMl": n(waterGoal), "drinks": water.map { ["at": n(date($0.timestamp)), "drink": $0.drinkId, "ml": $0.amountMl] as J }]
        let json: J = [
            "exportedAt": iso.string(from: .now), "profile": profileJSON, "program": program, "logs": logsJSON,
            "checkIns": checkInsJSON, "pledges": pledges.map { n(date($0.madeAt)) }, "plans": plansJSON, "calmTools": toolsJSON,
            "water": waterJSON,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) else { return nil }
        let name = "dayxero-export-\(Date.now.formatted(.iso8601.year().month().day())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        return (try? data.write(to: url)) != nil ? url : nil
    }

    /// Wipes the store, settings, reminders, the Live Activity and widgets, then the app returns to the welcome screen.
    static func deleteAll(context: ModelContext) {
        try? context.delete(model: LogEntry.self)
        try? context.delete(model: CheckIn.self)
        try? context.delete(model: Pledge.self)
        try? context.delete(model: IfThenPlan.self)
        try? context.delete(model: WeeklyCheckIn.self)
        try? context.delete(model: ToolUse.self)
        try? context.delete(model: WaterEntry.self)
        try? context.delete(model: WaterProfile.self)
        try? context.delete(model: UserProfile.self)
        try? context.save()
        for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("dx.") {
            UserDefaults.standard.removeObject(forKey: key)
        }
        SOSState.startedAt = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        Task { await SOSLiveActivity.endAll() }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

