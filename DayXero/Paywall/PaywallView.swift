import DayXeroCore
import StoreKit
import SwiftUI

/// Legal links shown on the paywall. Privacy policy URL still to come from Milan (S15.4).
enum AppLinks {
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy: URL? = nil
}

/// What onboarding learnt, so the first-run paywall can speak to it (S22).
struct PaywallContext {
    let triggers: [Trigger]
    let obstacles: [Obstacle]
    /// Nicotine spending a day, in the profile's currency.
    let moneyPerDay: Decimal
    let currencyCode: String

    init(profile: UserProfile) {
        triggers = profile.triggers
        obstacles = profile.obstaclesRaw.compactMap(Obstacle.init(rawValue:))
        moneyPerDay = profile.products.reduce(Decimal(0)) { $0 + $1.baseline.costPerDay }
        currencyCode = profile.currencyCode
    }

    /// "stress and cravings", from what got in the way before, or else their triggers.
    var focus: String? {
        let words = obstacles.contains(.stress) || obstacles.contains(.cravings)
            ? [Obstacle.stress, .cravings].filter(obstacles.contains).map { String(localized: $0.title).lowercased() }
            : Array(triggers.prefix(2)).map { String(localized: $0.title).lowercased() }
        return words.isEmpty ? nil : ListFormatter.localizedString(byJoining: words)
    }
}

/// The full paywall shown after the plan reveal (S3.1–S3.6), with S22's trial timeline.
struct PaywallView: View {
    let name: String
    let quitDay: Date
    @State var model: PaywallModel
    var context: PaywallContext? = nil
    let onClose: () -> Void
    /// Called as a purchase or restore starts, before the person can turn Pro.
    var onPurchaseStarted: () -> Void = {}

    @State private var showBilling = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                               button: "Start Day 1 meanwhile", action: onClose)
            case .unlocked:
                PaywallMessage(systemImage: "checkmark", tint: .sage, title: "You're all set, \(name)",
                               message: unlockedMessage, button: "Start prep day 1", action: onClose)
                    .sensoryFeedback(DX.Haptic.commit, trigger: model.phase)
            }
            if let notice = model.notice {
                NoticeBanner(text: notice) { model.notice = nil }
                    .padding(.horizontal, DX.Space.s)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(DX.Motion.animation(DX.Motion.glide, reduceMotion: reduceMotion), value: model.phase)
        .animation(DX.Motion.animation(DX.Motion.glide, reduceMotion: reduceMotion), value: model.notice != nil)
        .dxCanvas()
        .task { await model.load() }
        .sheet(isPresented: $showBilling) { BillingSheet().presentationDetents([.medium, .large]) }
    }

    private var unlockedMessage: LocalizedStringKey {
        if let end = model.trialEndDate, model.selectedOption?.trialDays != nil {
            return model.canRemind
                ? "Your free trial runs until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)). We'll remind you the day before it ends."
                : "Your free trial runs until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))."
        }
        return "The full program is unlocked. Let's get you ready for Quit Day."
    }

    // MARK: Main

    private var main: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, DX.Space.m).padding(.top, DX.Space.xs).dxReadableColumn()
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    Text(context == nil ? "\(name), your plan is ready" : "\(name), your prep and craving plan is ready")
                        .dxText(.title).accessibilityAddTraits(.isHeader)
                    Group {
                        if let focus = context?.focus {
                            Text("Built around \(focus), ready for your \(quitDay, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)) Quit Day.")
                        } else {
                            Text("Everything for your \(quitDay, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)) Quit Day.")
                        }
                    }
                    .font(.custom(DX.Typeface.regular, size: 15, relativeTo: .body))
                    .foregroundStyle(DX.Palette.text2)
                    if let option = model.selectedOption, option.trialDays != nil, let end = model.trialEndDate {
                        trialTimeline(option, end: end).padding(.vertical, DX.Space.s)
                    } else {
                        VStack(alignment: .leading, spacing: 7) {
                            included("All of prep, Quit week and 4 weeks after")
                            included("Insights on your triggers")
                            included("NRT planner, health timeline, share cards")
                        }
                        .padding(.vertical, DX.Space.s)
                    }
                    plans
                    if let anchor { anchorLine(anchor) }
                    if typeSize.isAccessibilitySize {
                        footer.padding(.top, DX.Space.l)
                    }
                }
                .padding(.horizontal, DX.Space.m)
                .dxReadableColumn()
                .padding(.top, DX.Space.m)
                .padding(.bottom, typeSize.isAccessibilitySize ? DX.Space.xl : 0)
            }
            if !typeSize.isAccessibilitySize {
                footer
                    .padding(.horizontal, DX.Space.m)
                    .dxReadableColumn()
                    .padding(.bottom, DX.Space.xs)
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                model.dismissed()
                onClose()
            } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DX.Palette.text2)
                    .frame(width: 36, height: 36)
                    .background(DX.Palette.surface1, in: Circle())
                    .overlay(Circle().strokeBorder(DX.Palette.hairline))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Close and continue with the free version"))
            Spacer()
            Button("Restore purchases") {
                onPurchaseStarted()
                Task { await model.restore() }
            }
                .font(.custom(DX.Typeface.medium, size: 13, relativeTo: .footnote))
                .foregroundStyle(DX.Palette.text2)
                .buttonStyle(.plain)
        }
        .frame(minHeight: 44)
    }

    private func included(_ text: LocalizedStringKey) -> some View {
        Label {
            Text(text).font(.custom(DX.Typeface.regular, size: 14, relativeTo: .subheadline)).foregroundStyle(DX.Palette.text)
        } icon: {
            Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(DX.Palette.accentInk)
        }
    }

    /// Today, the reminder, and the first charge, so nothing about the trial is a surprise (S22).
    private func trialTimeline(_ option: PlanOption, end: Date) -> some View {
        let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end
        let endsOnQuitDay = Calendar.current.isDate(end, inSameDayAs: quitDay)
        var rows: [(emoji: String, when: String, what: LocalizedStringKey, detail: LocalizedStringKey)] = [
            ("🔓", String(localized: "Today"), "Nothing to pay", "The full program unlocks: every lesson, insights and the NRT planner."),
        ]
        if model.canRemind {
            rows.append(("🔔", dayBefore.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)), "Reminder",
                         "We'll remind you the day before your trial ends."))
        }
        rows.append(("⭐", end.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)), endsOnQuitDay ? "Quit Day" : "Trial ends",
                     "First charge of \(option.priceText) a year, unless you cancel before in Settings."))
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(alignment: .top, spacing: DX.Space.s) {
                    Text(verbatim: row.emoji).font(.system(size: 15))
                        .frame(width: 34, height: 34).background(DX.Palette.accentSoft, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        (Text(verbatim: row.when).foregroundStyle(DX.Palette.text) + Text(verbatim: " · ").foregroundStyle(DX.Palette.muted)
                         + Text(row.what).foregroundStyle(DX.Palette.accentInk))
                            .font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline))
                        Text(row.detail).dxText(.subtitle).fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, index < rows.count - 1 ? DX.Space.m : 0)
                }
                // The line down to the next row runs the full height of this one.
                .background(alignment: .topLeading) {
                    if index < rows.count - 1 {
                        Rectangle().fill(DX.Palette.sage.opacity(0.6)).frame(width: 2).padding(.top, 34).padding(.leading, 16)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(DX.Palette.hairline))
    }

    /// Their daily nicotine spend next to DayXero's daily cost, when both are in the same currency.
    private var anchor: (spend: String, cost: String)? {
        guard let context, context.moneyPerDay > 0,
              let annual = model.plans.first(where: { $0.plan == .annual }), annual.currencyCode == context.currencyCode else { return nil }
        let style = Decimal.FormatStyle.Currency(code: annual.currencyCode).precision(.fractionLength(0))
        return (context.moneyPerDay.formatted(style), (annual.price / 365).formatted(style))
    }

    private func anchorLine(_ anchor: (spend: String, cost: String)) -> some View {
        Label {
            Text("You spend \(anchor.spend) a day on nicotine. DayXero is about \(anchor.cost) a day.")
        } icon: {
            Image(systemName: "creditcard").font(.system(size: 13, weight: .light))
        }
        .font(.custom(DX.Typeface.semibold, size: 12, relativeTo: .caption))
        .foregroundStyle(DX.Palette.accentInk)
        .padding(.vertical, 10).padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Palette.accentSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.top, DX.Space.xs)
    }

    @ViewBuilder
    private var plans: some View {
        VStack(spacing: DX.Space.xs) {
            if model.plans.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(DX.Palette.surface2).frame(height: 60)
                }
                .accessibilityHidden(true)
            } else {
                ForEach(model.plans) { option in
                    PlanRow(option: option, isSelected: model.selected == option.plan, savingPercent: model.annualSavingPercent) {
                        model.select(option.plan)
                    }
                }
            }
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
                    ProgressView().tint(DX.Palette.onPrimary)
                } else {
                    Text(ctaTitle)
                }
            }
            .buttonStyle(.dxPrimary)
            .disabled(model.phase != .ready)
            .accessibilityIdentifier("paywall.cta")
            Button("Continue with the basic tracker") {
                model.dismissed()
                onClose()
            }
            .buttonStyle(.dxQuiet)
            terms
        }
    }

    private func chargeLine(_ option: PlanOption) -> some View {
        Group {
            switch option.plan {
            case .annual:
                if let end = model.trialEndDate {
                    Text("Free until \(Text(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)).bold()), then \(option.priceText) a year.")
                    + (model.canRemind ? Text("\nWe'll remind you the day before.") : Text(""))
                } else {
                    Text("\(Text("\(option.priceText) today").bold()), then every year until you cancel.")
                }
            case .monthly:
                Text("\(Text("\(option.priceText) today").bold()), then every month until you cancel.")
            case .lifetime:
                Text("\(Text("\(option.priceText) once.").bold()) No subscription, nothing to cancel.")
            }
        }
        .font(DX.TextStyle.subtitle.font)
        .foregroundStyle(DX.Palette.text2)
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
        .font(.custom(DX.Typeface.regular, size: 11, relativeTo: .caption2))
        .foregroundStyle(DX.Palette.muted)
        .tint(DX.Palette.text2)
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
            header.padding(.horizontal, DX.Space.m).padding(.top, DX.Space.xs).dxReadableColumn()
            Spacer()
            DXStateView(.error, systemImage: "exclamationmark.circle", title: "Couldn't reach the App Store",
                        message: "Check your connection and try again. Day 1, your counter and Craving SOS work without it.",
                        actionTitle: "Try again") { Task { await model.load() } }
            Spacer()
            Button("Continue with free") {
                model.dismissed()
                onClose()
            }
            .buttonStyle(.dxQuiet)
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
        Button(action: action) {
            HStack(spacing: DX.Space.s) {
                ZStack {
                    Circle().strokeBorder(isSelected ? .clear : DX.Palette.faint, lineWidth: 1.5)
                    if isSelected {
                        Circle().fill(DX.Palette.sage)
                        Circle().fill(Color.black).frame(width: 7, height: 7)
                    }
                }
                .frame(width: 20, height: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                    Text(detail).dxText(.subtitle)
                }
                Spacer(minLength: DX.Space.xs)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(verbatim: option.priceText).font(.custom(DX.Typeface.bold, size: 15, relativeTo: .body))
                        .monospacedDigit().foregroundStyle(DX.Palette.text)
                    Text(period).font(.custom(DX.Typeface.medium, size: 11, relativeTo: .caption2)).foregroundStyle(DX.Palette.muted)
                }
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? DX.Palette.accentInk : DX.Palette.hairline, lineWidth: isSelected ? 1.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if let days = option.trialDays {
                    Text(savingPercent.map { "\(days) DAYS FREE · SAVE \($0)%" as LocalizedStringKey } ?? "\(days) DAYS FREE")
                        .font(.custom(DX.Typeface.bold, size: 10, relativeTo: .caption2))
                        .tracking(0.4)
                        .foregroundStyle(DX.Palette.onAccent)
                        .padding(.vertical, 3).padding(.horizontal, 8)
                        .background(DX.Palette.sage, in: Capsule())
                        .offset(x: -14, y: -9)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                .foregroundStyle(tint == .sage ? DX.Palette.onAccent : DX.Palette.accentInk)
                .frame(width: 76, height: 76)
                .background(tint == .sage ? DX.Palette.sage : DX.Palette.accentSoft, in: Circle())
                .accessibilityHidden(true)
            Text(title).dxText(.title).multilineTextAlignment(.center)
            Text(message).dxText(.subtitle).multilineTextAlignment(.center)
            Spacer()
            Button(button, action: action).buttonStyle(.dxPrimary)
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
            Image(systemName: "exclamationmark.circle").foregroundStyle(DX.Palette.amber)
            Text(text).font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                Image(systemName: "xmark").font(.system(size: 11, weight: .semibold)).foregroundStyle(DX.Palette.muted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Dismiss"))
        }
        .padding(DX.Space.s)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DX.Palette.hairline))
        .shadow(color: DX.Palette.shadow, radius: 16, y: 8)
        .accessibilityElement(children: .combine)
    }
}

/// "How billing works" (S3.4): cancelling in two taps, trial, refunds.
struct BillingSheet: View {
    @State private var manage = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                Text("How billing works").dxText(.title).font(.custom(DX.Typeface.bold, size: 22, relativeTo: .title2))
                Text("Plain and simple. Apple handles every payment.").dxText(.subtitle)
                Text("Cancel in two taps").dxText(.micro).padding(.top, DX.Space.m)
                step(1, "Tap **Manage subscription** below")
                step(2, "Tap **Cancel subscription**")
                Text("Free trial").dxText(.micro).padding(.top, DX.Space.s)
                Text("Cancel any time before it ends and you pay nothing. We'll remind you the day before.").dxText(.subtitle)
                Text("Refunds").dxText(.micro).padding(.top, DX.Space.s)
                Text("Refunds go through Apple. You can request one at reportaproblem.apple.com.").dxText(.subtitle)
                Button("Manage subscription") { manage = true }
                    .buttonStyle(.dxSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, DX.Space.m)
            }
            .padding(DX.Space.l)
        }
        .dxCanvas()
        .manageSubscriptionsSheet(isPresented: $manage)
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            Text(verbatim: "\(number)")
                .font(.custom(DX.Typeface.bold, size: 11, relativeTo: .caption2))
                .foregroundStyle(DX.Palette.text)
                .frame(width: 24, height: 24)
                .background(DX.Palette.surface2, in: Circle())
            Text(text).font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text)
        }
        .accessibilityElement(children: .combine)
    }
}
