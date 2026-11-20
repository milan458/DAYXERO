import DayXeroCore
import SwiftData
import SwiftUI
import UIKit

/// Numbers the moment and the share card can show. Only days clear is on a card by default (S13.4).
struct MilestoneStats: Equatable {
    var daysClear: Int
    var money: String
    var cravingsRiddenOut: Int
    /// The main product's counter, e.g. ("Puffs not taken", "1,400"), singular for one ("Puff not taken", "1").
    var counterLabel: String
    var counterValue: String
    /// The counter as one phrase: "362 puffs not taken", "1 puff not taken".
    var counterPhrase: String
    /// The raw numbers, for counting up (039).
    var moneyValue: Double = 0
    var currencyCode = "USD"
    var counterCount = 0
    var counterNoun = ""

    @MainActor
    init(profile: UserProfile, logs: [LogEntry], now: Date = .now) {
        let snap = HomeSnapshot(profile: profile, isPro: true, now: now)
        daysClear = snap.daysClear
        money = snap.moneyKept.formatted(.currency(code: snap.currencyCode))
        cravingsRiddenOut = logs.filter { $0.kind == .craving && $0.outcome == .passed }.count
        let counter = snap.counters.first
        let avoided = counter?.avoided ?? 0
        counterValue = avoided.formatted()
        counterLabel = switch counter?.product {
        case .vape: avoided == 1 ? String(localized: "Puff not taken") : String(localized: "Puffs not taken")
        case .pouches: avoided == 1 ? String(localized: "Pouch not used") : String(localized: "Pouches not used")
        default: avoided == 1 ? String(localized: "Cigarette not smoked") : String(localized: "Cigarettes not smoked")
        }
        moneyValue = NSDecimalNumber(decimal: snap.moneyKept).doubleValue
        currencyCode = snap.currencyCode
        counterCount = avoided
        counterNoun = switch counter?.product {
        case .vape: avoided == 1 ? String(localized: "puff not taken") : String(localized: "puffs not taken")
        case .pouches: avoided == 1 ? String(localized: "pouch not used") : String(localized: "pouches not used")
        default: avoided == 1 ? String(localized: "cigarette not smoked") : String(localized: "cigarettes not smoked")
        }
        counterPhrase = switch counter?.product {
        case .vape: String(localized: "\(avoided) puffs not taken")
        case .pouches: String(localized: "\(avoided) pouches not used")
        default: String(localized: "\(avoided) cigarettes not smoked")
        }
    }
}

/// Which milestones have been celebrated, so each one shows once (S13.2).
enum CelebratedMilestones {
    static let key = "dx.celebratedMilestones"

    static var ids: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    /// Marks everything reached so far, so earlier milestones missed during a break aren't celebrated one by one.
    static func markReached(daysClear: Int) {
        let all = ids.union(Milestone.reached(daysClear: daysClear).map(\.id))
        UserDefaults.standard.set(Array(all), forKey: key)
    }
}

/// The full-screen moment on a milestone day (v5, 039), on Xero's apricot. Soft paper rays fan out over the badge
/// like a sunrise and sway; the badge stamps in with a shine; Xero settles beside it and cheers. Then the day, the
/// headline with its mark, the quieter stat line counting up, and the line with its source behind an info button.
/// A milestone is one of the three places Celebrate motion is allowed. No confetti (finale only).
struct MilestoneMoment: View {
    let milestone: Milestone
    let stats: MilestoneStats
    let onClose: () -> Void

    private let motion = MotionPolicy()
    @State private var landed = false
    @State private var sharing = false
    @State private var showSource = false

    private let ground = DX.Ground.apricot

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    stage
                        .frame(height: 300)
                        .padding(.top, 84)
                        .accessibilityHidden(true)
                    copy
                        .padding(.top, 22)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 4) {
                Button("Keep going", action: onClose).buttonStyle(.dx(.primary, on: ground))
                    .dxArrive(9, delay: 0)
                Button { sharing = true } label: {
                    HStack(spacing: 8) {
                        DXIcon(.share, size: 20)
                        Text("Share my card")
                    }
                }
                .buttonStyle(.dx(.quiet, on: ground))
                .dxArrive(10, delay: 0)
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, DX.Layout.buttonGutter)
            .padding(.bottom, DX.Space.xs)
        }
        .dxReadableColumn()
        .background(ground.background.ignoresSafeArea())
        .dxGround(.apricot, paint: false)
        .sensoryFeedback(DX.Haptic.commit, trigger: landed)
        .task {
            try? await Task.sleep(for: .milliseconds(motion.reduce ? 0 : 870))
            landed = true
        }
        .sheet(isPresented: $sharing) {
            ShareCardMaker(milestone: milestone, stats: stats).presentationDetents([.large])
        }
    }

    /// The badge on the centre line, the rays centred on it, one soft shadow under the badge and Xero.
    private var stage: some View {
        ZStack(alignment: .topLeading) {
            MilestoneRays()
                .frame(width: 336, height: 336)
                .position(x: 173, y: 150)
            Ellipse()
                .fill(RadialGradient(colors: [Color(light: (0x1E1A3A, 0.2), dark: (0x000000, 0.55)), .clear],
                                     center: .center, startRadius: 0, endRadius: 133))
                .frame(width: 266, height: 22)
                .scaleEffect(x: 1, y: 1)
                .position(x: 86 + 133, y: 218 + 11)
                .dxFade(delay: 0.2)
            badge
                .frame(width: 168, height: 168)
                .dxShine(delay: 0.9)
                .dxStamp(delay: 0.25)
                .position(x: 173, y: 150)
            company
                .dxBob()
                .dxSettle(delay: 0.5)
                .position(x: 255 + 50, y: 131 + 50)
        }
        .frame(width: 346, height: 300)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var badge: some View {
        switch milestone {
        case .quitDay: DXBadge(.xero, size: 168)
        case .days(365): DXBadge(.day, n: "1y", size: 168)
        case let .days(n): DXBadge(.day, n: n, size: 168)
        }
    }

    private var copy: some View {
        VStack(spacing: 18) {
            Text(verbatim: dateLine).dxType(.footnote).foregroundStyle(ground.muted)
                .dxArrive(4, delay: 0)
            title
                .dxArrive(5, delay: 0)
            if milestone != .quitDay {
                statLine
                    .dxArrive(6, delay: 0)
            }
            if !milestone.line.isEmpty {
                lineWithSource
                    .frame(maxWidth: 300)
                    .dxArrive(7, delay: 0)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var dateLine: String {
        let date = Date.now.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        return milestone == .quitDay ? date : String(localized: "Day \(stats.daysClear) · \(date)")
    }

    /// "One week free" with its last word marked.
    @ViewBuilder
    private var title: some View {
        let words = milestone.title.split(separator: " ").map(String.init)
        if words.count > 1, let last = words.last {
            MarkedTitle(words.dropLast().joined(separator: " ") + " ", marking: last, mark: .underline,
                        color: DX.Mark.color(on: .apricot))
                .dxType(.display).foregroundStyle(ground.ink)
                .accessibilityAddTraits(.isHeader)
        } else {
            Text(verbatim: milestone.title).dxType(.display).foregroundStyle(ground.ink)
                .accessibilityAddTraits(.isHeader)
        }
    }

    /// "$49.00 kept · 84 cigarettes not smoked", both numbers counting up from 1.1 s.
    private var statLine: some View {
        let code = stats.currencyCode
        return HStack(spacing: 0) {
            CountingText(stats.moneyValue, delay: 1.1, duration: 0.9) {
                Decimal($0).formatted(.currency(code: code).precision(.fractionLength(2)))
            }
            Text(verbatim: "\(String(localized: "kept")) ·").padding(.horizontal, 4)
            CountingText(Double(stats.counterCount), delay: 1.1, duration: 0.9) { Int($0.rounded()).formatted() }
            Text(verbatim: stats.counterNoun).padding(.leading, 4)
        }
        .monospacedDigit()
        .dxFont(17, weight: 400, style: .body)
        .foregroundStyle(ground.muted)
        .lineLimit(1).minimumScaleFactor(0.7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(stats.money) \(String(localized: "kept")), \(stats.counterPhrase)"))
    }

    /// The line, ending in a small info button (44 pt target) that shows its source.
    @ViewBuilder
    private var lineWithSource: some View {
        let source = milestone.sourceID.flatMap { HealthTimeline.bundled?.source($0) }
        if let source {
            Button { showSource = true } label: {
                (Text(verbatim: milestone.line + " ") + Text(Image(systemName: "info.circle")).font(.system(size: 17)))
                    .dxType(.body).foregroundStyle(ground.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text(verbatim: source.label))
            .popover(isPresented: $showSource) {
                Link(destination: source.url) {
                    Text(verbatim: source.label).dxType(.footnote).underline().foregroundStyle(DX.Ground.reading.ink)
                }
                .padding(14)
                .presentationCompactAdaptation(.popover)
            }
        } else {
            Text(verbatim: milestone.line).dxType(.body).foregroundStyle(ground.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Who comes to celebrate (S27.16): Xero alone, then Jelli from one month, the whole crew from three months.
    @ViewBuilder
    private var company: some View {
        let stage = CrewGrowth.stage(daysClear: stats.daysClear)
        let mood: CrewMood = .cheer
        HStack(alignment: .bottom, spacing: 4) {
            switch milestone.company {
            case .xero:
                XeroView(mood: mood, stage: 0, points: 100).frame(width: 100, height: 100)
            case .xeroAndJelli:
                JelliView(mood: mood, stage: stage, points: 64)
                XeroView(mood: mood, stage: 0, points: 100)
            case .crew:
                JelliView(mood: mood, stage: stage, points: 56)
                XeroView(mood: mood, stage: 0, points: 90)
                GlimView(mood: mood, stage: stage, points: 56)
            }
        }
    }
}

/// The card maker (v5, 040): the card, what to show on it, and Share. Only the days are always on.
struct ShareCardMaker: View {
    let milestone: Milestone?
    let stats: MilestoneStats

    @Environment(\.dismiss) private var dismiss
    @State private var showMoney = true
    @State private var showCounter = true
    @State private var showWaves = false
    @State private var bump = 0

    private let ground = DX.Ground.reading

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                DXIconButton(.close, label: "Close") { dismiss() }
                Text(verbatim: navTitle).dxFace(.display, 16, weight: 700).foregroundStyle(ground.ink)
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)
                Color.clear.frame(width: 44, height: 1)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .padding(.top, DX.Space.xs)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ShareCard(days: days, lines: lines)
                        .frame(width: ShareCard.size.width, height: ShareCard.size.height)
                        .scaleEffect(1.18)
                        .frame(width: ShareCard.size.width * 1.18, height: ShareCard.size.height * 1.18)
                        .shadow(color: Color(light: (0x0E0B2B, 0.22), dark: (0x000000, 0.45)), radius: 20, y: 18)
                        .dxBump(bump)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                        .dxSettle(delay: 0.1)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(verbatim: ([daysLine] + lines).joined(separator: ", ")))
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Show on your card").dxType(.footnote).foregroundStyle(ground.muted)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible())], spacing: 8) {
                            chip(String(localized: "Days free"), locked: true, isOn: .constant(true))
                            chip(String(localized: "Money kept"), isOn: $showMoney)
                            chip(counterChip, isOn: $showCounter)
                            chip(String(localized: "Waves ridden"), isOn: $showWaves)
                        }
                    }
                    .padding(.top, 20)
                    .dxArrive(3, delay: 0)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, 4)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            if let image = rendered {
                ShareLink(item: image, preview: SharePreview("DayXero · \(daysLine)", image: image)) {
                    HStack(spacing: 10) {
                        DXIcon(.share, size: 20)
                        Text("Share")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.dx(.primary, on: .reading))
                .simultaneousGesture(TapGesture().onEnded {
                    Analytics.track(.shareCardShared(destination: "story"))
                })
                .padding(.horizontal, DX.Layout.buttonGutter)
                .padding(.bottom, DX.Space.xs)
                .dxArrive(4, delay: 0)
            }
        }
        .dxReadableColumn()
        .background(ground.background.ignoresSafeArea())
        .dxGround(.reading, paint: false)
        .onAppear { Analytics.track(.shareCardCreated(milestone: milestone?.id ?? "days-\(stats.daysClear)")) }
    }

    private var days: Int { milestone?.number ?? stats.daysClear }

    private var daysLine: String { days == 1 ? String(localized: "1 day free") : String(localized: "\(days) days free") }

    /// "Share your week": the unit the card's header counts in.
    private var navTitle: String {
        switch ShareCard.Unit(days: days) {
        case .day: String(localized: "Share your day")
        case .week: String(localized: "Share your week")
        case .month: String(localized: "Share your month")
        case .year: String(localized: "Share your year")
        }
    }

    private var counterChip: String {
        let phrase = stats.counterNoun
        if phrase.hasPrefix("puff") { return String(localized: "Puffs") }
        if phrase.hasPrefix("pouch") { return String(localized: "Pouches") }
        return String(localized: "Cigarettes")
    }

    /// What's on the card under the days.
    private var lines: [String] {
        var parts: [String] = []
        if showMoney { parts.append(String(localized: "\(stats.money) kept")) }
        if showCounter { parts.append(stats.counterPhrase) }
        if showWaves {
            parts.append(stats.cravingsRiddenOut == 1 ? String(localized: "1 craving ridden out")
                : String(localized: "\(stats.cravingsRiddenOut) cravings ridden out"))
        }
        return parts
    }

    /// The card drawn at 1080 wide for sharing.
    private var rendered: Image? {
        let renderer = ImageRenderer(content: ShareCard(days: days, lines: lines)
            .frame(width: ShareCard.size.width, height: ShareCard.size.height)
            .environment(\.colorScheme, .light))
        renderer.scale = 1080 / ShareCard.size.width
        return renderer.uiImage.map(Image.init(uiImage:))
    }

    /// A kit chip: on in the selected tint with a tick, off with a hairline; Days free sits in its own filled tone
    /// with a lock, and can't be switched off.
    private func chip(_ title: String, locked: Bool = false, isOn: Binding<Bool>) -> some View {
        let on = isOn.wrappedValue
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return Button {
            guard !locked else { return }
            isOn.wrappedValue.toggle()
            bump += 1
        } label: {
            HStack(spacing: 6) {
                if locked {
                    DXIcon(.lock, size: 15, weight: 2.6).foregroundStyle(ground.muted)
                } else if on {
                    DXIcon(.check, size: 16, weight: 3).foregroundStyle(ground.ink)
                }
                Text(verbatim: title).dxFont(15, weight: 600, style: .subheadline).foregroundStyle(ground.ink)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background {
                if locked { shape.fill(ground.ink.opacity(0.09)) } else { shape.fill(on ? ground.selTint : ground.card) }
            }
            .overlay {
                if !locked {
                    if on { shape.strokeBorder(ground.selEdge, lineWidth: 2) } else { shape.strokeBorder(Color(light: (0x1E1A3A, 0.26), dark: (0xFFFFFF, 0.16)), lineWidth: 1) }
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(.dxPress)
        .allowsHitTesting(!locked)
        .sensoryFeedback(DX.Haptic.select, trigger: on)
        .accessibilityLabel(Text(verbatim: locked ? String(localized: "\(title), always shown") : title))
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// The share card (040), laid out at 254 × 376 and drawn at 1080 wide to share: a warm sky over paper hills and a
/// low sun, "Week 1" at the top, the filled day medallion, "7 days free" and the lines chosen, Xero cheering in front
/// of the sun with a cream paper rim, and the wordmark. No name or photo (S13.4).
struct ShareCard: View {
    let days: Int
    let lines: [String]

    static let size = CGSize(width: 254, height: 376)

    enum Unit {
        case day, week, month, year
        init(days: Int) {
            self = days < 7 ? .day : days < 30 ? .week : days < 365 ? .month : .year
        }
    }

    private var header: String {
        switch Unit(days: days) {
        case .day: String(localized: "Day \(days)")
        case .week: String(localized: "Week \(days / 7)")
        case .month: String(localized: "Month \(days / 30)")
        case .year: String(localized: "Year \(days / 365)")
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(stops: [.init(color: Color(hex: 0xFFB98A), location: 0), .init(color: Color(hex: 0xFFD7AE), location: 0.46),
                                   .init(color: Color(hex: 0xFFE9CF), location: 0.7)], startPoint: .top, endPoint: .bottom)
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0xFFF6C8), Color(hex: 0xFFD25E)], center: UnitPoint(x: 0.4, y: 0.35),
                                     startRadius: 0, endRadius: 48 * 0.7 / 0.5))
                .frame(width: 96, height: 96)
                .opacity(0.95)
                .position(x: 79 + 48, y: 206 + 48)
            Canvas { ctx, size in
                ctx.translateBy(x: 0, y: size.height - 150)
                ctx.scaleBy(x: size.width / 212, y: 1)
                ctx.addFilter(.shadow(color: Color(hex: 0x1A0B2E).opacity(0.22), radius: 2.5, x: 0, y: -2))
                CalmPaint.fill(&ctx, "M0 44 C40 22 80 30 112 40 C150 52 180 30 212 26 V150 H0z", 0xFF9D6E)
                CalmPaint.fill(&ctx, "M0 76 C44 58 90 64 130 78 C166 90 190 72 212 66 V150 H0z", 0xFF7A55)
                CalmPaint.fill(&ctx, "M0 106 C40 94 90 100 130 110 C170 118 196 106 212 102 V150 H0z", 0xE85A3E)
                CalmPaint.fill(&ctx, "M0 128 C60 120 120 126 212 122 V150 H0z", 0xC2402A)
            }
            VStack(spacing: 0) {
                Text(verbatim: header).font(DX.Typeface4.swiftUIFont(.body, size: 13, weight: 700)).foregroundStyle(Color(hex: 0x5A3420))
                SunriseMedal().frame(width: 66, height: 66).padding(.top, 12)
                    .dxStamp(delay: 0.4)
                Text(verbatim: days == 1 ? String(localized: "1 day free") : String(localized: "\(days) days free"))
                    .font(DX.Typeface4.swiftUIFont(.display, size: 34, weight: 800)).tracking(-1.2)
                    .foregroundStyle(Color(hex: 0x1E1A3A))
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .padding(.top, 10)
                VStack(spacing: 2) {
                    ForEach(lines, id: \.self) { line in
                        Text(verbatim: line).transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .font(DX.Typeface4.swiftUIFont(.body, size: 14, weight: 700))
                .foregroundStyle(Color(hex: 0x4A2A18))
                .multilineTextAlignment(.center)
                .padding(.top, 7)
                .animation(.easeInOut(duration: 0.4), value: lines)
            }
            .padding(16)
            XeroView(mood: .cheer, stage: 0, points: 112, animate: false)
                .frame(width: 112, height: 112)
                .modifier(PaperRim(color: Color(hex: 0xFFF8EE), width: 2.6))
                .position(x: 71 + 56, y: 228 + 56)
            HStack(spacing: 6) {
                Circle().fill(Color(hex: 0xFFD966)).frame(width: 10, height: 10)
                Text(verbatim: "DayXero").font(DX.Typeface4.swiftUIFont(.display, size: 14, weight: 800)).tracking(-0.3)
                    .foregroundStyle(Color(hex: 0xFFF8EE))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.leading, 14).padding(.bottom, 9)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Color(light: (0xFFFFFF, 0), dark: (0xFFFFFF, 0.22)), lineWidth: 1.5))
        .environment(\.dynamicTypeSize, .large)
    }
}

/// A cream outline round a figure, like a paper cut-out (the kit's `rim` filter): the figure's silhouette in the rim
/// colour, nudged out in eight directions behind it.
private struct PaperRim: ViewModifier {
    let color: Color
    let width: CGFloat

    func body(content: Content) -> some View {
        content.background {
            ZStack {
                ForEach(0..<8, id: \.self) { i in
                    let a = Double(i) * .pi / 4
                    content.colorMultiply(.black).colorInvert().colorMultiply(color)
                        .offset(x: cos(a) * width, y: sin(a) * width)
                }
            }
        }
    }
}

/// The share card's medallion: the kit day badge filled with a sunrise sky, a big sun rising over the hills, no number.
private struct SunriseMedal: View {
    var body: some View {
        Canvas { ctx, size in
            let k = size.width / 100
            ctx.scaleBy(x: k, y: k)
            ctx.fill(CalmPaint.circle(50, 50, 50), with: .color(Color(hex: 0xFF7155)))
            let face = CalmPaint.circle(50, 50, 39)
            ctx.fill(face, with: .linearGradient(CalmPaint.gradient([(0, 0xFF8A66), (0.55, 0xFFB27C), (1, 0xFFE0B0)]),
                                                 startPoint: CGPoint(x: 50, y: 11), endPoint: CGPoint(x: 50, y: 89)))
            var inner = ctx
            inner.clip(to: face)
            CalmPaint.glow(&inner, 50, 62, 30, 0xFFF6C8, 0.8, mid: (0.3, 0.8))
            inner.fill(CalmPaint.circle(50, 64, 19), with: .color(Color(hex: 0xFFD966)))
            CalmPaint.fill(&inner, "M8 78c8-6 16-6 24 0s16 6 24 0 16-6 24 0 12 5 16 2v30H8z", 0xFF9A6B)
            ctx.stroke(CalmPaint.circle(50, 50, 44.5), with: .color(Color(hex: 0xFF9A6B).opacity(0.5)), lineWidth: 3)
        }
        .accessibilityHidden(true)
    }
}

/// Milestones on the Progress tab (S13.1): reached in sage, the next outlined with a countdown, the rest dashed.
struct MilestonesRow: View {
    let daysClear: Int
    let onOpen: (Milestone) -> Void

    var body: some View {
        let next = Milestone.next(daysClear: daysClear)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Milestones").dxType(.headline).foregroundStyle(Read4.ink)
                Spacer()
                Text("\(Milestone.reached(daysClear: daysClear).count) of \(Milestone.all.count)").v4Text(.subtitle)
            }
            .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 14) {
                ForEach(Milestone.all) { milestone in
                    let reached = milestone.isReached(daysClear: daysClear)
                    Button { if reached { onOpen(milestone) } } label: {
                        badge(milestone, reached: reached, isNext: milestone == next)
                    }
                    .buttonStyle(.plain)
                    .disabled(!reached)
                }
            }
            .padding(14)
            .dxCard(on: .reading)
        }
        .padding(.top, DX.Space.s)
    }

    /// v5 (036): the kit medallions. Day Xero is the Day Xero coin, the days their day badges; reached ones earned,
    /// the next one with its ring toward it, the rest locked.
    private func badge(_ m: Milestone, reached: Bool, isNext: Bool) -> some View {
        let bottom: String = if isNext {
            String(localized: "in \(m.reachedOnDay - daysClear) days")
        } else {
            switch m {
            case .quitDay: String(localized: "Day Xero")
            case .days(1): String(localized: "day")
            case .days(365): String(localized: "year")
            case .days: String(localized: "days")
            }
        }
        let state: DXBadge.Status = reached ? .earned : isNext ? .next(nextFraction(m)) : .locked
        return VStack(spacing: 6) {
            Group {
                switch m {
                case .quitDay: DXBadge(.xero, state: state, size: 64)
                case .days(365): DXBadge(.day, n: "1y", state: state, size: 64)
                case let .days(n): DXBadge(.day, n: n, state: state, size: 64)
                }
            }
            Text(verbatim: bottom).dxType(.caption).lineLimit(1).minimumScaleFactor(0.7)
                .foregroundStyle(isNext ? Read4.ink : Read4.muted)
        }
        .frame(maxWidth: .infinity)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: m.title))
        .accessibilityValue(Text(reached ? "Reached" : isNext ? "Next, in \(m.reachedOnDay - daysClear) days" : "Ahead"))
    }

    /// How far toward the next milestone, from the one before it.
    private func nextFraction(_ m: Milestone) -> Double {
        let before = Milestone.all.last { $0.reachedOnDay < m.reachedOnDay }?.reachedOnDay ?? 0
        let span = Double(max(m.reachedOnDay - before, 1))
        return min(1, max(0, Double(daysClear - before) / span))
    }
}

/// The milestone's rays (v5, 039): sixteen soft paper rays fanning round the badge in two warm tones.
struct MilestoneRays: View {
    @State private var sway = false
    @State private var shown = false
    private let motion = MotionPolicy()

    var body: some View {
        ZStack {
            layer(count: 7, start: -72, r0: 92, r1: 138, width: 14, color: Color(light: (0xFFE6AE, 1), dark: (0xFFF8EE, 0.85)))
                .opacity(1)
                .rotationEffect(.degrees(sway ? 3 : -3))
            layer(count: 6, start: -60, r0: 94, r1: 116, width: 10, color: Color(light: 0xFF9D5C, dark: 0xFFB27A))
                .rotationEffect(.degrees(sway ? -3 : 3))
        }
        .shadow(color: Color(light: (0xA04614, 0.22), dark: (0x000000, 0.4)), radius: 2, y: 2)
        .opacity(shown ? 1 : 0)
        .scaleEffect(shown ? 1 : 0.9)
        .onAppear {
            if motion.reduce { shown = true; return }
            withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.7).delay(0.1)) { shown = true }
            if motion.breathes {
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) { sway = true }
            }
        }
        .accessibilityHidden(true)
    }

    private func layer(count: Int, start: Double, r0: Double, r1: Double, width: Double, color: Color) -> some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 0..<count {
                let t = (start + Double(i) * 24) * .pi / 180
                var p = Path()
                p.move(to: CGPoint(x: c.x + r0 * sin(t), y: c.y - r0 * cos(t)))
                p.addLine(to: CGPoint(x: c.x + r1 * sin(t), y: c.y - r1 * cos(t)))
                ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
            }
        }
    }
}
