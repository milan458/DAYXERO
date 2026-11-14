import DayXeroCore
import SwiftUI

// Today's top (v5, cook/site/screens/015, 016, 018). A paper-cut dawn with Xero on his own knoll and a date pill by day;
// after Quit Day, the latest day badge stamps onto a cream disc in the sky and Xero stands beside it; after 6 PM,
// Glim's midnight meadow. The greeting and the day's line sit under the scene on the page. Scrolling folds it into
// the slim header pinned at the top (017).
//
// Motion (015): the dawn sun rises behind the hills (2.6s) while Xero's paper-cut knoll rises 20px into place (900ms)
// and Xero settles onto it (900ms), then bobs gently. The date pill, greeting, today line and the session card with
// its single Start button arrive with a 90ms stagger. The countdown card is the one meter: its 4 counts down from 7
// (850ms), Prep 1 to 3 stamps rise in one by one (90ms apart, no spring: earned earlier), today's open Prep 4 slot
// breathes its coral outline (2.4s loop), and Prep 5 to 7 and the Day Xero coin wait in dashed rings. 'Later today'
// and the top of its quiet list rise in last under the tab bar (600ms), so the page reads as the top of one scroll.
// Light haptic when the countdown lands.
//
// Motion (016): the dawn sun rises (2.6s) behind the centred cream disc as it fades up (700ms). At 600ms the 7-day
// badge stamps onto the disc (spring, 620ms) and a shine crosses it (1.4s, from 1.2s); Xero's own paper-cut knoll
// rises 20px into place on the hills beside it (900ms settle) and Xero settles onto it (900ms), does one cheer hop at
// 1.3s, then bobs. The date pill, greeting, '7-day badge earned' and the stats line arrive with a 90ms stagger while
// $49 and 84 count up (1.1s). The '7 days to your 14-day badge' chip arrives next and its small 14 ring sweeps to
// half (1.4s). Last, 'Now' and the top of the Now card rise into the bottom of the screen (600ms) so the page reads as
// the top of one scroll. Success haptic on the stamp.
//
// Motion (018): the night sky fades in with its stars twinkling and four fireflies drifting; Glim settles onto the
// glowing hill (900ms) and floats; the greeting and line arrive (90ms stagger); the check-in card rises (600ms), the
// night ticks pop in one by one (110ms) and tonight's ring breathes. Soft impact when the card lands.

/// The colours Today's page and cards draw with. All follow the colour scheme, so the night's forced dark mode turns
/// them; they come from the v5 apricot ground's tokens with the kit's lighter cream page under the hero (015, 017).
enum TodayInk {
    static let ground = DX.Ground.apricot
    /// The page under the hero: #FBF4EA cream in light (015), the one navy in dark.
    static let page = Color(light: 0xFBF4EA, dark: 0x0E1322)
    /// Cards: #FFFCF7 in light (kit `--cream-card`), the navy card in dark.
    static let card = Color(light: 0xFFFCF7, dark: 0x182034)
    static let well = Color(light: 0xF6EDE1, dark: 0x212A41)
    static let ink = DX.Ground.apricot.ink
    static let muted = Color(light: 0x5E5975, dark: 0xB3BACC)
    static let line = DX.Ground.reading.line
    /// The kit `--lift` shadow under the cream cards in light.
    static let shadow = Color(light: (0x4A2810, 0.10), dark: (0x000000, 0.30))
    static let coral = Color(hex: 0xFF7A55)
    static let coralText = Color(light: 0xC2402A, dark: 0xFF9A7A)
}

// MARK: Model

/// What the hero shows, worked out once by Today so the hero, the slim header and the cards always agree.
struct TodayHeroModel {
    enum Mode: Equatable {
        /// Prep: the knoll and Xero.
        case prep
        /// After Quit Day: the badge earned (a day number, or nil for Day Xero) on its disc.
        case postQuit(earned: Int?)
    }

    let night: Bool
    let mode: Mode
    let greeting: String
    /// "4 days to Quit Day · Sun, 8 Nov", "Quit Day is today", "Day 4 · 4 of 4 days smoke-free".
    let line: String
    let why: String?
    let profileInitial: String?
    /// The date pill: "Mon, Nov 2 · Prep 4", "Fri, Nov 13".
    let pill: String
    /// After Quit Day: "6d 14h" and "free", the title with "free" marked.
    let titleLead: String
    let titleWord: String
    /// After Quit Day: money kept and units not used, counted up.
    let moneyKept: Double
    let currencyCode: String
    let avoided: Int
    let avoidedUnit: String
    /// After Quit Day: the next milestone, its progress, and "Friday · 14 days free".
    let nextMilestone: Int?
    let nextFraction: Double
    let aheadText: String?
    /// The slim header's title and line.
    let slimTitle: String
    let slimLine: String
    /// "$49", beside "kept" on the right of the slim header after Quit Day (017).
    var slimMoney: String?
    let crewStage: Int
    let accessibilityLabel: String
}

// MARK: Hero

struct TodayHero: View {
    let model: TodayHeroModel
    let topInset: CGFloat
    let onProfile: () -> Void
    /// After Quit Day the badge opens what's changing in the body.
    let onRing: (() -> Void)?
    @State private var cheer = false
    private let motion = MotionPolicy()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if model.night {
                nightScene
            } else {
                dayScene
                below.padding(.top, 22)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Day

    private var sceneHeight: CGFloat {
        if case .postQuit = model.mode { return 350 }
        return 252
    }

    private var dayScene: some View {
        let height = topInset + sceneHeight
        return ZStack(alignment: .topLeading) {
            HorizonScene(.dawn, clarity: 85, fit: .bottom)
            switch model.mode {
            case .prep: prepStage(height: height)
            case let .postQuit(earned): badgeStage(earned: earned, height: height)
            }
            pill
                .frame(maxWidth: .infinity)
                .offset(y: height - 50 - (model.mode == .prep ? 0 : 36))
        }
        .frame(height: height)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 36, bottomTrailingRadius: 36, style: .continuous))
    }

    /// 015: Xero (140) stands on a 300 × 102 paper-cut knoll centred at the bottom.
    private func prepStage(height: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            Knoll(kind: .big)
                .frame(width: 300, height: 102)
                .dxSettle(delay: 0.15)
            XeroView(mood: .hello, stage: model.crewStage, size: .scene)
                .dxBob()
                .dxSettle()
                .padding(.bottom, 74)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .accessibilityHidden(true)
    }

    /// 016: the earned badge (156) on a 200 pt cream disc in the sky; Xero (104) on a small knoll at the right.
    private func badgeStage(earned: Int?, height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ZStack {
                Circle().fill(Color(light: (0xFFF8EE, 0.74), dark: (0xFFF8EE, 0.10)))
                    .shadow(color: Color(light: (0xFFF8EE, 0.45), dark: (0xFFC38A, 0.12)), radius: 17)
                    .dxFade(delay: 0.1)
                Group {
                    if let earned {
                        DXBadge(.day, n: earned, size: 156, liftNumeral: true)
                    } else {
                        DXBadge(.xero, size: 156)
                    }
                }
                .shadow(color: Color(light: (0x963214, 0.28), dark: (0x000000, 0.45)), radius: 7, y: 8)
                .dxShine(delay: 1.2)
                .dxStamp(delay: 0.6)
            }
            .frame(width: 200, height: 200)
            .frame(maxWidth: .infinity)
            .padding(.top, height - 304)
            .sensoryFeedback(DX.Haptic.commit, trigger: cheer)
            .modifier(OptionalButton(action: onRing, hint: Text("Opens what changes in your body")))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: model.accessibilityLabel))

            ZStack(alignment: .bottomLeading) {
                Knoll(kind: .small)
                    .frame(width: 160, height: 68)
                    .dxSettle(delay: 0.25)
                XeroView(mood: cheer ? .cheer : .hello, stage: model.crewStage, points: 104)
                    .frame(width: 104, height: 104)
                    .dxBob()
                    .dxSettle(delay: 0.4)
                    .padding(.leading, 28)
                    .padding(.bottom, 58)
            }
            .frame(width: 160, height: 160, alignment: .bottomLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .offset(x: 14)
            .accessibilityHidden(true)
        }
        .task {
            guard !motion.reduce else { return }
            try? await Task.sleep(for: .seconds(1.3))
            cheer = true
            try? await Task.sleep(for: .seconds(1.5))
            cheer = false
        }
    }

    private var pill: some View {
        Text(verbatim: model.pill)
            .dxFace(.body, 14, weight: 600)
            .foregroundStyle(TodayInk.ink)
            .lineLimit(1)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DX.Ground.apricot.card, in: Capsule())
            .overlay(Capsule().strokeBorder(Color(light: (0x000000, 0), dark: (0xFFFFFF, 0.12)), lineWidth: 1))
            .shadow(color: Color(light: (0x1E1A3A, 0.12), dark: (0x000000, 0.3)), radius: 8, y: 6)
            .dxArrive(1, delay: 0.5)
    }

    private var profileButton: some View {
        Button(action: onProfile) {
            Group {
                if let initial = model.profileInitial {
                    Text(verbatim: initial).dxFace(.display, 17, weight: 800)
                } else {
                    DXIcon(.people, size: 20)
                }
            }
            .foregroundStyle(Color(light: 0xFFF8EE, dark: 0x0E1322))
            .frame(width: 40, height: 40)
            .background(Color(light: 0x1E1A3A, dark: 0xFFF8EE), in: Circle())
        }
        .buttonStyle(.dxPress)
        .accessibilityLabel(Text("Profile and settings"))
    }

    /// Under the scene: the greeting and the day's line (prep); the greeting, the title and the stats (after Quit Day).
    @ViewBuilder
    private var below: some View {
        switch model.mode {
        case .prep:
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: model.greeting)
                    .dxType(.large)
                    .foregroundStyle(TodayInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .dxArrive(2)
                Text(verbatim: model.line)
                    .dxType(.body)
                    .foregroundStyle(TodayInk.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .dxArrive(3)
            }
            .padding(.horizontal, DX.Layout.gutter)
        case .postQuit:
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: model.greeting)
                    .dxType(.body)
                    .foregroundStyle(TodayInk.muted)
                    .dxArrive(2)
                MarkedTitle(model.titleLead + " ", marking: model.titleWord, color: DX.Mark.color(on: .apricot))
                    .dxType(.large)
                    .foregroundStyle(TodayInk.ink)
                    .padding(.top, 2)
                    .dxArrive(3)
                stats.padding(.top, 8).dxArrive(4)
                if let ahead = model.aheadText, let next = model.nextMilestone {
                    nextChip(next: next, text: ahead)
                        .padding(.top, 18)
                        .dxArrive(5)
                }
            }
            .padding(.horizontal, DX.Layout.gutter)
        }
    }

    @ViewBuilder
    private var why: some View {
        if let why = model.why {
            Text(verbatim: "“\(why)”")
                .dxType(.footnote)
                .italic()
                .foregroundStyle(TodayInk.muted)
                .lineLimit(2)
                .padding(.top, 4)
                .accessibilityLabel(Text("Your why: \(why)"))
                .dxArrive(4)
        }
    }

    /// "$49 kept • 84 cigarettes not smoked": the numbers in the display face, counting up over 1.1 s.
    private var stats: some View {
        let number = { (value: Double, format: @escaping (Double) -> String) in
            CountingText(value, delay: 0.3, duration: 1.1, format: format)
                .dxFace(.display, 20, weight: 800, tracking: -0.4)
                .foregroundStyle(TodayInk.ink)
        }
        let code = model.currencyCode
        return HStack(alignment: .firstTextBaseline, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                number(model.moneyKept) { Decimal(floor($0)).formatted(.currency(code: code).precision(.fractionLength(0))) }
                Text("kept")
            }
            Circle().fill(TodayInk.muted.opacity(0.5)).frame(width: 4, height: 4).alignmentGuide(.firstTextBaseline) { $0[.bottom] + 5 }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                number(Double(model.avoided)) { String(Int($0)) }
                Text(verbatim: model.avoidedUnit)
            }
        }
        .dxFace(.body, 17, weight: 500)
        .foregroundStyle(TodayInk.muted)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityElement(children: .combine)
    }

    /// "(14) Friday · 14 days free": a 28 pt ring sweeping toward the next badge.
    private func nextChip(next: Int, text: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                DXRing(p: model.nextFraction, size: 28, stroke: 3, color: Color(hex: 0xE8603F), track: TodayInk.ink.opacity(0.14))
                Text(verbatim: "\(next)").dxFace(.display, 12.5, weight: 800, tracking: -0.3).foregroundStyle(TodayInk.ink)
            }
            .frame(width: 28, height: 28)
            Text(verbatim: text).dxFace(.body, 15, weight: 600).foregroundStyle(TodayInk.ink)
        }
        .padding(.leading, 10)
        .padding(.trailing, 18)
        .frame(height: 48)
        .background(TodayInk.card, in: Capsule())
        .overlay(Capsule().strokeBorder(TodayInk.line, lineWidth: 1))
        .shadow(color: Color(light: (0x4A2810, 0.08), dark: (0x000000, 0)), radius: 6, y: 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: Night (018)

    private var nightScene: some View {
        let height = topInset + 330
        return ZStack(alignment: .topLeading) {
            NightSky(moon: CGPoint(x: 316, y: topInset + 132))
                .frame(height: height + 40)
            // Glim floats over the near hill, lit by its own glow (018).
            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(RadialGradient(colors: [Color(hex: 0xFFD37A).opacity(0.28), Color(hex: 0xFFD37A).opacity(0)],
                                         center: .center, startRadius: 0, endRadius: 90))
                    .frame(width: 200, height: 70)
                    .offset(y: -40)
                Knoll(kind: .big)
                    .frame(width: 420, height: 70)
                    .environment(\.colorScheme, .dark)
                GlimView(mood: .hello, stage: model.crewStage, size: .scene)
                    .dxBob()
                    .dxSettle()
                    .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, topInset + 110)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(verbatim: model.greeting)
                        .dxType(.large)
                        .foregroundStyle(Color(hex: 0xF6EFE2))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .dxArrive(1)
                Text(verbatim: model.line)
                    .dxType(.footnote)
                    .foregroundStyle(Color(hex: 0xAEB8D3))
                    .dxArrive(2)
            }
            .padding(.horizontal, DX.Layout.gutter)
            .padding(.top, topInset + 30)
        }
        .frame(height: height)
    }
}

/// Wraps content in a button when there's an action.
private struct OptionalButton: ViewModifier {
    let action: (() -> Void)?
    let hint: Text

    func body(content: Content) -> some View {
        if let action {
            Button(action: action) { content }.buttonStyle(.plain).accessibilityHint(hint)
        } else {
            content
        }
    }
}

/// Xero's own paper-cut knoll inside the hero: a lighter hill with a cream rim, never the page colour.
struct Knoll: View {
    enum Kind { case big, small }
    let kind: Kind
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        Canvas { ctx, size in
            let sx = size.width / (kind == .big ? 300 : 160), sy = size.height / (kind == .big ? 102 : 68)
            ctx.scaleBy(x: sx, y: sy)
            switch kind {
            case .big:
                let hill = SVGPath.path("M0 102 C22 40 92 10 150 10 C208 10 278 40 300 102Z")
                var shadowed = ctx
                shadowed.addFilter(.shadow(color: dark ? .black.opacity(0.5) : Color(hex: 0x78280A).opacity(0.24), radius: 4, y: -3))
                shadowed.fill(hill, with: .color(Color(hex: dark ? 0x1C2744 : 0xFFC796)))
                ctx.stroke(SVGPath.path("M0 102 C22 40 92 10 150 10 C208 10 278 40 300 102"), with: .linearGradient(
                    Gradient(colors: [Color(hex: dark ? 0xF6E7C1 : 0xFFF8EE).opacity(dark ? 0.26 : 0.8), .clear]),
                    startPoint: CGPoint(x: 0, y: 10), endPoint: CGPoint(x: 0, y: 84)), lineWidth: 2.5)
            case .small:
                let hill = SVGPath.path("M0 68 C10 32 44 10 82 10 C118 10 150 30 160 54 V68Z")
                var shadowed = ctx
                shadowed.addFilter(.shadow(color: dark ? .black.opacity(0.5) : Color(hex: 0x78280A).opacity(0.22), radius: 4, y: -3))
                shadowed.fill(hill, with: .linearGradient(
                    Gradient(colors: [Color(hex: dark ? 0x26355E : 0xFFDDB8), Color(hex: dark ? 0x151F3A : 0xFFCC9A)]),
                    startPoint: .zero, endPoint: CGPoint(x: 0, y: 68)))
                ctx.stroke(SVGPath.path("M0 68 C10 32 44 10 82 10 C118 10 150 30 160 54"), with: .linearGradient(
                    Gradient(colors: [dark ? Color(hex: 0xF6E7C1).opacity(0.42) : Color(hex: 0xFFFAF2).opacity(0.95), .clear]),
                    startPoint: CGPoint(x: 0, y: 10), endPoint: CGPoint(x: 0, y: 58)), lineWidth: 2.5)
                ctx.fill(SVGPath.path("M0 58 C40 52 100 54 160 48 V68 H0Z"), with: .color(Color(hex: dark ? 0x0A1326 : 0xB9422D)))
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: Slim header (017)

/// The hero folded up: a slim row pinned at the top once the scene has scrolled away. Xero (or Glim) at 40, the
/// title and the line, on the page with a soft blur.
struct TodaySlimHeader: View {
    let model: TodayHeroModel

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if model.night {
                    GlimView(mood: .calm, stage: model.crewStage, size: .avatar, animate: false)
                } else {
                    XeroView(mood: .hello, stage: model.crewStage, size: .avatar, animate: false)
                }
            }
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: model.slimTitle)
                    .dxFace(.display, 19, weight: 800, tracking: -0.3)
                    .foregroundStyle(TodayInk.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(verbatim: model.slimLine)
                    .dxType(.caption)
                    .foregroundStyle(TodayInk.muted)
                    .lineLimit(1).minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let money = model.slimMoney {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(verbatim: money).dxFace(.display, 20, weight: 800, tracking: -0.4).foregroundStyle(TodayInk.ink)
                    Text("kept").dxType(.caption).foregroundStyle(TodayInk.muted)
                }
            }
        }
        .padding(.horizontal, DX.Layout.gutter)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}
