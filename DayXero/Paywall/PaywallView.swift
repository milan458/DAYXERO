import DayXeroCore
import StoreKit
import SwiftData
import SwiftUI

/// Legal links shown on Welcome, every paywall and Settings (S15.4, S27.1). Apple requires both on any
/// screen that sells a subscription. Optional so a build without a policy still compiles; it is always set.
enum AppLinks {
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy: URL? = URL(string: "https://dayxero.app/privacy/")
}

/// The full paywall (S3.1–S3.6), opened from "See all plans", Settings, Program, Today and the locked features.
/// There is no paywall after onboarding (S27.2): the close button is always there and nothing here is a first run.
/// Every plan is sold whenever the Quit Day is; the 7-day trial starts the day it's bought (MON-01).
/// The paywall's palette (v5, cook/site/screens/014): Xero's apricot ground (the one navy in dark), kit cards and the
/// warm selection; ticks in coral.
///
/// Motion (014): the title and Xero arrive (600ms, 90ms stagger); the three benefit rows tick in one by one; the plan
/// rows settle (120ms apart) with the yearly row already chosen; the trial timeline draws left to right (900ms) and its
/// three stops pop in as it reaches them; the button arrives last.
enum PW {
    static let ground = DX.Ground.apricot
    static let background = DX.Ground.apricot.background
    static let ink = DX.Ground.apricot.ink
    static let muted = DX.Ground.apricot.muted
    static let card = DX.Ground.apricot.card
    static let surface = DX.Ground.apricot.card2
    static let hairline = DX.Ground.apricot.line
    static let faint = DX.Ground.apricot.ink.opacity(0.38)
    static let accent = Color(hex: 0xFF7A55)
    static let accentSoft = DX.Ground.apricot.selTint
    static let onInk = Color(light: 0xFFF8EE, dark: 0x0E1322)
    static let amber = Read4.amber
}

struct PaywallView: View {
    let name: String
    let quitDay: Date
    @State var model: PaywallModel
    let onClose: () -> Void
    /// Called as a purchase or restore starts, before the person can turn Pro.
    var onPurchaseStarted: () -> Void = {}
    /// The person's spend for the price anchor, where there's no profile yet (onboarding). Otherwise it's the profile's.
    var spend: PaywallModel.Spend?
    /// False for the hard paywall: no close button and no "continue with free".
    var closable = true

    @Query private var profiles: [UserProfile]

    @State private var showBilling = false
    private let motion = MotionPolicy()
    /// At accessibility text sizes the footer scrolls with the content instead of being pinned,
    /// so the charge line and button are never squeezed or truncated.
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ZStack(alignment: .top) {
            switch model.phase {
            case .loading, .ready, .purchasing:
                main
            case .failed:
                failed
            case .pending:
                PaywallMessage(systemImage: "clock", tint: .accent, title: "Waiting for approval",
                               message: "Your purchase needs approval (for example, Ask to Buy). We'll unlock everything as soon as it goes through.",
                               button: closable ? "Back to my day" : "Back to the plans",
                               action: leavePending)
            case .unlocked:
                PaywallMessage(systemImage: "checkmark", tint: .sage, title: allSetTitle,
                               message: unlockedMessage, button: closable ? "Back to my day" : "Start",
                               action: onClose)
                    .sensoryFeedback(DX.Haptic.commit, trigger: model.phase)
            }
            if let notice = model.notice {
                NoticeBanner(text: notice) { model.notice = nil }
                    .padding(.horizontal, DX.Space.s)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(motion.animation(DX.Move.settle), value: model.phase)
        .animation(motion.animation(DX.Move.settle), value: model.notice != nil)
        .background(PW.background.ignoresSafeArea())
        .task {
            model.quitDay = quitDay
            model.spend = spend ?? PaywallModel.Spend(profile: profiles.first)
            await model.load()
        }
        .sheet(isPresented: $showBilling) { BillingSheet().presentationDetents([.medium, .large]) }
    }

    /// From "Waiting for approval": back to the app, or on the hard paywall back to the plans.
    private func leavePending() {
        if closable {
            onClose()
        } else {
            Task { await model.load() }
        }
    }

    private var unlockedMessage: LocalizedStringKey {
        if let end = model.trialEndDate, model.selectedOption?.trialDays != nil {
            return model.canRemind
                ? "Your free trial runs until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)). Prep 1 to 3 open one a day. We'll remind you \(reminderLead) before it ends."
                : "Your free trial runs until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)). Prep 1 to 3 open one a day."
        }
        return "The full program is unlocked."
    }

    /// "Milan, your plan is ready", or "Your plan is ready" when there's no name to use.
    static func readyTitle(name: String) -> String {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? String(localized: "Your plan is ready") : String(localized: "\(name), your plan is ready")
    }

    private var allSetTitle: LocalizedStringKey {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return "You're all set" }
        return "You're all set, \(name)"
    }

    /// What the free trial opens, said before anyone starts it: Prep 1 to 3, one a day (16 Nov 2026).
    @ViewBuilder
    private var trialNote: some View {
        if model.selectedOption?.trialDays != nil {
            Text("During the free trial, Prep 1 to 3 open one a day. The rest of the program opens when the trial ends.")
            .dxFace(.body, 14, weight: 400)
            .foregroundStyle(PW.muted)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// "Costs 8 days of smoking" (MON-03): the yearly price in the person's own habit, from what they told us they spend.
    @ViewBuilder
    private var anchor: some View {
        if let annual = model.plans.first(where: { $0.plan == .annual }), let anchor = model.anchor(for: annual) {
            PriceAnchorLine(anchor: anchor)
        }
    }

    // MARK: Main

    private var main: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, 16).padding(.top, DX.Space.xs).dxReadableColumn()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // v5 (014): the offer as the headline, Xero in his cream disc beside it.
                    HStack(alignment: .center, spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            headline
                                .dxFace(.display, 30, weight: 800, tracking: -1)
                                .foregroundStyle(PW.ink)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                                .dxArrive(0)
                            Text("Everything for your \(quitDay, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)) Quit Day.")
                                .dxType(.footnote).foregroundStyle(PW.muted)
                                .dxArrive(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        XeroView(mood: .hello, stage: 0, points: 72)
                            .dxBob()
                            .padding(.top, 4)
                            .frame(width: 88, height: 88)
                            .background(Color(light: 0xFFF8EE, dark: 0x212A41), in: Circle())
                            .dxSettle(delay: 0.15)
                            .accessibilityHidden(true)
                    }
                    // What the full program adds, in the order the person meets it (hard paywall, 16 Nov 2026).
                    VStack(alignment: .leading, spacing: 9) {
                        included("Your prep days and your Day Xero badge", index: 0)
                        included("Weeks 1 to 4 of coaching after Quit Day", index: 1)
                        included("A 12-week NRT schedule and trigger heatmaps", index: 2)
                    }
                    .padding(.top, 18)
                    plans.padding(.top, 24)
                    timeline.padding(.top, 22)
                    if typeSize.isAccessibilitySize {
                        footer.padding(.top, DX.Space.l)
                    }
                }
                .padding(.horizontal, DX.Layout.gutter)
                .dxReadableColumn()
                .padding(.top, 4)
                .padding(.bottom, typeSize.isAccessibilitySize ? DX.Space.xl : DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            if !typeSize.isAccessibilitySize {
                footer
                    .padding(.horizontal, DX.Layout.gutter)
                    .dxReadableColumn()
                    .padding(.top, 10)
                    .padding(.bottom, 4)
            }
        }
    }

    /// "7 days free, then $39.99 a year", or the plan's readiness when there's no trial on offer.
    @ViewBuilder
    private var headline: some View {
        if let annual = model.plans.first(where: { $0.plan == .annual }), let days = annual.trialDays {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(days) days free, then")
                Text("\(annual.priceText) a year")
            }
            .lineLimit(1).minimumScaleFactor(0.8)
            .accessibilityElement(children: .combine)
        } else {
            Text(verbatim: Self.readyTitle(name: name))
        }
    }

    /// "2 days" or "the day", matching when the reminder actually comes.
    private var reminderLead: String {
        guard let end = model.trialEndDate, TrialReminder.leadDays(trialEndsAt: end, now: .now) == 2 else {
            return String(localized: "the day")
        }
        return String(localized: "2 days")
    }

    private var header: some View {
        HStack {
            if closable {
            Button {
                model.dismissed()
                onClose()
            } label: {
                DXIcon(.back, size: 20, weight: 2.4)
                    .foregroundStyle(PW.ink)
                    .frame(width: 44, height: 44)
                    .background(PW.surface, in: Circle())
            }
            .buttonStyle(.dxPress)
            .accessibilityLabel(Text("Close"))
            }
            Spacer()
        }
        .frame(height: 52)
    }

    /// A benefit with its small paper-cut coral stamp, the cream tick drawing in 90 ms apart.
    private func included(_ text: LocalizedStringKey, index: Int) -> some View {
        HStack(spacing: 10) {
            BenefitStamp(delay: 0.3 + Double(index) * 0.09)
            Text(text).dxType(.footnote).foregroundStyle(PW.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .dxArrive(2 + index)
    }

    @ViewBuilder
    private var plans: some View {
        VStack(spacing: 8) {
            if model.plans.isEmpty {
                ForEach(0..<Plan.offered.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 18, style: .continuous).fill(PW.surface).frame(height: i == 0 ? 80 : 52)
                }
                .accessibilityHidden(true)
            } else {
                ForEach(Array(model.plans.enumerated()), id: \.element.id) { i, option in
                    PlanRow(option: option, isSelected: model.selected == option.plan) {
                        model.select(option.plan)
                    }
                    .padding(.top, option.trialDays != nil ? 12 : 0)
                    .dxArrive(7 + i)
                }
            }
        }
    }

    /// The trial as a line: today, the reminder, the day it ends. It draws left to right (900 ms) and each stop fades
    /// in as the line reaches it. Without a trial, the charge says what happens instead.
    @ViewBuilder
    private var timeline: some View {
        if let option = model.selectedOption, let end = model.trialEndDate {
            let lead = TrialReminder.leadDays(trialEndsAt: end, now: .now)
            let remind = Calendar.current.date(byAdding: .day, value: -lead, to: end) ?? end
            TrialTimeline(end: end, remind: model.canRemind ? remind : nil)
                .id(option.plan)
                .dxArrive(10)
        } else if let option = model.selectedOption {
            chargeLine(option)
                .frame(maxWidth: .infinity, alignment: .leading)
                .dxArrive(10)
        }
    }

    private var footer: some View {
        VStack(spacing: 2) {
            Button {
                onPurchaseStarted()
                Task { await model.purchase() }
            } label: {
                if model.phase == .purchasing {
                    ProgressView().tint(PW.onInk)
                } else {
                    Text(ctaTitle)
                }
            }
            .buttonStyle(.dx(.primary, on: .apricot))
            .disabled(model.phase != .ready)
            .accessibilityIdentifier("paywall.cta")
            .dxArrive(11)
            Text(model.selected == .lifetime ? "One payment. No subscription to cancel." : "Renews automatically. Cancel anytime in Settings.")
                .dxFace(.body, 13, weight: 500)
                .foregroundStyle(PW.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
                .dxArrive(12)
            legal.dxArrive(13)
        }
    }

    private func chargeLine(_ option: PlanOption) -> some View {
        Group {
            switch option.plan {
            case .annual:
                Text("\(Text("\(option.priceText) today").dxRun(14, weight: 700)), then every year until you cancel.")
            case .quarterly:
                Text("\(Text("\(option.priceText) today").dxRun(14, weight: 700)), then every 3 months until you cancel.")
            case .monthly:
                Text("\(Text("\(option.priceText) today").dxRun(14, weight: 700)), then every month until you cancel.")
            case .lifetime:
                Text("\(Text("\(option.priceText) once.").dxRun(14, weight: 700)) No subscription, nothing to cancel.")
            }
        }
        .dxFace(.body, 14, weight: 400)
        .foregroundStyle(PW.muted)
    }

    private var ctaTitle: LocalizedStringKey {
        guard let option = model.selectedOption else { return "Loading prices…" }
        switch option.plan {
        case .annual:
            if let days = option.trialDays { return "Start my \(days)-day free trial" }
            return "Subscribe for \(option.priceText) a year"
        case .quarterly: return "Subscribe for \(option.priceText) every 3 months"
        case .monthly: return "Subscribe for \(option.priceText) a month"
        case .lifetime: return "Buy lifetime for \(option.priceText)"
        }
    }

    /// Restore purchases · Terms · Privacy (S15.4).
    private var legal: some View {
        ViewThatFits {
            HStack(spacing: 6) { legalLinks(separators: true) }
            VStack(spacing: 4) { legalLinks(separators: false) }
        }
        .dxFace(.body, 14, weight: 600)
        .foregroundStyle(PW.ink.opacity(0.85))
        .tint(PW.ink.opacity(0.85))
    }

    @ViewBuilder
    private func legalLinks(separators: Bool) -> some View {
        Button("Restore purchases") {
            onPurchaseStarted()
            Task { await model.restore() }
        }
        .buttonStyle(.plain)
        .frame(minHeight: 32)
        if separators { Text(verbatim: "·").foregroundStyle(PW.muted) }
        Link("Terms", destination: AppLinks.terms).frame(minHeight: 32)
        if let privacy = AppLinks.privacy {
            if separators { Text(verbatim: "·").foregroundStyle(PW.muted) }
            Link("Privacy", destination: privacy).frame(minHeight: 32)
        }
    }

    // MARK: Failed

    private var failed: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, DX.Layout.gutter).padding(.top, DX.Space.xs).dxReadableColumn()
            Spacer()
            V4StateView(.error, systemImage: "exclamationmark.circle", title: "Couldn't reach the App Store",
                        message: "Check your connection and try again.",
                        actionTitle: "Try again") { Task { await model.load() } }
            Spacer()
            if closable {
                Button("Close") {
                    model.dismissed()
                    onClose()
                }
                .buttonStyle(.dx(.quiet, on: .apricot))
                .padding(.bottom, DX.Space.xs)
            }
        }
    }
}

/// A plan (014): the radio on the left, the name, the price on the right. The trial plan is the hero row (80 pt, its
/// "7 days free" pill on its top edge); the others are lighter (52 pt).
private struct PlanRow: View {
    let option: PlanOption
    let isSelected: Bool
    let action: () -> Void

    private var hero: Bool { option.trialDays != nil }

    var body: some View {
        let g = PW.ground
        let shape = RoundedRectangle(cornerRadius: DX.Layout.optionRadius, style: .continuous)
        return Button(action: action) {
            HStack(spacing: 14) {
                DXRadio(isOn: isSelected, ground: g)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).dxFace(.display, hero ? 20 : 17, weight: 700, tracking: -0.2).foregroundStyle(PW.ink)
                    if hero, let perMonth = option.perMonthText {
                        Text("\(perMonth) a month").dxType(.footnote).foregroundStyle(PW.ink)
                    }
                }
                Spacer(minLength: DX.Space.xs)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(verbatim: option.priceText).dxFace(.display, hero ? 24 : 17, weight: 800, tracking: -0.3)
                        .monospacedDigit().foregroundStyle(PW.ink)
                    Text(period).dxType(.caption).foregroundStyle(PW.muted)
                }
            }
            .padding(.vertical, hero ? 14 : 10)
            .padding(.horizontal, hero ? 18 : 16)
            .frame(minHeight: hero ? 80 : 52)
            .background(isSelected ? (hero ? Color(light: 0xFFEFE5, dark: 0x2A3044) : g.selTint) : g.card, in: shape)
            .overlay(shape.strokeBorder(isSelected ? g.selEdge : g.line, lineWidth: isSelected ? 2 : 1))
            .overlay(alignment: .topLeading) {
                if let days = option.trialDays {
                    Text("\(days) days free")
                        .dxFace(.body, 13, weight: 700).tracking(0.1)
                        .foregroundStyle(g.selFg)
                        .padding(.vertical, 6).padding(.horizontal, 10)
                        .background(g.sel, in: Capsule())
                        .offset(x: 16, y: -12)
                }
            }
            .contentShape(Rectangle())
            .animation(DX.Move.arrive.speed(2.4), value: isSelected)
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var title: LocalizedStringKey {
        switch option.plan {
        case .annual: "Yearly"
        case .quarterly: "3 months"
        case .monthly: "Monthly"
        case .lifetime: "Lifetime"
        }
    }

    private var period: LocalizedStringKey {
        switch option.plan {
        case .annual: "a year"
        case .quarterly: "every 3 months"
        case .monthly: "a month"
        case .lifetime: "once"
        }
    }
}

/// The trial line (014): Today (full access), the reminder, the day it ends and the plan starts.
private struct TrialTimeline: View {
    let end: Date
    let remind: Date?
    @State private var drawn = false
    private let motion = MotionPolicy()

    var body: some View {
        let format = Date.FormatStyle.dateTime.month(.abbreviated).day()
        VStack(spacing: 0) {
            GeometryReader { proxy in
                let w = proxy.size.width - 14
                ZStack(alignment: .leading) {
                    Capsule().fill(PW.ground.track).frame(width: w, height: 3).offset(x: 7)
                    Capsule().fill(PW.ink).frame(width: w * (drawn || motion.reduce ? 1 : 0), height: 3).offset(x: 7)
                    node(filled: true).offset(x: 0)
                    if remind != nil {
                        node(filled: false).offset(x: proxy.size.width / 2 - 8)
                            .opacity(drawn || motion.reduce ? 1 : 0)
                            .animation(.easeOut(duration: 0.7).delay(0.45), value: drawn)
                    }
                    node(filled: false).offset(x: proxy.size.width - 16)
                        .opacity(drawn || motion.reduce ? 1 : 0)
                        .animation(.easeOut(duration: 0.7).delay(0.85), value: drawn)
                }
            }
            .frame(height: 16)
            HStack(alignment: .top) {
                stop(Text("Today"), Text("Full access"), align: .leading)
                Spacer(minLength: 4)
                if let remind {
                    stop(Text(remind, format: format), Text("We remind you"), align: .center)
                    Spacer(minLength: 4)
                }
                stop(Text(end, format: format), Text("Trial ends,\nplan starts"), align: .trailing)
            }
            .padding(.top, 6)
        }
        .accessibilityElement(children: .combine)
        .onAppear {
            withAnimation(motion.reduce ? nil : .timingCurve(0.2, 0.7, 0.2, 1, duration: 0.9).delay(0.4)) { drawn = true }
        }
    }

    private func node(filled: Bool) -> some View {
        Circle()
            .fill(filled ? PW.ink : PW.background)
            .overlay(Circle().strokeBorder(PW.ink, lineWidth: 3))
            .frame(width: 16, height: 16)
    }

    private func stop(_ title: Text, _ detail: Text, align: HorizontalAlignment) -> some View {
        VStack(alignment: align, spacing: 1) {
            title.dxFace(.body, 15, weight: 700).foregroundStyle(PW.ink)
            detail.dxFace(.body, 14, weight: 600).foregroundStyle(PW.muted)
        }
        .multilineTextAlignment(align == .leading ? .leading : align == .trailing ? .trailing : .center)
        .fixedSize()
    }
}

/// A benefit mark: a small scalloped coral stamp with a soft paper shadow, its cream tick drawing in.
private struct BenefitStamp: View {
    let delay: Double
    @State private var drawn = false
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()

    var body: some View {
        let shadow = scheme == .dark ? Color.black.opacity(0.55) : Color(red: 120 / 255, green: 52 / 255, blue: 24 / 255).opacity(0.26)
        ZStack {
            GridShape(d: DXBadge.scallop(cx: 12, cy: 12, r: 11.5, n: 10, a: 1.4), grid: 24).fill(Color(hex: 0xFF7155))
                .shadow(color: shadow, radius: 1, y: 1.6)
            GridShape(d: "M16.6 4.6 A9 9 0 0 1 16.6 19.4 A10 10 0 0 0 16.6 4.6 Z", grid: 24).fill(Color(hex: 0xE85A3E))
            GridShape(d: "M7.4 12.4l3.1 3.1L16.8 9", grid: 24)
                .trim(from: 0, to: drawn || motion.reduce ? 1 : 0)
                .stroke(Color(hex: 0xFFF8EE), style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 24, height: 24)
        .scaleEffect(22 / 24)
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)
        .onAppear { withAnimation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.52).delay(delay)) { drawn = true } }
    }
}

/// Full-screen confirmation used for "unlocked" and "waiting for approval".
private struct PaywallMessage: View {
    enum Tint { case sage, accent }
    let systemImage: String
    let tint: Tint
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let button: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        VStack(spacing: DX.Space.s) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(tint == .sage ? DX.Fill.cream : PW.accent)
                .frame(width: 76, height: 76)
                .background(tint == .sage ? PW.accent : PW.accentSoft, in: Circle())
                .accessibilityHidden(true)
            Text(title).dxType(.title).foregroundStyle(DX.Ground.reading.ink).multilineTextAlignment(.center)
            Text(message).dxType(.footnote).foregroundStyle(DX.Ground.reading.muted).multilineTextAlignment(.center)
            Spacer()
            Button(button, action: action).buttonStyle(.dx(.primary, on: .apricot))
        }
        .padding(.horizontal, DX.Space.l)
        .dxReadableColumn()
        .padding(.bottom, DX.Space.xs)
    }
}

private struct NoticeBanner: View {
    let text: LocalizedStringResource
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle").foregroundStyle(PW.amber)
            Text(text).dxFace(.body, 14, weight: 400).foregroundStyle(PW.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                DXIcon(.close, size: 11, weight: 2.6).foregroundStyle(PW.muted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Dismiss"))
        }
        .padding(DX.Space.s)
        .background(PW.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(PW.hairline))
        .shadow(color: Color.black.opacity(0.15), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
    }
}

/// "How billing works" (S3.4): cancelling in two taps, trial, refunds.
struct BillingSheet: View {
    @State private var manage = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                Text("How billing works").dxType(.title).foregroundStyle(DX.Ground.reading.ink).dxFace(.display, 24, weight: 700)
                Text("Plain and simple. Apple handles every payment.").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                Text("Cancel in two taps").dxType(.caption).foregroundStyle(DX.Ground.reading.muted).padding(.top, DX.Space.m)
                step(1, "Tap **Manage subscription** below")
                step(2, "Tap **Cancel subscription**")
                Text("Free trial").dxType(.caption).foregroundStyle(DX.Ground.reading.muted).padding(.top, DX.Space.s)
                Text("Cancel any time before it ends and you pay nothing. We'll remind you 2 days before.").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                Text("Refunds").dxType(.caption).foregroundStyle(DX.Ground.reading.muted).padding(.top, DX.Space.s)
                Text("Refunds go through Apple. You can request one at reportaproblem.apple.com.").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                Button("Manage subscription") { manage = true }
                    .buttonStyle(.dx(.ghost, on: .reading))
                    .frame(maxWidth: .infinity)
                    .padding(.top, DX.Space.m)
            }
            .padding(DX.Space.l)
        }
        .background(PW.background.ignoresSafeArea())
        .manageSubscriptionsSheet(isPresented: $manage)
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            Text(verbatim: "\(number)")
                .dxFace(.body, 12, weight: 700)
                .foregroundStyle(PW.ink)
                .frame(width: 24, height: 24)
                .background(PW.surface, in: Circle())
            Text(text).dxFace(.body, 14, weight: 400).foregroundStyle(PW.ink)
        }
        .accessibilityElement(children: .combine)
    }
}

/// "Costs 8 days of smoking" with where the number comes from (MON-03).
struct PriceAnchorLine: View {
    let anchor: PriceAnchor
    var ground: DX.Ground = .reading

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: Self.title(anchor)).dxFace(.body, 16, weight: 700).foregroundStyle(ground.ink)
            Text("A year of the full program, against what you told us you spend.")
                .dxFace(.body, 12, weight: 400).foregroundStyle(ground.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10).padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ground == .reading ? PW.accentSoft : DX.Fill.onColourCard(for: ground),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// "Costs 8 days of smoking", "Costs 1 day of vaping", "Costs 12 days of nicotine" for more than one product.
    static func title(_ anchor: PriceAnchor) -> String {
        let n = anchor.days
        switch anchor.habit {
        case .smoking: return n == 1 ? String(localized: "Costs 1 day of smoking") : String(localized: "Costs \(n) days of smoking")
        case .vaping: return n == 1 ? String(localized: "Costs 1 day of vaping") : String(localized: "Costs \(n) days of vaping")
        case .pouches: return n == 1 ? String(localized: "Costs 1 day of pouches") : String(localized: "Costs \(n) days of pouches")
        case .nicotine: return n == 1 ? String(localized: "Costs 1 day of nicotine") : String(localized: "Costs \(n) days of nicotine")
        }
    }
}
