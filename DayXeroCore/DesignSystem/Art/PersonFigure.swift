import SwiftUI

/// The illustrated person used once per screen as header art (decision 31), drawn from the
/// "Final screens" canvas's `Person.dc.html` in a 100 × 120 space. Flat shapes, no outline.
public struct PersonFigure: View {
    public enum Pose: String, CaseIterable, Sendable { case cheer, magnify, meditate, walk }

    let pose: Pose
    let height: CGFloat
    let shirt: UInt32
    let skin: UInt32
    let animate: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(_ pose: Pose, height: CGFloat = 120, shirt: UInt32 = 0xFF7A55, skin: UInt32 = 0x8A5A3C, animate: Bool = true) {
        self.pose = pose
        self.height = height
        self.shirt = shirt
        self.skin = skin
        self.animate = animate
    }

    public var body: some View {
        let moving = animate && !reduceMotion
        let pose = pose, shirt = shirt, skin = skin
        TimelineView(.animation(paused: !moving)) { timeline in
            Canvas { ctx, size in
                ctx.scaleBy(x: size.width / 100, y: size.height / 120)
                PersonDraw.draw(&ctx, pose: pose, shirt: shirt, skin: skin, time: timeline.date.timeIntervalSinceReferenceDate, on: moving)
            }
        }
        .frame(width: height * 100 / 120, height: height)
        .accessibilityHidden(true)
    }
}

enum PersonDraw {
    static let trousers: UInt32 = 0x2B2A6B
    static let ink: UInt32 = 0x1E1A3A

    static func draw(_ ctx: inout GraphicsContext, pose: PersonFigure.Pose, shirt: UInt32, skin: UInt32, time t: Double, on: Bool) {
        KitDraw.fill(&ctx, Path(ellipseIn: CGRect(x: 24, y: 110, width: 52, height: 8)), ink, 0.15)
        let track = { (values: [Double], times: [Double]?, duration: Double) in
            ArtTrack(scalars: values, times: times, duration: duration).scalar(at: t, animate: on)
        }
        switch pose {
        case .cheer:
            var body = ctx
            body.translateBy(x: 0, y: track([0, -4, 0], nil, 1.6))
            legs(&body, left: "M42 78 L40 108", right: "M58 78 L60 108", shoes: "M36 110 h8 M56 110 h8")
            KitDraw.fill(&body, "M36 48 Q50 42 64 48 L62 82 L38 82 Z", shirt)
            arm(&body, d: "M38 50 L24 30 L20 14", hand: CGPoint(x: 20, y: 12), pivot: CGPoint(x: 38, y: 50), angle: track([0, -8, 0], nil, 1.6), shirt: shirt, skin: skin)
            arm(&body, d: "M62 50 L76 30 L80 14", hand: CGPoint(x: 80, y: 12), pivot: CGPoint(x: 62, y: 50), angle: track([0, 8, 0], nil, 1.6), shirt: shirt, skin: skin)
            head(&body, y: 32, skin: skin, eyes: (45, 55), smile: "M45 38 Q50 42 55 38")

        case .magnify:
            legs(&ctx, left: "M44 78 L42 108", right: "M56 78 L58 108", shoes: "M38 110 h8 M54 110 h8")
            KitDraw.fill(&ctx, "M38 48 Q50 42 62 48 L60 82 L40 82 Z", shirt)
            KitDraw.stroke(&ctx, "M40 52 L34 72", shirt, 8)
            KitDraw.fill(&ctx, KitDraw.circle(33, 75, 4.5), skin)
            var arm = ctx
            Crew.pose(&arm, pivot: CGPoint(x: 60, y: 52), scale: [1, 1], rotate: track([0, -6, 0], nil, 3))
            KitDraw.stroke(&arm, "M60 52 L72 58 L76 50", shirt, 8)
            KitDraw.fill(&arm, KitDraw.circle(77, 48, 4.5), skin)
            KitDraw.stroke(&arm, "M78 46 L84 36", ink, 4)
            KitDraw.fill(&arm, KitDraw.circle(88, 28, 9), 0xE3EEFC)
            arm.stroke(KitDraw.circle(88, 28, 9), with: .color(Color(hex: ink)), lineWidth: 3.5)
            KitDraw.stroke(&arm, "M84 24 a5 5 0 0 1 5 -2", 0xFFFFFF, 2)
            head(&ctx, y: 32, skin: skin, eyes: (47, 57), smile: "M48 38 Q52 40 56 38")

        case .meditate:
            KitDraw.fill(&ctx, "M22 100 C26 88 74 88 78 100 C70 106 30 106 22 100 Z", trousers)
            var body = ctx
            body.translateBy(x: 0, y: track([0, -2, 0], [0, 0.4, 1], 10))
            KitDraw.fill(&body, "M36 58 Q50 52 64 58 L66 94 L34 94 Z", shirt)
            KitDraw.stroke(&body, "M38 62 L28 88 L36 94", shirt, 8)
            KitDraw.fill(&body, KitDraw.circle(38, 95, 4), skin)
            KitDraw.stroke(&body, "M62 62 L72 88 L64 94", shirt, 8)
            KitDraw.fill(&body, KitDraw.circle(62, 95, 4), skin)
            KitDraw.fill(&body, KitDraw.circle(50, 42, 13), skin)
            KitDraw.fill(&body, "M37 40 C37 28 63 26 63 39 C58 34 46 33 37 40 Z", ink)
            KitDraw.fill(&body, KitDraw.circle(50, 24, 6), ink)
            KitDraw.stroke(&body, "M43 43 q2 2 4 0 M53 43 q2 2 4 0", ink, 1.8)
            KitDraw.stroke(&body, "M47 48 Q50 50 53 48", ink, 1.8)

        case .walk:
            var body = ctx
            body.translateBy(x: 0, y: track([0, -2, 0], nil, 1.2))
            legs(&body, left: "M44 78 L36 108", right: "M56 78 L62 108", shoes: "M30 110 h8 M60 110 h8")
            KitDraw.fill(&body, "M38 48 Q50 42 62 48 L60 82 L40 82 Z", shirt)
            KitDraw.stroke(&body, "M40 52 L34 72", shirt, 8)
            KitDraw.fill(&body, KitDraw.circle(33, 75, 4.5), skin)
            arm(&body, d: "M60 50 L70 36 L72 24", hand: CGPoint(x: 72, y: 21), pivot: CGPoint(x: 60, y: 50), angle: track([0, -14, 0], nil, 1.2), shirt: shirt, skin: skin)
            head(&body, y: 32, skin: skin, eyes: (46, 56), smile: "M46 38 Q51 42 56 38")
        }
    }

    static func legs(_ ctx: inout GraphicsContext, left: String, right: String, shoes: String) {
        KitDraw.stroke(&ctx, left, trousers, 9)
        KitDraw.stroke(&ctx, right, trousers, 9)
        KitDraw.stroke(&ctx, shoes, ink, 5)
    }

    static func arm(_ ctx: inout GraphicsContext, d: String, hand: CGPoint, pivot: CGPoint, angle: Double, shirt: UInt32, skin: UInt32) {
        var a = ctx
        Crew.pose(&a, pivot: pivot, scale: [1, 1], rotate: angle)
        KitDraw.stroke(&a, d, shirt, 8)
        KitDraw.fill(&a, KitDraw.circle(hand.x, hand.y, 4.5), skin)
    }

    static func head(_ ctx: inout GraphicsContext, y: CGFloat, skin: UInt32, eyes: (CGFloat, CGFloat), smile: String) {
        KitDraw.fill(&ctx, KitDraw.circle(50, y, 13), skin)
        KitDraw.fill(&ctx, "M37 30 C37 18 63 16 63 29 C58 24 46 23 37 30 Z", ink)
        KitDraw.fill(&ctx, KitDraw.circle(eyes.0, y + 1, 1.6), ink)
        KitDraw.fill(&ctx, KitDraw.circle(eyes.1, y + 1, 1.6), ink)
        KitDraw.stroke(&ctx, smile, ink, 2)
    }
}
