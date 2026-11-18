import DayXeroCore
import SwiftUI

// The evidence story's shared pieces (18 Nov 2026, canvas page "Evidence story"): the card palette, the icon chips,
// the drawn objects (`EvIllo`), the two-groups-of-100 card, the source link and the research sheet.

/// Card and selection colours for the evidence screens, on the apricot ground (navy in dark).
enum Ev {
    static let card = Color(light: 0xFFFAF5, dark: 0x1B2439)
    static let ring = Color(light: (0x1E1A3A, 0), dark: (0xFFFFFF, 0.22))
    static let well = Color(light: 0xFFE2CF, dark: 0x232C45)
    static let line = Color(light: (0x1E1A3A, 0.14), dark: (0xFFFFFF, 0.14))
    /// The coral disc behind a picked chip's icon and a picked row's tick.
    static let badge = Color(hex: 0xF26A45)
    static let cream = Color(hex: 0xFFF8EE)
    /// A picked chip or option: ink in light, cream in dark.
    static let sel = Color(light: 0x1E1A3A, dark: 0xFFF8EE)
    static let selFg = Color(light: 0xFFF8EE, dark: 0x0E1322)
    static let selSub = Color(light: 0xD8D3E6, dark: 0x4A5068)
    static let coral = Color(light: 0xF2603C, dark: 0xFF8A65)
    static let dotOff = Color(light: (0x1E1A3A, 0.15), dark: (0xFFFFFF, 0.2))
    static let arrow = Color(light: (0x1E1A3A, 0.45), dark: (0xFFFFFF, 0.45))
}

extension View {
    /// The evidence card: warm white (a lifted navy with a hairline in dark).
    func evCard(radius: CGFloat = 20) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return background(Ev.card, in: shape).overlay(shape.strokeBorder(Ev.ring, lineWidth: 1))
    }
}

/// A line icon on the 24-unit grid, from an SVG path.
struct EvGlyph: View {
    let d: String
    var size: CGFloat = 16
    var weight: CGFloat = 2.2

    var body: some View {
        GridShape(d: d, grid: 24)
            .stroke(style: StrokeStyle(lineWidth: weight * size / 24, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    static let info = "M12 3 a9 9 0 1 0 0.01 0 M12 11 v6 M12 7.5 v0.5"
    static let bolt = "M13 3L5 13.5h6L10 21l8-10.5h-6z"
    static let people = "M9 11a3 3 0 100-6 3 3 0 000 6zM3.5 19a5.5 5.5 0 0111 0M16 11a2.6 2.6 0 100-5.2M17 14.2a4.8 4.8 0 013.5 4.8"
    static let moon = "M20 14A8 8 0 1110 4a6 6 0 0010 10z"
    static let bed = "M3 18v-6h13a4 4 0 014 4v2M3 12V6M3 15.5h17M7 9.5h3"
}

extension Trigger {
    /// The chip's line icon (canvas `EvTriggers`).
    var evIcon: String {
        switch self {
        case .morning: "M4 18h16M7 18a5 5 0 0110 0M12 6v3M5.5 9.5l1.8 1.8M18.5 9.5l-1.8 1.8"
        case .meals: "M6 3v6a2.5 2.5 0 005 0V3M8.5 3v18M17 21V3c-2.2 1.6-3 4.2-3 7.5V13h3"
        case .work: "M4 8h16v11H4zM9 8V5.5h6V8M4 13h16"
        case .coffee: "M5 9h11v6a4 4 0 01-4 4H9a4 4 0 01-4-4zM16 10.5h1.5a2.5 2.5 0 010 5H16M8 3v2.5M12 3v2.5"
        case .driving: "M5 11l1.6-4.2A2 2 0 018.5 5.5h7a2 2 0 011.9 1.3L19 11M4 11h16v6H4zM6.5 17v2M17.5 17v2M7.5 14h1M15.5 14h1"
        case .alcohol: "M6 4h12l-1 6a5 5 0 01-10 0zM12 15v5M8.5 20h7"
        case .evening: EvGlyph.moon
        case .stress: EvGlyph.bolt
        case .boredom: "M12 4a8 8 0 100 16 8 8 0 000-16zM12 8v4.5l3 1.5"
        case .lowMood: "M7.5 15.5a4 4 0 01.6-7.9 5 5 0 019.5 1.4 3.3 3.3 0 01-.6 6.5zM9 18.5v1.5M13 18.5v1.5"
        case .anxiety: "M3 12h4l2-5 4 10 2.5-5H21"
        case .social: EvGlyph.people
        default: "M6 12h.01M12 12h.01M18 12h.01"
        }
    }
}

extension Trigger {
    /// The short name on the onboarding chip (canvas `EvTriggers`).
    var evChipTitle: String {
        switch self {
        case .morning: String(localized: "Morning")
        case .meals: String(localized: "After meals")
        case .work: String(localized: "At work")
        case .alcohol: String(localized: "Alcohol")
        case .evening: String(localized: "Evening")
        case .social: String(localized: "Social")
        case .other: String(localized: "Other")
        default: chipTitle
        }
    }

    /// The trigger as it reads inside a sentence: "For coffee and for stress."
    var evPlanWord: String {
        switch self {
        case .morning: String(localized: "mornings")
        case .meals: String(localized: "meals")
        case .work: String(localized: "work")
        case .alcohol: String(localized: "drinking")
        case .evening: String(localized: "evenings")
        case .social: String(localized: "time with friends")
        case .other: String(localized: "other moments")
        default: String(localized: title).lowercased()
        }
    }
}

extension Obstacle {
    /// The chip's line icon (canvas `EvObstacles`).
    var evIcon: String {
        switch self {
        case .irritability, .stress: EvGlyph.bolt
        case .sleep: EvGlyph.bed
        case .hunger: "M12 8c-2-1.6-6-1-6 3.5 0 4 2.6 7.5 4.5 7.5.8 0 1-.5 1.5-.5s.7.5 1.5.5c1.9 0 4.5-3.5 4.5-7.5 0-4.5-4-5.1-6-3.5zM12 8c0-2 1-3.5 2.5-4"
        case .social: EvGlyph.people
        case .restlessness, .cravings: "M3 9c3-3.5 6-3.5 9 0s6 3.5 9 0M3 15c3-3.5 6-3.5 9 0s6 3.5 9 0"
        case .weight: "M6 4h12a2 2 0 012 2v12a2 2 0 01-2 2H6a2 2 0 01-2-2V6a2 2 0 012-2zM8.5 10.5a3.5 3.5 0 017 0zM12 10.5l1.5-2.4"
        case .focus: "M12 4a8 8 0 100 16 8 8 0 000-16zM12 9a3 3 0 100 6 3 3 0 000-6z"
        case .motivation: "M6 21V4M6 5h11l-2.5 4 2.5 4H6"
        case .other: "M6 12h.01M12 12h.01M18 12h.01"
        }
    }

    /// The short name on the onboarding chip.
    var evChipTitle: String {
        switch self {
        case .sleep: String(localized: "Sleep")
        case .social: String(localized: "Social pressure")
        case .weight: String(localized: "Weight")
        case .focus: String(localized: "Focus")
        case .motivation: String(localized: "Motivation")
        default: String(localized: title)
        }
    }

    /// Hughes 2007's withdrawal symptoms (it leaves out craving and hunger): the ones the "worst in week one" line
    /// can honestly be said about.
    var isWithdrawalSymptom: Bool {
        switch self {
        case .irritability, .sleep, .restlessness, .focus: true
        default: false
        }
    }
}

/// A pill chip with a line icon: picked, it fills with ink and its icon sits on a coral disc.
struct EvChip: View {
    let text: String
    let icon: String
    let isOn: Bool
    let action: () -> Void
    @State private var taps = 0
    @State private var land = 0
    private let motion = MotionPolicy()

    var body: some View {
        Button {
            taps += 1
            if !isOn { land += 1 }
            action()
        } label: {
            HStack(spacing: 6) {
                EvGlyph(d: icon, size: 16)
                    .foregroundStyle(isOn ? Ev.cream : Onb.muted)
                    .frame(width: 24, height: 24)
                    .background(isOn ? Ev.badge : Color.clear, in: Circle())
                Text(verbatim: text)
                    .dxFace(.body, 15, weight: 600)
                    .foregroundStyle(isOn ? Ev.selFg : Onb.ink)
                    .lineLimit(1)
            }
            .padding(.leading, 9).padding(.trailing, 12)
            .frame(minHeight: 44)
            .background(isOn ? Ev.sel : Ev.card, in: Capsule())
            .overlay { if !isOn { Capsule().strokeBorder(Ev.ring, lineWidth: 1) } }
            .contentShape(Capsule())
            .fixedSize()
            .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.25), value: isOn)
            .phaseAnimator([1.0, 1.08, 1.0], trigger: land) { view, scale in
                view.scaleEffect(motion.reduce ? 1 : scale)
            } animation: { scale in
                scale == 1.08 ? .timingCurve(0.3, 1.4, 0.5, 1, duration: 0.21) : .timingCurve(0.3, 1.4, 0.5, 1, duration: 0.31)
            }
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: taps)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// "(i) Cochrane review of 52 trials, 2016": the small underlined source under a number. It opens the research sheet.
struct EvSourceLink: View {
    let text: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                EvGlyph(d: EvGlyph.info, size: 14)
                Text(text).underline()
            }
            .dxFace(.body, 13, weight: 600)
            .foregroundStyle(Onb.muted)
            .frame(minHeight: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Opens the research"))
    }
}

// MARK: Drawn objects

/// The paper-cut objects of the evidence story, on a 64-unit grid (canvas `EvIllo`).
struct EvIllo: View {
    enum Kind { case patch, bubble, gum, lozenge, plan, leaf, cup, bolt, stack, page, sun, shield }
    let kind: Kind
    var size: CGFloat = 64
    @Environment(\.colorScheme) private var scheme

    private var dark: Bool { scheme == .dark }
    private var coral: Color { dark ? Color(hex: 0xFF8A65) : Color(hex: 0xF2603C) }
    private var ink: Color { dark ? Color(hex: 0xFFF8EE) : Color(hex: 0x1E1A3A) }
    private var paper: Color { dark ? Color(hex: 0x0E1322) : Color(hex: 0xFFF8EE) }
    private var board: Color { dark ? Color(hex: 0x3A4670) : Color(hex: 0xFFDCC6) }

    var body: some View {
        ZStack { art }
            .frame(width: size, height: size)
            .compositingGroup()
            .shadow(color: dark ? Color.black.opacity(0.4) : Color(hex: 0x5A1E0A).opacity(0.22), radius: 1, y: 2 * size / 64)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var art: some View {
        switch kind {
        case .patch:
            ZStack {
                f(Self.rr(8, 8, 48, 48, 14), coral)
                s("M12 38 V26 a14 14 0 0 1 14 -14 h12", Color(hex: 0xFFB09C).opacity(0.75), 3)
                s(Self.rr(19, 19, 26, 26, 7), Color(hex: 0xFFF8EE), 2.5, dash: [4, 4])
                s("M32 27 v10 M27 32 h10", Color(hex: 0xFFF8EE), 3)
            }.rotationEffect(.degrees(-8))
        case .bubble:
            ZStack {
                f("M13 9 h38 a9 9 0 0 1 9 9 v21 a9 9 0 0 1 -9 9 H31 l-13 10 v-10 h-5 a9 9 0 0 1 -9 -9 V18 a9 9 0 0 1 9 -9 Z", ink)
                s("M22 29 l7 7 l14 -15", paper, 4.5)
            }.rotationEffect(.degrees(6))
        case .gum:
            ZStack {
                f(Self.rr(5, 15, 54, 34, 9), Color(hex: 0xC9D8F2))
                f(Self.rr(11, 22, 12, 20, 5), .white)
                f(Self.rr(26, 22, 12, 20, 5), .white)
                f(Self.rr(41, 22, 12, 20, 5), .white)
                s("M14 38 h6 M29 38 h6 M44 38 h6", Color(hex: 0xA9BDE0), 2)
            }.rotationEffect(.degrees(-6))
        case .lozenge:
            ZStack {
                oval(32, 32, 24, 16).fill(Color(hex: 0xFFC93C)).modifier(place(32, 32, 24, 16))
                oval(32, 32, 15, 8.5).stroke(Color(hex: 0xF29A2E), lineWidth: 2.5 * k).modifier(place(32, 32, 15, 8.5))
                s("M13 27 C17 21 23 18 30 18", Color(hex: 0xFFF1C4), 3)
            }.rotationEffect(.degrees(-14))
        case .plan:
            ZStack {
                f(Self.rr(12, 10, 40, 48, 8), board)
                f(Self.rr(23, 5, 18, 11, 5), ink)
                s("M21 31 l4 4 l7 -8", coral, 3.5)
                s("M37 31 h7 M21 44 h23", ink.opacity(0.55), 3)
            }.rotationEffect(.degrees(4))
        case .leaf:
            ZStack {
                f("M11 53 C11 27 27 12 54 10 C54 37 38 53 13 53 Z", Color(hex: 0x3FB37F))
                f("M54 10 C54 37 38 53 13 53 L40 25 Z", Color(hex: 0x2F9A6A))
                s("M13 53 L40 25", Color(hex: 0xFFF8EE), 2.5, dash: [4, 4])
                s("M17 34 C20 25 27 19 36 16", Color(hex: 0x8FE0B6).opacity(0.8), 3)
            }.rotationEffect(.degrees(-4))
        case .cup:
            ZStack {
                s("M25 13 c-3 -4 3 -6 0 -10 M35 13 c-3 -4 3 -6 0 -10", Color(hex: 0xFFF8EE).opacity(0.85), 2.5)
                oval(30, 54, 20, 4.5).fill(Color(hex: 0xFFDCC6)).modifier(place(30, 54, 20, 4.5))
                s("M46 26 h3 a7.5 7.5 0 0 1 0 15 h-4", Color(hex: 0xFFF8EE), 5)
                f("M13 20 h34 v17 a14 14 0 0 1 -14 14 h-6 a14 14 0 0 1 -14 -14 Z", Color(hex: 0xFFF8EE))
                f("M40 20 h7 v17 a14 14 0 0 1 -14 14 h-3 c6 -3 10 -9 10 -17 Z", Color(hex: 0xF3DCC8))
                oval(30, 20, 17, 4.5).fill(Color(hex: 0x7A4A2A)).modifier(place(30, 20, 17, 4.5))
            }.rotationEffect(.degrees(-6))
        case .bolt:
            ZStack {
                f("M37 5 L13 36 h15 l-5 23 l27 -34 H34 Z", Color(hex: 0xFFC93C))
                s("M37 5 L13 36 h15 l-5 23 l27 -34 H34 Z", Color(hex: 0xF29A2E), 2.5)
                s("M33 13 L21 30", Color(hex: 0xFFF1C4), 3)
            }.rotationEffect(.degrees(8))
        case .stack:
            f(Self.rr(16, 9, 36, 46, 7), coral).rotationEffect(.degrees(10))
            f(Self.rr(14, 9, 36, 46, 7), Color(hex: 0xFFC93C)).rotationEffect(.degrees(3))
            ZStack {
                f(Self.rr(12, 9, 36, 46, 7), .white)
                s("M19 21 h22 M19 30 h22 M19 39 h13", Color(hex: 0x1E1A3A).opacity(0.55), 3)
            }.rotationEffect(.degrees(-5))
        case .page:
            ZStack {
                f("M17 7 h20 l13 13 v33 a5 5 0 0 1 -5 5 H17 a5 5 0 0 1 -5 -5 V12 a5 5 0 0 1 5 -5 Z", .white)
                f("M37 7 v8 a5 5 0 0 0 5 5 h8 Z", Color(hex: 0xC9D8F2))
                s("M19 28 h24 M19 37 h24 M19 46 h14", Color(hex: 0x1E1A3A).opacity(0.55), 3)
            }.rotationEffect(.degrees(5))
        case .sun:
            Circle().fill(Color(hex: 0xFFC93C)).frame(width: 50 * k, height: 50 * k)
            Circle().strokeBorder(Color(hex: 0xF29A2E), lineWidth: 4 * k).frame(width: 54 * k, height: 54 * k)
            Circle().stroke(Color(hex: 0xFFD966), lineWidth: 4 * k).frame(width: 32 * k, height: 32 * k)
            s("M17 24 C20 17 26 13 33 12", Color(hex: 0xFFF1C4), 3)
        case .shield:
            f("M32 5 L55 13 v17 c0 14 -9 23 -23 29 C18 53 9 44 9 30 V13 Z", Color(hex: 0x2F5CBA))
            f("M32 5 L55 13 v17 c0 14 -9 23 -23 29 Z", Color(hex: 0x244A9E))
            s("M32 21 v20 M22 31 h20", Color(hex: 0xFFF8EE), 5)
        }
    }

    /// Points per grid unit.
    private var k: CGFloat { size / 64 }

    private func f(_ d: String, _ color: Color) -> some View {
        GridShape(d: d, grid: 64).fill(color)
    }

    private func s(_ d: String, _ color: Color, _ width: CGFloat, dash: [CGFloat] = []) -> some View {
        GridShape(d: d, grid: 64)
            .stroke(color, style: StrokeStyle(lineWidth: width * k, lineCap: .round, lineJoin: .round, dash: dash.map { $0 * k }))
    }

    private func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Ellipse { Ellipse() }

    /// Sizes and places an ellipse given in grid units.
    private func place(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Place {
        Place(width: rx * 2 * k, height: ry * 2 * k, x: (cx - 32) * k, y: (cy - 32) * k)
    }

    private struct Place: ViewModifier {
        let width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat
        func body(content: Content) -> some View {
            content.frame(width: width, height: height).offset(x: x, y: y)
        }
    }

    /// A rounded rectangle as an SVG path.
    static func rr(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ r: Double) -> String {
        "M\(x + r) \(y) h\(w - 2 * r) a\(r) \(r) 0 0 1 \(r) \(r) v\(h - 2 * r) a\(r) \(r) 0 0 1 \(-r) \(r) "
            + "h\(-(w - 2 * r)) a\(r) \(r) 0 0 1 \(-r) \(-r) v\(-(h - 2 * r)) a\(r) \(r) 0 0 1 \(r) \(-r) Z"
    }
}

// MARK: Two groups of 100

/// Two groups of 100 dots, one per arm of a trial: the filled dots are the people still quit; the hollow ones in the
/// lower group are the gap to the upper one (canvas `EvCard`).
struct EvDotsCard: View {
    let kicker: LocalizedStringKey
    let aLabel: LocalizedStringKey
    let a: Int
    let bLabel: LocalizedStringKey
    let b: Int
    var note: LocalizedStringKey? = nil
    let source: LocalizedStringKey
    let onSource: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(kicker).dxFace(.body, 13, weight: 700).foregroundStyle(Onb.muted)
            group(aLabel, n: a, gap: nil)
            group(bLabel, n: b, gap: a - b)
            if let note {
                Text(note).dxFace(.body, 13, weight: 500).foregroundStyle(Onb.muted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            EvSourceLink(text: source, action: onSource).padding(.vertical, -4)
        }
        .padding(.top, 14).padding(.horizontal, 16).padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .evCard()
    }

    private func group(_ label: LocalizedStringKey, n: Int, gap: Int?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(label).dxFace(.body, 14, weight: 600).foregroundStyle(Onb.muted)
                if let gap, gap > 0 {
                    Circle().strokeBorder(Ev.coral, lineWidth: 1.5).frame(width: 9, height: 9)
                    Text("\(gap) fewer").dxFace(.body, 14, weight: 500).foregroundStyle(Onb.muted)
                }
                Spacer(minLength: 8)
                Text("\(n) in 100").dxFace(.display, 18, weight: 800).foregroundStyle(Onb.ink).lineLimit(1)
            }
            Dots(filled: n, upTo: max(a, b))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text("\(n) of 100 people"))
    }

    /// 100 dots in four rows of 25.
    private struct Dots: View {
        let filled: Int
        let upTo: Int

        var body: some View {
            Canvas { ctx, size in
                let gap: CGFloat = 3
                let d = (size.width - 24 * gap) / 25
                for i in 0..<100 {
                    let rect = CGRect(x: CGFloat(i % 25) * (d + gap), y: CGFloat(i / 25) * (d + gap), width: d, height: d)
                    if i < filled {
                        ctx.fill(Path(ellipseIn: rect), with: .color(Ev.coral))
                    } else if i < upTo {
                        ctx.stroke(Path(ellipseIn: rect.insetBy(dx: 0.75, dy: 0.75)), with: .color(Ev.coral), lineWidth: 1.5)
                    } else {
                        ctx.fill(Path(ellipseIn: rect), with: .color(Ev.dotOff))
                    }
                }
            }
            // Four rows of 25 at a 3 pt gap: 6.56 wide for every 1 tall at the card's width.
            .aspectRatio(6.56, contentMode: .fit)
        }
    }
}

// MARK: The research sheet

/// One entry in the research sheet.
struct ResearchItem: Identifiable {
    let id: Int
    let title: LocalizedStringKey
    let kind: LocalizedStringKey
    let illo: EvIllo.Kind
    let detail: LocalizedStringKey
    let source: HealthSource

    /// Every number the onboarding shows, with where it comes from. The first entry depends on the product.
    static func all(for product: Product) -> [ResearchItem] {
        var items: [ResearchItem] = []
        switch product {
        case .cigarettes:
            items.append(ResearchItem(id: 0, title: "Wanting to quit", kind: "Survey", illo: .page,
                                      detail: "CDC survey of US adults who smoke, 2022.", source: HealthSources.wantToQuitCDC2022))
        case .vape:
            items.append(ResearchItem(id: 0, title: "Wanting to quit", kind: "Survey", illo: .page,
                                      detail: "US PATH Study, 2017 to 2018. Adults who vape.", source: HealthSources.vapeQuitIntentPATH))
        case .pouches:
            break
        }
        items += [
            ResearchItem(id: 1, title: "Medicine plus support", kind: "Review", illo: .stack,
                         detail: "Cochrane, 52 trials, 2016. Support came from trained advisers.",
                         source: HealthSources.medicinePlusSupportCochrane2016),
            ResearchItem(id: 2, title: "Nicotine replacement", kind: "Review", illo: .stack,
                         detail: "Cochrane, 133 trials, 2018. People quitting cigarettes.", source: HealthSources.nrtCochrane2018),
            ResearchItem(id: 3, title: "A patch plus a faster form", kind: "Review", illo: .stack,
                         detail: "Cochrane, 16 trials, 2023.", source: HealthSources.nrtCombinationCochrane2023),
            ResearchItem(id: 4, title: "Reaching 28 days", kind: "NHS", illo: .shield,
                         detail: "NHS Better Health. The NHS does not cite a study for it.", source: HealthSources.nhs28Days),
            ResearchItem(id: 5, title: "Stopping all at once", kind: "Trial", illo: .plan,
                         detail: "One trial of 697 smokers, 2016, and a Cochrane review of 22 trials, 2019.",
                         source: HealthSources.abruptVsGradual2016),
            ResearchItem(id: 6, title: "Withdrawal over time", kind: "Paper", illo: .page,
                         detail: "Hughes, Nicotine and Tobacco Research, 2007.", source: HealthSources.withdrawalHughes2007),
        ]
        return items
    }
}

/// "The research": every source behind the onboarding's numbers, each opening in the browser, with Xero standing on
/// the sheet's edge holding a page. Presented over a dimmed screen (`researchSheet`).
struct ResearchSheet: View {
    let product: Product
    let onClose: () -> Void
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize
    private let motion = MotionPolicy()

    private var paper: Color { Color(light: 0xFFFAF5, dark: 0x151C30) }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(light: (0x461E12, 0.52), dark: (0x03050C, 0.62))
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onClose)
                .accessibilityHidden(true)
            ViewThatFits(in: .vertical) {
                content
                ScrollView { content }
            }
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                    .fill(paper)
                    .overlay(alignment: .top) {
                        if scheme == .dark { Rectangle().fill(Color.white.opacity(0.16)).frame(height: 1).padding(.horizontal, 28) }
                    }
                    .ignoresSafeArea(edges: .bottom)
            }
            .overlay(alignment: .topTrailing) {
                XeroView(mood: .hello, stage: 0, points: 80, animate: !motion.reduce, pose: .hold)
                    .frame(width: 80, height: 80)
                    .overlay { EvIllo(kind: .page, size: 40).offset(y: 10) }
                    .offset(x: -70, y: -70)
                    .accessibilityHidden(true)
            }
            .padding(.top, 96)
        }
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onClose)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Color(light: (0x1E1A3A, 0.25), dark: (0xFFFFFF, 0.3)))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
            HStack(spacing: 12) {
                Text("The research")
                    .dxFace(.display, 26, weight: 800, tracking: -0.7)
                    .foregroundStyle(Onb.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                Button(action: onClose) {
                    EvGlyph(d: "M5 5 L19 19 M19 5 L5 19", size: 16, weight: 2.6)
                        .foregroundStyle(Onb.ink)
                        .frame(width: 44, height: 44)
                        .background(Color(light: 0xFFE7D0, dark: 0x212A41), in: Circle())
                }
                .buttonStyle(.dxPress)
                .accessibilityLabel(Text("Close"))
                .accessibilityIdentifier("research.close")
            }
            .padding(.top, 18)
            Text("Every number in DayXero comes from published research on ways of quitting, not from using DayXero, which hasn’t been tested in a clinical trial.")
                .dxFace(.body, 15, weight: 500).foregroundStyle(Onb.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            VStack(spacing: 0) {
                ForEach(ResearchItem.all(for: product)) { item in
                    row(item)
                }
            }
            .padding(.top, 14)
            Text("DayXero isn’t a medical device and doesn’t replace advice from a doctor or pharmacist.")
                .dxFace(.body, 13, weight: 500).foregroundStyle(Onb.muted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
        }
        .padding(.top, 10).padding(.horizontal, DX.Layout.gutter).padding(.bottom, 16)
        .dxReadableColumn()
    }

    private func row(_ item: ResearchItem) -> some View {
        Link(destination: item.source.url) {
            HStack(alignment: .top, spacing: 12) {
                if !typeSize.isAccessibilitySize {
                    VStack(spacing: 2) {
                        EvIllo(kind: item.illo, size: 38)
                        Text(item.kind).dxFace(.body, 13, weight: 600).foregroundStyle(Onb.muted).lineLimit(1)
                    }
                    .frame(width: 52)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).dxFace(.display, 17, weight: 700, tracking: -0.2).foregroundStyle(Onb.ink)
                    Text(item.detail).dxFace(.body, 14, weight: 500).foregroundStyle(Onb.muted)
                        .lineSpacing(2)
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                EvGlyph(d: "M8 5 h11 v11 M19 5 L6 18", size: 17, weight: 2.4)
                    .foregroundStyle(Onb.ink)
                    .frame(width: 20, height: 26)
            }
            .padding(.top, 12).padding(.bottom, 10)
            .frame(minHeight: 66, alignment: .top)
            .overlay(alignment: .top) { Rectangle().fill(Ev.line).frame(height: 1) }
            .contentShape(Rectangle())
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Opens in your browser"))
    }
}

extension View {
    /// Presents the research sheet over this screen, dimmed behind it.
    func researchSheet(isPresented: Binding<Bool>, product: Product) -> some View {
        fullScreenCover(isPresented: isPresented) {
            ResearchSheet(product: product) { isPresented.wrappedValue = false }
                .presentationBackground(.clear)
                .dxGround(.apricot, paint: false)
        }
    }
}
