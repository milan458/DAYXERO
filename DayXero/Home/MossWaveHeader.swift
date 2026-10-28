import DayXeroCore
import SwiftUI

/// Home's top section (S19.2): two moss hills rolling past each other, after the dayxero.in phone preview
/// (`drawPhoneMoss` in website/index.html), with today's cravings, when the next one tends to come, and Log.
/// It's a picture, like the orb, so it keeps its colours in the light theme.
struct MossWaveHeader: View {
    let cravingsToday: Int
    /// A usual day's count, once there's one to compare with.
    let usualCravings: Int?
    let nextCraving: CravingPredictor.Window?
    let now: Date
    let onLog: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: DX.Radius.input, style: .continuous)
        MossHills(still: reduceMotion)
            .frame(height: 112)
            .overlay {
                LinearGradient(colors: [.black, .clear, .clear], startPoint: .bottom, endPoint: .top)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .bottom) {
                HStack(spacing: DX.Space.xs) {
                    HStack(spacing: DX.Space.xs) {
                        pill(cravingLine, color: DX.Palette.sage)
                        if let nextLine { pill(nextLine, color: .white.opacity(0.8)) }
                    }
                    .accessibilityElement(children: .combine)
                    Spacer(minLength: 0)
                    Button(action: onLog) {
                        Label("Log", systemImage: "plus")
                            .font(.custom(DX.Typeface.semibold, size: 12, relativeTo: .caption))
                            .foregroundStyle(.black)
                            .padding(.vertical, 6).padding(.horizontal, 12)
                            .background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Log"))
                    .accessibilityHint(Text("Log a craving or a use"))
                }
                .padding(10)
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(DX.Palette.sage.opacity(0.2)))
            .environment(\.colorScheme, .dark)
    }

    private var cravingLine: String {
        if let usualCravings, usualCravings > 0 {
            return String(localized: "\(cravingsToday)/\(usualCravings) cravings today")
        }
        return cravingsToday == 1 ? String(localized: "1 craving today") : String(localized: "\(cravingsToday) cravings today")
    }

    /// "Next: 2h", "Next: 40m", or "Next: now" inside a window. Nil until the predictor has learnt one.
    private var nextLine: String? {
        guard let window = nextCraving else { return nil }
        if window.start <= now { return String(localized: "Next: now") }
        let minutes = Int(window.start.timeIntervalSince(now) / 60)
        if minutes < 60 { return String(localized: "Next: \(max(minutes, 1))m") }
        return String(localized: "Next: \(Int((Double(minutes) / 60).rounded()))h")
    }

    private func pill(_ text: String, color: Color) -> some View {
        Text(verbatim: text)
            .font(.custom(DX.Typeface.mono, size: 10, relativeTo: .caption2))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.vertical, 5).padding(.horizontal, 10)
            .background(.black.opacity(0.75), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.1)))
    }
}

/// The hills themselves: the website's canvas maths, with its 350 × 112 drawing stretched to the card.
struct MossHills: View {
    var still = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: still)) { timeline in
            // The website steps 0.008 a frame at 60 fps.
            let t: CGFloat = still ? 0 : CGFloat(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000) * 0.48)
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                context.fill(Path(rect), with: .linearGradient(
                    Gradient(stops: [.init(color: Color(hex: 0x1E280C), location: 0),
                                     .init(color: Color(hex: 0x43511C), location: 0.6),
                                     .init(color: .black, location: 1)]),
                    startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
                let sx = 350 / max(size.width, 1)
                let sy = size.height / 112
                context.fill(hill(in: size, step: 10, sy: sy) { x in
                    50 + sin(x * sx * 0.015 + t) * 18 + cos(x * sx * 0.03) * 6
                }, with: .color(DX.Palette.sage.opacity(0.45)))
                context.fill(hill(in: size, step: 8, sy: sy) { x in
                    68 + sin(x * sx * 0.02 - t * 1.2) * 15
                }, with: .color(Color(hex: 0x283410, opacity: 0.95)))
            }
        }
        .accessibilityHidden(true)
    }

    /// A filled hill whose top follows `y` (in the website's 112-high units).
    private func hill(in size: CGSize, step: CGFloat, sy: CGFloat, y: (CGFloat) -> CGFloat) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: size.height))
            var x: CGFloat = 0
            while x <= size.width + step {
                p.addLine(to: CGPoint(x: x, y: y(x) * sy))
                x += step
            }
            p.addLine(to: CGPoint(x: size.width + step, y: size.height))
            p.closeSubpath()
        }
    }
}
