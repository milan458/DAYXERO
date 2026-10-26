import DayXeroCore
import StoreKit
import SwiftData
import SwiftUI
import UIKit
import UserNotifications
import WidgetKit

/// Settings behind the profile button on Home (S15.1–S15.4, S15.6, S15.7).
struct SettingsSheet: View {
    let profile: UserProfile
    var start: Page?

    enum Page: String, Hashable {
        case reminders, dayEnd, quietHours, products, quitDay, subscription, privacy, health
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(Entitlement.self) private var entitlement
    @AppStorage("dx.sosHaptics") private var haptics = true
    @AppStorage("dx.voiceGuidance") private var voiceGuidance = true
    @AppStorage(WidgetSync.privacyKey) private var widgetPrivacy = false
    @AppStorage(WidgetSync.privacyHomeKey) private var widgetPrivacyHome = false
    @AppStorage(AppearanceSetting.key) private var appearance = AppearanceSetting.automatic.rawValue
    @State private var path: [Page] = []
    @State private var confirmDelete = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("Your quit") {
                    NavigationLink(value: Page.products) {
                        LabeledContent { Text(verbatim: productNames) } label: { SettingLabel("Products", systemImage: "cloud") }
                    }
                    NavigationLink(value: Page.quitDay) {
                        LabeledContent { Text(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month())) } label: {
                            SettingLabel("Quit Day", systemImage: "calendar")
                        }
                    }
                    NavigationLink(value: Page.dayEnd) {
                        LabeledContent { Text(DayEndSettings.label(profile.dayBoundaryHour)) } label: { SettingLabel("Day ends at", systemImage: "moon") }
                    }
                }
                Section {
                    NavigationLink(value: Page.reminders) { SettingLabel("Notifications", systemImage: "bell") }
                    Toggle(isOn: $haptics) { SettingLabel("Breathing haptics", systemImage: "water.waves") }
                    Toggle(isOn: $voiceGuidance) { SettingLabel("Voice guidance", systemImage: "waveform") }
                    Picker(selection: $appearance) {
                        ForEach(AppearanceSetting.allCases, id: \.rawValue) { Text($0.title).tag($0.rawValue) }
                    } label: {
                        SettingLabel("Appearance", systemImage: "circle.lefthalf.filled")
                    }
                } header: {
                    Text("App")
                } footer: {
                    Text("Other haptics follow System Haptics in iPhone Settings.")
                }
                // Widgets (S17.11): what widgets anyone can see show.
                Section {
                    Toggle(isOn: $widgetPrivacy) { SettingLabel("Privacy mode on the Lock Screen", systemImage: "eye.slash") }
                    if widgetPrivacy {
                        Toggle(isOn: $widgetPrivacyHome) { SettingLabel("Apply to Home Screen", systemImage: "apps.iphone") }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Craving SOS to your Lock Screen").font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body))
                        Text("Long-press the Lock Screen, tap Customize, then swap the torch or camera button for Craving SOS.")
                            .dxText(.subtitle)
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("Widgets")
                } footer: {
                    Text("Hides money and the word nicotine from widgets anyone can see.")
                }
                .onChange(of: widgetPrivacy) { WidgetSync.refresh(in: context, isPro: entitlement.isPro) }
                .onChange(of: widgetPrivacyHome) { WidgetSync.refresh(in: context, isPro: entitlement.isPro) }
                Section("Subscription") {
                    NavigationLink(value: Page.subscription) {
                        LabeledContent { Text(entitlement.isPro ? "Pro" : "Free") } label: { SettingLabel("DayXero Pro", systemImage: "star") }
                    }
                }
                Section("Your data") {
                    NavigationLink(value: Page.privacy) { SettingLabel("Privacy", systemImage: "lock") }
                    Button { exportURL = DataTools.export(context: context, profile: profile) } label: {
                        SettingLabel("Export my data", systemImage: "square.and.arrow.up")
                    }
                    .foregroundStyle(DX.Palette.text)
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Delete all data", systemImage: "trash")
                    }
                }
                Section {
                    NavigationLink(value: Page.health) { SettingLabel("Health information", systemImage: "heart") }
                    Link(destination: AppLinks.terms) { SettingLabel("Terms of use", systemImage: "doc.text") }
                        .foregroundStyle(DX.Palette.text)
                } header: {
                    Text("About")
                } footer: {
                    Text(verbatim: "DayXero \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                        .frame(maxWidth: .infinity)
                        .padding(.top, DX.Space.s)
                }
            }
            .tint(DX.Palette.sage)
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .navigationDestination(for: Page.self) { page in
                switch page {
                case .reminders: NotificationSettingsView()
                case .quietHours: QuietHoursView()
                case .dayEnd: DayEndSettings(profile: profile)
                case .products: ProductsSettingsView(profile: profile)
                case .quitDay: QuitDaySettingsView(profile: profile)
                case .subscription: SubscriptionSettingsView()
                case .privacy: PrivacySettingsView()
                case .health: HealthInfoView()
                }
            }
            .alert("Delete everything?", isPresented: $confirmDelete) {
                Button("Delete everything", role: .destructive) {
                    dismiss()
                    DataTools.deleteAll(context: context)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes your plan, logs, check-ins and progress from this iPhone. It can't be undone. Your subscription isn't affected.")
            }
            .sheet(item: Binding(get: { exportURL.map(ExportFile.init) }, set: { if $0 == nil { exportURL = nil } })) { file in
                ShareSheet(items: [file.url])
            }
        }
        .onAppear { if let start, path.isEmpty { path = [start] } }
    }

    private var productNames: String {
        ListFormatter.localizedString(byJoining: profile.products.map { String(localized: $0.product.title) })
    }
}

private struct ExportFile: Identifiable {
    let url: URL
    var id: URL { url }
}

/// The system share sheet, for the export file.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct SettingLabel: View {
    let title: LocalizedStringKey
    let systemImage: String

    init(_ title: LocalizedStringKey, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage).font(.system(size: 13)).foregroundStyle(DX.Palette.accentInk)
                .frame(width: 28, height: 28).background(DX.Palette.accentSoft, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
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

// MARK: - Products and baselines

struct ProductsSettingsView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @State private var editing: ProductUse?

    var body: some View {
        List {
            Section {
                ForEach(profile.products.sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }) { use in
                    Button { editing = use } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(use.product.title).font(.custom(DX.Typeface.semibold, size: 16, relativeTo: .body))
                                Spacer()
                                if use.isPrimary { Text("Main").dxText(.micro, color: DX.Palette.accentInk) }
                            }
                            Text("\(Int(use.unitsPerDay)) \(Text(use.product.unit)) a day · \(use.pricePerPurchase.formatted(.currency(code: profile.currencyCode))) for \(Int(use.unitsPerPurchase))")
                                .dxText(.subtitle)
                        }
                    }
                    .foregroundStyle(DX.Palette.text)
                }
                Menu {
                    ForEach(DayXeroCore.Product.allCases.filter { p in !profile.products.contains { $0.product == p } }, id: \.self) { p in
                        Button(String(localized: p.title)) { add(p) }
                    }
                } label: {
                    Label("Add a product", systemImage: "plus")
                }
                .disabled(profile.products.count == DayXeroCore.Product.allCases.count)
            } footer: {
                Text("Changing a baseline updates money kept and counters from Quit Day. Days clear don't change.")
            }
        }
        .navigationTitle("Products")
        .tint(DX.Palette.sage)
        .sheet(item: $editing) { use in
            ProductEditor(use: use, profile: profile).presentationDetents([.large])
        }
    }

    private func add(_ product: DayXeroCore.Product) {
        let use = ProductUse(product: product, isPrimary: profile.products.isEmpty, unitsPerDay: product == .vape ? 100 : 10,
                             pricePerPurchase: 10, unitsPerPurchase: product == .vape ? 600 : 20)
        profile.products.append(use)
        try? context.save()
        editing = use
    }
}

struct ProductEditor: View {
    @Bindable var use: ProductUse
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var price = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $use.unitsPerDay, in: 1...2000, step: use.product == .vape ? 10 : 1) {
                        LabeledContent { Text(verbatim: "\(Int(use.unitsPerDay))") } label: { Text("\(Text(use.product.unit).foregroundStyle(DX.Palette.text)) a day") }
                    }
                    LabeledContent("Price") {
                        TextField("10.00", text: $price).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    Stepper(value: $use.unitsPerPurchase, in: 1...5000, step: use.product == .vape ? 50 : 1) {
                        LabeledContent { Text(verbatim: "\(Int(use.unitsPerPurchase))") } label: { Text("\(Text(use.product.unit)) per purchase") }
                    }
                }
                if !use.isPrimary {
                    Section {
                        Button("Make this my main product") {
                            profile.products.forEach { $0.isPrimary = false }
                            use.isPrimary = true
                        }
                    }
                }
                if profile.products.count > 1 {
                    Section {
                        Button("Remove \(String(localized: use.product.title).lowercased())", role: .destructive) {
                            let wasPrimary = use.isPrimary
                            profile.products.removeAll { $0 === use }
                            context.delete(use)
                            if wasPrimary { profile.products.first?.isPrimary = true }
                            try? context.save()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(Text(use.product.title))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if let value = Decimal(string: price.replacingOccurrences(of: ",", with: ".")), value > 0 { use.pricePerPurchase = value }
                        try? context.save()
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    }
                }
            }
            .onAppear { price = "\(use.pricePerPurchase)" }
        }
        .tint(DX.Palette.sage)
    }
}

// MARK: - Quit Day

/// Before Quit Day: the onboarding calendar. After: only by choice, "Set a new Quit Day" restarts the count (Milan: allow it).
struct QuitDaySettingsView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @State private var newDate = Date.now
    @State private var choosing = false
    @State private var confirm = false

    var body: some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: clock)
        let today = Calendar.current.startOfDay(for: .now)
        let latest = Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.quitDay.formatted(.dateTime.weekday(.wide).day().month(.wide))).font(.custom(DX.Typeface.semibold, size: 17, relativeTo: .headline))
                    if stats.isPrep(at: .now) {
                        Text("In \(stats.daysUntilQuitDay(at: .now)) days").dxText(.subtitle)
                    } else {
                        Text("\(stats.daysClear(at: .now)) days clear").dxText(.subtitle)
                    }
                }
            }
            if stats.isPrep(at: .now) {
                Section {
                    DatePicker("Quit Day", selection: Binding(get: { profile.quitDay }, set: { setQuitDay($0) }),
                               in: (Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today)...latest, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                } footer: {
                    Text("Your prep days adjust to fit.")
                }
            } else {
                Section {
                    Text("Your Quit Day has passed. If you'd like to start counting again from a new date, you can set one. Your lessons, logs and plans all stay.")
                        .dxText(.subtitle)
                    if choosing {
                        DatePicker("New Quit Day", selection: $newDate, in: today...latest, displayedComponents: .date).datePickerStyle(.graphical)
                        Button("Use this date") { confirm = true }
                    } else {
                        Button("Set a new Quit Day") { choosing = true; newDate = today }
                    }
                }
            }
        }
        .navigationTitle("Quit Day")
        .tint(DX.Palette.sage)
        .alert("Start counting from \(newDate.formatted(.dateTime.weekday(.wide).day().month()))?", isPresented: $confirm) {
            Button("Set new Quit Day") {
                setQuitDay(newDate)
                UserDefaults.standard.removeObject(forKey: CelebratedMilestones.key)
                choosing = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Days clear and milestones will count from the new date. Your lessons, logs and plans stay.")
        }
    }

    private func setQuitDay(_ date: Date) {
        profile.quitDay = Calendar.current.startOfDay(for: date)
        try? context.save()
        DailyReminders.refresh(in: context)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Subscription

struct SubscriptionSettingsView: View {
    @Environment(Entitlement.self) private var entitlement
    @State private var current: CurrentPlan?
    @State private var plans: [PlanOption] = []
    @State private var manage = false
    @State private var restoring = false
    @State private var restoreNote: String?
    @State private var showPaywall = false

    var body: some View {
        List {
            Section {
                if let current {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your plan").dxText(.micro)
                        Text(verbatim: planLine(current)).font(.custom(DX.Typeface.semibold, size: 17, relativeTo: .headline))
                        if let date = current.renews {
                            Text(current.willRenew ? "Renews on \(date.formatted(date: .long, time: .omitted))" : "Ends on \(date.formatted(date: .long, time: .omitted))")
                                .dxText(.subtitle)
                        }
                    }
                    if current.plan != .lifetime {
                        Button("Manage subscription") { manage = true }
                    }
                } else if entitlement.isPro {
                    Text("DayXero Pro is active.")
                } else {
                    Button("Unlock the full program") { showPaywall = true }
                }
                Button(restoring ? "Restoring…" : "Restore purchases") {
                    Task {
                        restoring = true
                        let found = (try? await entitlement.store.restore()) ?? false
                        Analytics.track(.purchasesRestored(success: found))
                        if found { entitlement.grant() }
                        current = await entitlement.store.currentPlan()
                        restoreNote = found ? String(localized: "Purchases restored.") : String(localized: "No purchases found for this Apple ID.")
                        restoring = false
                    }
                }
                .disabled(restoring)
            } footer: {
                Text(restoreNote ?? String(localized: "Payment, renewal and cancellation are handled by your Apple ID."))
            }
        }
        .navigationTitle("DayXero Pro")
        .tint(DX.Palette.sage)
        .task {
            current = await entitlement.store.currentPlan()
            plans = (try? await entitlement.store.loadPlans()) ?? []
        }
        .manageSubscriptionsSheet(isPresented: $manage)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(name: "", quitDay: .now, model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                        onClose: { showPaywall = false })
        }
    }

    private func planLine(_ current: CurrentPlan) -> String {
        let price = plans.first { $0.plan == current.plan }?.priceText
        let name: String = switch current.plan {
        case .annual: String(localized: "Annual")
        case .monthly: String(localized: "Monthly")
        case .lifetime: String(localized: "Lifetime")
        }
        guard let price else { return name }
        return switch current.plan {
        case .annual: String(localized: "\(name) · \(price) a year")
        case .monthly: String(localized: "\(name) · \(price) a month")
        case .lifetime: String(localized: "\(name) · \(price)")
        }
    }
}

// MARK: - Privacy and health

struct PrivacySettingsView: View {
    @State private var shareUsage = AnalyticsConsent.isOn

    var body: some View {
        List {
            Section {
                fact("iphone", "No account", "Your plan, reasons, photos, logs and notes are stored only on this iPhone.")
                fact("chart.bar", "Anonymous usage data", "Things like \"lesson started\" or \"paywall shown\", so we can improve DayXero. Never your reasons, notes, photos or anything you type. Sent to PostHog (US).")
                fact("star", "Purchases", "Handled by Apple and RevenueCat with an anonymous ID.")
            } header: {
                Text("Your data stays on this iPhone")
            }
            Section {
                Toggle("Share anonymous usage data", isOn: $shareUsage)
                    .onChange(of: shareUsage) { _, on in AnalyticsConsent.set(on) }
                if let privacy = AppLinks.privacy {
                    Link("Privacy policy", destination: privacy)
                }
            }
        }
        .navigationTitle("Privacy")
        .tint(DX.Palette.sage)
    }

    private func fact(_ icon: String, _ title: LocalizedStringKey, _ body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: DX.Space.s) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(DX.Palette.accentInk)
                .frame(width: 30, height: 30).background(DX.Palette.accentSoft, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body))
                Text(body).dxText(.subtitle)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

/// The health disclaimer (S15.6): educational support, not medical treatment.
struct HealthInfoView: View {
    static var oneLine: LocalizedStringKey { "DayXero offers education and support. It isn't medical treatment." }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                Text("DayXero offers education and support to help you stop using nicotine. It isn't medical treatment, and it doesn't replace advice from a doctor or pharmacist.")
                Text("If you're pregnant, have a health condition or take other medication, talk to a doctor or pharmacist before using NRT.")
                Text("Health facts in the app name their sources, and you can open each one.")
                Text("If you're struggling with your mood, or in crisis, contact a doctor or your local emergency number.")
            }
            .font(DX.TextStyle.body.font)
            .foregroundStyle(DX.Palette.text)
            .padding(DX.Space.m)
        }
        .dxCanvas()
        .navigationTitle("Health information")
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
