import SwiftUI

/// Glim, the night character: your evenings. Drawn from `Glim2.dc.html`.
/// The tail glow grows with `stage`; stars appear at stage 4.
public struct GlimView: View {
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
        CrewCanvas(label: "Glim", size: size, animate: animate) { ctx, time, on in
            GlimView.draw(&ctx, mood: mood, stage: stage, time: time, animate: on)
        }
    }

    nonisolated static func draw(_ ctx: inout GraphicsContext, mood: CrewMood, stage: Int, time t: Double, animate on: Bool) {
        let cheer = mood == .cheer
        let cheerTimes = [0, 0.15, 0.35, 0.55, 1.0]
        let yellow = Color(hex: 0xFFE27A)

        let body: ArtTrack = switch mood {
        case .hello: ArtTrack([[1, 1], [1.025, 0.985], [1, 1]], times: Crew.spline, duration: 4, spline: true)
        case .calm: ArtTrack([[1, 1], [1.02, 0.99], [1, 1]], times: Crew.spline, duration: 6, spline: true)
        case .breathe: ArtTrack([[1, 1], [1.07, 1.07], [1, 1]], times: [0, 0.4, 1], duration: 10, spline: true)
        case .cheer: ArtTrack([[1, 1], [1.08, 0.9], [0.96, 1.06], [1, 1], [1, 1]], times: cheerTimes, duration: 1.3, spline: true)
        case .sleepy: ArtTrack([[1, 1], [1.015, 0.99], [1, 1]], times: Crew.spline, duration: 7, spline: true)
        }
        let hop = cheer
            ? ArtTrack(scalars: [0, 0, -18, 0, 0], times: cheerTimes, duration: 1.3, spline: true).scalar(at: t, animate: on)
            : ArtTrack(scalars: [0, -7, 0], times: Crew.spline, duration: mood == .sleepy ? 7 : 3, spline: true).scalar(at: t, animate: on)
        let sway = mood == .sleepy
            ? ArtTrack(scalars: [-4, 4, -4], times: Crew.spline, duration: 7, spline: true).scalar(at: t, animate: on)
            : 0
        // Wings flap fast when awake, slowly when calm or breathing, not at all when sleepy.
        let flap: Double? = mood == .sleepy ? nil : (mood == .breathe || mood == .calm ? 1.2 : 0.3)
        let wing = flap.map { ArtTrack(scalars: [0, -14, 0], duration: $0).scalar(at: t, animate: on) } ?? 0
        let base: Double = [30, 38, 48, 58][stage - 1]
        let glowPeriod = mood == .breathe ? 10.0 : 2.6
        let glowR = on ? ArtTrack(scalars: [base, base + 10, base], duration: glowPeriod).scalar(at: t) : base
        let glowO = on ? ArtTrack(scalars: [0.22, 0.45, 0.22], duration: glowPeriod).scalar(at: t) : 0.3

        Crew.fill(&ctx, Crew.ellipse(100, 194, 34, 4), .black, opacity: 0.1)
        if stage >= 4 {
            let stars: [(String, Double, Double)] = [
                ("M30 60 l3 7 l7 3 l-7 3 l-3 7 l-3 -7 l-7 -3 l7 -3 Z", 1.8, 0),
                ("M168 120 l2.5 5 l5 2.5 l-5 2.5 l-2.5 5 l-2.5 -5 l-5 -2.5 l5 -2.5 Z", 2.3, 0.6),
                ("M40 160 l2 4 l4 2 l-4 2 l-2 4 l-2 -4 l-4 -2 l4 -2 Z", 2.0, 1.1),
            ]
            for (d, period, begin) in stars {
                let o = on ? ArtTrack(scalars: [0.2, 1, 0.2], duration: period, begin: begin).scalar(at: t) : 1
                Crew.fill(&ctx, d, yellow, opacity: o)
            }
        }

        var g = ctx
        g.translateBy(x: 0, y: hop)
        // Tail glow (decision 24): a soft radial light that pulses with the glow track and is added
        // to what's behind it, so it reads as light on violet and plum rather than a flat brown ring.
        var glow = g
        glow.blendMode = .plusLighter
        // Capped at the drawing's bottom edge (150 + 50 = 200) so the light never ends in a hard line;
        // later stages glow brighter instead of wider.
        let reach = min(glowR * 1.6, 50)
        let strength = glowO * (1 + 0.15 * Double(stage - 1))
        let light = Gradient(stops: [
            .init(color: yellow.opacity(min(1, strength * 2)), location: 0),
            .init(color: yellow.opacity(min(1, strength * 1.4)), location: 0.4),
            .init(color: yellow.opacity(0), location: 1),
        ])
        glow.fill(Crew.circle(100, 150, reach),
                  with: .radialGradient(light, center: CGPoint(x: 100, y: 150), startRadius: 0, endRadius: reach))

        var b = g
        Crew.pose(&b, pivot: CGPoint(x: 100, y: 120), scale: body.value(at: t, animate: on), rotate: sway)

        // Wings rotate about their roots.
        for side in [-1.0, 1.0] {
            var w = b
            let rootX = 100 + 16 * side
            w.translateBy(x: rootX, y: 82)
            w.rotate(by: .degrees(-wing * side))
            w.translateBy(x: -rootX, y: -82)
            let cx = 100 + 42 * side
            var e = w
            e.translateBy(x: cx, y: 66)
            e.rotate(by: .degrees(28 * side))
            e.translateBy(x: -cx, y: -66)
            let blade = Crew.ellipse(cx, 66, 30, 17)
            Crew.fill(&e, blade, Color(hex: 0xE9F1FF), opacity: 0.92)
            Crew.stroke(&e, blade, Color(hex: 0xB9C6F2), 2)
            Crew.stroke(&w, side < 0 ? "M40 74 C52 66 66 62 80 64" : "M160 74 C148 66 134 62 120 64", Color(hex: 0xB9C6F2), 1.5)
        }
        let shade = Color(hex: 0x5638C4)
        Crew.stroke(&b, "M90 62 C84 50 78 40 74 32", shade, 3.5)
        Crew.stroke(&b, "M110 62 C116 50 122 40 126 32", shade, 3.5)
        Crew.fill(&b, Crew.circle(73, 29, 6), yellow)
        Crew.fill(&b, Crew.circle(127, 29, 6), yellow)
        Crew.fill(&b, Crew.ellipse(100, 150, 33, 31), yellow)
        Crew.stroke(&b, "M70 146 C84 154 116 154 130 146 M72 160 C86 168 114 168 128 160", Color(hex: 0xF2C94C), 3.5)
        Crew.stroke(&b, "M80 132 C86 126 94 124 100 124", Color(hex: 0xFFF6C8), 4)
        let head = Color(hex: 0x6B4FD8)
        Crew.stroke(&b, cheer ? "M66 108 C54 98 50 86 52 74" : "M64 114 C54 120 50 128 52 136", head, 9)
        Crew.stroke(&b, cheer ? "M134 108 C146 98 150 86 148 74" : "M136 114 C146 120 150 128 148 136", head, 9)
        Crew.fill(&b, Crew.circle(100, 96, 40), head)
        Crew.fill(&b, "M124 64 C136 74 142 88 140 102 C138 118 126 132 108 136 C124 124 132 108 130 94 C129 82 126 72 124 64 Z", shade)
        Crew.stroke(&b, "M70 84 C72 72 80 64 90 60", Color(hex: 0x9A84F0), 5)
        Crew.fill(&b, Crew.circle(74, 106, 6), Color(hex: 0xFF8FA3), opacity: 0.8)
        Crew.fill(&b, Crew.circle(126, 106, 6), Color(hex: 0xFF8FA3), opacity: 0.8)
        Crew.Face.make(mood, y: 94).draw(in: &b, y: 94, time: t, animate: on, blinkPeriod: 4.4, mood: mood, color: Color(hex: 0xFFF8EE))

        if mood == .sleepy {
            Crew.zzz(&ctx, at: CGPoint(x: 150, y: 34), time: t, animate: on, color: Color(hex: 0x9A84F0))
        }
    }
}
