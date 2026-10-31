import SwiftUI

/// Xero, the land character: your days. Drawn from `design/handoff/canvas/project/Xero.dc.html`.
/// The sun inside Xero's hole rises with `stage`; rays appear at stage 4.
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

        // Ground shadow stays put.
        Crew.fill(&ctx, Crew.ellipse(100, 192, 48, 6), .black, opacity: 0.12)

        var g = ctx
        g.translateBy(x: 0, y: hop)
        Crew.pose(&g, pivot: CGPoint(x: 100, y: 190), scale: body.value(at: t, animate: on), rotate: sway)

        // The hole: sky, a rising sun and a hill, clipped to the hole.
        let hole = Crew.ellipse(100, 138, 21, 29)
        Crew.fill(&g, hole, Color(hex: 0xBFD7FF))
        var inside = g
        inside.clip(to: hole)
        Crew.fill(&inside, Crew.circle(100, sunY, 11), Color(hex: 0xFFC93C))
        Crew.fill(&inside, "M76 160 C90 152 110 156 124 150 L124 172 L76 172 Z", Color(hex: 0x3FB37F))

        // Feet and arms.
        Crew.fill(&g, Crew.ellipse(84, 188, 12, 7), Color(hex: 0xC9542F))
        Crew.fill(&g, Crew.ellipse(116, 188, 12, 7), Color(hex: 0xC9542F))
        let coral = Color(hex: 0xFF7155)
        Crew.stroke(&g, cheer ? "M38 112 C28 98 24 86 26 74" : "M36 124 C26 132 22 142 24 152", coral, 12)
        Crew.stroke(&g, cheer ? "M162 112 C172 98 176 86 174 74" : "M164 124 C174 132 178 142 176 152", coral, 12)

        // Body with the hole cut out, shade and highlight.
        Crew.fill(&g, "M100 34 C138 34 166 68 166 112 C166 156 138 188 100 188 C62 188 34 156 34 112 C34 68 62 34 100 34 Z M100 109 C112 109 121 121 121 138 C121 155 112 167 100 167 C88 167 79 155 79 138 C79 121 88 109 100 109 Z",
                  coral, evenOdd: true)
        Crew.fill(&g, "M136 52 C156 70 166 92 166 112 C166 156 138 188 100 188 C126 178 146 150 146 112 C146 88 142 68 136 52 Z", Color(hex: 0xE85A3E))
        Crew.stroke(&g, "M58 82 C62 66 74 52 90 46", Color(hex: 0xFFB09C), 6)
        if stage >= 4 {
            let rays = Color(hex: 0xFFC93C)
            Crew.stroke(&g, "M100 24 l0 -10", rays, 3)
            Crew.stroke(&g, "M146 40 l7 -7", rays, 3)
            Crew.stroke(&g, "M54 40 l-7 -7", rays, 3)
        }
        Crew.fill(&g, Crew.circle(72, 92, 7), Color(hex: 0xFFB09C), opacity: 0.8)
        Crew.fill(&g, Crew.circle(128, 92, 7), Color(hex: 0xFFB09C), opacity: 0.8)
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
}
