import DayXeroCore
import SwiftUI

/// The health-timeline illustration set (CHAR-05, 2 Nov 2026), one drawing per change, as signed off on the
/// "Milestone illustrations" canvas: warm, rounded, flat shapes in an earthy palette, objects only. Each has one
/// deeper shadow shape set down and right, one cream highlight, and one slow loop, and sits on a soft hand-cut blob
/// in the mist of its main colour. The drawings are the same in both themes; only the blob follows the theme.
/// Every screen that shows the health timeline draws it with `HealthBadge` (DESIGN_METHODOLOGY.md).
struct HealthBadge: View {
    /// A health-timeline item id (health-timeline.json). Unknown ids get a sparkle.
    let id: String
    /// Reached gets a check, under way a progress ring, ahead goes grey and still.
    var state: HealthTimeline.State = .underWay(0)
    var size: CGFloat = 48
    /// The ring round an under-way change; off where the card shows its own progress.
    var showsRing = true

    var body: some View {
        let ahead = state == .ahead
        ZStack {
            BadgeBlob().fill(ahead ? Self.aheadFill : Self.tint(for: id))
            HealthArt(id: id, size: size * 0.64, still: ahead)
                .grayscale(ahead ? 1 : 0)
                .opacity(ahead ? 0.55 : 1)
        }
        .frame(width: size, height: size)
        .overlay {
            if showsRing, case .underWay(let progress) = state {
                Circle()
                    .trim(from: 0, to: CGFloat(max(progress, 0.03)))
                    .stroke(Read4.accent, style: StrokeStyle(lineWidth: max(2, size / 22), lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(-size * 0.09)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if state == .done {
                let d = max(size * 0.36, 14)
                Image(systemName: "checkmark")
                    .font(.system(size: d * 0.5, weight: .heavy))
                    .foregroundStyle(Read4.onInk)
                    .frame(width: d, height: d)
                    .background(Read4.accent, in: Circle())
                    .overlay(Circle().strokeBorder(Read4.card, lineWidth: 2))
                    .offset(x: d * 0.15, y: d * 0.15)
            }
        }
        .accessibilityHidden(true)
    }

    private static let aheadFill = Color(light: (0xECE6DC, 1), dark: (0xFFFFFF, 0.07))

    /// The soft blob in the drawing's main colour: its mist in light, a deep version of it in dark.
    static func tint(for id: String) -> Color {
        switch MilestoneDrawing.hue(id) {
        case .clay: Color(light: (0xF4DFD2, 1), dark: (0x432A21, 1))
        case .blue: Color(light: (0xDDE7EC, 1), dark: (0x26333A, 1))
        case .sage: Color(light: (0xE3E7D3, 1), dark: (0x2C3224, 1))
        case .plum: Color(light: (0xE9DCE2, 1), dark: (0x352731, 1))
        case .ochre: Color(light: (0xF3E5C6, 1), dark: (0x3D3220, 1))
        }
    }
}

/// The hand-cut blob behind each drawing, from the canvas's 100-point grid.
struct BadgeBlob: Shape {
    func path(in rect: CGRect) -> Path {
        MilestoneDrawing.svg("M50 5 C73 4 93 21 95 47 C97 73 77 95 51 95 C25 96 6 77 5 51 C4 25 26 6 50 5 Z")
            .applying(CGAffineTransform(scaleX: rect.width / 100, y: rect.height / 100))
            .offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

/// One drawing on its own, on a 64-point grid scaled to `size`. Loops gently; still with Reduce Motion or `still`.
struct HealthArt: View {
    let id: String
    var size: CGFloat = 40
    var still = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let frozen = still || reduceMotion
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: frozen)) { timeline in
            let clock = MilestoneDrawing.Clock(t: timeline.date.timeIntervalSinceReferenceDate, still: frozen)
            Canvas { context, canvas in
                context.scaleBy(x: canvas.width / 64, y: canvas.height / 64)
                MilestoneDrawing.draw(id, clock: clock, in: &context)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// The drawings, ported from the canvas's SVG (CHAR-05), on a 64 × 64 grid.
enum MilestoneDrawing {
    static let ids = ["heart-rate", "carbon-monoxide", "circulation", "coughing", "heart-attack", "mouth-cancer",
                      "lung-cancer", "heart-disease", "withdrawal-start", "nicotine-gone", "withdrawal-peak", "mood",
                      "cravings-fade", "taste", "fresh-breath", "lips", "skin-glow", "hair", "even-tone", "sleep"]

    enum Hue { case clay, blue, sage, plum, ochre }

    static func hue(_ id: String) -> Hue {
        switch id {
        case "heart-rate", "carbon-monoxide", "circulation", "heart-disease", "taste", "lips": .clay
        case "coughing", "lung-cancer", "fresh-breath": .blue
        case "withdrawal-start", "cravings-fade", "hair", "sleep": .plum
        case "nicotine-gone", "mood", "skin-glow": .ochre
        default: .sage
        }
    }


    /// Time for the loops. `still` holds each one at rest.
    struct Clock {
        let t: Double
        let still: Bool

        func phase(_ period: Double, delay: Double = 0) -> Double {
            let p = (t - delay).truncatingRemainder(dividingBy: period) / period
            return p < 0 ? p + 1 : p
        }

        /// 0 at the start of each loop, 1 halfway, back to 0, eased; `rest` when still.
        func swing(_ period: Double, delay: Double = 0, rest: Double = 0) -> Double {
            still ? rest : 0.5 - 0.5 * cos(2 * .pi * phase(period, delay: delay))
        }

        /// A heartbeat: two pulses, then a pause, every 1.6 s.
        var beat: CGFloat {
            guard !still else { return 1 }
            let keys: [(Double, Double)] = [(0, 1), (0.14, 1.1), (0.28, 1), (0.42, 1.06), (0.6, 1), (1, 1)]
            let p = phase(1.6)
            for (a, b) in zip(keys, keys.dropFirst()) where p <= b.0 {
                return CGFloat(a.1 + (b.1 - a.1) * (p - a.0) / (b.0 - a.0))
            }
            return 1
        }
    }

    /// The earthy palette from the canvas. The same in both themes, except the stems and windpipe, which lift in dark.
    private enum Ink {
        static let terracotta = Color(hex: 0xC8613F), terracottaDeep = Color(hex: 0xA44A2C), clay = Color(hex: 0xE59A7A)
        static let ochre = Color(hex: 0xD9A03A), ochreDeep = Color(hex: 0xB07E22), ochreMist = Color(hex: 0xF3E5C6)
        static let sage = Color(hex: 0x93A27A), sageDeep = Color(hex: 0x77865E), sageLight = Color(hex: 0xA6B38F)
        static let olive = Color(hex: 0x5C6B36), mossDeep = Color(hex: 0x3C4A2C)
        static let moss = Color(light: 0x3C4A2C, dark: 0xC9D2B4)
        static let blue = Color(hex: 0x6F92A8), blueDeep = Color(hex: 0x52758B), blueLight = Color(hex: 0xB9CCD6)
        static let plum = Color(hex: 0x7C4E63), plumDeep = Color(hex: 0x613B4D), plumLight = Color(hex: 0x94627A)
        static let grey = Color(hex: 0xA9A197)
        static let cream = Color(hex: 0xFBF5EC), creamShade = Color(hex: 0xD9CBB4), toothShade = Color(hex: 0xB7C3C6)
        static let shine = Color(hex: 0xF7EFE2)
    }

    private static let heart = "M32 54 C15 43 8 33 8 23 C8 15 14 9.5 21.5 9.5 C26.5 9.5 30 12.5 32 16.5 C34 12.5 37.5 9.5 42.5 9.5 C50 9.5 56 15 56 23 C56 33 49 43 32 54 Z"
    private static let heartLow = "M32 56 C16 46 9 36 9 26.5 C9 19 14.5 13.5 21.5 13.5 C26.5 13.5 30 16.5 32 20.5 C34 16.5 37.5 13.5 42.5 13.5 C49.5 13.5 55 19 55 26.5 C55 36 48 46 32 56 Z"
    private static let lobeLeft = "M29 20 C22 18 12 26 11 40 C10 50 16 54 22 52 C27 50 29 46 29 40 Z"
    private static let lobeRight = "M35 20 C42 18 52 26 53 40 C54 50 48 54 42 52 C37 50 35 46 35 40 Z"
    private static let lobeLeftLow = "M29 22 C22 20 13 28 12 41 C11 50 17 54 22.5 52 C27 50 29 46 29 41 Z"
    private static let lobeRightLow = "M35 22 C42 20 51 28 52 41 C53 50 47 54 41.5 52 C37 50 35 46 35 41 Z"
    private static let shield = "M32 6 C40 9 47 11.5 52 12.5 C53.5 13 54 14 54 15.5 V30 C54 43 44 52 32 58 C20 52 10 43 10 30 V15.5 C10 14 10.5 13 12 12.5 C17 11.5 24 9 32 6 Z"
    private static let bubble = "M14 12 H50 Q56 12 56 18 V38 Q56 44 50 44 H30 L21.5 51.5 Q19.5 53 19.5 50.5 V44 H14 Q8 44 8 38 V18 Q8 12 14 12 Z"
    private static let vessel = "M9 44 C9 22 28 18 32 32 C36 46 55 42 55 20"
    private static let toothShape = "M14 14 C20 10 24 13 28 13 C32 13 36 10 42 14 C48 18 46 30 43 38 C41 45 40 54 36 54 C32 54 32 42 28 42 C24 42 24 54 20 54 C16 54 15 45 13 38 C10 30 8 18 14 14 Z"
    private static let lipsShape = "M10 32 C14 24 20 20 26 22 C29 23 31 25 32 26 C33 25 35 23 38 22 C44 20 50 24 54 32 C48 44 40 48 32 48 C24 48 16 44 10 32 Z"
    private static let moonShape = "M36 10 C24 12 16 22 16 34 C16 46 26 56 38 56 C44 56 48 54 51 50 C36 50 26 40 26 28 C26 20 30 14 36 10 Z"
    private static let cloudLow = "M14 54 H40 C45 54 48 50.5 48 46 C48 41.5 44.5 38 40 38 C39 33 35 30 30 30 C24.5 30 20 34 20 39.5 C16 39.5 12 42.5 12 46.5 C12 50.5 14 54 14 54 Z"
    private static let cloudRight = "M30 56 H52 C56 56 59 53 59 49 C59 45 56 42 52 42 C51 38 47.5 35.5 43 35.5 C38 35.5 34 39 34 43.5 C30.5 43.5 27 46 27 49.5 C27 53 30 56 30 56 Z"
    private static let pebble = "M32 12 C46 12 54 22 54 34 C54 46 45 54 32 54 C19 54 10 46 10 34 C10 22 18 12 32 12 Z"
    private static let starShape = "M0 -5 C0.7 -1.2 1.2 -0.7 5 0 C1.2 0.7 0.7 1.2 0 5 C-0.7 1.2 -1.2 0.7 -5 0 C-1.2 -0.7 -0.7 -1.2 0 -5 Z"

    static func draw(_ id: String, clock k: Clock, in c: inout GraphicsContext) {
        switch id {
        case "heart-rate":
            let h = scaled(c, by: k.beat, around: CGPoint(x: 32, y: 32))
            shaded(h, heart, Ink.terracotta, Ink.terracottaDeep)
            shine(h, "M14 22 Q15 15 21.5 13.5")
            let trace = svg("M12 31 H21 L25 24 L30 38 L34 27 L37 31 H52")
            c.stroke(k.still ? trace : trace.trimmedPath(from: 0, to: min(1, k.phase(1.6) / 0.55)),
                     with: .color(Ink.shine), style: line(3.2))
            star(c, 58, 6, k, delay: 0)
        case "carbon-monoxide":
            c.fill(ellipse(31.5, 43.5, 19, 12), with: .color(Ink.terracottaDeep))
            c.fill(ellipse(30, 41, 19, 12), with: .color(Ink.terracotta))
            c.fill(ellipse(30, 41, 9, 5), with: .color(Ink.terracottaDeep.opacity(0.5)))
            shine(c, "M16 37.5 Q19 32.5 25 31.5", width: 2.2)
            // Oxygen rises in; the carbon monoxide fades away.
            for (x, y, r, delay) in [(16.0, 20.0, 6.0, 0.0), (34, 13, 7.5, 0.9), (50, 22, 5, 1.7)] as [(CGFloat, CGFloat, CGFloat, Double)] {
                var o = c
                if !k.still {
                    let p = k.phase(2.6, delay: delay)
                    o.translateBy(x: 0, y: CGFloat(5 - 12 * p))
                    o.opacity = p < 0.25 ? p / 0.25 : 1 - (p - 0.25) / 0.75
                }
                o.fill(ellipse(x, y, r, r), with: .color(Ink.blue))
                o.fill(ellipse(x - r * 0.33, y - r * 0.33, r * 0.3, r * 0.3), with: .color(Ink.shine.opacity(0.85)))
            }
            var co = c
            co.opacity = 0.8 - 0.6 * k.swing(3)
            co.fill(ellipse(56, 45, 3.6, 3.6), with: .color(Ink.grey))
        case "circulation":
            let v = svg(vessel)
            c.stroke(v.offsetBy(dx: 0, dy: 2.5), with: .color(Ink.terracottaDeep), style: line(9))
            c.stroke(v, with: .color(Ink.terracotta), style: line(9))
            var flow = line(2.6)
            flow.dash = [3, 7]
            flow.dashPhase = k.still ? 0 : CGFloat(-20 * k.phase(1.1))
            c.stroke(v, with: .color(Ink.shine), style: flow)
            star(c, 50, 52, k, delay: 0)
            star(c, 15, 12, scale: 0.8, k, delay: 0.7)
        case "coughing":
            drawLungs(scaled(c, by: breathe(k), around: CGPoint(x: 32, y: 36)), left: lobeLeft, right: lobeRight,
                      shine: "M15.5 36 Q16.5 28 22 24.5")
            c.stroke(svg("M32 7 V24 M32 23 Q32 28 26 31 M32 23 Q32 28 38 31"), with: .color(Ink.moss), style: line(3.6))
            breathLines(c, "M43 10 Q47 7 51 10", "M45 15.5 Q49.5 13 54 15.5", k)
        case "heart-attack":
            shaded(c, shield, Ink.olive, Ink.mossDeep)
            shine(c, "M15 27 Q15 19 19 16.5", width: 2.2, opacity: 0.5)
            var inner = c
            inner.translateBy(x: 20, y: 21)
            inner.scaleBy(x: 0.375, y: 0.375)
            scaled(inner, by: k.beat, around: CGPoint(x: 32, y: 32)).fill(svg(heart), with: .color(Ink.terracotta))
            star(c, 56, 6, scale: 0.9, k, delay: 0)
        case "mouth-cancer":
            shaded(c, bubble, Ink.sage, Ink.sageDeep)
            shine(c, "M12.5 24 Q12.5 17 17.5 16", width: 2.2, opacity: 0.6)
            // The dots of someone talking, one after another.
            for i in 0..<3 {
                let lift = 2.2 * CGFloat(k.swing(1.2, delay: Double(i) * 0.2))
                c.fill(ellipse(22 + CGFloat(i) * 10, 28 - lift, 3.2, 3.2), with: .color(Ink.cream))
            }
        case "lung-cancer":
            drawLungs(scaled(c, by: breathe(k), around: CGPoint(x: 32, y: 38)), left: lobeLeftLow, right: lobeRightLow,
                      shine: "M16.5 37 Q17.5 30 22.5 27")
            c.stroke(svg("M32 12 V25 M32 24 Q32 29 26 32 M32 24 Q32 29 38 32"), with: .color(Ink.moss), style: line(3.4))
            let leaves = rotated(c, by: sway(k), around: CGPoint(x: 32, y: 13))
            leaves.fill(svg("M32 14 C28 8 22 8 20 10 C23 15 28 15.5 32 14 Z"), with: .color(Ink.sage))
            leaves.fill(svg("M32 12 C35 6 41 5 44 7 C42 12 37 13 32 12 Z"), with: .color(Ink.sage))
        case "heart-disease":
            c.stroke(svg("M32 18 Q32 11 35.5 7"), with: .color(Ink.olive), style: line(2.4))
            rotated(c, by: sway(k), around: CGPoint(x: 35, y: 8))
                .fill(svg("M35 8.5 C38.5 3 45.5 3 48 6 C45 10.5 39 11.5 35 8.5 Z"), with: .color(Ink.sage))
            let h = scaled(c, by: k.beat, around: CGPoint(x: 32, y: 35))
            shaded(h, heartLow, Ink.terracotta, Ink.terracottaDeep)
            shine(h, "M14.5 26 Q15.5 19 21.5 17.5")
        case "withdrawal-start":
            // A small boat setting out, rocking on the water.
            var boat = c
            boat.translateBy(x: 0, y: -2.5 * CGFloat(k.swing(2.8)))
            boat.stroke(svg("M32 40 V14"), with: .color(Ink.moss), style: line(1.8))
            boat.fill(svg("M33 15 C40 22 44 30 45 37 H33 Z"), with: .color(Ink.terracotta))
            boat.fill(svg("M31 19 C26 25 23 31 22 37 H31 Z"), with: .color(Ink.cream))
            boat.fill(svg("M17 40 H47 C46 45 41.5 48.5 36 48.5 H28 C22.5 48.5 18 45 17 40 Z"), with: .color(Ink.plum))
            c.fill(svg("M4 48 C10 44 16 44 22 48 C28 52 34 52 40 48 C46 44 52 44 60 48 V54 C60 57 58 59 55 59 H9 C6 59 4 57 4 54 Z"),
                   with: .color(Ink.blue))
            c.fill(svg("M4 53 C10 50 16 50 22 53 C28 56 34 56 40 53 C46 50 52 50 60 53 V54 C60 57 58 59 55 59 H9 C6 59 4 57 4 54 Z"),
                   with: .color(Ink.blueDeep))
        case "nicotine-gone":
            var molecule = scaled(c, by: 1 - 0.15 * CGFloat(k.swing(3)), around: CGPoint(x: 31, y: 35))
            molecule.opacity = 1 - 0.6 * k.swing(3)
            molecule.stroke(svg("M18 42 L31 29 L45 37"), with: .color(Ink.grey), style: line(3))
            molecule.fill(ellipse(18, 42, 6.5, 6.5), with: .color(Ink.grey))
            molecule.fill(ellipse(31, 29, 6.5, 6.5), with: .color(Ink.grey.opacity(0.75)))
            molecule.fill(ellipse(45, 37, 6.5, 6.5), with: .color(Ink.grey.opacity(0.5)))
            molecule.fill(ellipse(16, 40, 1.8, 1.8), with: .color(Ink.shine.opacity(0.8)))
            star(c, 50, 16, k, delay: 0)
            star(c, 13, 20, scale: 0.7, k, delay: 0.7)
            c.fill(ellipse(54, 46, 1.8, 1.8), with: .color(Ink.ochre))
            c.fill(ellipse(50, 52, 1.2, 1.2), with: .color(Ink.ochre))
        case "withdrawal-peak":
            c.fill(ellipse(47, 16, 6.5, 6.5), with: .color(Ink.ochre))
            c.fill(svg("M30 54 C38 42 44 34 49 32 C54 34 59 44 64 54 Z"), with: .color(Ink.sage))
            c.fill(svg("M2 54 C12 40 22 22 28 14 C34 22 44 40 54 54 Z"), with: .color(Ink.olive))
            c.fill(svg("M28 14 C34 22 44 40 54 54 L36 54 C34 40 31 25 28 14 Z"), with: .color(Ink.mossDeep))
            c.fill(svg("M28 14 C25.5 17.5 23.5 21 22 24.5 C24.5 23.5 26 25.5 28 24 C30 25.5 32 23.5 34.5 24.5 C32.5 21 30.5 17.5 28 14 Z"),
                   with: .color(Ink.shine))
            var trail = line(1.8)
            trail.dash = [2.5, 3.5]
            trail.dashPhase = k.still ? 0 : CGFloat(-12 * k.phase(1.4))
            c.stroke(svg("M17 54 C21 48 25 44 25 38"), with: .color(Ink.shine.opacity(0.8)), style: trail)
            c.stroke(svg("M28 14 V5"), with: .color(Ink.mossDeep), style: line(1.6))
            var flag = c
            flag.translateBy(x: 28, y: 7.5)
            flag.concatenate(CGAffineTransform(a: 1, b: tan(-10 * .pi / 180 * CGFloat(k.swing(1.4))), c: 0, d: 1, tx: 0, ty: 0))
            flag.translateBy(x: -28, y: -7.5)
            flag.fill(svg("M28 5 L36 7.5 L28 10 Z"), with: .color(Ink.terracotta))
        case "mood":
            // The sun comes out from behind a cloud, its rays turning a little.
            let rays = rotated(c, by: .degrees(k.still ? 0 : -12 + 24 * k.swing(6)), around: CGPoint(x: 38, y: 26))
            rays.stroke(svg("M38 7 V10.5 M51.4 12.6 L49 15 M57 26 H53.5 M24.6 12.6 L27 15"), with: .color(Ink.ochre), style: line(3))
            c.fill(ellipse(39.5, 28.5, 11, 11), with: .color(Ink.ochreDeep))
            c.fill(ellipse(38, 26, 11, 11), with: .color(Ink.ochre))
            shine(c, "M31 23 Q32.5 18.5 37 17.5", width: 2.2)
            var drift = c
            drift.translateBy(x: -2 * CGFloat(k.swing(4)), y: 0)
            shaded(drift, cloudLow, Ink.cream, Ink.creamShade, lift: CGSize(width: 0, height: 2.5))
        case "cravings-fade":
            // Three waves, each calmer than the last; the top one still rocks.
            var top = c
            top.translateBy(x: 0, y: -2 * CGFloat(k.swing(2.8)))
            top.stroke(svg("M9 21 C15 13 21 13 27 21 C33 29 39 29 45 21 C49 16 53 16 56 19"), with: .color(Ink.plum), style: line(4.5))
            c.stroke(svg("M9 34 C15 29 21 29 27 34 C33 39 39 39 45 34 C49 31 53 31 56 33"), with: .color(Ink.blue), style: line(4.5))
            c.stroke(svg("M9 47 C19 45 29 49 39 47 C45 46 51 46 56 47"), with: .color(Ink.sage), style: line(4.5))
            star(c, 53, 55, scale: 0.8, k, delay: 0)
        case "taste":
            // Two cherries swinging gently from their stalk.
            let bunch = rotated(c, by: sway(k), around: CGPoint(x: 37, y: 12))
            bunch.stroke(svg("M22 34 Q26 20 37 12 M42 36 Q41 24 37 12"), with: .color(Ink.olive), style: line(2.6))
            bunch.fill(svg("M37 12 C42 5 51 6 54 10 C49 15 42 15 37 12 Z"), with: .color(Ink.sage))
            for (x, y) in [(22.0, 42.0), (43, 44)] as [(CGFloat, CGFloat)] {
                bunch.fill(ellipse(x + 1.5, y + 2.5, 11, 11), with: .color(Ink.terracottaDeep))
                bunch.fill(ellipse(x, y, 11, 11), with: .color(Ink.terracotta))
                shine(bunch, "M\(x - 7) \(y - 2) Q\(x - 6) \(y - 7.5) \(x - 1.5) \(y - 8.5)")
            }
        case "fresh-breath":
            // A clean tooth that bobs a little, a sprig of mint, and fresh air.
            var tooth = c
            tooth.translateBy(x: 0, y: -2 * CGFloat(k.swing(2.8)))
            shaded(tooth, toothShape, Ink.cream, Ink.toothShade)
            tooth.stroke(svg("M15.5 25 Q16.5 18.5 21 17"), with: .color(Ink.blueLight), style: line(2.4))
            c.stroke(svg("M51 57 Q51 47 48 39"), with: .color(Ink.olive), style: line(2.2))
            c.fill(svg("M49.5 46 C54 40 59.5 40.5 60.5 43.5 C57 48.5 52 48.5 49.5 46 Z"), with: .color(Ink.sage))
            c.fill(svg("M48.5 40 C45 34.5 45.5 29.5 48.5 28 C52 31.5 51.5 36.5 48.5 40 Z"), with: .color(Ink.sage))
            breathLines(c, "M47 13 Q51 10 55 13", "M49 18.5 Q53 16 57 18.5", k)
        case "lips":
            // Lips that soften and fill out, slowly.
            let l = scaled(c, by: 0.96 + 0.06 * CGFloat(k.swing(2.6, rest: 0.6)), around: CGPoint(x: 32, y: 35))
            shaded(l, lipsShape, Ink.terracotta, Ink.terracottaDeep)
            l.stroke(svg("M14 32 C22 34.5 27 33.5 32 32 C37 33.5 42 34.5 50 32"), with: .color(Ink.terracottaDeep), style: line(1.8))
            shine(l, "M25 41.5 Q32 44 39 41.5", width: 2.2, opacity: 0.6)
            star(c, 51, 16, k, delay: 0.4)
        case "skin-glow":
            // A hand mirror with a glint sweeping across the glass.
            c.fill(svg("M29 40 H35 V54 C35 56 33.5 57.5 32 57.5 C30.5 57.5 29 56 29 54 Z"), with: .color(Ink.plum))
            c.fill(ellipse(33.5, 28.5, 16, 16), with: .color(Ink.ochreDeep))
            c.fill(ellipse(32, 26, 16, 16), with: .color(Ink.ochre))
            c.fill(ellipse(32, 26, 11.5, 11.5), with: .color(Ink.cream))
            var glass = c
            glass.clip(to: ellipse(32, 26, 11.5, 11.5))
            let sweep = CGFloat(k.still ? 0.5 : k.phase(3.2))
            glass.translateBy(x: -16 + 32 * sweep, y: 0)
            glass.stroke(svg("M26 31 L36 21"), with: .color(Ink.ochreMist), style: line(3))
            glass.stroke(svg("M30.5 33 L38 25.5"), with: .color(Ink.ochreMist), style: line(1.6))
            star(c, 52, 10, color: Ink.clay, k, delay: 0)
            c.fill(ellipse(12, 44, 1.8, 1.8), with: .color(Ink.clay))
        case "hair":
            // Three strands swaying from the root, each a beat behind the last.
            for (i, x) in ([22, 32, 42] as [CGFloat]).enumerated() {
                let strand = rotated(c, by: .degrees(k.still ? 0 : -4 + 8 * k.swing(3.2, delay: Double(i) * 0.35)),
                                     around: CGPoint(x: x, y: 10))
                let d = "M\(x) 10 C\(x - 4) 22 \(x + 4) 30 \(x) 42 C\(x - 2) 48 \(x - 1) 52 \(x) 54"
                strand.stroke(svg(d).offsetBy(dx: 1.5, dy: 2.5), with: .color(Ink.plumDeep), style: line(5.5))
                strand.stroke(svg(d), with: .color(i == 1 ? Ink.plumLight : Ink.plum), style: line(5.5))
                if i == 1 { shine(strand, "M29.6 15 Q28.8 19 29.8 23", width: 1.4, opacity: 0.6) }
            }
            star(c, 53, 14, k, delay: 0.6)
        case "even-tone":
            // Two tones in one pebble, the lighter side slowly evening out.
            shaded(c, pebble, Ink.sage, Ink.sageDeep)
            var half = c
            half.opacity = k.still ? 1 : 1 - 0.6 * k.swing(4)
            half.fill(svg("M32 12 C18 12 10 22 10 34 C10 46 19 54 32 54 C28 46 30 40 33 34 C36 27 35 18 32 12 Z"), with: .color(Ink.sageLight))
            shine(c, "M16 27 Q17.5 20 23 17.5")
            star(c, 52, 12, k, delay: 0)
        case "sleep":
            // A moon bobbing gently above a cloud, a star twinkling.
            var moon = c
            moon.translateBy(x: 0, y: -2.5 * CGFloat(k.swing(2.8)))
            shaded(moon, moonShape, Ink.ochre, Ink.ochreDeep)
            shine(moon, "M20.5 31 Q21.5 22 27 17", width: 2.2, opacity: 0.6)
            shaded(c, cloudRight, Ink.cream, Ink.creamShade, lift: CGSize(width: 0, height: 2.5))
            star(c, 48, 16, scale: 0.9, color: Ink.plum, k, delay: 0)
            c.fill(ellipse(56, 27, 1.6, 1.6), with: .color(Ink.plum))
        default:
            var big = c
            big.translateBy(x: 1.5, y: 2.5)
            star(big, 32, 32, scale: 4.2, color: Ink.ochreDeep, k, delay: 0)
            star(c, 32, 32, scale: 4.2, k, delay: 0)
        }
    }

    // MARK: Parts

    /// The shadow set down and right, then the shape itself.
    private static func shaded(_ c: GraphicsContext, _ d: String, _ fill: Color, _ shadow: Color,
                               lift: CGSize = CGSize(width: 1.5, height: 2.5)) {
        let shape = svg(d)
        c.fill(shape.offsetBy(dx: lift.width, dy: lift.height), with: .color(shadow))
        c.fill(shape, with: .color(fill))
    }

    /// The one cream highlight.
    private static func shine(_ c: GraphicsContext, _ d: String, width: CGFloat = 2.4, opacity: Double = 0.7) {
        c.stroke(svg(d), with: .color(Ink.shine.opacity(opacity)), style: line(width))
    }

    private static func drawLungs(_ c: GraphicsContext, left: String, right: String, shine highlight: String) {
        let l = svg(left), r = svg(right)
        c.fill(l.offsetBy(dx: 1.5, dy: 2.5), with: .color(Ink.blueDeep))
        c.fill(r.offsetBy(dx: 1.5, dy: 2.5), with: .color(Ink.blueDeep))
        c.fill(l, with: .color(Ink.blue))
        c.fill(r, with: .color(Ink.blue))
        shine(c, highlight, width: 2.2, opacity: 0.6)
    }

    /// Two short breaths of air that fade in and out, one after the other.
    private static func breathLines(_ c: GraphicsContext, _ first: String, _ second: String, _ k: Clock) {
        for (d, delay, rest) in [(first, 0.0, 1.0), (second, 0.7, 0.6)] {
            var w = c
            w.opacity = k.still ? rest : 0.25 + 0.75 * k.swing(2.2, delay: delay)
            w.stroke(svg(d), with: .color(Ink.blue), style: line(2.3))
        }
    }

    /// A soft four-point star that twinkles every 2.2 s, centred on (x, y).
    private static func star(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, scale s: CGFloat = 1, color: Color = Ink.ochre,
                             _ k: Clock, delay: Double) {
        let p = k.swing(2.2, delay: delay, rest: 1)
        var g = c
        g.translateBy(x: x, y: y)
        let size = s * (0.65 + 0.35 * CGFloat(p))
        g.scaleBy(x: size, y: size)
        g.opacity = 0.4 + 0.6 * p
        g.fill(svg(starShape), with: .color(color))
    }

    private static func line(_ w: CGFloat) -> StrokeStyle { StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round) }
    private static func breathe(_ k: Clock) -> CGFloat { 0.94 + 0.09 * CGFloat(k.swing(3.8, rest: 0.6)) }
    private static func sway(_ k: Clock) -> Angle { .degrees(k.still ? 0 : -6 + 12 * k.swing(3.2)) }

    private static func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry))
    }

    private static func scaled(_ c: GraphicsContext, by s: CGFloat, around p: CGPoint) -> GraphicsContext {
        var g = c
        g.translateBy(x: p.x, y: p.y)
        g.scaleBy(x: s, y: s)
        g.translateBy(x: -p.x, y: -p.y)
        return g
    }

    private static func rotated(_ c: GraphicsContext, by angle: Angle, around p: CGPoint) -> GraphicsContext {
        var g = c
        g.translateBy(x: p.x, y: p.y)
        g.rotate(by: angle)
        g.translateBy(x: -p.x, y: -p.y)
        return g
    }

    // MARK: SVG path data

    private enum Token { case command(Character), number(CGFloat) }

    /// Absolute SVG path data, as the kit's drawings are written: M L H V C S Q T Z.
    static func svg(_ d: String) -> Path {
        var tokens: [Token] = []
        var number = ""
        func endNumber() {
            if let v = Double(number) { tokens.append(.number(CGFloat(v))) }
            number = ""
        }
        for ch in d {
            if ch.isLetter {
                endNumber()
                tokens.append(.command(ch))
            } else if ch == "-" {
                endNumber()
                number = "-"
            } else if ch.isNumber || ch == "." {
                number.append(ch)
            } else {
                endNumber()
            }
        }
        endNumber()

        var path = Path()
        var i = 0
        var command: Character = "M"
        var previous: Character = "M"
        var current = CGPoint.zero
        var control = CGPoint.zero
        func next() -> CGFloat {
            defer { i += 1 }
            if case .number(let v) = tokens[i] { return v }
            return 0
        }
        func point() -> CGPoint {
            let x = next()
            return CGPoint(x: x, y: next())
        }
        func reflected() -> CGPoint { CGPoint(x: 2 * current.x - control.x, y: 2 * current.y - control.y) }

        while i < tokens.count {
            if case .command(let c) = tokens[i] {
                command = c
                i += 1
                if c == "Z" {
                    path.closeSubpath()
                    previous = c
                    continue
                }
            }
            guard i < tokens.count, case .number = tokens[i] else { continue }
            switch command {
            case "M":
                current = point()
                path.move(to: current)
                command = "L"
            case "L":
                current = point()
                path.addLine(to: current)
            case "H":
                current.x = next()
                path.addLine(to: current)
            case "V":
                current.y = next()
                path.addLine(to: current)
            case "C":
                let c1 = point(), c2 = point()
                current = point()
                path.addCurve(to: current, control1: c1, control2: c2)
                control = c2
            case "S":
                let c1 = previous == "C" || previous == "S" ? reflected() : current
                let c2 = point()
                current = point()
                path.addCurve(to: current, control1: c1, control2: c2)
                control = c2
            case "Q":
                let c1 = point()
                current = point()
                path.addQuadCurve(to: current, control: c1)
                control = c1
            case "T":
                let c1 = previous == "Q" || previous == "T" ? reflected() : current
                current = point()
                path.addQuadCurve(to: current, control: c1)
                control = c1
            default:
                i += 1
            }
            previous = command
        }
        return path
    }
}

#if DEBUG
/// Every illustration in its three states, for review (`-dx.illustrationGallery YES`).
struct MilestoneIllustrationGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.m) {
                Text("Your body · CHAR-05").v4Text(.micro)
                Text("Health illustrations").v4Text(.title)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: DX.Space.s)], spacing: DX.Space.m) {
                    ForEach(MilestoneDrawing.ids + ["sparkle"], id: \.self) { id in
                        VStack(spacing: 6) {
                            HealthBadge(id: id, state: .underWay(0.6), size: 72, showsRing: false)
                            Text(verbatim: id).v4Text(.subtitle).lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                }
                Text("Reached · under way · ahead").v4Text(.micro)
                HStack(spacing: DX.Space.l) {
                    HealthBadge(id: "mood", state: .done, size: 56)
                    HealthBadge(id: "mood", state: .underWay(0.8), size: 56)
                    HealthBadge(id: "mood", state: .ahead, size: 56)
                }
                .padding(.leading, DX.Space.xs)
            }
            .padding(.horizontal, DX.Space.m)
            .padding(.top, DX.Space.xl)
            .padding(.bottom, DX.Space.xxl)
        }
        .background(Read4.background.ignoresSafeArea())
    }
}
#endif
