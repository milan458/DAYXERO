import DayXeroCore
import SwiftUI

/// The health-timeline illustration set (S21.6), one drawing per change, as signed off on the illustration kit board:
/// chunky filled shapes, a darker bottom edge, one white highlight and one slow loop each. The colour says which
/// part of the body is healing and is the same in both themes; only the soft circle behind it follows the theme.
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
            Circle().fill(ahead ? Self.aheadFill : Self.tint(for: id))
            HealthArt(id: id, size: size * 0.68, still: ahead)
                .grayscale(ahead ? 1 : 0)
                .opacity(ahead ? 0.5 : 1)
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

    private static let aheadFill = Color(light: (0xE7E9DD, 1), dark: (0xFFFFFF, 0.07))

    /// The soft circle in the drawing's body-part colour.
    static func tint(for id: String) -> Color {
        switch MilestoneDrawing.hue(id) {
        case .coral: Color(light: (0xFFE5DF, 1), dark: (0xFF7A66, 0.18))
        case .sky: Color(light: (0xE1F0FD, 1), dark: (0x7FC0F5, 0.18))
        case .sage: Color(light: (0xE9ECD7, 1), dark: (0xBCC388, 0.2))
        case .lilac: Color(light: (0xEEEAFD, 1), dark: (0xB7A4F2, 0.2))
        case .sun: Color(light: (0xFDF2D2, 1), dark: (0xF7C548, 0.18))
        }
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

/// The drawings, ported from the kit's SVG (planning mockups, "Illustration kit"), on a 64 × 64 grid.
enum MilestoneDrawing {
    static let ids = ["heart-rate", "carbon-monoxide", "circulation", "coughing", "heart-attack", "mouth-cancer",
                      "lung-cancer", "heart-disease", "withdrawal-start", "nicotine-gone", "withdrawal-peak", "mood",
                      "cravings-fade", "taste", "fresh-breath", "lips", "skin-glow", "hair", "even-tone", "sleep"]

    enum Hue { case coral, sky, sage, lilac, sun }

    static func hue(_ id: String) -> Hue {
        switch id {
        case "heart-rate", "circulation", "heart-disease", "lips": .coral
        case "carbon-monoxide", "coughing", "lung-cancer", "fresh-breath": .sky
        case "withdrawal-start", "cravings-fade", "hair", "sleep": .lilac
        case "nicotine-gone", "mood", "skin-glow": .sun
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

    private enum Ink {
        static let coral = Color(hex: 0xFF7A66), coralDeep = Color(hex: 0xE2563F)
        static let sky = Color(hex: 0x7FC0F5), skyDeep = Color(hex: 0x4F9BE6)
        static let sage = Color(hex: 0xBCC388), sageDeep = Color(hex: 0x8E9A55)
        static let olive = Color(hex: 0x55621F), oliveDeep = Color(hex: 0x3C4614)
        static let sun = Color(hex: 0xF7C548), sunDeep = Color(hex: 0xD9A52E), glass = Color(hex: 0xFFF3CF)
        static let lilac = Color(hex: 0xB7A4F2), lilacDeep = Color(hex: 0x8E78E0)
        static let grey = Color(hex: 0xB3B6A4), greyDeep = Color(hex: 0x868A74)
        static let cloudShade = Color(hex: 0xD9DCCB)
    }

    private static let heart = "M32 54 C15 43 8 33 8 23 C8 15 14 9.5 21.5 9.5 C26.5 9.5 30 12.5 32 16.5 C34 12.5 37.5 9.5 42.5 9.5 C50 9.5 56 15 56 23 C56 33 49 43 32 54 Z"
    private static let lobeLeft = "M29 20 C22 18 12 26 11 40 C10 50 16 54 22 52 C27 50 29 46 29 40 Z"
    private static let lobeRight = "M35 20 C42 18 52 26 53 40 C54 50 48 54 42 52 C37 50 35 46 35 40 Z"
    private static let shield = "M32 6 L53 13.5 V30 C53 43 44 52 32 58 C20 52 11 43 11 30 V13.5 Z"
    private static let bubble = "M14 12 H50 Q56 12 56 18 V38 Q56 44 50 44 H30 L20 53 V44 H14 Q8 44 8 38 V18 Q8 12 14 12 Z"
    private static let vessel = "M9 44 C9 22 28 18 32 32 C36 46 55 42 55 20"
    private static let toothShape = "M18 14 C24 10 28 13 32 13 C36 13 40 10 46 14 C52 18 50 30 47 38 C45 45 44 54 40 54 C36 54 36 42 32 42 C28 42 28 54 24 54 C20 54 19 45 17 38 C14 30 12 18 18 14 Z"
    private static let lipsShape = "M10 32 C14 24 20 20 26 22 C29 23 31 25 32 26 C33 25 35 23 38 22 C44 20 50 24 54 32 C48 44 40 48 32 48 C24 48 16 44 10 32 Z"
    private static let moonShape = "M36 10 C24 12 16 22 16 34 C16 46 26 56 38 56 C44 56 48 54 51 50 C36 50 26 40 26 28 C26 20 30 14 36 10 Z"
    private static let cloud = "M14 54 H40 C45 54 48 50.5 48 46 C48 41.5 44.5 38 40 38 C39 33 35 30 30 30 C24.5 30 20 34 20 39.5 C16 39.5 12 42.5 12 46.5 C12 50.5 14 54 14 54 Z"

    static func draw(_ id: String, clock k: Clock, in c: inout GraphicsContext) {
        func width(_ w: CGFloat) -> StrokeStyle { StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round) }

        switch id {
        case "heart-rate":
            drawHeart(scaled(c, by: k.beat, around: CGPoint(x: 32, y: 32)))
            let trace = svg("M10 32 H21 L25 25 L30 39 L34 28 L37 32 H54")
            c.stroke(k.still ? trace : trace.trimmedPath(from: 0, to: min(1, k.phase(1.6) / 0.55)), with: .color(.white), style: width(3.2))
        case "carbon-monoxide":
            c.fill(ellipse(30, 43, 19, 13), with: .color(Ink.coralDeep))
            c.fill(ellipse(30, 41, 19, 13), with: .color(Ink.coral))
            c.fill(ellipse(30, 41, 9, 5.5), with: .color(Ink.coralDeep.opacity(0.55)))
            var shine = c
            shine.translateBy(x: 20, y: 36)
            shine.rotate(by: .degrees(-20))
            shine.fill(ellipse(0, 0, 4, 2), with: .color(.white.opacity(0.55)))
            for (x, y, r, delay) in [(16.0, 20.0, 6.0, 0.0), (34, 14, 7.5, 0.9), (50, 22, 5, 1.7)] as [(CGFloat, CGFloat, CGFloat, Double)] {
                var o = c
                if !k.still {
                    let p = k.phase(2.6, delay: delay)
                    o.translateBy(x: 0, y: CGFloat(6 - 15 * p))
                    o.opacity = p < 0.25 ? p / 0.25 : 1 - (p - 0.25) / 0.75
                }
                o.fill(ellipse(x, y, r, r), with: .color(Ink.sky))
                o.fill(ellipse(x - r * 0.33, y - r * 0.33, r * 0.3, r * 0.3), with: .color(.white.opacity(0.85)))
            }
            var co = scaled(c, by: 1 - 0.18 * CGFloat(k.swing(3)), around: CGPoint(x: 55, y: 45))
            co.opacity = 0.95 - 0.7 * k.swing(3)
            co.fill(ellipse(55, 45, 3.6, 3.6), with: .color(Ink.grey))
        case "circulation":
            let v = svg(vessel)
            c.stroke(v.offsetBy(dx: 0, dy: 2.5), with: .color(Ink.coralDeep), style: width(9))
            c.stroke(v, with: .color(Ink.coral), style: width(9))
            var flow = width(2.6)
            flow.dash = [3, 7]
            flow.dashPhase = k.still ? 0 : CGFloat(20 * k.phase(1.1))
            c.stroke(v, with: .color(.white), style: flow)
            sparkle(c, 50, 50, 5, k, delay: 0)
            sparkle(c, 15, 13, 4, k, delay: 0.7)
        case "coughing":
            drawLungs(scaled(c, by: breathe(k), around: CGPoint(x: 32, y: 36)))
            c.stroke(svg("M32 7 V25 M32 24 Q32 28 27 31 M32 24 Q32 28 37 31"), with: .color(Ink.olive), style: width(4))
            for (d, delay) in [("M43 11 Q47.5 8.5 52 11", 0.0), ("M45 16.5 Q50 14 55.5 16.5", 0.7)] {
                var w = c
                if !k.still { w.opacity = 0.25 + 0.75 * k.swing(2.2, delay: delay) }
                w.stroke(svg(d), with: .color(Ink.skyDeep), style: width(2.6))
            }
        case "heart-attack":
            let s = svg(shield)
            c.fill(s.offsetBy(dx: 0, dy: 2.5), with: .color(Ink.oliveDeep))
            c.fill(s, with: .color(Ink.olive))
            c.fill(svg("M32 6 L53 13.5 V30 C53 43 44 52 32 58 Z"), with: .color(.white.opacity(0.08)))
            var inner = c
            inner.translateBy(x: 17.6, y: 16.6)
            inner.scaleBy(x: 0.45, y: 0.45)
            drawHeart(scaled(inner, by: k.beat, around: CGPoint(x: 32, y: 32)))
            sparkle(c, 53, 9, 4.5, k, delay: 0)
        case "mouth-cancer":
            let b = svg(bubble)
            c.fill(b.offsetBy(dx: 0, dy: 2.5), with: .color(Ink.sageDeep))
            c.fill(b, with: .color(Ink.sage))
            for i in 0..<4 {
                let height = 16 * CGFloat(k.still ? 0.7 : 0.35 + 0.65 * k.swing(1.1, delay: Double(i) * 0.2))
                let x = 19.5 + CGFloat(i) * 7
                c.fill(Path(roundedRect: CGRect(x: x, y: 28 - height / 2, width: 4.5, height: height), cornerRadius: 2.25), with: .color(.white))
            }
        case "lung-cancer":
            var lungs = c
            lungs.translateBy(x: 4.8, y: 6)
            lungs.scaleBy(x: 0.85, y: 0.85)
            drawLungs(scaled(lungs, by: breathe(k), around: CGPoint(x: 32, y: 36)))
            c.stroke(svg("M32 13 V27 M32 26 Q32 29 28 31.5 M32 26 Q32 29 36 31.5"), with: .color(Ink.olive), style: width(3.6))
            let leaves = rotated(c, by: sway(k), around: CGPoint(x: 32, y: 14))
            leaves.fill(svg("M32 14 C26 14 20 10.5 19 4.5 C25 4.5 31 7.5 32 14 Z"), with: .color(Ink.sage))
            leaves.fill(svg("M32 14 C38 13 44 8.5 45 3.5 C39 3.5 33 7 32 14 Z"), with: .color(Ink.sageDeep))
        case "heart-disease":
            var h = c
            h.translateBy(x: 6.4, y: 12.5)
            h.scaleBy(x: 0.8, y: 0.8)
            drawHeart(scaled(h, by: k.beat, around: CGPoint(x: 32, y: 32)))
            c.stroke(svg("M32 26 Q32 18 33 11"), with: .color(Ink.sageDeep), style: width(3))
            let leaves = rotated(c, by: sway(k), around: CGPoint(x: 33, y: 13))
            leaves.fill(svg("M33 13 C28 13 24 10 23 5 C28 5 32 8 33 13 Z"), with: .color(Ink.sage))
            leaves.fill(svg("M33 11 C37 10 41 7 42 3 C37 3 34 6 33 11 Z"), with: .color(Ink.sageDeep))
        case "withdrawal-start":
            c.fill(svg("M6 40 Q14 32 22 40 T38 40 T58 40 V54 Q58 57 55 57 H9 Q6 57 6 54 Z"), with: .color(Ink.lilacDeep))
            var boat = c
            boat.translateBy(x: 0, y: -2.5 * CGFloat(k.swing(2.8)))
            boat.stroke(svg("M33 13 V36"), with: .color(Ink.olive), style: width(2.4))
            boat.fill(svg("M34.5 15 L46 34 H34.5 Z"), with: .color(Ink.coral))
            boat.fill(svg("M31.5 19 L23 34 H31.5 Z"), with: .color(.white))
            boat.fill(svg("M20 36 H46 L41.5 43 H24.5 Z"), with: .color(Ink.olive))
            c.fill(svg("M6 46 Q14 40 22 46 T38 46 T58 46 V54 Q58 57 55 57 H9 Q6 57 6 54 Z"), with: .color(Ink.lilac))
            c.stroke(svg("M12 50 Q16 48 20 50"), with: .color(.white.opacity(0.7)), style: width(2))
        case "nicotine-gone":
            var molecule = scaled(c, by: 1 - 0.18 * CGFloat(k.swing(3)), around: CGPoint(x: 34, y: 33))
            molecule.opacity = 0.95 - 0.7 * k.swing(3)
            molecule.stroke(svg("M22 38 L38 25 L46 42"), with: .color(Ink.greyDeep), style: width(3.5))
            molecule.fill(ellipse(22, 38, 8, 8), with: .color(Ink.grey))
            molecule.fill(ellipse(38, 25, 6, 6), with: .color(Ink.grey))
            molecule.fill(ellipse(46, 42, 6.5, 6.5), with: .color(Ink.grey))
            molecule.fill(ellipse(19.5, 35.5, 2.2, 2.2), with: .color(.white.opacity(0.6)))
            sparkle(c, 52, 13, 5.5, k, delay: 0)
            sparkle(c, 13, 18, 4, k, delay: 0.7)
            sparkle(c, 32, 53, 3.5, k, delay: 1.4)
        case "withdrawal-peak":
            c.fill(svg("M30 55 L45.5 27 L60 55 Z"), with: .color(Ink.sage))
            c.fill(svg("M4 55 L26 15 L48 55 Z"), with: .color(Ink.olive))
            c.fill(svg("M26 15 L33 27.7 L29.5 25 L26 29 L22.5 25 L19 27.7 Z"), with: .color(.white))
            var trail = width(1.8)
            trail.dash = [3, 7]
            trail.dashPhase = k.still ? 0 : CGFloat(20 * k.phase(1.1))
            c.stroke(svg("M12 55 Q20 47 17 42 Q24 37 24.5 31"), with: .color(.white.opacity(0.75)), style: trail)
            c.stroke(svg("M26 15 V4"), with: .color(Ink.oliveDeep), style: width(2))
            var flag = c
            flag.translateBy(x: 26, y: 7.5)
            flag.concatenate(CGAffineTransform(a: 1, b: tan(-10 * .pi / 180 * CGFloat(k.swing(1.4))), c: 0, d: 1, tx: 0, ty: 0))
            flag.translateBy(x: -26, y: -7.5)
            flag.fill(svg("M26 4.5 L37 7.5 L26 10.5 Z"), with: .color(Ink.coral))
            c.stroke(svg("M4 55 H60"), with: .color(Ink.oliveDeep), style: width(2.4))
        case "mood":
            let rays = rotated(c, by: .degrees(k.still ? 0 : 360 * k.phase(24)), around: CGPoint(x: 40, y: 24))
            for i in 0..<8 {
                let a = Double(i) * .pi / 4
                rays.stroke(Path { p in
                    p.move(to: CGPoint(x: 40 + 14 * cos(a), y: 24 + 14 * sin(a)))
                    p.addLine(to: CGPoint(x: 40 + 18.5 * cos(a), y: 24 + 18.5 * sin(a)))
                }, with: .color(Ink.sun), style: width(3))
            }
            c.fill(ellipse(40, 24, 10.5, 10.5), with: .color(Ink.sun))
            c.fill(ellipse(36.5, 20.5, 2.6, 2.6), with: .color(.white.opacity(0.6)))
            var drift = c
            drift.translateBy(x: 0, y: -2.5 * CGFloat(k.swing(2.8)))
            drift.fill(svg(cloud).offsetBy(dx: 0, dy: 2.5), with: .color(Ink.cloudShade))
            drift.fill(svg(cloud), with: .color(.white))
        case "cravings-fade":
            var top = c
            top.translateBy(x: 0, y: -2.5 * CGFloat(k.swing(2.8)))
            top.stroke(svg("M8 21 Q14 11 20 21 T32 21 T44 21 T56 21"), with: .color(Ink.lilacDeep.opacity(0.55)), style: width(4))
            c.stroke(svg("M8 35 Q14 29.5 20 35 T32 35 T44 35 T56 35"), with: .color(Ink.lilac), style: width(4))
            c.stroke(svg("M8 48 Q14 46.5 20 48 T32 48 T44 48 T50 48"), with: .color(Ink.skyDeep), style: width(4))
            sparkle(c, 56, 48, 4.5, k, delay: 0)
        // The looks changes (S25): same kit rules, chunky fills, a darker edge, one highlight, one slow loop.
        case "taste":
            // Two cherries swinging gently from their stalk.
            let bunch = rotated(c, by: sway(k), around: CGPoint(x: 36, y: 11))
            bunch.stroke(svg("M22 36 Q25 21 36 11 M43 38 Q40 23 36 11"), with: .color(Ink.olive), style: width(3))
            bunch.fill(svg("M36 11 C41 6 50 6 53 11 C48 15 41 15 36 11 Z"), with: .color(Ink.sageDeep))
            for (x, y) in [(21.0, 42.0), (43, 44)] as [(CGFloat, CGFloat)] {
                bunch.fill(ellipse(x, y + 2.5, 10.5, 10.5), with: .color(Ink.coralDeep))
                bunch.fill(ellipse(x, y, 10.5, 10.5), with: .color(Ink.coral))
                var shine = bunch
                shine.translateBy(x: x - 4.5, y: y - 4)
                shine.rotate(by: .degrees(-30))
                shine.fill(ellipse(0, 0, 3.6, 2), with: .color(.white.opacity(0.55)))
            }
        case "fresh-breath":
            // A clean tooth that bobs a little, with twinkles.
            var tooth = c
            tooth.translateBy(x: 0, y: -2 * CGFloat(k.swing(2.8)))
            let t = svg(toothShape)
            tooth.fill(t.offsetBy(dx: 0, dy: 2.5), with: .color(Ink.cloudShade))
            tooth.fill(t, with: .color(.white))
            var shine = tooth
            shine.translateBy(x: 22, y: 22)
            shine.rotate(by: .degrees(-15))
            shine.fill(ellipse(0, 0, 2.4, 5), with: .color(Ink.sky.opacity(0.6)))
            sparkle(c, 53, 11, 5, k, delay: 0)
            sparkle(c, 10, 29, 3.2, k, delay: 0.9)
        case "lips":
            // Lips that soften and fill out, slowly.
            let l = scaled(c, by: 0.96 + 0.06 * CGFloat(k.swing(2.6, rest: 0.6)), around: CGPoint(x: 32, y: 35))
            let shape = svg(lipsShape)
            l.fill(shape.offsetBy(dx: 0, dy: 2.5), with: .color(Ink.coralDeep))
            l.fill(shape, with: .color(Ink.coral))
            l.stroke(svg("M11 32 Q32 37 53 32"), with: .color(Ink.coralDeep), style: width(2.6))
            var shine = l
            shine.translateBy(x: 24, y: 40.5)
            shine.rotate(by: .degrees(-10))
            shine.fill(ellipse(0, 0, 5, 2.2), with: .color(.white.opacity(0.55)))
            sparkle(c, 53, 12, 5, k, delay: 0.4)
        case "skin-glow":
            // A hand mirror with a glint sweeping across the glass.
            c.fill(Path(roundedRect: CGRect(x: 28.5, y: 40, width: 7, height: 19), cornerRadius: 3.5), with: .color(Ink.oliveDeep))
            c.fill(Path(roundedRect: CGRect(x: 28.5, y: 38, width: 7, height: 19), cornerRadius: 3.5), with: .color(Ink.olive))
            c.fill(ellipse(32, 27.5, 17, 17), with: .color(Ink.sunDeep))
            c.fill(ellipse(32, 25, 17, 17), with: .color(Ink.sun))
            c.fill(ellipse(32, 25, 11.5, 11.5), with: .color(Ink.glass))
            var glass = c
            glass.clip(to: ellipse(32, 25, 11.5, 11.5))
            let sweep = CGFloat(k.still ? 0.3 : k.phase(3.2))
            var glint = glass
            glint.translateBy(x: -14 + 28 * sweep, y: 0)
            glint.rotate(by: .degrees(25))
            glint.fill(Path(CGRect(x: 28, y: -10, width: 4, height: 60)), with: .color(.white.opacity(0.8)))
            sparkle(c, 54, 11, 5, k, delay: 0)
            sparkle(c, 9, 17, 3.2, k, delay: 1.1)
        case "hair":
            // Three strands swaying from the root, each a beat behind the last.
            for (i, x) in ([20, 32, 44] as [CGFloat]).enumerated() {
                let strand = rotated(c, by: .degrees(k.still ? 0 : -5 + 10 * k.swing(3.2, delay: Double(i) * 0.35)),
                                     around: CGPoint(x: x, y: 56))
                let d = "M\(x) 56 C\(x - 4) 40 \(x + 6) 28 \(x) \(i == 1 ? 8 : 11)"
                strand.stroke(svg(d).offsetBy(dx: 0, dy: 2), with: .color(Ink.lilacDeep), style: width(7))
                strand.stroke(svg(d), with: .color(Ink.lilac), style: width(7))
                if i == 1 { strand.stroke(svg("M33.5 13 C35 19 34.5 23 33.5 26"), with: .color(.white.opacity(0.7)), style: width(2)) }
            }
            sparkle(c, 54, 9, 4.5, k, delay: 0.6)
        case "even-tone":
            // Two tones in one circle, the sun side slowly giving way.
            c.fill(ellipse(32, 36.5, 19, 19), with: .color(Ink.sageDeep))
            c.fill(ellipse(32, 34, 19, 19), with: .color(Ink.sage))
            var half = c
            half.opacity = k.still ? 1 : 1 - 0.45 * k.swing(4)
            half.fill(svg("M32 15 C26 23 38 29 32 35 C26 41 38 46 32 53 A19 19 0 0 1 32 15 Z"), with: .color(Ink.sun))
            var shine = c
            shine.translateBy(x: 22, y: 26)
            shine.rotate(by: .degrees(-35))
            shine.fill(ellipse(0, 0, 4, 2.4), with: .color(.white.opacity(0.55)))
            sparkle(c, 53, 11, 5, k, delay: 0)
        case "sleep":
            // A moon bobbing gently while the Zs drift up.
            var moon = c
            moon.translateBy(x: 0, y: -2.5 * CGFloat(k.swing(2.8)))
            let m = svg(moonShape)
            moon.fill(m.offsetBy(dx: 0, dy: 2.5), with: .color(Ink.lilacDeep))
            moon.fill(m, with: .color(Ink.lilac))
            var shine = moon
            shine.translateBy(x: 22, y: 30)
            shine.rotate(by: .degrees(12))
            shine.fill(ellipse(0, 0, 2.4, 6), with: .color(.white.opacity(0.5)))
            for (d, delay, w) in [("M40 14 H48 L40 22 H48", 0.0, 2.6), ("M50 28 H55 L50 33 H55", 0.8, 2.2)] as [(String, Double, CGFloat)] {
                var z = c
                if !k.still {
                    let p = k.phase(2.8, delay: delay)
                    z.translateBy(x: 0, y: CGFloat(3 - 6 * p))
                    z.opacity = p < 0.3 ? p / 0.3 : 1 - (p - 0.3) / 0.7
                }
                z.stroke(svg(d), with: .color(.white), style: width(w))
            }
        default:
            sparkle(c, 32, 32, 20, k, delay: 0)
        }
    }

    // MARK: Parts

    private static func drawHeart(_ c: GraphicsContext) {
        let h = svg(heart)
        c.fill(h.offsetBy(dx: 0, dy: 3), with: .color(Ink.coralDeep))
        c.fill(h, with: .color(Ink.coral))
        var shine = c
        shine.translateBy(x: 20, y: 19)
        shine.rotate(by: .degrees(-35))
        shine.fill(ellipse(0, 0, 5, 3), with: .color(.white.opacity(0.55)))
    }

    private static func drawLungs(_ c: GraphicsContext) {
        let left = svg(lobeLeft), right = svg(lobeRight)
        c.fill(left.offsetBy(dx: 0, dy: 2), with: .color(Ink.skyDeep))
        c.fill(right.offsetBy(dx: 0, dy: 2), with: .color(Ink.skyDeep))
        c.fill(left, with: .color(Ink.sky))
        c.fill(right, with: .color(Ink.sky))
        var shine = c
        shine.translateBy(x: 18, y: 34)
        shine.rotate(by: .degrees(18))
        shine.fill(ellipse(0, 0, 2.4, 6), with: .color(.white.opacity(0.5)))
    }

    /// A four-point star that twinkles every 2.2 s.
    private static func sparkle(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ k: Clock, delay: Double) {
        let p = k.swing(2.2, delay: delay, rest: 1)
        var g = scaled(c, by: 0.55 + 0.45 * CGFloat(p), around: CGPoint(x: x, y: y))
        g.opacity = 0.25 + 0.75 * p
        g.fill(Path { path in
            let center = CGPoint(x: x, y: y)
            path.move(to: CGPoint(x: x, y: y - s))
            path.addQuadCurve(to: CGPoint(x: x + s, y: y), control: center)
            path.addQuadCurve(to: CGPoint(x: x, y: y + s), control: center)
            path.addQuadCurve(to: CGPoint(x: x - s, y: y), control: center)
            path.addQuadCurve(to: CGPoint(x: x, y: y - s), control: center)
            path.closeSubpath()
        }, with: .color(Ink.sun))
    }

    private static func breathe(_ k: Clock) -> CGFloat { 0.93 + 0.11 * CGFloat(k.swing(3.8, rest: 0.6)) }
    private static func sway(_ k: Clock) -> Angle { .degrees(k.still ? 0 : -7 + 14 * k.swing(3.2)) }

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
                Text("Your body · S21").v4Text(.micro)
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
