import DayXeroCore
import SwiftUI

// Today's top half (Today redesign, 4 Nov 2026, from Milan's sketch): a sky with a curved bottom edge holding the week,
// the greeting and a ring with the crew. Sunrise by day with Xero, a violet night with Glim from 6 PM. Scrolling
// folds it into a slim card that stays pinned at the top.

/// The fixed colours the hero's text sits on. The sky is drawn in fixed colours, so its text is too.
struct TodayHeroInk {
    let night: Bool
    var ink: Color { Color(hex: night ? 0xFFF8EE : 0x1E1A3A) }
    var muted: Color { Color(hex: night ? 0xD2C8FF : 0x4A2A1A) }
    var done: Color { Color(hex: night ? 0x2FD08A : 0x0F6E43) }
    var onDone: Color { Color(hex: night ? 0x0E0B2B : 0xFFF8EE) }
    var track: Color { Color(hex: 0xFFF8EE).opacity(night ? 0.22 : 0.8) }
    var quit: Color { Color(hex: 0xFF7155) }
    var quitLabel: Color { Color(hex: night ? 0xFFB09C : 0x8E2F18) }
    var futureRing: Color { night ? Color(hex: 0xFFF8EE).opacity(0.35) : Color(hex: 0x1E1A3A).opacity(0.35) }
    var disk: Color { Color(hex: night ? 0x2A1C6E : 0xFFF3E4) }
    var crewDisk: Color { Color(hex: night ? 0x3A2885 : 0xFFE1C2) }
}

// MARK: Sky

/// The hero's backdrop: sunrise hills by day, a starry violet night with a crescent moon after 6 PM. Drawn on a
/// 390-wide grid measured up from the bottom edge, so it fits any width and any hero height.
struct TodaySky: View {
    let night: Bool
    /// The slim header's strip: just the gradient, the sun or stars, and two low hills.
    var compact = false

    var body: some View {
        Canvas { context, size in
            if compact { drawCompact(&context, size) } else { drawFull(&context, size) }
        }
        .accessibilityHidden(true)
    }

    private func gradient(_ size: CGSize) -> GraphicsContext.Shading {
        let stops: [Gradient.Stop] = night
            ? [.init(color: Color(hex: 0x1C1257), location: 0), .init(color: Color(hex: 0x4A3596), location: 1)]
            : compact
                ? [.init(color: Color(hex: 0xFF8A62), location: 0), .init(color: Color(hex: 0xFFC994), location: 1)]
                : [.init(color: Color(hex: 0xFF8A62), location: 0), .init(color: Color(hex: 0xFFB877), location: 0.55),
                   .init(color: Color(hex: 0xFFE6BF), location: 1)]
        return .linearGradient(Gradient(stops: stops), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
    }

    /// A hill: a start point and pairs of cubic segments (control, control, end), closed along the bottom.
    private func hill(_ points: [(CGFloat, CGFloat)], grid: CGFloat, in size: CGSize) -> Path {
        let sx = size.width / grid
        func p(_ point: (CGFloat, CGFloat)) -> CGPoint { CGPoint(x: point.0 * sx, y: size.height + point.1) }
        var path = Path()
        path.move(to: p(points[0]))
        var index = 1
        while index + 2 < points.count {
            path.addCurve(to: p(points[index + 2]), control1: p(points[index]), control2: p(points[index + 1]))
            index += 3
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
        return path
    }

    private func drawFull(_ context: inout GraphicsContext, _ size: CGSize) {
        let sx = size.width / 390
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: size.height + y) }
        context.fill(Path(CGRect(origin: .zero, size: size)), with: gradient(size))
        if night {
            let stars: [(CGFloat, CGFloat, CGFloat)] = [(34, -286, 1.5), (356, -298, 1.5), (58, -114, 1.2), (332, -124, 1.2),
                                                        (28, -204, 1), (364, -214, 1)]
            for (x, y, r) in stars {
                let c = p(x, y)
                context.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(Color(hex: 0xFFF8EE)))
            }
            var sparkle = Path()
            sparkle.move(to: p(352, -338))
            sparkle.addQuadCurve(to: p(360, -330), control: p(352, -330))
            sparkle.addQuadCurve(to: p(352, -322), control: p(352, -330))
            sparkle.addQuadCurve(to: p(344, -330), control: p(352, -330))
            sparkle.addQuadCurve(to: p(352, -338), control: p(352, -330))
            context.fill(sparkle, with: .color(Color(hex: 0xFFE27A)))
            var moon = Path()
            moon.move(to: p(30, -180))
            moon.addCurve(to: p(58, -208), control1: p(30, -196), control2: p(42, -208))
            moon.addCurve(to: p(46, -184), control1: p(50, -202), control2: p(46, -194))
            moon.addCurve(to: p(66, -160), control1: p(46, -172), control2: p(54, -162))
            moon.addCurve(to: p(54, -158), control1: p(62, -158), control2: p(58, -158))
            moon.addCurve(to: p(30, -180), control1: p(40, -158), control2: p(30, -168))
            context.fill(moon, with: .color(Color(hex: 0xFFE9A8)))
            context.fill(hill([(0, -110), (80, -132), (160, -124), (230, -110), (300, -96), (350, -116), (390, -122)], grid: 390, in: size),
                         with: .color(Color(hex: 0x3A2885)))
            context.fill(hill([(0, -68), (90, -82), (170, -76), (250, -64), (320, -54), (360, -62), (390, -66)], grid: 390, in: size),
                         with: .color(Color(hex: 0x2A1C6E)))
        } else {
            let glow = p(330, -164)
            context.fill(Path(ellipseIn: CGRect(x: glow.x - 72, y: glow.y - 72, width: 144, height: 144)),
                         with: .radialGradient(Gradient(colors: [.white.opacity(0.7), .white.opacity(0)]), center: glow,
                                               startRadius: 0, endRadius: 72))
            let sun = p(330, -158)
            context.fill(Path(ellipseIn: CGRect(x: sun.x - 30, y: sun.y - 30, width: 60, height: 60)),
                         with: .radialGradient(Gradient(colors: [Color(hex: 0xFFF6C8), Color(hex: 0xFFC23A)]),
                                               center: CGPoint(x: sun.x - 6, y: sun.y - 9), startRadius: 0, endRadius: 45))
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 4))
                let clouds: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(44, -272, 34, 9), (62, -280, 18, 9), (352, -294, 30, 8)]
                for (x, y, rx, ry) in clouds {
                    let c = p(x, y)
                    layer.fill(Path(ellipseIn: CGRect(x: c.x - rx * sx, y: c.y - ry, width: rx * 2 * sx, height: ry * 2)),
                               with: .color(Color(hex: 0xFFF4E6).opacity(0.9)))
                }
            }
            context.fill(hill([(0, -152), (70, -180), (140, -172), (210, -158), (290, -142), (340, -166), (390, -174)], grid: 390, in: size),
                         with: .color(Color(hex: 0xFF9D6E)))
            context.fill(hill([(0, -110), (80, -132), (160, -124), (230, -110), (300, -96), (350, -116), (390, -122)], grid: 390, in: size),
                         with: .color(Color(hex: 0xFF7A55)))
            context.fill(hill([(0, -68), (90, -82), (170, -76), (250, -64), (320, -54), (360, -62), (390, -66)], grid: 390, in: size),
                         with: .color(Color(hex: 0xE85A3E)))
            var trees = Path()
            let treeSpots: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(30, -120, 12, 16), (46, -122, 8, 10), (350, -130, 10, 12)]
            for (x, y, w, h) in treeSpots {
                trees.move(to: p(x, y))
                trees.addLine(to: p(x + w / 2, y - h))
                trees.addLine(to: p(x + w, y))
                trees.closeSubpath()
            }
            context.fill(trees, with: .color(Color(hex: 0xC2402A)))
        }
    }

    private func drawCompact(_ context: inout GraphicsContext, _ size: CGSize) {
        let sx = size.width / 358
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: size.height + y) }
        context.fill(Path(CGRect(origin: .zero, size: size)), with: gradient(size))
        if night {
            let stars: [(CGFloat, CGFloat)] = [(160, 14), (238, 30), (300, 12)]
            for (x, y) in stars {
                let c = CGPoint(x: x * sx, y: y)
                context.fill(Path(ellipseIn: CGRect(x: c.x - 1.3, y: c.y - 1.3, width: 2.6, height: 2.6)), with: .color(Color(hex: 0xFFF8EE)))
            }
            context.fill(hill([(0, -12), (80, -20), (160, -16), (230, -10), (290, -5), (330, -10), (358, -12)], grid: 358, in: size),
                         with: .color(Color(hex: 0x2A1C6E)))
        } else {
            let sun = p(252, -20)
            context.fill(Path(ellipseIn: CGRect(x: sun.x - 15, y: sun.y - 15, width: 30, height: 30)),
                         with: .radialGradient(Gradient(colors: [Color(hex: 0xFFF6C8), Color(hex: 0xFFC23A)]),
                                               center: CGPoint(x: sun.x - 3, y: sun.y - 5), startRadius: 0, endRadius: 22))
            context.fill(hill([(0, -20), (60, -32), (120, -28), (180, -22), (250, -14), (300, -28), (358, -32)], grid: 358, in: size),
                         with: .color(Color(hex: 0xFF9D6E)))
            context.fill(hill([(0, -8), (80, -16), (160, -12), (230, -6), (290, -2), (330, -7), (358, -9)], grid: 358, in: size),
                         with: .color(Color(hex: 0xFF7A55)))
        }
    }
}

/// The sky's outline: straight sides and a gentle curve along the bottom, deepest in the middle.
struct TodaySkyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: rect.origin)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 72))
        path.addCurve(to: CGPoint(x: rect.minX, y: rect.maxY - 72),
                      control1: CGPoint(x: rect.minX + rect.width * 310 / 390, y: rect.maxY),
                      control2: CGPoint(x: rect.minX + rect.width * 80 / 390, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: Week strip

/// Seven days: ticks where the day counted (`TodayWeek`), today filled, Quit Day flagged, the days ahead as rings.
struct TodayWeekStrip: View {
    let week: TodayWeek
    let night: Bool

    var body: some View {
        let ink = TodayHeroInk(night: night)
        HStack(spacing: 0) {
            ForEach(week.days) { day in
                VStack(spacing: 4) {
                    circle(day, ink: ink)
                    Text(verbatim: label(day))
                        .dxFont(12, weight: day.isToday || day.isQuitDay ? 800 : 600, style: .caption1)
                        .foregroundStyle(day.isQuitDay && !day.isToday ? ink.quitLabel : day.isToday ? ink.ink : ink.muted)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(accessibility(day)))
            }
        }
    }

    private func label(_ day: TodayWeek.Day) -> String {
        if day.isToday { return String(localized: "Today") }
        if day.isQuitDay { return String(localized: "Quit") }
        return day.date.formatted(.dateTime.weekday(.abbreviated))
    }

    private func accessibility(_ day: TodayWeek.Day) -> String {
        let date = day.date.formatted(.dateTime.weekday(.wide).day().month(.wide))
        let isPrepDay = day.date < week.quitDay
        let state: String
        switch day.mark {
        case .done: state = isPrepDay ? String(localized: "a session done") : String(localized: "nicotine-free")
        case .today: state = String(localized: "today")
        case .future, .before, .quiet: state = ""
        }
        let quit = day.isQuitDay ? String(localized: "Quit Day") : ""
        return [date, quit, state].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    @ViewBuilder
    private func circle(_ day: TodayWeek.Day, ink: TodayHeroInk) -> some View {
        let number = Text(verbatim: day.date.formatted(.dateTime.day())).dxFont(15, weight: 700, style: .subheadline)
        ZStack {
            if day.isQuitDay {
                Circle().fill(ink.quit)
                Image(systemName: "flag.fill").font(.system(size: 13, weight: .bold)).foregroundStyle(Color(hex: 0xFFF8EE))
            } else {
                switch day.mark {
                case .done:
                    Circle().fill(ink.done)
                    Image(systemName: "checkmark").font(.system(size: 13, weight: .heavy)).foregroundStyle(ink.onDone)
                case .today:
                    Circle().fill(ink.ink)
                    number.foregroundStyle(night ? Color(hex: 0x0E0B2B) : Color(hex: 0xFFF8EE))
                case .future:
                    Circle().strokeBorder(ink.futureRing, lineWidth: 2)
                    number.foregroundStyle(ink.ink)
                case .quiet:
                    Circle().fill(ink.ink.opacity(0.12))
                    number.foregroundStyle(ink.muted)
                case .before:
                    number.foregroundStyle(ink.muted)
                }
            }
            if day.isToday, day.isQuitDay || day.mark == .done {
                Circle().strokeBorder(ink.ink, lineWidth: 3)
            }
        }
        .frame(width: 38, height: 38)
    }
}

// MARK: Ring

/// The ring in the middle of the sky. During prep, one segment per prep session; after Quit Day, it fills to the next
/// change in the body. The crew sits in the middle: Xero by day, Glim at night.
struct TodayRingView: View {
    enum Fill: Equatable {
        case sessions(done: Int, total: Int, current: Int?)
        /// Nil once every counted change has started: the ring is full.
        case toNextChange(Double?)
    }

    let fill: Fill
    let big: String
    let small: String
    let night: Bool
    let crewStage: Int
    var diameter: CGFloat = 200
    var lineRatio: CGFloat = 0.055

    var body: some View {
        let ink = TodayHeroInk(night: night)
        let lineWidth = diameter * lineRatio
        ZStack {
            Circle().fill(ink.disk).padding(diameter * 0.1)
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = size.width / 2 - lineWidth / 2
                let style = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                func arc(_ from: Double, _ to: Double) -> Path {
                    var path = Path()
                    path.addArc(center: center, radius: radius, startAngle: .degrees(from - 90), endAngle: .degrees(to - 90),
                                clockwise: false)
                    return path
                }
                switch fill {
                case let .sessions(done, total, current):
                    let count = max(total, 1)
                    if count <= 14 {
                        let step = 360.0 / Double(count)
                        let gap = min(7, step * 0.2)
                        for index in 0..<count {
                            let color: Color = index < done ? ink.done : index == current ? ink.ink : ink.track
                            let start = Double(index) * step + gap / 2
                            context.stroke(arc(start, start + step - gap), with: .color(color), style: style)
                        }
                    } else {
                        context.stroke(arc(0, 360), with: .color(ink.track), style: style)
                        if done > 0 {
                            context.stroke(arc(0, 360 * Double(min(done, count)) / Double(count)), with: .color(ink.done), style: style)
                        }
                    }
                case let .toNextChange(fraction):
                    context.stroke(arc(0, 360), with: .color(ink.track), style: style)
                    let value = fraction ?? 1
                    if value > 0 {
                        context.stroke(arc(0, 360 * value), with: .color(ink.done), style: style)
                        if value < 1 {
                            let angle = Angle.degrees(360 * value - 90).radians
                            let end = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
                            let dot = lineWidth * 0.8
                            let rect = CGRect(x: end.x - dot, y: end.y - dot, width: dot * 2, height: dot * 2)
                            context.fill(Path(ellipseIn: rect), with: .color(night ? Color(hex: 0x0E0B2B) : Color(hex: 0xFFF8EE)))
                            context.stroke(Path(ellipseIn: rect), with: .color(ink.done), lineWidth: lineWidth * 0.35)
                        }
                    }
                }
            }
            Circle().fill(ink.crewDisk)
                .frame(width: diameter * 0.46, height: diameter * 0.46)
                .offset(y: diameter * 0.13)
            Group {
                if night {
                    GlimView(mood: .calm, stage: crewStage, points: diameter * 0.42, animate: false)
                } else {
                    XeroView(mood: .hello, stage: crewStage, points: diameter * 0.42, animate: false)
                }
            }
            .frame(width: diameter * 0.42, height: diameter * 0.42)
            .offset(y: diameter * 0.1)
            VStack(spacing: 2) {
                Text(verbatim: big)
                    .dxFont(diameter * 0.15, weight: 800, style: .title1)
                    .foregroundStyle(ink.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
                Text(verbatim: small)
                    .dxFont(13, weight: 700, style: .footnote)
                    .foregroundStyle(ink.muted)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(width: diameter * 0.66)
            .offset(y: -diameter * 0.25)
        }
        .frame(width: diameter, height: diameter)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}

// MARK: Hero

/// What the hero shows, worked out once by Today so the hero and the slim header always agree.
struct TodayHeroModel {
    let night: Bool
    let week: TodayWeek
    let greeting: String
    /// "4 days to Quit Day · Sun, 8 Nov", "Quit Day is today", "Day 4 · 4 of 4 days smoke-free".
    let line: String
    let why: String?
    let profileInitial: String?
    let ring: TodayRingView.Fill
    /// Inside the ring: "4 days", "Today", "3d 14h".
    let ringBig: String
    /// Under it: "2 of 7 done", "free".
    let ringSmall: String
    let ringLabel: String
    /// After Quit Day: "Next: Fresher breath, brighter smile · in 3 days · £24 kept".
    let pill: String?
    /// The slim header's title and line.
    let slimTitle: String
    let slimLine: String
    /// The digit in the slim header's small ring.
    let slimDigit: String
    let crewStage: Int
}

struct TodayHero: View {
    let model: TodayHeroModel
    let topInset: CGFloat
    let onProfile: () -> Void
    /// After Quit Day the ring opens what's changing in the body.
    let onRing: (() -> Void)?

    var body: some View {
        let ink = TodayHeroInk(night: model.night)
        VStack(spacing: 0) {
            TodayWeekStrip(week: model.week, night: model.night)
                .padding(.horizontal, DX.Space.m)
            HStack(alignment: .top, spacing: DX.Space.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: model.greeting)
                        .dxFont(30, weight: 800, style: .title1)
                        .foregroundStyle(ink.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: model.line)
                        .dxFont(17, weight: 700, style: .body)
                        .foregroundStyle(ink.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if let why = model.why {
                        Text(verbatim: "“\(why)”")
                            .dxFont(15, weight: 600, style: .subheadline)
                            .italic()
                            .foregroundStyle(ink.muted)
                            .lineLimit(2)
                            .padding(.top, 2)
                            .accessibilityLabel(Text("Your why: \(why)"))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: onProfile) {
                    Group {
                        if let initial = model.profileInitial {
                            Text(verbatim: initial).dxType(.headline)
                        } else {
                            Image(systemName: "person.fill").font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundStyle(model.night ? Color(hex: 0x1E1A3A) : Color(hex: 0xFFF8EE))
                    .frame(width: 44, height: 44)
                    .background(model.night ? Color(hex: 0xFFF8EE) : Color(hex: 0x1E1A3A), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Profile and settings"))
            }
            .padding(.horizontal, DX.Space.m + 4)
            .padding(.top, 14)
            ring
                .padding(.top, DX.Space.s)
            if let pill = model.pill {
                Text(verbatim: pill)
                    .dxFont(14, weight: 600, style: .footnote)
                    .foregroundStyle(model.night ? Color(hex: 0xFFF8EE) : Color(hex: 0x4A2A1A))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(model.night ? Color(hex: 0xFFF8EE).opacity(0.16) : Color(hex: 0xFFF8EE).opacity(0.92), in: Capsule())
                    .padding(.horizontal, DX.Space.m)
                    .padding(.top, DX.Space.xs)
            }
        }
        .padding(.top, topInset + DX.Space.xs)
        .padding(.bottom, 64)
        .frame(maxWidth: .infinity)
        .background(TodaySky(night: model.night).clipShape(TodaySkyShape()))
    }

    @ViewBuilder
    private var ring: some View {
        let view = TodayRingView(fill: model.ring, big: model.ringBig, small: model.ringSmall, night: model.night,
                                 crewStage: model.crewStage)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(model.ringLabel))
        if let onRing {
            Button(action: onRing) { view }
                .buttonStyle(.plain)
                .accessibilityHint(Text("Opens what changes in your body"))
        } else {
            view
        }
    }
}

/// The hero folded up: a slim card pinned at the top once the sky has scrolled away.
struct TodaySlimHeader: View {
    let model: TodayHeroModel

    var body: some View {
        let ink = TodayHeroInk(night: model.night)
        HStack(spacing: DX.Space.s) {
            ZStack {
                TodayRingView(fill: model.ring, big: "", small: "", night: model.night, crewStage: model.crewStage,
                              diameter: 52, lineRatio: 0.11)
                    .mask {
                        // Just the ring: the disk and the crew are too small to read here.
                        Circle().strokeBorder(lineWidth: 52 * 0.12)
                    }
                Text(verbatim: model.slimDigit)
                    .dxFont(19, weight: 800, style: .headline)
                    .foregroundStyle(ink.ink)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .frame(width: 36)
            }
            .frame(width: 52, height: 52)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: model.slimTitle)
                    .dxFont(22, weight: 800, style: .title2)
                    .foregroundStyle(ink.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(verbatim: model.slimLine)
                    .dxFont(14, weight: 600, style: .footnote)
                    .foregroundStyle(ink.muted)
                    .lineLimit(1).minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                if model.night {
                    GlimView(mood: .calm, stage: model.crewStage, points: 76, animate: false)
                } else {
                    XeroView(mood: .hello, stage: model.crewStage, points: 76, animate: false)
                }
            }
            .frame(width: 76, height: 76)
            .offset(x: 4, y: 22)
            .accessibilityHidden(true)
        }
        .padding(.leading, DX.Space.m)
        .frame(height: 92)
        .background(TodaySky(night: model.night, compact: true))
        .clipShape(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}
