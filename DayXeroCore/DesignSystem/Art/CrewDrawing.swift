import SwiftUI

/// Drawing helpers shared by Xero, Jelli and Glim. All three draw in a 200 × 200 space,
/// the same as their `.dc.html` sources, and are scaled to the requested size.
enum Crew {
    static let ink = Color(hex: 0x24163A)
    static let spline = [0.0, 0.5, 1.0]

    struct Face {
        let eyeL: String
        let eyeR: String
        let eyeWidth: CGFloat
        let mouth: String
        let mouthFilled: Bool

        /// The five faces, identical across the crew apart from the eye line `y`.
        static func make(_ mood: CrewMood, y: Int) -> Face {
            let c = 100, l = 86, r = 114
            switch mood {
            case .hello:
                return Face(eyeL: "M\(l) \(y - 3) L\(l) \(y + 3)", eyeR: "M\(r) \(y - 3) L\(r) \(y + 3)", eyeWidth: 8,
                            mouth: "M\(c - 8) \(y + 14) Q\(c) \(y + 22) \(c + 8) \(y + 14)", mouthFilled: false)
            case .calm:
                return Face(eyeL: closed(l, y), eyeR: closed(r, y), eyeWidth: 3.5,
                            mouth: "M\(c - 5) \(y + 15) Q\(c) \(y + 19) \(c + 5) \(y + 15)", mouthFilled: false)
            case .breathe:
                return Face(eyeL: closed(l, y), eyeR: closed(r, y), eyeWidth: 3.5,
                            mouth: "M\(c) \(y + 12) C\(c + 6) \(y + 12) \(c + 6) \(y + 23) \(c) \(y + 23) C\(c - 6) \(y + 23) \(c - 6) \(y + 12) \(c) \(y + 12) Z",
                            mouthFilled: true)
            case .cheer:
                return Face(eyeL: "M\(l - 6) \(y + 2) Q\(l) \(y - 5) \(l + 6) \(y + 2)", eyeR: "M\(r - 6) \(y + 2) Q\(r) \(y - 5) \(r + 6) \(y + 2)", eyeWidth: 3.5,
                            mouth: "M\(c - 10) \(y + 12) L\(c + 10) \(y + 12) Q\(c) \(y + 28) \(c - 10) \(y + 12) Z", mouthFilled: true)
            case .sleepy:
                return Face(eyeL: "M\(l - 6) \(y + 1) L\(l + 6) \(y + 1)", eyeR: "M\(r - 6) \(y + 1) L\(r + 6) \(y + 1)", eyeWidth: 3.5,
                            mouth: "M\(c - 3) \(y + 16) Q\(c) \(y + 18) \(c + 3) \(y + 16)", mouthFilled: false)
            }
        }

        private static func closed(_ x: Int, _ y: Int) -> String {
            "M\(x - 6) \(y) Q\(x) \(y + 5) \(x + 6) \(y)"
        }

        /// Eyes blink (scale y to 0.1 around the eye line) on hello and cheer only.
        func draw(in ctx: inout GraphicsContext, y: Int, time: Double, animate: Bool, blinkPeriod: Double, mood: CrewMood, color: Color) {
            let blinks = animate && (mood == .hello || mood == .cheer)
            let scaleY = ArtTrack(scalars: [1, 1, 0.1, 1], times: [0, 0.92, 0.96, 1], duration: blinkPeriod).scalar(at: time, animate: blinks)
            var eyes = ctx
            eyes.translateBy(x: 100, y: CGFloat(y))
            eyes.scaleBy(x: 1, y: scaleY)
            eyes.translateBy(x: -100, y: -CGFloat(y))
            Crew.stroke(&eyes, eyeL, color, eyeWidth)
            Crew.stroke(&eyes, eyeR, color, eyeWidth)
            if mouthFilled { Crew.fill(&ctx, mouth, color) }
            Crew.stroke(&ctx, mouth, color, 3.5)
        }
    }

    static func fill(_ ctx: inout GraphicsContext, _ d: String, _ color: Color, opacity: Double = 1, evenOdd: Bool = false) {
        guard opacity > 0 else { return }
        ctx.fill(SVGPath.path(d), with: .color(color.opacity(opacity)), style: FillStyle(eoFill: evenOdd))
    }

    static func fill(_ ctx: inout GraphicsContext, _ path: Path, _ color: Color, opacity: Double = 1) {
        guard opacity > 0 else { return }
        ctx.fill(path, with: .color(color.opacity(opacity)))
    }

    static func stroke(_ ctx: inout GraphicsContext, _ d: String, _ color: Color, _ width: CGFloat, opacity: Double = 1) {
        guard opacity > 0 else { return }
        ctx.stroke(SVGPath.path(d), with: .color(color.opacity(opacity)),
                   style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    static func stroke(_ ctx: inout GraphicsContext, _ path: Path, _ color: Color, _ width: CGFloat, opacity: Double = 1) {
        guard opacity > 0 else { return }
        ctx.stroke(path, with: .color(color.opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    static func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    static func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        ellipse(cx, cy, r, r)
    }

    /// Applies the SVG pattern translate(p) scale(s) rotate(r) translate(-p).
    static func pose(_ ctx: inout GraphicsContext, pivot: CGPoint, scale: [Double], rotate: Double) {
        ctx.translateBy(x: pivot.x, y: pivot.y)
        ctx.scaleBy(x: scale.first ?? 1, y: scale.count > 1 ? scale[1] : 1)
        ctx.rotate(by: .degrees(rotate))
        ctx.translateBy(x: -pivot.x, y: -pivot.y)
    }

    /// The sparkle, zzz and breeze marks drawn outside the body.
    static func zzz(_ ctx: inout GraphicsContext, at origin: CGPoint, time: Double, animate: Bool, color: Color) {
        let float = ArtTrack([[0, 0], [5, -8], [0, 0]], duration: 3).value(at: time, animate: animate)
        var z = ctx
        z.translateBy(x: float[0], y: float[1])
        let x = origin.x, y = origin.y
        stroke(&z, "M\(x) \(y) h12 l-12 12 h12", color, 3)
        stroke(&z, "M\(x + 20) \(y - 20) h8 l-8 8 h8", color, 3)
    }
}

/// Wraps a crew drawing in a looping timeline. Animation stops when `animate` is off
/// or Reduce Motion is on, leaving the resting pose.
struct CrewCanvas: View {
    let label: String
    let size: CGFloat
    let animate: Bool
    let draw: @Sendable (inout GraphicsContext, Double, Bool) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let moving = animate && !reduceMotion
        TimelineView(.animation(paused: !moving)) { timeline in
            Canvas { ctx, canvasSize in
                ctx.scaleBy(x: canvasSize.width / 200, y: canvasSize.height / 200)
                draw(&ctx, timeline.date.timeIntervalSinceReferenceDate, moving)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isImage)
    }
}
