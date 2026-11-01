import DayXeroCore
import SwiftUI

/// One phase of the program as a winding path, bottom to top (decision 31): done stops ticked on a green
/// road, today's a coral play button with Xero beside it (the crew replaced the person figure, S27.15), later
/// ones locked, and the phase's
/// last session as its milestone. Labels are titles only; "Today · 3 min" sits on today's stop.
struct ProgramPathMap: View {
    struct Stop: Identifiable {
        enum Kind { case done, today, locked, goal }
        let id: String
        let title: String
        let kind: Kind
        let minutes: Int
        let needsUpgrade: Bool
        let accessibility: String
    }

    let stops: [Stop]
    let ground: DX.Ground
    let onTap: (Stop) -> Void

    private let step: CGFloat = 66
    private let road = Color(light: 0xFFF8EE, dark: 0x1F4A3B)
    private let roadDone = Color(light: 0x3E9E6A, dark: 0x2FD08A)
    private let tile = Color(light: 0xFFF8EE, dark: 0x16382D)

    var body: some View {
        let height = max(CGFloat(stops.count - 1) * step + 84, 120)
        GeometryReader { proxy in
            let points = points(width: proxy.size.width, height: height)
            let todayIndex = stops.firstIndex { $0.kind == .today }
            let doneUpTo = todayIndex ?? (stops.lastIndex { $0.kind == .done } ?? -1)
            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in
                    guard points.count > 1 else { return }
                    ctx.stroke(curve(points, 0, points.count - 1), with: .color(road), style: StrokeStyle(lineWidth: 28, lineCap: .round))
                    if doneUpTo > 0 {
                        ctx.stroke(curve(points, 0, doneUpTo), with: .color(roadDone), style: StrokeStyle(lineWidth: 28, lineCap: .round))
                    }
                    ctx.stroke(curve(points, max(doneUpTo, 0), points.count - 1), with: .color(ground.ink),
                               style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 9]))
                }
                .accessibilityHidden(true)

                ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                    let p = points[index]
                    label(stop, at: p, width: proxy.size.width)
                    Button { onTap(stop) } label: { node(stop) }
                        .buttonStyle(.plain)
                        .position(p)
                        .accessibilityLabel(Text(verbatim: stop.title))
                        .accessibilityValue(Text(verbatim: stop.accessibility))
                        .accessibilityHint(stop.kind == .today ? Text("Starts today's session") : Text(""))
                }

                if let todayIndex {
                    let p = points[todayIndex]
                    let leftSide = p.x < proxy.size.width / 2
                    XeroView(mood: .hello, size: .card)
                        .position(x: leftSide ? max(p.x - 74, 44) : min(p.x + 74, proxy.size.width - 44), y: p.y - 18)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(height: height)
    }

    /// Alternating left and right, the last stop centred; y from the bottom up.
    private func points(width: CGFloat, height: CGFloat) -> [CGPoint] {
        stops.indices.map { i in
            let last = i == stops.count - 1 && stops.count > 1
            let fraction: CGFloat = last ? 0.52 : (i.isMultiple(of: 2) ? 0.32 : 0.66)
            return CGPoint(x: (width * fraction).rounded(), y: height - 42 - CGFloat(i) * step)
        }
    }

    private func curve(_ p: [CGPoint], _ from: Int, _ to: Int) -> Path {
        var path = Path()
        guard from < p.count, to < p.count, from <= to else { return path }
        path.move(to: p[from])
        if from == to { return path }
        for i in (from + 1)...to {
            let a = p[i - 1], b = p[i], m = (a.y + b.y) / 2
            path.addCurve(to: b, control1: CGPoint(x: a.x, y: m), control2: CGPoint(x: b.x, y: m))
        }
        return path
    }

    @ViewBuilder
    private func node(_ stop: Stop) -> some View {
        switch stop.kind {
        case .done:
            Image(systemName: "checkmark").font(.system(size: 14, weight: .heavy))
                .foregroundStyle(DX.Ground.reading.background)
                .frame(width: 36, height: 36).background(DX.Fill.green, in: Circle())
                .frame(width: 44, height: 44)
        case .today:
            Image(systemName: "play.fill").font(.system(size: 20, weight: .bold)).foregroundStyle(DX.Fill.navy)
                .frame(width: 56, height: 56)
                .background(Color(hex: 0xFF7A55), in: Circle())
                .background(Circle().fill(Color(hex: 0xFF7A55).opacity(0.25)).padding(-10))
        case .goal:
            Image(systemName: "star.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(DX.Fill.navy)
                .frame(width: 46, height: 46).background(Color(hex: 0xFFD966), in: Circle())
        case .locked:
            Image(systemName: stop.needsUpgrade ? "lock.open.fill" : "lock.fill").font(.system(size: 11, weight: .bold))
                .foregroundStyle(DX.Ground.reading.ink)
                .frame(width: 30, height: 30).background(tile, in: Circle())
                .overlay(Circle().strokeBorder(ground.background, lineWidth: 3))
                .frame(width: 44, height: 44)
        }
    }

    @ViewBuilder
    private func label(_ stop: Stop, at p: CGPoint, width: CGFloat) -> some View {
        let right = p.x < width / 2
        let radius: CGFloat = stop.kind == .today ? 28 : stop.kind == .goal ? 23 : 18
        let gap = radius + 12
        let w = max(right ? width - p.x - gap - 4 : p.x - gap - 4, 60)
        VStack(alignment: right ? .leading : .trailing, spacing: 1) {
            if stop.kind == .today {
                Text("Today · \(stop.minutes) min").dxType(.caption).textCase(.uppercase).foregroundStyle(ground.ink)
            }
            Text(verbatim: stop.title)
                .font(stop.kind == .today || stop.kind == .goal
                      ? DX.Typeface4.swiftUIFont(.display, size: 18, weight: 800)
                      : DX.Typeface4.swiftUIFont(.body, size: 16, weight: stop.kind == .locked ? 600 : 700))
                .foregroundStyle(ground.ink)
                .multilineTextAlignment(right ? .leading : .trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(width: w, alignment: right ? .leading : .trailing)
        .position(x: right ? p.x + gap + w / 2 : p.x - gap - w / 2, y: p.y)
        .accessibilityHidden(true)
    }
}

/// Each session's illustration from the kit (decision 31).
enum ProgramArt {
    static func kind(for sessionId: String) -> KitArt.Kind {
        switch sessionId {
        case "P1": .dawn
        case "P2": .cup
        case "P3": .eye
        case "P4": .breath
        case "P5": .sea
        case "P6": .heart
        case "P7": .night
        case "DX": .flower
        case "W1D1": .glass
        case "W1D2": .clouds
        case "W1D3": .sprout
        case "W1D4": .sparkle
        case "W1D5": .night
        case "W1D6": .tag
        case "W1D7": .peak
        case "W2S1": .clouds
        case "W2S2": .night
        case "W2S3": .peak
        case "W3S1": .anchor
        case "W3S2": .sea
        case "W3S3": .sprout
        case "W4S1": .heart
        case "W4S2": .shield
        case "W4S3": .flower
        default: .dawn
        }
    }
}
