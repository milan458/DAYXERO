import SwiftUI

/// Jelli, the sea character: your waves (SOS, cravings). Drawn from `Jelli.dc.html`.
/// Glints appear with `stage`; a small crown at stage 4.
public struct JelliView: View {
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
        CrewCanvas(label: "Jelli", size: size, animate: animate) { ctx, time, on in
            JelliView.draw(&ctx, mood: mood, stage: stage, time: time, animate: on)
        }
    }

    /// A tentacle; `k` runs 1 → −1 → 1 to make it wave (the canvas morphs between two paths).
    nonisolated static func tentacle(x: Double, k: Double) -> String {
        "M\(x) 122 C\(x - 6 * k) 138 \(x + 6 * k) 152 \(x) 166 C\(x - 4 * k) 174 \(x + 2 * k) 180 \(x - 2 * k) 186"
    }

    nonisolated static func draw(_ ctx: inout GraphicsContext, mood: CrewMood, stage: Int, time t: Double, animate on: Bool) {
        let cheer = mood == .cheer
        let cheerTimes = [0, 0.15, 0.35, 0.55, 1.0]

        let body: ArtTrack = switch mood {
        case .hello: ArtTrack([[1, 1], [1.06, 0.95], [1, 1]], times: [0, 0.35, 1], duration: 3, spline: true)
        case .calm: ArtTrack([[1, 1], [1.04, 0.97], [1, 1]], times: [0, 0.4, 1], duration: 5, spline: true)
        case .breathe: ArtTrack([[1, 1], [1.12, 1.05], [1, 1]], times: [0, 0.4, 1], duration: 10, spline: true)
        case .cheer: ArtTrack([[1, 1], [1.12, 0.88], [0.95, 1.06], [1, 1], [1, 1]], times: cheerTimes, duration: 1.2, spline: true)
        case .sleepy: ArtTrack([[1, 1], [1.03, 0.98], [1, 1]], times: Crew.spline, duration: 7, spline: true)
        }
        let hop = cheer
            ? ArtTrack(scalars: [0, 0, -18, 0, 0], times: cheerTimes, duration: 1.2, spline: true).scalar(at: t, animate: on)
            : ArtTrack(scalars: [0, -7, 0], times: Crew.spline, duration: mood == .sleepy ? 7 : 4, spline: true).scalar(at: t, animate: on)
        let sway = mood == .sleepy
            ? ArtTrack(scalars: [-4, 4, -4], times: Crew.spline, duration: 7, spline: true).scalar(at: t, animate: on)
            : 0

        Crew.fill(&ctx, Crew.ellipse(100, 194, 34, 4), .black, opacity: 0.08)

        if mood == .breathe || mood == .calm {
            let y1 = ArtTrack(scalars: [160, 60], duration: 4).scalar(at: t, animate: on)
            let y2 = ArtTrack(scalars: [130, 40], duration: 5, begin: 1).scalar(at: t, animate: on)
            Crew.stroke(&ctx, Crew.circle(160, on ? y1 : 150, 5), .white, 2.5)
            Crew.stroke(&ctx, Crew.circle(44, y2, 3.5), .white, 2.5)
        }

        var g = ctx
        g.translateBy(x: 0, y: hop)
        if stage >= 4 {
            Crew.fill(&g, "M100 18 l4 9 l9 1 l-7 6 l2 9 l-8 -5 l-8 5 l2 -9 l-7 -6 l9 -1 Z", Color(hex: 0xFFC93C))
        }
        // Four tentacles wave out of step, 0.3 s apart.
        for (i, x) in [78.0, 93, 108, 123].enumerated() {
            let k = ArtTrack(scalars: [1, -1, 1], duration: 2.4, begin: 0.3 * Double(i)).scalar(at: t, animate: on)
            Crew.stroke(&g, tentacle(x: x, k: k), Color(hex: i.isMultiple(of: 2) ? 0xF07188 : 0xFF8FA3), 5)
        }
        let arm = Color(hex: 0xFFC2CD)
        Crew.stroke(&g, cheer ? "M56 118 C42 106 38 92 44 78" : "M58 120 C50 136 60 150 52 166", arm, 10)
        Crew.stroke(&g, cheer ? "M144 118 C158 106 162 92 156 78" : "M142 120 C150 136 140 150 148 166", arm, 10)

        var b = g
        Crew.pose(&b, pivot: CGPoint(x: 100, y: 44), scale: body.value(at: t, animate: on), rotate: sway)
        Crew.fill(&b, "M42 112 C40 68 66 44 100 44 C134 44 160 68 158 112 C158 120 152 124 144 121 C136 128 126 128 118 121 C110 128 90 128 82 121 C74 128 64 128 56 121 C48 124 42 120 42 112 Z", Color(hex: 0xFF8FA3))
        Crew.fill(&b, "M120 48 C146 58 160 82 158 112 C158 120 152 124 144 121 C148 94 140 68 120 48 Z", Color(hex: 0xF07188))
        Crew.fill(&b, "M48 110 C70 116 130 116 152 110 C152 114 150 116 146 116 C120 122 80 122 54 116 C50 116 48 114 48 110 Z", Color(hex: 0xFFB3C1))
        Crew.stroke(&b, "M62 78 C66 62 78 52 94 48", Color(hex: 0xFFD6DE), 7)
        let glint = Color(hex: 0xFFF1B8)
        Crew.fill(&b, Crew.circle(62, 96, 4), glint)
        if stage >= 2 {
            Crew.fill(&b, Crew.circle(140, 88, 4), glint)
            Crew.fill(&b, Crew.circle(132, 66, 3), glint)
        }
        if stage >= 3 {
            Crew.fill(&b, Crew.circle(74, 64, 3), glint)
            Crew.fill(&b, Crew.circle(148, 104, 3), glint)
        }
        Crew.fill(&b, Crew.circle(72, 104, 7), Color(hex: 0xFF6F8E), opacity: 0.6)
        Crew.fill(&b, Crew.circle(128, 104, 7), Color(hex: 0xFF6F8E), opacity: 0.6)
        Crew.Face.make(mood, y: 92).draw(in: &b, y: 92, time: t, animate: on, blinkPeriod: 4.2, mood: mood, color: Crew.ink)

        if cheer {
            Crew.stroke(&ctx, "M24 60 l0 12 M18 66 l12 0", Crew.ink, 3)
            Crew.stroke(&ctx, "M176 56 l0 10 M171 61 l10 0", Crew.ink, 3)
        }
        if mood == .sleepy {
            Crew.zzz(&ctx, at: CGPoint(x: 154, y: 30), time: t, animate: on, color: Crew.ink)
        }
    }
}
