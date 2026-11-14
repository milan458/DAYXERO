import SwiftUI

/// Xero, the land character: your days. Drawn from `design/handoff/canvas/project/Xero.dc.html`.
/// The four stages (`CrewGrowth.stage`) read at a glance (S27.16): stage 1 is small and pale; stage 2 grows a leaf;
/// stage 3 two leaves and deeper colour; stage 4 is full size and deepest, with a bud, rays and a warm glow. The sun
/// inside the hole rises with the stage, and the body scales from the feet.
public struct XeroView: View {
    let mood: CrewMood
    let stage: Int
    let size: CGFloat
    let animate: Bool
    let pose: Pose
    let since: Double

    /// Kit poses on top of a mood (001, 002): breath puffs that leave his mouth on the out-breath (in place of the
    /// marks beside his arm), or a raised right arm that waves twice from 1.2 s. Both run on a clock that starts at
    /// `since`, so they line up with the rest of the screen.
    public enum Pose: Sendable { case standard, breathPuffs, wave, holdFlag, headphones }

    public init(mood: CrewMood = .hello, stage: Int = 1, size: DX.CharacterSize = .scene, animate: Bool = true) {
        self.init(mood: mood, stage: stage, points: size.rawValue, animate: animate)
    }

    public init(mood: CrewMood, stage: Int, points: CGFloat, animate: Bool = true, pose: Pose = .standard, since: Date? = nil) {
        self.mood = mood
        self.stage = min(4, max(0, stage))
        self.size = points
        self.animate = animate
        self.pose = pose
        self.since = since?.timeIntervalSinceReferenceDate ?? 0
    }

    public var body: some View {
        let mood = mood, stage = stage, pose = pose, since = since
        CrewCanvas(label: "Xero", size: size, animate: animate) { ctx, time, on, dark in
            XeroView.draw(&ctx, mood: mood, stage: stage, time: time - since, animate: on, dark: dark, pose: pose)
        }
    }

    nonisolated static func draw(_ ctx: inout GraphicsContext, mood: CrewMood, stage: Int, time t: Double, animate on: Bool, dark: Bool = false,
                                 pose: Pose = .standard) {
        let cheer = mood == .cheer
        let cheerTimes = [0, 0.15, 0.35, 0.55, 1.0]

        let body: ArtTrack = switch mood {
        case .hello: ArtTrack([[1, 1], [1.025, 0.985], [1, 1]], times: Crew.spline, duration: 5, spline: true)
        case .calm: ArtTrack([[1, 1], [1.02, 0.99], [1, 1]], times: Crew.spline, duration: 6, spline: true)
        case .breathe: ArtTrack([[1, 1], [1.07, 1.07], [1, 1]], times: [0, 0.4, 1], duration: 10, spline: true)
        case .cheer: ArtTrack([[1, 1], [1.08, 0.9], [0.96, 1.06], [1, 1], [1, 1]], times: cheerTimes, duration: 1.4, spline: true)
        case .sleepy: ArtTrack([[1, 1], [1.015, 0.99], [1, 1]], times: Crew.spline, duration: 7, spline: true)
        }
        let hop = cheer
            ? ArtTrack(scalars: [0, 0, -18, 0, 0], times: cheerTimes, duration: 1.4, spline: true).scalar(at: t, animate: on)
            : 0
        let sway = mood == .sleepy
            ? ArtTrack(scalars: [-3, 3, -3], times: Crew.spline, duration: 7, spline: true).scalar(at: t, animate: on)
            : 0
        let sunRest: Double = [168, 156, 142, 128][max(stage, 1) - 1]
        let sunY = mood == .breathe
            ? ArtTrack(scalars: [sunRest, sunRest - 16, sunRest], times: [0, 0.4, 1], duration: 10, spline: true).scalar(at: t, animate: on)
            : ArtTrack(scalars: [sunRest, sunRest - 3, sunRest], times: Crew.spline, duration: 4, spline: true).scalar(at: t, animate: on)

        let look = XeroView.look(stage: stage)

        // Ground shadow stays put, sized to the stage.
        Crew.fill(&ctx, Crew.ellipse(100, 192, 48 * look.grow, 6), .black, opacity: 0.12)

        var g = ctx
        g.translateBy(x: 0, y: hop)
        Crew.pose(&g, pivot: CGPoint(x: 100, y: 190), scale: body.value(at: t, animate: on), rotate: sway)
        // The whole body scales from the feet with the stage.
        Crew.pose(&g, pivot: CGPoint(x: 100, y: 190), scale: [Double(look.grow), Double(look.grow)], rotate: 0)

        // The hole: sky, a rising sun and a hill, clipped to the hole.
        let hole = Crew.ellipse(100, 138, 21, 29)
        Crew.fill(&g, hole, Color(hex: 0xBFD7FF))
        var inside = g
        inside.clip(to: hole)
        Crew.fill(&inside, Crew.circle(100, sunY, 11), Color(hex: 0xFFC93C))
        Crew.fill(&inside, "M76 160 C90 152 110 156 124 150 L124 172 L76 172 Z", Color(hex: 0x3FB37F))

        // Stage 4: a soft radial glow, bright in the centre and clear at the edge, so it reads on dawn and dark skies.
        if stage >= 4 {
            g.fill(Crew.circle(100, 112, 96), with: .radialGradient(
                Gradient(stops: [.init(color: Color(hex: 0xFFF1C2).opacity(0.75), location: 0),
                                 .init(color: Color(hex: 0xFFD966).opacity(0.35), location: 0.6),
                                 .init(color: Color(hex: 0xFFD966).opacity(0), location: 1)]),
                center: CGPoint(x: 100, y: 112), startRadius: 0, endRadius: 96))
        }

        // Feet and arms.
        Crew.fill(&g, Crew.ellipse(84, 188, 12, 7), look.feet)
        Crew.fill(&g, Crew.ellipse(116, 188, 12, 7), look.feet)
        let coral = look.body
        Crew.stroke(&g, cheer ? "M38 112 C28 98 24 86 26 74" : "M36 124 C26 132 22 142 24 152", coral, 12)
        if pose == .wave {
            // Two 16° swings from 1.2 s (2 × 800 ms), then it rests raised.
            let local = on ? t - 1.2 : 2
            let swing = local <= 0 || local >= 1.6 ? 0 : -16 * sin(local / 0.8 * .pi).magnitude
            var arm = g
            arm.translateBy(x: 162, y: 112)
            arm.rotate(by: .degrees(swing))
            arm.translateBy(x: -162, y: -112)
            Crew.stroke(&arm, "M162 112 C172 98 178 86 176 74", coral, 12)
            let ink = dark ? Color(hex: 0xF3E9DE) : Color(hex: 0x24163A)
            Crew.stroke(&ctx, "M186 62 q7 6 6 14", ink.opacity(0.55), 3)
            Crew.stroke(&ctx, "M193 52 q9 9 6 22", ink.opacity(0.55), 3)
        } else if pose == .holdFlag {
            // 010: the right arm reaches out to hold the flag's pole (drawn by the screen, behind him).
            Crew.stroke(&g, "M164 122 C176 118 183 110 186 100", coral, 12)
        } else {
            Crew.stroke(&g, cheer ? "M162 112 C172 98 176 86 174 74" : "M164 124 C174 132 178 142 176 152", coral, 12)
        }

        // Body with the hole cut out, shade and highlight.
        Crew.fill(&g, "M100 34 C138 34 166 68 166 112 C166 156 138 188 100 188 C62 188 34 156 34 112 C34 68 62 34 100 34 Z M100 109 C112 109 121 121 121 138 C121 155 112 167 100 167 C88 167 79 155 79 138 C79 121 88 109 100 109 Z",
                  coral, evenOdd: true)
        Crew.fill(&g, "M136 52 C156 70 166 92 166 112 C166 156 138 188 100 188 C126 178 146 150 146 112 C146 88 142 68 136 52 Z", look.shade)
        Crew.stroke(&g, "M58 82 C62 66 74 52 90 46", look.highlight, 6)
        // The sprout on top: one leaf at stage 2, two at 3, two and a sun-yellow bud at 4.
        let leaf = Color(hex: 0x3FB37F), stem = Color(hex: 0x2F8A5A)
        if stage >= 2 {
            let top = stage >= 3 ? 12 : 20
            Crew.stroke(&g, "M100 36 C100 30 101 \(top + 8) 102 \(top)", stem, 4)
            Crew.fill(&g, "M102 \(top + 4) C108 \(top - 8) 124 \(top - 10) 130 \(top - 4) C122 \(top + 6) 110 \(top + 8) 102 \(top + 4) Z", leaf)
        }
        if stage >= 3 {
            Crew.fill(&g, "M101 24 C94 14 80 12 74 17 C80 26 92 28 101 24 Z", leaf)
        }
        if stage >= 4 {
            Crew.fill(&g, Crew.circle(102, 9, 7), Color(hex: 0xFFC93C))
            Crew.fill(&g, Crew.circle(102, 9, 3), Color(hex: 0xFFF1C2))
            let rays = Color(hex: 0xFFC93C)
            Crew.stroke(&g, "M150 44 l8 -8", rays, 3)
            Crew.stroke(&g, "M50 44 l-8 -8", rays, 3)
        }
        Crew.fill(&g, Crew.circle(72, 92, 7), look.highlight, opacity: look.cheek)
        Crew.fill(&g, Crew.circle(128, 92, 7), look.highlight, opacity: look.cheek)
        Crew.Face.make(mood, y: 78).draw(in: &g, y: 78, time: t, animate: on, blinkPeriod: 4.5, mood: mood, color: Crew.ink)
        if pose == .headphones {
            // 023/024: Xero listening. The band and cups sit in his body group, so they sway with him.
            let ink = Color(hex: 0x1E1A3A)
            Crew.stroke(&g, "M38 108 C30 -4 170 -4 162 108", ink, 10)
            Crew.stroke(&g, "M52 62 C66 30 100 22 122 26", Color(hex: 0xFFF8EE).opacity(0.35), 3)
            g.fill(Path(roundedRect: CGRect(x: 18, y: 88, width: 30, height: 48), cornerRadius: 14), with: .color(ink))
            g.fill(Path(roundedRect: CGRect(x: 24, y: 96, width: 9, height: 32), cornerRadius: 4.5), with: .color(Color(hex: 0xFF9A6B)))
            g.fill(Path(roundedRect: CGRect(x: 152, y: 88, width: 30, height: 48), cornerRadius: 14), with: .color(ink))
            g.fill(Path(roundedRect: CGRect(x: 167, y: 96, width: 9, height: 32), cornerRadius: 4.5), with: .color(Color(hex: 0xFF9A6B)))
        }

        // Marks outside the body.
        if cheer {
            Crew.sparkle(&ctx, x: 26, y: 64, length: 12)
            Crew.sparkle(&ctx, x: 174, y: 70, length: 10)
        }
        if mood == .sleepy {
            Crew.zzz(&ctx, at: CGPoint(x: 150, y: 40), time: t, animate: on, color: Crew.markColor(dark: dark))
        }
        if mood == .breathe && pose == .breathPuffs {
            // Two soft cream puffs about 9 pt clear of his mouth, drifting out and fading over the 6 s out-breath.
            let cycle = t.truncatingRemainder(dividingBy: 10)
            let p = on ? max(0, (cycle - 4) / 6) : 0.6
            let eased = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.3, y: 0.6), endControlPoint: UnitPoint(x: 0.3, y: 1)).value(at: p)
            let opacity = !on ? 1 : cycle < 4 ? 0 : p < 0.2 ? p / 0.2 : p < 0.8 ? 1 - (p - 0.2) / 0.6 * 0.1 : 0.9 * (1 - (p - 0.8) / 0.2)
            var w = g
            w.translateBy(x: 3 - 6 + 16 * eased, y: 7 - 2 + 5 * eased)
            w.opacity = opacity
            let cream = Color(hex: 0xFFF8EE)
            var a = w
            a.opacity = opacity * 0.72
            for c in [(119.0, 100.5, 2.9), (123, 98.4, 3.6), (127, 100.5, 2.7)] { Crew.fill(&a, Crew.circle(c.0, c.1, c.2), cream) }
            a.fill(Path(roundedRect: CGRect(x: 119, y: 99.4, width: 8, height: 4), cornerRadius: 2), with: .color(cream))
            var b = w
            b.opacity = opacity * 0.52
            for c in [(133.0, 106.0, 1.9), (135.6, 104.6, 2.3), (138.2, 106, 1.7)] { Crew.fill(&b, Crew.circle(c.0, c.1, c.2), cream) }
            b.fill(Path(roundedRect: CGRect(x: 133, y: 105.3, width: 5.2, height: 2.6), cornerRadius: 1.3), with: .color(cream))
            var d = w
            d.opacity = opacity * 0.38
            Crew.fill(&d, Crew.circle(142.5, 110, 1.2), cream)
        } else if mood == .breathe {
            let drift = ArtTrack([[0, 0], [8, 0], [0, 0]], duration: 5).value(at: t, animate: on)
            var b = ctx
            b.translateBy(x: drift[0], y: drift[1])
            Crew.stroke(&b, "M172 100 q8 -5 16 0", Crew.markColor(dark: dark), 3)
            Crew.stroke(&b, "M176 112 q6 -4 12 0", Crew.markColor(dark: dark), 3)
        }
    }

    /// How Xero looks at each growth stage (S27.16): size and colour depth, matching the Screen Lab.
    public struct Look: Equatable, Sendable {
        public let grow: CGFloat
        public let body: Color
        public let shade: Color
        public let highlight: Color
        public let feet: Color
        public let cheek: Double
    }

    /// The kit's Xero (chars.js), as every v5 mockup draws him outside the growth story: full size, #FF7155, no sprout.
    /// Pass stage 0 for it.
    public nonisolated static let kit = Look(grow: 1, body: Color(hex: 0xFF7155), shade: Color(hex: 0xE85A3E), highlight: Color(hex: 0xFFB09C),
                                             feet: Color(hex: 0xC9542F), cheek: 0.8)

    public nonisolated static func look(stage: Int) -> Look {
        switch min(4, max(0, stage)) {
        case 0: kit
        case 1: Look(grow: 0.8, body: Color(hex: 0xFF9478), shade: Color(hex: 0xF27858), highlight: Color(hex: 0xFFC8B8),
                     feet: Color(hex: 0xD86A48), cheek: 0.55)
        case 2: Look(grow: 0.88, body: Color(hex: 0xFF8064), shade: Color(hex: 0xEC6648), highlight: Color(hex: 0xFFBBA8),
                     feet: Color(hex: 0xCF5E3B), cheek: 0.65)
        case 3: Look(grow: 0.95, body: Color(hex: 0xFF7155), shade: Color(hex: 0xE85A3E), highlight: Color(hex: 0xFFB09C),
                     feet: Color(hex: 0xC9542F), cheek: 0.8)
        default: Look(grow: 1, body: Color(hex: 0xF2583A), shade: Color(hex: 0xD24328), highlight: Color(hex: 0xFFA286),
                      feet: Color(hex: 0xB4441F), cheek: 0.95)
        }
    }
}
