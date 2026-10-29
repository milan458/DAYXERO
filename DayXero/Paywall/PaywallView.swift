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
    let products: [DayXeroCore.Product]
    /// What a pack of their cigarettes costs, when they buy by the pack.
    let packPrice: Decimal?

    init(profile: UserProfile) {
        triggers = profile.triggers
        obstacles = profile.obstaclesRaw.compactMap(Obstacle.init(rawValue:))
        moneyPerDay = profile.products.reduce(Decimal(0)) { $0 + $1.baseline.costPerDay }
        currencyCode = profile.currencyCode
        products = profile.products.map(\.product)
        packPrice = profile.products.first { $0.product == .cigarettes && $0.unitsPerPurchase >= 10 }?.pricePerPurchase
    }

    #if DEBUG
    /// For screenshots of the first-run paywall (`-dx.paywallFirstRun YES`).
    init(sampleCurrency currency: String) {
        triggers = [.coffee, .stress]
        obstacles = [.stress, .cravings]
        moneyPerDay = currency == "INR" ? 478 : 8
        currencyCode = currency
        products = [.cigarettes, .vape]
        packPrice = currency == "INR" ? 500 : 10
    }
    #endif

    /// "stress and cravings", from what got in the way before, or else their triggers.
    var focus: String? {
        let words = obstacles.contains(.stress) || obstacles.contains(.cravings)
            ? [Obstacle.stress, .cravings].filter(obstacles.contains).map { String(localized: $0.title).lowercased() }
            : Array(triggers.prefix(2)).map { String(localized: $0.title).lowercased() }
        return words.isEmpty ? nil : ListFormatter.localizedString(byJoining: words)
    }
}

/// The full paywall (S3.1–S3.6). After onboarding it's S22's hard paywall: one promise, three bullets, trust,
/// two plans and one button, with the close button appearing after a few seconds. From Settings it's the plain one.
struct PaywallView: View {
    let name: String
    let quitDay: Date
    @State var model: PaywallModel
    var context: PaywallContext? = nil
    let onClose: () -> Void
    /// Called as a purchase or restore starts, before the person can turn Pro.
    var onPurchaseStarted: () -> Void = {}

    @State private var showBilling = false
    /// First run: ✕ fades in after a few seconds (straight away with VoiceOver).
    @State private var closeShown = false
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
        .task {
            guard context != nil, !UIAccessibility.isVoiceOverRunning else { closeShown = true; return }
            try? await Task.sleep(for: .seconds(3))
            withAnimation(DX.Motion.animation(DX.Motion.glide, reduceMotion: reduceMotion)) { closeShown = true }
        }
        .sheet(isPresented: $showBilling) { BillingSheet().presentationDetents([.medium, .large]) }
    }

    private var unlockedMessage: LocalizedStringKey {
        if let end = model.trialEndDate, model.selectedOption?.trialDays != nil {
            return model.canRemind
                ? "Your free trial runs until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)). We'll remind you \(reminderLead) before it ends."
                : "Your free trial runs until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))."
        }
        return "The full program is unlocked. Let's get you ready for Quit Day."
    }

    // MARK: Main

    @ViewBuilder
    private var main: some View {
        if context != nil { firstRun } else { standard }
    }

    private var standard: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, DX.Space.m).padding(.top, DX.Space.xs).dxReadableColumn()
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    Text("\(name), your plan is ready").dxText(.title).accessibilityAddTraits(.isHeader)
                    Text("Everything for your \(quitDay, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)) Quit Day.")
                        .dxText(.subtitle)
                    VStack(alignment: .leading, spacing: 7) {
                        included("All of prep, Quit week and 4 weeks after")
                        included("Insights on your triggers")
                        included("NRT planner, health timeline, share cards")
                    }
                    .padding(.vertical, DX.Space.s)
                    plans
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

    // MARK: First run (S22)

    private var firstRun: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, DX.Space.m).padding(.top, DX.Space.xs).dxReadableColumn()
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.s) {
                    Text("Custom plan ready · \(quitDay, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))")
                        .dxText(.micro, color: DX.Palette.accentInk)
                    Text(firstRunTitle).dxText(.title).fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                    VStack(alignment: .leading, spacing: DX.Space.xs) {
                        included("Complete prep, Quit week and 4 weeks after")
                        included(context?.products.count ?? 0 > 1 ? "Craving SOS any time, plus your dual-use tracker"
                                                                   : "Craving SOS any time, plus your daily tracker")
                        included("NRT step-down planner for patches and gum")
                    }
                    .padding(.vertical, DX.Space.xxs)
                    trustCard
                    planCards
                    if typeSize.isAccessibilitySize {
                        firstRunFooter.padding(.top, DX.Space.l)
                    }
                }
                .padding(.horizontal, DX.Space.m)
                .dxReadableColumn()
                .padding(.top, DX.Space.s)
                .padding(.bottom, DX.Space.xl)
            }
            if !typeSize.isAccessibilitySize {
                firstRunFooter
                    .padding(.horizontal, DX.Space.m)
                    .dxReadableColumn()
                    .padding(.bottom, DX.Space.xs)
                    .background(alignment: .bottom) {
                        Hills(still: reduceMotion).frame(height: 150).opacity(0.55).ignoresSafeArea().allowsHitTesting(false)
                    }
            }
        }
    }

    private var firstRunTitle: LocalizedStringKey {
        let date = quitDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        if let focus = context?.focus { return "Beat \(focus) on \(date)" }
        return "Quit on \(date) without the cold-turkey shock"
    }

    /// Plain facts in place of reviews, until there are real ones to show.
    private var trustCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            trust("lock", "Your answers stay on this phone")
            trust("doc.text", "NRT advice from a Cochrane review of 133 trials")
            trust("hand.tap", "Cancel in two taps, in Settings")
        }
        .padding(DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(DX.Palette.hairline))
        .accessibilityElement(children: .combine)
    }

    private func trust(_ systemImage: String, _ text: LocalizedStringKey) -> some View {
        Label {
            Text(text).font(.custom(DX.Typeface.regular, size: 13, relativeTo: .footnote)).foregroundStyle(DX.Palette.text2)
        } icon: {
            Image(systemName: systemImage).font(.system(size: 13, weight: .light)).foregroundStyle(DX.Palette.accentInk)
        }
    }

    @ViewBuilder
    private var planCards: some View {
        let recurring = model.plans.filter { $0.plan != .lifetime }
        if recurring.isEmpty {
            HStack(spacing: DX.Space.s) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 22, style: .continuous).fill(DX.Palette.surface2).frame(height: 132)
                }
            }
            .accessibilityHidden(true)
        } else {
            HStack(alignment: .bottom, spacing: DX.Space.s) {
                ForEach(recurring) { option in planCard(option) }
            }
            .padding(.top, DX.Space.s)
        }
        if let lifetime = model.plans.first(where: { $0.plan == .lifetime }) {
            PlanRow(option: lifetime, isSelected: model.selected == .lifetime, savingPercent: nil) { model.select(.lifetime) }
        }
    }

    private func planCard(_ option: PlanOption) -> some View {
        let selected = model.selected == option.plan
        return Button { model.select(option.plan) } label: {
            VStack(spacing: 4) {
                Text(option.plan == .annual ? "Yearly" : "Monthly")
                    .font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline)).foregroundStyle(DX.Palette.text2)
                Text(verbatim: option.priceText + (option.plan == .annual ? String(localized: "/yr") : String(localized: "/mo")))
                    .font(.custom(DX.Typeface.bold, size: option.plan == .annual ? 24 : 20, relativeTo: .title2))
                    .foregroundStyle(DX.Palette.text)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Text(planDetail(option)).font(.custom(DX.Typeface.regular, size: 11, relativeTo: .caption2))
                    .foregroundStyle(DX.Palette.text2).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, option.plan == .annual ? 22 : 14).padding(.bottom, 14).padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(selected ? DX.Palette.accentInk : DX.Palette.hairline, lineWidth: selected ? 1.5 : 1))
            .overlay(alignment: .top) {
                if option.plan == .annual, let days = option.trialDays {
                    Text(model.annualSavingPercent.map { "\(days) DAYS FREE · SAVE \($0)%" as LocalizedStringKey } ?? "\(days) DAYS FREE")
                        .font(.custom(DX.Typeface.bold, size: 10, relativeTo: .caption2)).tracking(0.4)
                        .foregroundStyle(DX.Palette.onAccent)
                        .padding(.vertical, 4).padding(.horizontal, 9)
                        .background(DX.Palette.sage, in: Capsule())
                        .offset(y: -10)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(DX.Haptic.select, trigger: selected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    /// "₹249/mo · Less than half a pack a month", or for monthly, how it bills.
    private func planDetail(_ option: PlanOption) -> LocalizedStringKey {
        switch option.plan {
        case .annual:
            guard let perMonth = option.perMonthText else { return "Billed yearly" }
            if let context, let pack = context.packPrice, context.currencyCode == option.currencyCode, pack > 0 {
                let monthly = option.price / 12
                if monthly < pack / 2 { return "\(perMonth)/mo · Less than half a pack a month" }
                if monthly < pack { return "\(perMonth)/mo · Less than a pack a month" }
            }
            return "\(perMonth)/mo"
        case .monthly:
            if let days = option.trialDays { return "\(days) days free · Cancel anytime" }
            return "Billed today · Cancel anytime"
        case .lifetime:
            return "Pay once"
        }
    }

    private var firstRunFooter: some View {
        VStack(spacing: DX.Space.xs) {
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
            if let option = model.selectedOption {
                Group {
                    if option.plan == .annual, option.trialDays != nil {
                        Text("\(Decimal(0).formatted(.currency(code: option.currencyCode).precision(.fractionLength(0)))) due today. Cancel any time in Settings.")
                    } else {
                        chargeLine(option)
                    }
                }
                .font(.custom(DX.Typeface.regular, size: 12, relativeTo: .caption))
                .foregroundStyle(DX.Palette.text2)
                .multilineTextAlignment(.center)
            }
            terms
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
                Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DX.Palette.text2)
                    .frame(width: 36, height: 36)
                    .background(DX.Palette.surface1, in: Circle())
                    .overlay(Circle().strokeBorder(DX.Palette.hairline))
            }
            .buttonStyle(.plain)
            .opacity(context == nil || closeShown ? 1 : 0)
            .disabled(!(context == nil || closeShown))
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
                Text("Cancel any time before it ends and you pay nothing. We'll remind you 2 days before.").dxText(.subtitle)
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
