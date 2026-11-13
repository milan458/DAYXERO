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
                               button: "Back to my day", action: onClose)
            case .unlocked:
                PaywallMessage(systemImage: "checkmark", tint: .sage, title: allSetTitle,
                               message: unlockedMessage, button: "Back to my day",
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

    private var unlockedMessage: LocalizedStringKey {
        if let end = model.trialEndDate, model.selectedOption?.trialDays != nil {
            return model.canRemind
                ? "Your free trial runs until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)). We'll remind you \(reminderLead) before it ends."
                : "Your free trial runs until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))."
        }
        return "The full program is unlocked. Prep 4 is ready when you are."
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

    /// Where the trial ends against the Quit Day, said plainly whichever side it falls (MON-01).
    @ViewBuilder
    private var trialNote: some View {
        if let days = model.trialEndsAfterQuitDay {
            Group {
                if days > 0 {
                    Text(days == 1 ? "Your trial runs past your Quit Day: it ends the day after."
                         : "Your trial runs past your Quit Day: it ends \(days) days after.")
                } else if days == 0 {
                    Text("Your trial ends on your Quit Day.")
                } else {
                    Text(days == -1 ? "Your trial ends the day before your Quit Day." : "Your trial ends \(-days) days before your Quit Day.")
                }
            }
            .dxFont(14, weight: 400, style: .footnote)
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
            header.padding(.horizontal, DX.Layout.gutter).padding(.top, DX.Space.xs).dxReadableColumn()
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    // v5 (014): the title beside Xero on a cream disc.
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(verbatim: Self.readyTitle(name: name)).dxType(.title).foregroundStyle(PW.ink)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                            Text("Everything for your \(quitDay, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)) Quit Day.")
                                .dxType(.footnote).foregroundStyle(PW.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        XeroView(mood: .hello, stage: 2, points: 72)
                            .frame(width: 88, height: 88)
                            .background(Color(light: 0xFFF8EE, dark: 0x182034), in: Circle())
                            .dxSettle()
                            .accessibilityHidden(true)
                    }
                    .dxArrive(0)
                    // MON-01: what the full program adds, in the order the person meets it.
                    VStack(alignment: .leading, spacing: 10) {
                        included("Prep 4 to 7 and your Day Xero launch kit")
                        included("Weeks 1 to 4 of the program path")
                        included("Jelli's voice coaching")
                        included("If-then slip planner and a 12-week NRT schedule")
                        included("Trigger heatmaps")
                    }
                    .padding(.top, DX.Space.s)
                    Text(FreeLine.text)
                        .dxFont(14, weight: 400, style: .footnote).foregroundStyle(PW.muted)
                        .padding(.bottom, DX.Space.s)
                    anchor
                    plans
                    if typeSize.isAccessibilitySize {
                        footer.padding(.top, DX.Space.l)
                    }
                }
                .padding(.horizontal, DX.Layout.gutter)
                .dxReadableColumn()
                .padding(.top, DX.Space.m)
                .padding(.bottom, typeSize.isAccessibilitySize ? DX.Space.xl : 0)
            }
            if !typeSize.isAccessibilitySize {
                footer
                    .padding(.horizontal, DX.Layout.gutter)
                    .dxReadableColumn()
                    .padding(.bottom, DX.Space.xs)
            }
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
            Button {
                model.dismissed()
                onClose()
            } label: {
                DXIcon(.close, size: 20, weight: 2.4)
                    .foregroundStyle(PW.ink)
                    .frame(width: 44, height: 44)
                    .background(PW.surface, in: Circle())
            }
            .buttonStyle(.dxPress)
            .accessibilityLabel(Text("Close and continue with the free version"))
            Spacer()
            Button("Restore purchases") {
                onPurchaseStarted()
                Task { await model.restore() }
            }
                .dxFont(14, weight: 500, style: .footnote)
                .foregroundStyle(PW.muted)
                .buttonStyle(.plain)
        }
        .frame(minHeight: 44)
    }

    private func included(_ text: LocalizedStringKey) -> some View {
        // v5 (014): a coral scalloped tick, then the benefit.
        HStack(spacing: 12) {
            ZStack {
                Box(d: DXBadge.scallop(cx: 50, cy: 50, r: 48, n: 10, a: 6)).fill(PW.accent)
                DXIconShape(d: DX.Icon.check.d)
                    .stroke(.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .padding(5)
            }
            .frame(width: 22, height: 22)
            .accessibilityHidden(true)
            Text(text).dxType(.footnote).foregroundStyle(PW.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var plans: some View {
        VStack(spacing: DX.Space.xs) {
            if model.plans.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(PW.surface).frame(height: 60)
                }
                .accessibilityHidden(true)
            } else {
                ForEach(model.plans) { option in
                    PlanRow(option: option, isSelected: model.selected == option.plan, savingPercent: model.annualSavingPercent) {
                        model.select(option.plan)
                    }
                }
            }
            trialNote
        }
        .padding(.top, DX.Space.xs)
    }

    private var footer: some View {
        VStack(spacing: DX.Space.xs) {
            if let option = model.selectedOption {
                chargeLine(option)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
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
            terms
        }
    }

    private func chargeLine(_ option: PlanOption) -> some View {
        Group {
            switch option.plan {
            case .annual:
                if let end = model.trialEndDate {
                    Text("Free until \(Text(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)).bold()), then \(option.priceText) a year.")
                    + (model.canRemind ? Text("\nWe'll remind you \(reminderLead) before.") : Text(""))
                } else {
                    Text("\(Text("\(option.priceText) today").bold()), then every year until you cancel.")
                }
            case .monthly:
                Text("\(Text("\(option.priceText) today").bold()), then every month until you cancel.")
            case .lifetime:
                Text("\(Text("\(option.priceText) once.").bold()) No subscription, nothing to cancel.")
            }
        }
        .dxFont(14, weight: 400, style: .footnote)
        .foregroundStyle(PW.muted)
    }

    private var ctaTitle: LocalizedStringKey {
        guard let option = model.selectedOption else { return "Loading prices…" }
        switch option.plan {
        case .annual:
            if let days = option.trialDays { return "Start my \(days)-day free trial" }
            return "Subscribe for \(option.priceText) a year"
        case .monthly: return "Subscribe for \(option.priceText) a month"
        case .lifetime: return "Buy lifetime for \(option.priceText)"
        }
    }

    private var terms: some View {
        VStack(spacing: 2) {
            if model.selected != .lifetime {
                Text("Cancel in Settings › Apple ID › Subscriptions.").multilineTextAlignment(.center)
            }
            // One centred line when it fits, stacked when text is large.
            ViewThatFits {
                HStack(spacing: 6) { termsLinks(separators: true) }
                VStack(spacing: 4) { termsLinks(separators: false) }
            }
        }
        .dxFont(12, weight: 400, style: .caption2)
        .foregroundStyle(PW.muted)
        .tint(PW.muted)
    }

    @ViewBuilder
    private func termsLinks(separators: Bool) -> some View {
        Button("How billing works") { showBilling = true }.buttonStyle(.plain).underline()
        if separators { Text(verbatim: "·") }
        Link("Terms", destination: AppLinks.terms).underline()
        if let privacy = AppLinks.privacy {
            if separators { Text(verbatim: "·") }
            Link("Privacy", destination: privacy).underline()
        }
    }

    // MARK: Failed

    private var failed: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, DX.Layout.gutter).padding(.top, DX.Space.xs).dxReadableColumn()
            Spacer()
            V4StateView(.error, systemImage: "exclamationmark.circle", title: "Couldn't reach the App Store",
                        message: "Check your connection and try again. Prep 1 to 3, your counter and Craving SOS work without it.",
                        actionTitle: "Try again") { Task { await model.load() } }
            Spacer()
            Button("Continue with free") {
                model.dismissed()
                onClose()
            }
            .buttonStyle(.dx(.quiet, on: .apricot))
            .padding(.bottom, DX.Space.xs)
        }
    }
}

private struct PlanRow: View {
    let option: PlanOption
    let isSelected: Bool
    let savingPercent: Int?
    let action: () -> Void

    var body: some View {
        let g = PW.ground
        let shape = RoundedRectangle(cornerRadius: DX.Layout.optionRadius, style: .continuous)
        return Button(action: action) {
            HStack(spacing: 14) {
                // The kit radio: a filled ink disc with a tick when chosen.
                ZStack {
                    if isSelected {
                        Circle().fill(g.sel)
                        DXIconShape(d: DX.Icon.check.d)
                            .stroke(g.selFg, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                            .frame(width: 14, height: 14)
                    } else {
                        Circle().strokeBorder(PW.faint, lineWidth: 2)
                    }
                }
                .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).dxType(.headline).foregroundStyle(PW.ink)
                    Text(detail).dxType(.footnote).foregroundStyle(PW.muted)
                }
                Spacer(minLength: DX.Space.xs)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(verbatim: option.priceText).dxFace(.display, isSelected ? 22 : 17, weight: 800, tracking: -0.4)
                        .monospacedDigit().foregroundStyle(PW.ink)
                    Text(period).dxType(.caption).foregroundStyle(PW.muted)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(minHeight: 64)
            .background(isSelected ? g.selTint : g.card, in: shape)
            .overlay(shape.strokeBorder(isSelected ? g.selEdge : g.line, lineWidth: isSelected ? 2 : 1))
            .overlay(alignment: .topLeading) {
                if let days = option.trialDays {
                    Text(savingPercent.map { "\(days) days free · save \($0)%" as LocalizedStringKey } ?? "\(days) days free")
                        .dxType(.caption)
                        .foregroundStyle(PW.onInk)
                        .padding(.vertical, 4).padding(.horizontal, 10)
                        .background(PW.ink, in: Capsule())
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
        case .monthly: "Monthly"
        case .lifetime: "Lifetime"
        }
    }

    private var detail: LocalizedStringKey {
        switch option.plan {
        case .annual:
            if let perMonth = option.perMonthText {
                // With a trial, the badge carries the saving.
                if let savingPercent, option.trialDays == nil { return "\(perMonth) a month · save \(savingPercent)%" }
                return "\(perMonth) a month"
            }
            return "Billed yearly"
        case .monthly: return "Cancel anytime"
        case .lifetime: return "Pay once"
        }
    }

    private var period: LocalizedStringKey {
        switch option.plan {
        case .annual: "per year"
        case .monthly: "per month"
        case .lifetime: "one time"
        }
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
            Text(title).v4Text(.title).multilineTextAlignment(.center)
            Text(message).v4Text(.subtitle).multilineTextAlignment(.center)
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
            Text(text).dxFont(14, weight: 400, style: .footnote).foregroundStyle(PW.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                Image(systemName: "xmark").font(.system(size: 11, weight: .semibold)).foregroundStyle(PW.muted)
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
                Text("How billing works").v4Text(.title).dxFont(24, weight: 700, style: .title2)
                Text("Plain and simple. Apple handles every payment.").v4Text(.subtitle)
                Text("Cancel in two taps").v4Text(.micro).padding(.top, DX.Space.m)
                step(1, "Tap **Manage subscription** below")
                step(2, "Tap **Cancel subscription**")
                Text("Free trial").v4Text(.micro).padding(.top, DX.Space.s)
                Text("Cancel any time before it ends and you pay nothing. We'll remind you 2 days before.").v4Text(.subtitle)
                Text("Refunds").v4Text(.micro).padding(.top, DX.Space.s)
                Text("Refunds go through Apple. You can request one at reportaproblem.apple.com.").v4Text(.subtitle)
                Button("Manage subscription") { manage = true }
                    .buttonStyle(.v4Secondary)
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
                .dxFont(12, weight: 700, style: .caption2)
                .foregroundStyle(PW.ink)
                .frame(width: 24, height: 24)
                .background(PW.surface, in: Circle())
            Text(text).dxFont(14, weight: 400, style: .footnote).foregroundStyle(PW.ink)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The line every screen that sells the full program shows about what stays free (S27.2, MON-01).
enum FreeLine {
    static var text: LocalizedStringKey { "Always free: Prep 1 to 3, your counter, Craving SOS and a 60-second breathing timer." }
}

/// "Costs 8 days of smoking" with where the number comes from (MON-03).
struct PriceAnchorLine: View {
    let anchor: PriceAnchor
    var ground: DX.Ground = .reading

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: Self.title(anchor)).dxFont(16, weight: 700, style: .headline).foregroundStyle(ground.ink)
            Text("A year of the full program, against what you told us you spend.")
                .dxFont(12, weight: 400, style: .caption1).foregroundStyle(ground.muted)
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
