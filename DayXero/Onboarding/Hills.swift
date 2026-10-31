import DayXeroCore
import SwiftUI

/// Rolling moss hills behind the welcome screen (S22): three layers drifting past each other like Home's header,
/// with a dotted path along the middle ridge to a flag on Quit Day. Flat colours, so it works in both themes.
struct Hills: View {
    /// The flag's date; no flag when nil.
    var quitDay: Date? = nil
    var still = false

    /// One hill: its resting height (share of the height), swell, waviness, drift speed (radians a second) and phase.
    private struct Layer {
        let base: CGFloat
        let color: Color
        let amp: CGFloat
        let k: CGFloat
        let speed: CGFloat
        let phase: CGFloat
    }

    private static let layers: [Layer] = [
        Layer(base: 0.30, color: Color(light: 0xDFE3CF, dark: 0x1D2410), amp: 0.06, k: 1.6, speed: 0.34, phase: 0.4),
        Layer(base: 0.47, color: Color(light: 0xC9D0A8, dark: 0x2C3816), amp: 0.05, k: 2.1, speed: -0.44, phase: 2.0),
        Layer(base: 0.68, color: Color(light: 0xBCC388, dark: 0x43511C), amp: 0.04, k: 2.6, speed: 0.55, phase: 4.1),
    ]

    var body: some View {
        TimelineView(.animation(paused: still)) { timeline in
            let t = still ? 0 : CGFloat(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000))
            Canvas { context, size in
                for (index, layer) in Self.layers.enumerated() {
                    context.fill(hill(size) { y(layer, x: $0, width: size.width, height: size.height, t: t) }, with: .color(layer.color))
                    if index == 1, let quitDay { drawPath(&context, size: size, layer: layer, t: t, quitDay: quitDay) }
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// The ridge height at x: two sines at different speeds, so the hills swell and settle rather than slide.
    private func y(_ layer: Layer, x: CGFloat, width: CGFloat, height: CGFloat, t: CGFloat) -> CGFloat {
        let u = x / max(width, 1) * .pi
        let wave = sin(u * layer.k + t * layer.speed + layer.phase) + 0.45 * cos(u * layer.k * 1.7 - t * layer.speed * 0.6)
        return height * (layer.base + layer.amp * wave)
    }

    private func hill(_ size: CGSize, top: (CGFloat) -> CGFloat) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: size.height))
            var x: CGFloat = 0
            while x <= size.width + 4 {
                p.addLine(to: CGPoint(x: x, y: top(x)))
                x += 4
            }
            p.addLine(to: CGPoint(x: size.width + 4, y: size.height))
            p.closeSubpath()
        }
    }

    private func drawPath(_ context: inout GraphicsContext, size: CGSize, layer: Layer, t: CGFloat, quitDay: Date) {
        let flagX = size.width * 0.8
        let lift: CGFloat = 14
        var trail = Path()
        var x: CGFloat = 0
        trail.move(to: CGPoint(x: 0, y: y(layer, x: 0, width: size.width, height: size.height, t: t) + lift))
        while x <= flagX {
            // The path climbs from just under the ridge to the flag's foot.
            let rise = lift * (1 - x / flagX)
            trail.addLine(to: CGPoint(x: x, y: y(layer, x: x, width: size.width, height: size.height, t: t) + rise))
            x += 4
        }
        var glow = context
        glow.addFilter(.shadow(color: DX.Palette.sage.opacity(0.9), radius: 6))
        glow.stroke(trail, with: .color(DX.Palette.accentInk), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [0.5, 7]))

        let foot = CGPoint(x: flagX, y: y(layer, x: flagX, width: size.width, height: size.height, t: t))
        var pole = Path()
        pole.move(to: foot)
        pole.addLine(to: CGPoint(x: foot.x, y: foot.y - 28))
        context.stroke(pole, with: .color(DX.Palette.accentInk), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        var flag = Path()
        flag.move(to: CGPoint(x: foot.x, y: foot.y - 28))
        flag.addLine(to: CGPoint(x: foot.x + 15, y: foot.y - 28))
        flag.addLine(to: CGPoint(x: foot.x + 11, y: foot.y - 22.5))
        flag.addLine(to: CGPoint(x: foot.x + 15, y: foot.y - 17))
        flag.addLine(to: CGPoint(x: foot.x, y: foot.y - 17))
        context.fill(flag, with: .color(DX.Palette.sage))

        let label = context.resolve(Text("Day Xero · \(quitDay, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))")
            .font(.custom(DX.Typeface.semibold, size: 12, relativeTo: .caption))
            .foregroundStyle(DX.Palette.accentInk))
        let textSize = label.measure(in: size)
        let tag = CGRect(x: min(foot.x - textSize.width + 6, size.width - textSize.width - 28), y: foot.y - 64,
                         width: textSize.width + 20, height: textSize.height + 10)
        let capsule = Path(roundedRect: tag, cornerRadius: tag.height / 2)
        context.fill(capsule, with: .color(DX.Palette.canvas))
        context.stroke(capsule, with: .color(DX.Palette.accentInk), lineWidth: 1)
        context.draw(label, at: CGPoint(x: tag.midX, y: tag.midY))
    }
}
