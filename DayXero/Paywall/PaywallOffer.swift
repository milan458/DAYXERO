import DayXeroCore
import SwiftUI

// Paywall v2 (18 Nov 2026), drawn to the canvas "DayXero onboarding: three new screens", page "Paywall v2" (board D):
//   1  What you'll keep      the person's own spend as a year, a month and a week, with Xero and the coins.
//   2  Everything in Pro     the eight things the full program holds.
//   3  The offer             what happens when, what they keep, the two plans and the button.
// After onboarding (the hard paywall) all three pages run in order. Opened from inside the app it starts on the offer,
// with a close button: someone who tapped "Subscription" already knows what the app is.

/// Paywall v2's palette: a cream page in light, the one navy in dark.
enum PW2 {
    static let background = Color(light: 0xFFFAF3, dark: 0x0E1322)
    static let ink = Color(light: 0x1E1A3A, dark: 0xFFF8EE)
    static let muted = Color(light: 0x4A2810, dark: 0xB3BACC)
    static let coral = Color(light: 0xF2603C, dark: 0xFF8A65)
    static let mark = Color(light: 0xFF7A55, dark: 0xFF8A65)
    static let card = Color(light: 0xFFFFFF, dark: 0x182034)
    static let card2 = Color(light: 0xFFE7D0, dark: 0x212A41)
    static let soft = Color(light: 0xFFE9D6, dark: 0x262F48)
    static let selTint = Color(light: 0xFFF0E4, dark: 0x262F48)
    static let selEdge = Color(light: 0xF26A45, dark: 0xFFB27A)
    static let strip = Color(light: 0xFFF1E2, dark: 0x182034)
    static let gold = Color(hex: 0xFFC93C)
    static let goldEdge = Color(hex: 0xF29A2E)
    static let goldInk = Color(hex: 0xB8650F)
    static let cream = Color(hex: 0xFFF8EE)
    static let navy = Color(hex: 0x1E1A3A)
}

struct PaywallOffer: View {
    let name: String
    let quitDay: Date
    let model: PaywallModel
    let spend: PaywallModel.Spend?
    let closable: Bool
    let onClose: () -> Void
    let onPurchaseStarted: () -> Void

    @State private var step: Int
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize
    private let motion = MotionPolicy()

    init(name: String, quitDay: Date, model: PaywallModel, spend: PaywallModel.Spend?, closable: Bool,
         onClose: @escaping () -> Void, onPurchaseStarted: @escaping () -> Void) {
        self.name = name
        self.quitDay = quitDay
        self.model = model
        self.spend = spend
        self.closable = closable
        self.onClose = onClose
        self.onPurchaseStarted = onPurchaseStarted
        var first = closable ? 3 : 1
        #if DEBUG
        // For screenshots: `-dx.paywallStep 1|2|3`.
        let forced = UserDefaults.standard.integer(forKey: "dx.paywallStep")
        if (1...3).contains(forced) { first = forced }
        #endif
        _step = State(initialValue: first)
    }

    private var dark: Bool { scheme == .dark }

    /// There is a spend to show: without one the savings page is skipped and the flow is two pages.
    private var hasSavings: Bool { (spend?.perYear ?? 0) > 0 }
    private var page: Int { step == 1 && !hasSavings ? 2 : step }

    private var annual: PlanOption? { model.plans.first { $0.plan == .annual } }

    var body: some View {
        Group {
            switch page {
            case 1: savings
            case 2: everything
            default: offer
            }
        }
        .transition(.opacity)
        .id(page)
        .animation(motion.animation(DX.Move.settle), value: page)
        .background(PW2.background.ignoresSafeArea())
    }

    private func go(_ to: Int) {
        withAnimation(motion.animation(DX.Move.settle)) { step = to }
    }

    // MARK: Shared pieces

    /// The top bar of pages 1 and 2: back (or close) on the left, the step dots in the middle.
    private var topBar: some View {
        let count = hasSavings ? 3 : 2
        let current = hasSavings ? page : page - 1
        return ZStack {
            HStack(spacing: 6) {
                ForEach(1...count, id: \.self) { i in
                    Capsule()
                        .fill(i == current ? PW2.ink : PW2.ink.opacity(0.14))
                        .frame(width: i == current ? 22 : 6, height: 6)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(Text("Step \(current) of \(count)"))
            HStack {
                if page == 2 && hasSavings {
                    roundButton(label: "Back") { go(1) }
                } else if closable {
                    roundButton(label: "Close", action: onClose)
                }
                Spacer()
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 22)
        .padding(.top, 6)
    }

    private func roundButton(label: LocalizedStringKey, fill: Color = PW2.card2, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            DXIcon(.back, size: 20, weight: 2.4)
                .foregroundStyle(PW2.ink)
                .frame(width: 44, height: 44)
                .background(fill, in: Circle())
        }
        .buttonStyle(.dxPress)
        .accessibilityLabel(Text(label))
    }

    /// A page: its content scrolls when it has to, the button stays at the bottom.
    private func pageBody<Content: View, Footer: View>(padding: CGFloat, @ViewBuilder content: () -> Content,
                                                       @ViewBuilder footer: () -> Footer) -> some View {
        ScrollView {
            content()
                .padding(.horizontal, padding)
                .dxReadableColumn()
                .padding(.bottom, DX.Space.s)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer()
                .padding(.horizontal, padding)
                .dxReadableColumn()
                .padding(.top, 10)
                .padding(.bottom, DX.Space.xs)
                .background(PW2.background.ignoresSafeArea(edges: .bottom))
        }
    }

    private func money(_ amount: Decimal, digits: Int = 0) -> String {
        amount.formatted(.currency(code: spend?.currencyCode ?? "USD").precision(.fractionLength(digits)))
    }

    private func anchor(_ option: PlanOption?) -> PriceAnchor? {
        guard let option, let spend else { return nil }
        return PriceAnchor.make(price: option.price, priceCurrency: option.currencyCode, spendPerYear: spend.perYear,
                                spendCurrency: spend.currencyCode, products: spend.products)
    }

    /// "about 8 days of smoking": a plan's price in the person's own habit.
    static func daysOf(_ anchor: PriceAnchor) -> String {
        let n = anchor.days
        switch anchor.habit {
        case .smoking: return n == 1 ? String(localized: "about 1 day of smoking") : String(localized: "about \(n) days of smoking")
        case .vaping: return n == 1 ? String(localized: "about 1 day of vaping") : String(localized: "about \(n) days of vaping")
        case .pouches: return n == 1 ? String(localized: "about 1 day of pouches") : String(localized: "about \(n) days of pouches")
        case .nicotine: return n == 1 ? String(localized: "about 1 day of nicotine") : String(localized: "about \(n) days of nicotine")
        }
    }

    private var dayFormat: Date.FormatStyle { .dateTime.weekday(.abbreviated).month(.abbreviated).day() }

    // MARK: 1 · What you'll keep

    private var savings: some View {
        let perYear = spend?.perYear ?? 0
        let perDay = perYear / 365
        return VStack(spacing: 0) {
            topBar
            pageBody(padding: 26) {
                VStack(spacing: 0) {
                    savingsArt
                        .padding(.top, 10)
                        .dxArrive(0)
                    VStack(spacing: 0) {
                        Text(verbatim: keepLead).lineLimit(1).minimumScaleFactor(0.6)
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text(verbatim: money(perYear)).lineLimit(1).minimumScaleFactor(0.6).dxMark(.underline, color: PW2.mark)
                            Text(verbatim: "\u{00A0}" + String(localized: "this year")).lineLimit(1).minimumScaleFactor(0.6)
                        }
                    }
                    .dxFace(.display, 30, weight: 800, tracking: -0.9)
                    .foregroundStyle(PW2.ink)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: keepLead + " " + money(perYear) + " " + String(localized: "this year")))
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 26)
                    .dxArrive(1)
                    Text(verbatim: costLine(perDay: money(perDay, digits: perDay < 5 ? 2 : 0)))
                        .dxFace(.body, 16, weight: 400)
                        .foregroundStyle(PW2.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)
                        .dxArrive(1)
                    ladder(perYear: perYear, perDay: perDay)
                        .padding(.top, 26)
                        .dxArrive(2)
                }
                .frame(maxWidth: .infinity)
            } footer: {
                VStack(spacing: 14) {
                    if let anchor = anchor(annual) {
                        let days = anchor.days == 1 ? String(localized: "about 1 day") : String(localized: "about \(anchor.days) days")
                        Text("DayXero Pro costs \(Text(verbatim: days).dxRun(15, weight: 700).foregroundStyle(PW2.ink)) of it.")
                            .dxFace(.body, 15, weight: 500)
                            .foregroundStyle(PW2.muted)
                            .multilineTextAlignment(.center)
                    }
                    Button("Continue") { go(2) }
                        .buttonStyle(.dx(.primary, on: .reading))
                        .accessibilityIdentifier("paywall.continue")
                }
                .dxArrive(3)
            }
        }
    }

    private var keepLead: String {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? String(localized: "You’ll keep") : String(localized: "\(name), you’ll keep")
    }

    /// "What smoking costs you, at about $5 a day."
    private func costLine(perDay: String) -> String {
        let products = Set(spend?.products ?? [])
        switch products.count > 1 ? nil : products.first {
        case .cigarettes?: return String(localized: "What smoking costs you, at about \(perDay) a day.")
        case .vape?: return String(localized: "What vaping costs you, at about \(perDay) a day.")
        case .pouches?: return String(localized: "What pouches cost you, at about \(perDay) a day.")
        case nil: return String(localized: "What nicotine costs you, at about \(perDay) a day.")
        }
    }

    /// The dawn in a disc, Xero cheering in front of it, four coins around him (272 pt square).
    private var savingsArt: some View {
        // "$" on the coins where the currency has a one-character sign; a plain coin otherwise.
        let sign = money(0).filter { !$0.isNumber && !$0.isWhitespace && $0 != "." && $0 != "," }
        let coins: [(x: CGFloat, y: CGFloat, size: CGFloat, turn: Double)] = [(196, 70, 40, 12), (214, 132, 30, -14), (22, 92, 28, -8), (186, 182, 24, 20)]
        return ZStack(alignment: .topLeading) {
            Group {
                if dark {
                    NightSky(dawn: true, animate: !motion.reduce,
                             options: .init(sunAt: 0.7, sunScale: 1.7, sunLift: 10, softSun: true, stars: false, fade: false))
                } else {
                    HorizonScene(.dawn, clarity: 100, fit: .bottom, animate: !motion.reduce,
                                 sun: .init(x: 250, radius: 44, drop: -10, clouds: false))
                }
            }
            .frame(width: 272, height: 272)
            .background(Color(light: 0xFFD3A6, dark: 0x1F2950))
            .clipShape(Circle())
            Ellipse()
                .fill(RadialGradient(colors: [dark ? Color.black.opacity(0.55) : Color(hex: 0x50140A).opacity(0.35), .clear],
                                     center: .center, startRadius: 0, endRadius: 52))
                .frame(width: 104, height: 16)
                .offset(x: 74, y: 226)
            crew(XeroView(mood: .cheer, stage: 1, points: 132, animate: !motion.reduce), size: 132)
                .offset(x: 60, y: 106)
            ForEach(Array(coins.enumerated()), id: \.offset) { _, coin in
                Coin(size: coin.size, sign: sign.count == 1 ? sign : "")
                    .rotationEffect(.degrees(coin.turn))
                    .shadow(color: Color(hex: 0x783418).opacity(0.25), radius: 5, y: 4)
                    .offset(x: coin.x, y: coin.y)
            }
        }
        .frame(width: 272, height: 272)
        .accessibilityHidden(true)
    }

    /// A character with the canvas's light: a cream rim and a soft drop in light, a warm side glow in dark.
    private func crew<V: View>(_ view: V, size: CGFloat) -> some View {
        view
            .shadow(color: dark ? Color(hex: 0xFFAA5A).opacity(0.45) : PW2.cream.opacity(0.95),
                    radius: dark ? 8 : 2.5, x: dark ? 4 : 0, y: dark ? -2 : 0)
            .shadow(color: dark ? .clear : Color(hex: 0x781E0A).opacity(0.22), radius: 10, y: 6)
            .frame(width: size, height: size)
    }

    /// A week, a month, a year of the spend as three rising bars.
    private func ladder(perYear: Decimal, perDay: Decimal) -> some View {
        let fills: [Color] = dark
            ? [Color(hex: 0xFFAA82).opacity(0.5), Color(hex: 0xFFA078).opacity(0.75), PW2.coral]
            : [PW2.coral.opacity(0.25), PW2.coral.opacity(0.5), PW2.coral]
        let rungs: [(label: LocalizedStringKey, value: String, height: CGFloat, size: CGFloat)] = [
            ("1 week", money(perDay * 7), 26, 18),
            ("1 month", money(perYear / 12), 58, 20),
            ("1 year", money(perYear), 112, 24),
        ]
        return HStack(alignment: .bottom, spacing: 12) {
            ForEach(Array(rungs.enumerated()), id: \.offset) { i, rung in
                VStack(spacing: 8) {
                    Text(verbatim: rung.value)
                        .dxFace(.display, rung.size, weight: 800, tracking: -0.4)
                        .foregroundStyle(PW2.ink)
                        .lineLimit(1).minimumScaleFactor(0.6)
                    UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 6, bottomTrailingRadius: 6, topTrailingRadius: 14,
                                           style: .continuous)
                        .fill(fills[i])
                        .frame(height: rung.height)
                    Text(rung.label)
                        .dxFace(.body, 14, weight: 600)
                        .foregroundStyle(PW2.muted)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: 2 · Everything in Pro

    private struct Feature: Identifiable {
        let id: Int
        let title: LocalizedStringKey
        let detail: LocalizedStringKey
        let icon: String
    }

    private static let features: [Feature] = [
        Feature(id: 0, title: "Your 7-day prep", detail: "A short session a day, before you quit", icon: Glyph.path),
        Feature(id: 1, title: "Quit Day, hour by hour", detail: "Your first day planned before it starts", icon: Glyph.sun),
        Feature(id: 2, title: "Four weeks of coaching", detail: "A weekly session after Quit Day", icon: Glyph.chat),
        Feature(id: 3, title: "Craving SOS with Jelli", detail: "Breathe through any craving, any time", icon: Glyph.wave),
        Feature(id: 4, title: "Mornings and nights", detail: "A pledge with Xero, a check-in with Glim", icon: Glyph.moon),
        Feature(id: 5, title: "NRT tracker", detail: "Patches and gum, stepped down weekly", icon: Glyph.patch),
        Feature(id: 6, title: "Trigger heatmap", detail: "See when and where cravings hit", icon: Glyph.grid),
        Feature(id: 7, title: "Money and health", detail: "Every dollar kept, every milestone reached", icon: Glyph.coin),
    ]

    /// Each feature's disc and icon colour, light then dark.
    private static let tints: [(light: (UInt32, UInt32), dark: (UInt32, UInt32))] = [
        ((0xFFE9D6, 0xC2410C), (0x3A2D2C, 0xFFB27A)), ((0xFFF1C7, 0x9A6A00), (0x3A3524, 0xFFD37A)),
        ((0xE3EAFB, 0x1F3C8C), (0x22314F, 0x9DB8FF)), ((0xDCE5FA, 0x1F3C8C), (0x1B3378, 0xC9D7FF)),
        ((0xECE7FB, 0x4B3B8F), (0x2C2A48, 0xC7B8FF)), ((0xDDF3E6, 0x1B6E46), (0x20372E, 0x9FE3BC)),
        ((0xFFE3DA, 0xB83A1E), (0x3A2D2C, 0xFF8A65)), ((0xFFF1C7, 0x8A5A00), (0x3A3524, 0xFFC93C)),
    ]

    private var everything: some View {
        VStack(spacing: 0) {
            topBar
            pageBody(padding: 26) {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Text("Everything in").lineLimit(1).minimumScaleFactor(0.6)
                        Text(verbatim: "DayXero Pro").lineLimit(1).minimumScaleFactor(0.6).dxMark(.underline, color: PW2.mark)
                    }
                    .dxFace(.display, 30, weight: 800, tracking: -0.9)
                    .foregroundStyle(PW2.ink)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Everything in DayXero Pro"))
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 14)
                    .dxArrive(0)
                    Text("Built around your Quit Day, \(quitDay, format: dayFormat).")
                        .dxFace(.body, 16, weight: 400)
                        .foregroundStyle(PW2.muted)
                        .multilineTextAlignment(.center)
                        .padding(.top, 14)
                        .dxArrive(0)
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(Self.features) { feature in
                            let tint = dark ? Self.tints[feature.id].dark : Self.tints[feature.id].light
                            HStack(spacing: 14) {
                                GlyphView(d: feature.icon, size: 20, weight: 2.2)
                                    .foregroundStyle(Color(hex: tint.1))
                                    .frame(width: 40, height: 40)
                                    .background(Color(hex: tint.0), in: Circle())
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(feature.title).dxFace(.display, 17, weight: 700, tracking: -0.2).foregroundStyle(PW2.ink)
                                    Text(feature.detail).dxFace(.body, 14, weight: 500).foregroundStyle(PW2.muted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .accessibilityElement(children: .combine)
                            .dxArrive(1 + feature.id)
                        }
                    }
                    .padding(.top, 22)
                }
            } footer: {
                Button("Continue") { go(3) }
                    .buttonStyle(.dx(.primary, on: .reading))
                    .accessibilityIdentifier("paywall.continue")
                    .dxArrive(2)
            }
        }
    }

    // MARK: 3 · The offer

    private struct Stop: Identifiable {
        let id: Int
        let when: String
        let what: String
        let icon: String
        let fill: Color
        let ink: Color
    }

    private var offer: some View {
        let pinned = !typeSize.isAccessibilitySize
        return ZStack(alignment: .topLeading) {
            offerScroll(pinned: pinned)
            if closable {
                roundButton(label: "Close", fill: Color(light: 0xFFF8EE, dark: 0x212A41), action: onClose)
                    .padding(.leading, 16)
                    .padding(.top, 6)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if pinned {
                offerFooter
                    .padding(.horizontal, 22)
                    .dxReadableColumn()
                    .padding(.top, 14)
                    .padding(.bottom, 4)
                    .background(PW2.background.ignoresSafeArea(edges: .bottom))
            }
        }
    }

    private func offerScroll(pinned: Bool) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                offerArt
                VStack(spacing: 0) {
                    Text(verbatim: offerTitle)
                        .dxFace(.display, 30, weight: 800, tracking: -0.9)
                        .foregroundStyle(PW2.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(2).minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 4)
                        .dxArrive(0)
                    if let line = offerLine {
                        Text(verbatim: line)
                            .dxFace(.body, 15, weight: 500)
                            .foregroundStyle(PW2.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                            .dxArrive(0)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(stops) { stop in
                            HStack(spacing: 12) {
                                GlyphView(d: stop.icon, size: 15, weight: 2.4)
                                    .foregroundStyle(stop.ink)
                                    .frame(width: 30, height: 30)
                                    .background(stop.fill, in: Circle())
                                    .accessibilityHidden(true)
                                Text("\(Text(verbatim: stop.when).dxRun(15, weight: 700, family: .display).foregroundStyle(PW2.ink))  \(Text(verbatim: stop.what))")
                                    .dxFace(.body, 15, weight: 500)
                                    .foregroundStyle(PW2.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 18)
                    .dxArrive(1)
                    if hasSavings, let option = model.selectedOption {
                        keepStrip(option)
                            .padding(.top, 20)
                            .dxArrive(1)
                    }
                    if !pinned {
                        offerFooter.padding(.top, DX.Space.l)
                    }
                }
                .padding(.horizontal, 22)
                .dxReadableColumn()
                .padding(.bottom, pinned ? DX.Space.s : DX.Space.xl)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        // The dawn runs up under the status bar.
        .ignoresSafeArea(edges: .top)
    }

    /// The dawn across the top with the three of them on the ridge, settling into the page through a paper edge.
    private var offerArt: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            // The crew keep their canvas spacing and stay centred on wider screens.
            let x0 = (w - 390) / 2
            ZStack(alignment: .topLeading) {
                if dark {
                    NightSky(dawn: true, animate: !motion.reduce,
                             options: .init(sunAt: 0.5, sunScale: 2, sunLift: 12, softSun: true, stars: false, fade: false))
                } else {
                    HorizonScene(.dawn, clarity: 100, fit: .bottom, animate: !motion.reduce,
                                 sun: .init(x: 200, radius: 54, drop: -6, clouds: false))
                }
                Ellipse()
                    .fill(RadialGradient(colors: [dark ? Color.black.opacity(0.55) : Color(hex: 0x50140A).opacity(0.35), .clear],
                                         center: .center, startRadius: 0, endRadius: 42))
                    .frame(width: 84, height: 13)
                    .offset(x: x0 + 112, y: 190)
                crew(XeroView(mood: .cheer, stage: 1, points: 96, animate: !motion.reduce), size: 96)
                    .offset(x: x0 + 106, y: 102)
                crew(JelliView(mood: .hello, stage: 1, points: 64, animate: !motion.reduce), size: 64)
                    .offset(x: x0 + 206, y: 132)
                GlimView(mood: .hello, stage: 1, points: 50, animate: !motion.reduce)
                    .shadow(color: Color(hex: 0xFFD37A).opacity(0.6), radius: 8)
                    .frame(width: 50, height: 50)
                    .offset(x: x0 + 262, y: 92)
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ZStack(alignment: .bottom) {
                        LinearGradient(colors: [PW2.background.opacity(0), PW2.background.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                            .frame(height: 56)
                        OfferEdge().fill(PW2.background).frame(height: 30)
                    }
                }
            }
            .frame(width: w, height: proxy.size.height)
            .clipped()
        }
        .frame(height: 214)
        .accessibilityHidden(true)
    }

    private var trial: Int? { model.selectedOption?.trialDays }

    private var offerTitle: String {
        if let days = trial { return String(localized: "Start your \(days) free days") }
        return String(localized: "Start your plan today")
    }

    /// "Then $39.99 a year, about 8 days of smoking."
    private var offerLine: String? {
        guard let option = model.selectedOption else { return nil }
        let price = option.priceText
        let days = anchor(option).map { ", " + Self.daysOf($0) } ?? ""
        switch option.plan {
        case .annual:
            return trial != nil ? String(localized: "Then \(price) a year\(days).") : String(localized: "\(price) a year\(days).")
        case .quarterly: return String(localized: "\(price) every 3 months\(days).")
        case .monthly: return String(localized: "\(price) a month\(days).")
        case .lifetime: return String(localized: "\(price) once. No subscription.")
        }
    }

    /// What happens when: the trial's three dates, or for a paid start today, the Quit Day and the renewal.
    private var stops: [Stop] {
        guard let option = model.selectedOption else { return [] }
        let price = option.priceText
        let plain = (fill: PW2.soft, ink: PW2.ink)
        let calendar = Calendar.current
        let today = String(localized: "Today")
        if let end = model.trialEndDate {
            var list = [Stop(id: 0, when: today, what: String(localized: "Prep 1 to 3 open, one a day"), icon: Glyph.lock,
                             fill: PW2.coral, ink: PW2.cream)]
            if model.canRemind {
                let lead = TrialReminder.leadDays(trialEndsAt: end, now: .now)
                let remind = calendar.date(byAdding: .day, value: -lead, to: end) ?? end
                list.append(Stop(id: 1, when: remind.formatted(dayFormat), what: String(localized: "We remind you"), icon: Glyph.bell,
                                 fill: plain.fill, ink: plain.ink))
            }
            list.append(Stop(id: 2, when: end.formatted(dayFormat), what: String(localized: "Trial ends, \(price) charged"), icon: Glyph.card,
                             fill: plain.fill, ink: plain.ink))
            return list
        }
        var list = [Stop(id: 0, when: today, what: String(localized: "\(price), your full program opens"), icon: Glyph.lock,
                         fill: PW2.coral, ink: PW2.cream)]
        if calendar.startOfDay(for: quitDay) > calendar.startOfDay(for: .now) {
            list.append(Stop(id: 1, when: quitDay.formatted(dayFormat), what: String(localized: "Your Quit Day"), icon: Glyph.sun,
                             fill: PW2.gold, ink: PW2.navy))
        }
        let renews: Date? = switch option.plan {
        case .annual: calendar.date(byAdding: .year, value: 1, to: .now)
        case .quarterly: calendar.date(byAdding: .month, value: 3, to: .now)
        case .monthly: calendar.date(byAdding: .month, value: 1, to: .now)
        case .lifetime: nil
        }
        if let renews {
            list.append(Stop(id: 2, when: renews.formatted(dayFormat), what: String(localized: "Renews at \(price)"), icon: Glyph.repeats,
                             fill: plain.fill, ink: plain.ink))
        }
        return list
    }

    /// "You keep $1,825 this year" beside a coin, with the price under it.
    private func keepStrip(_ option: PlanOption) -> some View {
        let perYear = spend?.perYear ?? 0
        let title: String = option.plan == .quarterly
            ? String(localized: "You keep \(money(perYear / 4)) in 3 months")
            : String(localized: "You keep \(money(perYear)) this year")
        let sign = money(0).filter { !$0.isNumber && !$0.isWhitespace && $0 != "." && $0 != "," }
        return HStack(spacing: 14) {
            Coin(size: 40, sign: sign.count == 1 ? sign : "")
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: title).dxFace(.display, 17, weight: 700).foregroundStyle(PW2.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text("Pro is \(option.priceText), all 8 features included")
                    .dxFace(.body, 14, weight: 500).foregroundStyle(PW2.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 14).padding(.horizontal, 16)
        .background(PW2.strip, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var offerFooter: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                if model.plans.isEmpty {
                    ForEach(0..<Plan.offered.count, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 18, style: .continuous).fill(PW2.soft).frame(height: 62)
                    }
                    .accessibilityHidden(true)
                } else {
                    ForEach(model.plans) { option in
                        OfferPlanRow(option: option, isSelected: model.selected == option.plan,
                                     saving: option.plan == .annual ? model.annualSavingPercent : nil,
                                     trialOnOffer: annual?.trialDays != nil) {
                            model.select(option.plan)
                        }
                    }
                }
            }
            .padding(.top, 8)
            .dxArrive(2)
            Button {
                onPurchaseStarted()
                Task { await model.purchase() }
            } label: {
                if model.phase == .purchasing {
                    ProgressView().tint(Color(light: 0xFFF8EE, dark: 0x0E1322))
                } else {
                    Text(verbatim: ctaTitle)
                }
            }
            .buttonStyle(.dx(.primary, on: .reading))
            .disabled(model.phase != .ready)
            .accessibilityIdentifier("paywall.cta")
            .padding(.top, 16)
            .dxArrive(3)
            Text(legalLine)
                .dxFace(.body, 13, weight: 500)
                .foregroundStyle(PW2.ink.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
            HStack(spacing: 28) {
                Button("Restore") {
                    onPurchaseStarted()
                    Task { await model.restore() }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Restore purchases"))
                Link("Terms", destination: AppLinks.terms)
                if let privacy = AppLinks.privacy {
                    Link("Privacy", destination: privacy)
                }
            }
            .dxFace(.body, 13, weight: 600)
            .underline()
            .foregroundStyle(PW2.ink)
            .tint(PW2.ink)
            .frame(minHeight: 32)
            .padding(.top, 2)
        }
    }

    private var ctaTitle: String {
        guard let option = model.selectedOption else { return String(localized: "Loading prices…") }
        switch option.plan {
        case .annual:
            if let days = option.trialDays { return String(localized: "Start my \(days) free days") }
            return String(localized: "Continue with yearly")
        case .quarterly: return String(localized: "Continue with 3 months")
        case .monthly: return String(localized: "Subscribe for \(option.priceText) a month")
        case .lifetime: return String(localized: "Buy lifetime for \(option.priceText)")
        }
    }

    private var legalLine: LocalizedStringKey {
        switch model.selected {
        case .annual: trial != nil ? "Nothing to pay today. Renews yearly until you cancel." : "Renews yearly until you cancel."
        case .quarterly: "Renews every 3 months until you cancel."
        case .monthly: "Renews monthly until you cancel."
        case .lifetime: "One payment. No subscription to cancel."
        }
    }
}

/// A plan on the offer: the radio, the name with what it costs a month under it, and the price. Yearly carries the
/// "Save 50%" pill on its top edge when it is a real saving.
private struct OfferPlanRow: View {
    let option: PlanOption
    let isSelected: Bool
    let saving: Int?
    /// Yearly comes with a free trial, so 3 months says it has none.
    let trialOnOffer: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        let line = scheme == .dark ? Color.white.opacity(0.18) : PW2.navy.opacity(0.14)
        return Button(action: action) {
            HStack(spacing: 14) {
                DXRadio(isOn: isSelected, ground: .reading)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: title).dxFace(.display, 17, weight: 700).foregroundStyle(PW2.ink)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    if let detail {
                        Text(verbatim: detail).dxFace(.body, 14, weight: 500).foregroundStyle(PW2.muted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(verbatim: price).dxFace(.display, 18, weight: 800).monospacedDigit().foregroundStyle(PW2.ink)
            }
            .padding(.vertical, 10).padding(.horizontal, 16)
            .frame(minHeight: 62)
            .background(isSelected ? PW2.selTint : PW2.card, in: shape)
            .overlay(shape.strokeBorder(isSelected ? PW2.selEdge : line, lineWidth: isSelected ? 2 : 1))
            .overlay(alignment: .topTrailing) {
                if let saving {
                    Text("Save \(saving)%")
                        .dxFace(.body, 12, weight: 700)
                        .foregroundStyle(PW2.cream)
                        .padding(.vertical, 3).padding(.horizontal, 9)
                        .background(PW2.coral, in: Capsule())
                        .offset(x: -14, y: -11)
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

    private var title: String {
        switch option.plan {
        case .annual:
            if let days = option.trialDays { return String(localized: "Yearly · \(days) days free") }
            return String(localized: "Yearly")
        case .quarterly: return String(localized: "3 months")
        case .monthly: return String(localized: "Monthly")
        case .lifetime: return String(localized: "Lifetime")
        }
    }

    private var detail: String? {
        switch option.plan {
        case .annual: option.perMonthText.map { String(localized: "\($0) a month") }
        case .quarterly: trialOnOffer ? String(localized: "No free trial") : String(localized: "Billed every 3 months")
        case .monthly: nil
        case .lifetime: String(localized: "One payment")
        }
    }

    private var price: String {
        option.plan == .annual ? String(localized: "\(option.priceText)/yr") : option.priceText
    }
}

/// A gold coin with the currency sign.
private struct Coin: View {
    let size: CGFloat
    let sign: String

    var body: some View {
        Circle()
            .fill(PW2.gold)
            .overlay(Circle().strokeBorder(PW2.goldEdge, lineWidth: 2.5))
            .overlay {
                Text(verbatim: sign)
                    .dxFace(.display, size / 2, weight: 800)
                    .lineLimit(1).minimumScaleFactor(0.4)
                    .frame(width: size * 0.7, height: size * 0.8)
                    .foregroundStyle(PW2.goldInk)
            }
            .frame(width: size, height: size)
    }
}

/// A line icon from the canvas's own 24-unit path.
private struct GlyphView: View {
    let d: String
    let size: CGFloat
    let weight: CGFloat

    var body: some View {
        GridShape(d: d, grid: 24)
            .stroke(style: StrokeStyle(lineWidth: weight * size / 24, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

/// The canvas's icon paths (PayD `I`).
private enum Glyph {
    static let path = "M6 21 C6 15 18 15 18 9 C18 6 15 4 12 4 M12 4 h-3"
    static let sun = "M12 8 a4 4 0 1 0 0.01 0 M12 2 v2 M12 20 v2 M2 12 h2 M20 12 h2 M4.9 4.9 l1.4 1.4 M17.7 17.7 l1.4 1.4 M4.9 19.1 l1.4 -1.4 M17.7 6.3 l1.4 -1.4"
    static let chat = "M4 5 h16 v11 H9 l-5 4 Z"
    static let wave = "M3 12 c2 -3 4 -3 6 0 s4 3 6 0 s4 -3 6 0 M3 17 c2 -3 4 -3 6 0 s4 3 6 0 s4 -3 6 0"
    static let moon = "M20 14 A8 8 0 1 1 10 4 A6 6 0 0 0 20 14 Z"
    static let patch = "M7 4 h10 a3 3 0 0 1 3 3 v10 a3 3 0 0 1 -3 3 H7 a3 3 0 0 1 -3 -3 V7 a3 3 0 0 1 3 -3 Z M9 12 h6 M12 9 v6"
    static let grid = "M4 4 h6 v6 H4 Z M14 4 h6 v6 h-6 Z M4 14 h6 v6 H4 Z M14 14 h6 v6 h-6 Z"
    static let coin = "M12 3 a9 9 0 1 0 0.01 0 M15 9 c-1 -1.5 -6 -1.5 -6 1 c0 3 6 1 6 4 c0 2.5 -5 2.5 -6 1 M12 6 v2 M12 16 v2"
    static let lock = "M7 11 V8 a5 5 0 0 1 9.6 -2 M5 11 h14 v10 H5 Z"
    static let bell = "M6 16 V11 a6 6 0 0 1 12 0 V16 L19.5 18 H4.5 Z M10 21 h4"
    static let card = "M3 6 h18 v12 H3 Z M3 10 h18"
    static let repeats = "M4 12 a8 8 0 0 1 14 -5 M20 4 v4 h-4 M20 12 a8 8 0 0 1 -14 5 M4 20 v-4 h4"
}

/// The paper edge under the offer's dawn: "M0 16 C110 3 250 4 390 14 L390 30 L0 30 Z", scaled.
private struct OfferEdge: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 390, sy = rect.height / 30
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + 16 * sy))
        p.addCurve(to: CGPoint(x: rect.minX + 390 * sx, y: rect.minY + 14 * sy),
                   control1: CGPoint(x: rect.minX + 110 * sx, y: rect.minY + 3 * sy),
                   control2: CGPoint(x: rect.minX + 250 * sx, y: rect.minY + 4 * sy))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
