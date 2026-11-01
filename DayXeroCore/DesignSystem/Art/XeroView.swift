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

    public init(mood: CrewMood = .hello, stage: Int = 1, size: DX.CharacterSize = .scene, animate: Bool = true) {
        self.init(mood: mood, stage: stage, points: size.rawValue, animate: animate)
    }

    public init(mood: CrewMood, stage: Int, points: CGFloat, animate: Bool = true) {
        self.mood = mood
        self.stage = min(4, max(1, stage))
        self.size = points
        self.animate = animate
    }

    public var body: some View {
        let mood = mood, stage = stage
        CrewCanvas(label: "Xero", size: size, animate: animate) { ctx, time, on in
            XeroView.draw(&ctx, mood: mood, stage: stage, time: time, animate: on)
        }
    }

    nonisolated static func draw(_ ctx: inout GraphicsContext, mood: CrewMood, stage: Int, time t: Double, animate on: Bool) {
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
        let sunRest: Double = [168, 156, 142, 128][stage - 1]
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
        Crew.stroke(&g, cheer ? "M162 112 C172 98 176 86 174 74" : "M164 124 C174 132 178 142 176 152", coral, 12)

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

        // Marks outside the body.
        if cheer {
            Crew.stroke(&ctx, "M26 64 l0 12 M20 70 l12 0", Crew.ink, 3)
            Crew.stroke(&ctx, "M174 70 l0 10 M169 75 l10 0", Crew.ink, 3)
        }
        if mood == .sleepy {
            Crew.zzz(&ctx, at: CGPoint(x: 150, y: 40), time: t, animate: on, color: Crew.ink)
        }
        if mood == .breathe {
            let drift = ArtTrack([[0, 0], [8, 0], [0, 0]], duration: 5).value(at: t, animate: on)
            var b = ctx
            b.translateBy(x: drift[0], y: drift[1])
            Crew.stroke(&b, "M172 100 q8 -5 16 0", Crew.ink, 3)
            Crew.stroke(&b, "M176 112 q6 -4 12 0", Crew.ink, 3)
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

    public nonisolated static func look(stage: Int) -> Look {
        switch min(4, max(1, stage)) {
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
