import DayXeroCore
import SwiftUI
import WidgetKit

/// Shared look for the widgets (DAYXERO_WIDGETS_HANDOFF.md §1), compiled into the app (for the debug gallery)
/// and the widget extension.
enum WidgetTone {
    static let background = Color(hex: 0x070806)
    static let sage = Color(hex: 0xBCC388)
    static let moss = Color(hex: 0x43511C)
    static let lens = Color(hex: 0x070A04)
    static let empty = Color(hex: 0x0C0F08)
}

/// Colours per rendering mode: full colour as drawn; accented (tinted and clear) and vibrant turn sage and moss white.
struct WidgetInk {
    let mode: WidgetRenderingMode

    var isFullColor: Bool { mode == .fullColor }
    var sage: Color { isFullColor ? WidgetTone.sage : .white }
    var moss: Color { isFullColor ? WidgetTone.moss : .white.opacity(0.35) }
    var lens: Color { isFullColor ? WidgetTone.lens : .black.opacity(0.28) }
    /// Black on a sage button in colour; black on a white button otherwise.
    var onButton: Color { .black }
    var secondary: Color { .white.opacity(0.55) }
}

/// Eyebrow labels: JetBrains Mono SemiBold 10, tracking 0.8, uppercase.
struct WidgetEyebrow: View {
    let text: String
    var color: Color = .white.opacity(0.5)

    var body: some View {
        Text(verbatim: text.uppercased())
            .font(.custom(DX.Typeface.mono, fixedSize: 10))
            .tracking(0.8)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}

/// The craving wave line used for SOS (`dx.wave`).
struct WaveGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let mid = rect.midY, amp = rect.height * 0.28, w = rect.width
        p.move(to: CGPoint(x: rect.minX, y: mid))
        p.addCurve(to: CGPoint(x: rect.minX + w / 2, y: mid),
                   control1: CGPoint(x: rect.minX + w * 0.16, y: mid - amp * 2), control2: CGPoint(x: rect.minX + w * 0.34, y: mid - amp * 2))
        p.addCurve(to: CGPoint(x: rect.maxX, y: mid),
                   control1: CGPoint(x: rect.minX + w * 0.66, y: mid + amp * 2), control2: CGPoint(x: rect.minX + w * 0.84, y: mid + amp * 2))
        return p
    }
}

/// The shield with a ring inside (`dx.shield`), for guards and the forecast.
struct ShieldGlyph: View {
    var fill: Color
    var stroke: Color
    var lineWidth: CGFloat = 1.6

    var body: some View {
        ZStack {
            ShieldShape().fill(fill)
            ShieldShape().stroke(stroke, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
            Circle().stroke(stroke, lineWidth: lineWidth).scaleEffect(0.32).offset(y: -1)
        }
    }
}

struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height, x = rect.minX, y = rect.minY
        var p = Path()
        p.move(to: CGPoint(x: x + w / 2, y: y + h * 0.04))
        p.addLine(to: CGPoint(x: x + w * 0.9, y: y + h * 0.2))
        p.addCurve(to: CGPoint(x: x + w / 2, y: y + h * 0.96),
                   control1: CGPoint(x: x + w * 0.9, y: y + h * 0.62), control2: CGPoint(x: x + w * 0.68, y: y + h * 0.86))
        p.addCurve(to: CGPoint(x: x + w * 0.1, y: y + h * 0.2),
                   control1: CGPoint(x: x + w * 0.32, y: y + h * 0.86), control2: CGPoint(x: x + w * 0.1, y: y + h * 0.62))
        p.closeSubpath()
        return p
    }
}

/// The static orb used in the SOS widget and StandBy (§4.1, §4.2): halo, glow, moss and sage rings,
/// white filament and a dark lens. Widgets can't animate, so this is a still drawing.
struct OrbGlyph: View {
    let ink: WidgetInk
    /// Ring radius; everything else scales from the SOS widget's numbers (ring 34).
    var ringRadius: CGFloat = 34

    var body: some View {
        let k = ringRadius / 34
        ZStack {
            if ink.isFullColor {
                Circle()
                    .fill(RadialGradient(stops: [.init(color: WidgetTone.moss.opacity(0.5), location: 0.3),
                                                 .init(color: WidgetTone.moss.opacity(0), location: 1)],
                                         center: .center, startRadius: 0, endRadius: 58 * k))
                    .frame(width: 116 * k, height: 116 * k)
                Circle().stroke(WidgetTone.sage.opacity(0.5), lineWidth: 12 * k).blur(radius: 4 * k)
                    .frame(width: ringRadius * 2, height: ringRadius * 2)
            }
            Circle().stroke(ink.moss, lineWidth: 11 * k).frame(width: ringRadius * 2, height: ringRadius * 2)
            Circle().stroke(ink.sage, lineWidth: 4.5 * k).frame(width: ringRadius * 2, height: ringRadius * 2)
                .widgetAccentable()
            Circle().stroke(Color.white.opacity(0.92), lineWidth: 1.4 * k).frame(width: 66.4 * k, height: 66.4 * k)
            Circle().fill(ink.lens).frame(width: 50 * k, height: 50 * k)
        }
    }
}

/// The still water pill for widgets (§4.4): capsule, highlight, liquid with a still wave.
struct WidgetPill: View {
    let ink: WidgetInk
    let level: Double
    let drink: Drink
    var width: CGFloat = 52
    var height: CGFloat = 96

    var body: some View {
        let level = min(max(level, 0), 1)
        Canvas { context, size in
            let w = size.width, h = size.height
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(ink.isFullColor ? WidgetTone.empty : .black.opacity(0.28)))
            if level > 0 {
                let top = h * (1 - level)
                var liquid = Path()
                liquid.move(to: CGPoint(x: 0, y: top))
                // A still wave on the surface: wavelength 28, amplitude 2.
                var x: CGFloat = 0
                var up = true
                while x < w {
                    liquid.addQuadCurve(to: CGPoint(x: x + 14, y: top), control: CGPoint(x: x + 7, y: top + (up ? -4 : 4)))
                    x += 14
                    up.toggle()
                }
                liquid.addLine(to: CGPoint(x: w, y: h))
                liquid.addLine(to: CGPoint(x: 0, y: h))
                liquid.closeSubpath()
                if ink.isFullColor {
                    let g = drink.gradient
                    context.fill(liquid, with: .linearGradient(Gradient(colors: [Color(hex: g.top), Color(hex: g.bottom)]),
                                                               startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: h)))
                } else {
                    context.fill(liquid, with: .color(.white.opacity(0.85)))
                }
            }
            let highlight = CGRect(x: 9 * w / 52, y: h * 0.14, width: 4 * w / 52, height: 64 * h / 96)
            context.fill(Path(roundedRect: highlight, cornerRadius: 2), with: .color(.white.opacity(0.18)))
        }
        .frame(width: width, height: height)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.75), lineWidth: 1.5))
        .widgetAccentable()
    }
}
