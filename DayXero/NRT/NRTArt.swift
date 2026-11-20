import DayXeroCore
import SwiftUI

// v5 art for NRT setup and the pouch taper (kit screens 047–052): the duotone product glyphs, the step-down
// silhouettes on the schedule list, the plan's step chart and the taper chart with its Day Xero marker.

/// The apricot tints the NRT screens share (kit `.gl`, `--t1…3`, `--edge`).
enum NRTPalette {
    static let accent = Color(light: 0xFFB27F, dark: 0xF39A62)
    static let accent2 = Color(light: 0xFFDCC4, dark: 0xFFD3B4)
    static let tints: [Color] = [Color(hex: 0xFFAD70), Color(hex: 0xFFC190), Color(hex: 0xFFD3AE)]
    /// One apricot for every taper bar; the heights carry the mg.
    static let bar = Color(hex: 0xFFB27A)
    /// A deeper edge in light so the palest bar holds 3:1 on the card; dark needs none on the plan chart.
    static let edge = Color(light: (0xD9692A, 1), dark: (0xD9692A, 0))
    static let taperEdge = Color(light: 0xD9692A, dark: 0xFFB27A)
    static let stripe = Color(light: 0xF59A5C, dark: 0xFFB27A)
    static let stripeGround = Color(light: 0xFFF1E6, dark: 0xFFDFC6)
    /// The "the extra" label under the evidence bar.
    static let extra = Color(light: 0xC8561F, dark: 0xFFB27A)

    static func tint(_ index: Int) -> Color { tints[min(index, tints.count - 1)] }
}

// MARK: - Glyphs

/// The bespoke duotone glyphs: apricot fills under an ink line, on the kit's 24 × 24 grid.
struct NRTGlyph: View {
    enum Kind { case patch, gum, lozenge, inhaler, steps }
    let kind: Kind
    var size: CGFloat = 32
    @Environment(\.dxGround) private var ground

    init(_ kind: Kind, size: CGFloat = 32) {
        self.kind = kind
        self.size = size
    }

    init(_ type: NRTType, size: CGFloat = 32) {
        switch type {
        case .patch: self.init(Kind.patch, size: size)
        case .gum: self.init(Kind.gum, size: size)
        case .lozenge: self.init(Kind.lozenge, size: size)
        case .inhaler: self.init(Kind.inhaler, size: size)
        }
    }

    var body: some View {
        let ink = ground.resolved.ink
        ZStack {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                if let fill = part.fill { part.shape.fill(fill) }
                part.shape.stroke(ink.opacity(part.lineOpacity),
                                  style: StrokeStyle(lineWidth: part.lineWidth * size / 24, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private struct Part {
        let shape: Grid24
        var fill: Color?
        var lineOpacity = 1.0
        var lineWidth = 1.7
    }

    private var parts: [Part] {
        let a = NRTPalette.accent, b = NRTPalette.accent2
        switch kind {
        case .patch:
            let r = Grid24.rotation(-8, 12, 12)
            return [
                Part(shape: Grid24(svg: "M7.2 3.8h9.6a3.4 3.4 0 013.4 3.4v8.4l-4.6 4.6H7.2a3.4 3.4 0 01-3.4-3.4V7.2a3.4 3.4 0 013.4-3.4z", r), fill: b),
                Part(shape: Grid24(svg: "M20.2 15.6h-3.2a1.4 1.4 0 00-1.4 1.4v3.2z", r), fill: a),
                Part(shape: Grid24(Path(ellipseIn: CGRect(x: 7.7, y: 7.7, width: 7.4, height: 7.4)), r), fill: a),
            ]
        case .gum:
            return [
                Part(shape: Grid24(Path(roundedRect: CGRect(x: 3, y: 5, width: 13, height: 8), cornerRadius: 4), Grid24.rotation(-12, 9.5, 9)), fill: b),
                Part(shape: Grid24(Path(roundedRect: CGRect(x: 8, y: 11, width: 13, height: 8), cornerRadius: 4), Grid24.rotation(-12, 14.5, 15)), fill: a),
                Part(shape: Grid24(svg: "M12 13.6l5.4-1.1"), lineOpacity: 0.5),
            ]
        case .lozenge:
            return [
                Part(shape: Grid24(Path(ellipseIn: CGRect(x: 3.5, y: 6.5, width: 17, height: 13))), fill: b),
                Part(shape: Grid24(Path(ellipseIn: CGRect(x: 3.5, y: 5, width: 17, height: 13))), fill: a),
                Part(shape: Grid24(svg: "M7.5 11.5h9"), lineOpacity: 0.5),
            ]
        case .inhaler:
            let r = Grid24.rotation(35, 12, 12)
            return [
                Part(shape: Grid24(svg: "M8.6 9.4L3.6 10.3a1.7 1.7 0 000 3.4l5 .9z", r), fill: b),
                Part(shape: Grid24(Path(roundedRect: CGRect(x: 8.6, y: 7.6, width: 13, height: 8.8), cornerRadius: 4.4), r), fill: a),
                Part(shape: Grid24(svg: "M13.4 7.6v8.8", r), lineOpacity: 0.55),
            ]
        case .steps:
            return [
                Part(shape: Grid24(Path(roundedRect: CGRect(x: 3.5, y: 5, width: 17, height: 15.5), cornerRadius: 3.5)), fill: b),
                Part(shape: Grid24(svg: "M3.5 9.8V8.5A3.5 3.5 0 017 5h10a3.5 3.5 0 013.5 3.5v1.3z"), fill: a),
                Part(shape: Grid24(svg: "M8 3v3.6M16 3v3.6")),
                Part(shape: Grid24(svg: "M6.6 18v-5.4h3.7V18zM10.3 18v-3.5h3.6V18zM13.9 18v-1.8h3.5V18z"), fill: a, lineWidth: 1.3),
            ]
        }
    }
}

/// A path on the 24 × 24 grid, scaled to the frame.
struct Grid24: Shape {
    let base: Path

    init(_ path: Path, _ transform: CGAffineTransform = .identity) {
        base = path.applying(transform)
    }

    init(svg d: String, _ transform: CGAffineTransform = .identity) {
        self.init(SVGPath.path(d), transform)
    }

    static func rotation(_ degrees: Double, _ cx: CGFloat, _ cy: CGFloat) -> CGAffineTransform {
        CGAffineTransform(translationX: cx, y: cy).rotated(by: degrees * .pi / 180).translatedBy(x: -cx, y: -cy)
    }

    func path(in rect: CGRect) -> Path {
        base.applying(CGAffineTransform(scaleX: rect.width / 24, y: rect.height / 24)).offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

/// A glyph in its tile (kit `.ico-tile`): card-2, turning white on a selected row in light so it holds on the tint.
struct NRTGlyphTile: View {
    let glyph: NRTGlyph
    var selected = false
    var tile: CGFloat = 46
    @Environment(\.dxGround) private var ground

    var body: some View {
        glyph
            .frame(width: tile, height: tile)
            .background(selected ? Color(light: 0xFFFFFF, dark: 0x212A41) : ground.resolved.card2,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(.easeOut(duration: 0.3), value: selected)
    }
}

// MARK: - Step-down silhouette

/// The schedule list's 72 × 36 step-down shape in an 88 × 56 tile: the steps butted together on a hairline
/// baseline, widths by weeks, heights by mg. Empty draws the dashed frame of "Something else".
struct StairGlyph: View {
    /// (weeks, height 0…1) per step.
    let steps: [(weeks: Int, height: Double)]
    var selected = false
    @Environment(\.dxGround) private var ground

    static func shape(for steps: [PlanStep]) -> [(weeks: Int, height: Double)] {
        let most = steps.map(\.strengthMg).max() ?? 0
        if most > 0 {
            let scale = max(most, 21)
            return steps.map { ($0.weeks, $0.strengthMg / scale) }
        }
        // Gum and lozenges keep one strength and step down how often: a gentle stair by position.
        return steps.enumerated().map { i, s in (s.weeks, Double(steps.count - i) / Double(steps.count) * 0.8) }
    }

    var body: some View {
        let g = ground.resolved
        ZStack {
            if steps.isEmpty {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(g.ink.opacity(0.4), style: StrokeStyle(lineWidth: 1.6, dash: [4, 3.5]))
                    .frame(width: 70, height: 34)
            } else {
                let fill = selected ? Color(light: 0xFFB98A, dark: 0xFFB27A) : Color(light: (0xFFB98A, 0.3), dark: (0xFFB27A, 0))
                let outline = selected ? Color(light: 0xB4531E, dark: 0xFFE3C8) : Color(light: 0xF08A4B, dark: 0xFFB27A)
                StairShape(steps: steps, closed: true).fill(fill)
                StairShape(steps: steps, closed: false)
                    .stroke(outline, style: StrokeStyle(lineWidth: selected ? 2 : 1.8, lineCap: .round, lineJoin: .round))
                Path { p in p.move(to: CGPoint(x: -2, y: 35.5)); p.addLine(to: CGPoint(x: 74, y: 35.5)) }
                    .stroke(g.ink.opacity(0.45), lineWidth: 1)
            }
        }
        .frame(width: 72, height: 36)
        .frame(width: 88, height: 56)
        .background(selected ? Color(light: 0xFFFFFF, dark: 0x212A41) : g.card2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.easeOut(duration: 0.3), value: selected)
        .accessibilityHidden(true)
    }
}

private struct StairShape: Shape {
    let steps: [(weeks: Int, height: Double)]
    let closed: Bool

    func path(in rect: CGRect) -> Path {
        let total = Double(max(steps.reduce(0) { $0 + $1.weeks }, 10))
        let base = rect.height - 1
        var p = Path()
        p.move(to: CGPoint(x: 0, y: base))
        var x = 0.0
        for step in steps {
            let y = base - step.height * (rect.height - 5)
            p.addLine(to: CGPoint(x: x, y: y))
            x += Double(step.weeks) / total * rect.width
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.addLine(to: CGPoint(x: x, y: base))
        if closed { p.closeSubpath() }
        return p
    }
}

// MARK: - Evidence bars (047)

/// "Without" and "With NRT": no full-scale track, the two bars only compare with each other; the deeper tail of
/// the NRT bar is the extra, labelled under it.
struct NRTEvidenceBars: View {
    @State private var grown = false
    private let motion = MotionPolicy()
    @Environment(\.dxGround) private var ground

    var body: some View {
        let g = ground.resolved
        VStack(alignment: .leading, spacing: 12) {
            row("Without", width: 0.56, delay: 0.5) { Capsule().fill(g.muted.opacity(0.45)) }
            row("With NRT", width: 0.9, delay: 0.65) {
                GeometryReader { proxy in
                    HStack(spacing: 0) {
                        Color(hex: 0xFFC9A3).frame(width: proxy.size.width * 0.625)
                        Color(hex: 0xFF8A4C)
                    }
                    .clipShape(Capsule())
                }
            }
            HStack(spacing: 10) {
                Color.clear.frame(width: 76, height: 1)
                GeometryReader { proxy in
                    Text("the extra")
                        .dxFace(.body, 13, weight: 700)
                        .foregroundStyle(NRTPalette.extra)
                        .frame(width: proxy.size.width * 0.34)
                        .offset(x: proxy.size.width * 0.56)
                }
                .frame(height: 14)
                .dxFade(delay: 1.3)
            }
            .padding(.top, -4)
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .onAppear {
            if motion.reduce { grown = true } else { withAnimation(DX.Move.settle) { grown = true } }
        }
        .accessibilityHidden(true)
    }

    private func row(_ label: LocalizedStringKey, width: CGFloat, delay: Double, @ViewBuilder bar: () -> some View) -> some View {
        let content = bar()
        return HStack(spacing: 10) {
            Text(label).dxFace(.body, 14, weight: 500).frame(width: 76, alignment: .leading)
            GeometryReader { proxy in
                content
                    .frame(width: proxy.size.width * width, height: 14)
                    .scaleEffect(x: grown ? 1 : 0.001, anchor: .leading)
                    .animation(motion.reduce ? nil : DX.Move.settle.delay(delay - 0.5), value: grown)
            }
            .frame(height: 14)
        }
    }
}

// MARK: - Plan chart (050)

/// The plan's steps as solid apricot bars: widths by weeks, heights by mg, the mg above and the weeks below.
struct NRTStepChart: View {
    let steps: [PlanStep]
    @State private var grown = false
    private let motion = MotionPolicy()

    var body: some View {
        let total = max(steps.reduce(0) { $0 + $1.weeks }, 1)
        let heights = Self.heights(steps)
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let gap: CGFloat = 8
                let usable = proxy.size.width - gap * CGFloat(max(steps.count - 1, 0))
                HStack(alignment: .bottom, spacing: gap) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                        let width = usable * CGFloat(step.weeks) / CGFloat(total)
                        UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 4, bottomTrailingRadius: 4, topTrailingRadius: 12,
                                               style: .continuous)
                            .fill(NRTPalette.tint(i))
                            .overlay(UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 4, bottomTrailingRadius: 4,
                                                            topTrailingRadius: 12, style: .continuous)
                                .strokeBorder(NRTPalette.edge, lineWidth: 1.5))
                            .frame(width: width, height: proxy.size.height * heights[i])
                            .overlay(alignment: .top) {
                                Text(verbatim: label(step))
                                    .dxFace(.display, 15, weight: 700, tracking: -0.3)
                                    .lineLimit(1).minimumScaleFactor(0.6)
                                    .fixedSize(horizontal: width > 56, vertical: false)
                                    .frame(minWidth: width)
                                    .offset(y: -22)
                            }
                            .scaleEffect(y: grown ? 1 : 0.001, anchor: .bottom)
                            .animation(motion.reduce ? nil : DX.Move.settle.delay(0.25 + Double(i) * 0.15), value: grown)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 102)
            .overlay(alignment: .bottom) { Rectangle().fill(DX.Ground.reading.line).frame(height: 1.5) }
            .padding(.top, 28)
            GeometryReader { proxy in
                let gap: CGFloat = 8
                let usable = proxy.size.width - gap * CGFloat(max(steps.count - 1, 0))
                HStack(spacing: gap) {
                    ForEach(Array(weekRanges.enumerated()), id: \.offset) { i, text in
                        Text(verbatim: text)
                            .dxType(.caption).foregroundStyle(DX.Ground.reading.muted)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .frame(width: usable * CGFloat(steps[i].weeks) / CGFloat(total))
                    }
                }
            }
            .frame(height: 18)
        }
        .onAppear {
            if motion.reduce { grown = true } else { withAnimation { grown = true } }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: steps.map { "\(label($0)), \($0.weeks) weeks" }.joined(separator: "; ")))
    }

    static func heights(_ steps: [PlanStep]) -> [CGFloat] {
        let most = steps.map(\.strengthMg).max() ?? 0
        if most > 0 { return steps.map { max(0.3, CGFloat($0.strengthMg / most)) } }
        return steps.indices.map { CGFloat(steps.count - $0) / CGFloat(steps.count) * 0.9 + 0.1 }
    }

    private func label(_ step: PlanStep) -> String {
        step.strengthMg > 0 ? NRTReminderPlan.strength(step.strengthMg) : (step.note ?? "")
    }

    private var weekRanges: [String] {
        var start = 1
        return steps.enumerated().map { i, step in
            let end = start + step.weeks - 1
            defer { start = end + 1 }
            let range = step.weeks == 1 ? "\(start)" : String(localized: "\(start) to \(end)")
            return i == 0 ? (step.weeks == 1 ? String(localized: "Week \(start)") : String(localized: "Weeks \(range)")) : range
        }
    }
}

// MARK: - Taper chart (052)

/// The pouch taper: one bar per step plus the 0 mg column; the coral dot is Day Xero on the axis, and the part of
/// the taper that runs past it is striped. When it doesn't fit, a target ring marks the Day Xero that would.
struct TaperChart: View {
    let schedule: StepSchedule
    let quitDay: Date
    let fits: Bool
    let clock: DayClock
    @State private var grown = false
    private let motion = MotionPolicy()
    @Environment(\.dxGround) private var ground

    private static let barHeight: CGFloat = 112
    private static let gap: CGFloat = 8

    var body: some View {
        let g = ground.resolved
        let spans = schedule.spans
        let most = max(spans.map(\.step.strengthMg).max() ?? 1, 0.1)
        let quit = quitPosition
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 18) {
                HStack(spacing: 6) {
                    Circle().fill(g.mark).frame(width: 11, height: 11)
                    Text("Day Xero")
                }
                if !fits {
                    HStack(spacing: 6) {
                        Hatch().frame(width: 18, height: 12)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(NRTPalette.taperEdge, lineWidth: 1.5))
                        Text("Runs past Day Xero")
                    }
                }
            }
            .dxFace(.body, 14, weight: 500)
            .foregroundStyle(g.muted)
            .lineLimit(1).minimumScaleFactor(0.8)
            GeometryReader { proxy in
                let columns = spans.count + 1
                let colW = (proxy.size.width - Self.gap * CGFloat(columns - 1)) / CGFloat(columns)
                let x = { (col: Int, f: Double) in CGFloat(col) * (colW + Self.gap) + colW * f }
                let base = proxy.size.height
                let qx = x(quit.column, quit.fraction)
                ZStack {
                    ForEach(Array(spans.enumerated()), id: \.offset) { i, span in
                        let h = max(Self.barHeight * span.step.strengthMg / most, 6)
                        bar(height: h, past: pastFraction(of: i, quit: quit))
                            .frame(width: colW)
                            .scaleEffect(y: grown ? 1 : 0.001, anchor: .bottom)
                            .animation(motion.reduce ? nil : DX.Move.settle.delay(0.25 + Double(i) * 0.15), value: grown)
                            .position(x: x(i, 0.5), y: base - h / 2)
                    }
                    // The 0 mg column: a short track, and the ring Day Xero would move into.
                    UnevenRoundedRectangle(topLeadingRadius: 3, topTrailingRadius: 3)
                        .fill(g.track)
                        .frame(width: colW, height: 4)
                        .position(x: x(spans.count, 0.5), y: base - 2)
                    if !fits {
                        Circle().fill(g.card)
                            .overlay(Circle().strokeBorder(g.mark, lineWidth: 2.5))
                            .overlay(Circle().fill(g.mark.opacity(0.45)).padding(5))
                            .frame(width: 18, height: 18)
                            .position(x: x(spans.count, 0.5), y: base + 1)
                            .dxFade(delay: 1.0)
                    }
                    // Day Xero: a coral hairline up from the axis to its date tag, and the dot on the axis.
                    ZStack {
                        Capsule().fill(g.mark).frame(width: 2, height: 120)
                            .position(x: qx, y: base - 60)
                        Circle().fill(g.mark)
                            .overlay(Circle().strokeBorder(g.card, lineWidth: 2.5).padding(-2.5))
                            .frame(width: 13, height: 13)
                            .position(x: qx, y: base + 1)
                        Text(verbatim: quitDay.formatted(.dateTime.weekday(.abbreviated).day()))
                            .dxFace(.body, 13, weight: 700)
                            .foregroundStyle(DX.Fill.navy)
                            .padding(.horizontal, 8)
                            .frame(height: 22)
                            .background(g.mark, in: Capsule())
                            .fixedSize()
                            .position(x: qx, y: base - 131)
                    }
                    .dxPop(delay: 0.9)
                    .animation(motion.animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.7)), value: qx)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .frame(height: Self.barHeight)
            .overlay(alignment: .bottom) { Rectangle().fill(g.line).frame(height: 2).offset(y: 1) }
            .padding(.top, 38)
            HStack(alignment: .top, spacing: Self.gap) {
                ForEach(Array(spans.enumerated()), id: \.offset) { _, span in
                    axisLabel(NRTReminderPlan.strength(span.step.strengthMg), span.start)
                }
                axisLabel(NRTReminderPlan.strength(0), schedule.end ?? quitDay)
            }
            .padding(.top, 8)
        }
        .onAppear {
            if motion.reduce { grown = true } else { withAnimation { grown = true } }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilitySummary))
    }

    private func axisLabel(_ mg: String, _ date: Date) -> some View {
        VStack(spacing: 1) {
            Text(verbatim: mg).dxFace(.display, 15, weight: 800).foregroundStyle(ground.resolved.ink)
            Text(verbatim: date.formatted(.dateTime.month(.abbreviated).day())).dxType(.caption).foregroundStyle(ground.resolved.muted)
        }
        .lineLimit(1).minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
    }

    private func bar(height: CGFloat, past: Double) -> some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 3, bottomTrailingRadius: 3, topTrailingRadius: 10,
                                           style: .continuous)
        return GeometryReader { proxy in
            HStack(spacing: 0) {
                NRTPalette.bar.frame(width: proxy.size.width * (1 - past))
                Hatch()
            }
        }
        .frame(height: max(height, 6))
        .clipShape(shape)
        .overlay(shape.strokeBorder(NRTPalette.taperEdge, lineWidth: 1.5))
        .animation(motion.animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.7)), value: past)
    }

    /// Where Day Xero falls: the column and how far into it. Past the last step it sits in the 0 mg column's middle.
    private var quitPosition: (column: Int, fraction: Double) {
        let cal = clock.calendar
        let quit = clock.startOfDate(quitDay)
        for (i, span) in schedule.spans.enumerated() where quit < span.end {
            let days = Double(cal.dateComponents([.day], from: span.start, to: quit).day ?? 0)
            let length = Double(max(span.step.weeks * 7, 1))
            return (i, min(max(days / length, 0), 1))
        }
        return (schedule.spans.count, 0.5)
    }

    private func pastFraction(of index: Int, quit: (column: Int, fraction: Double)) -> Double {
        if index < quit.column { return 0 }
        if index == quit.column { return 1 - quit.fraction }
        return 1
    }

    private var accessibilitySummary: String {
        let steps = schedule.spans.map { NRTReminderPlan.strength($0.step.strengthMg) }.joined(separator: ", ")
        let quit = quitDay.formatted(.dateTime.weekday(.wide).day().month())
        return fits ? String(localized: "Steps \(steps), ending before Day Xero, \(quit).")
            : String(localized: "Steps \(steps). Day Xero, \(quit), comes before the taper ends.")
    }
}

/// Runs past Day Xero: the bar's own apricot in diagonal stripes.
private struct Hatch: View {
    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            var x = -size.height
            while x < size.width + size.height {
                p.move(to: CGPoint(x: x, y: size.height))
                p.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += 6.5
            }
            ctx.stroke(p, with: .color(NRTPalette.stripe), lineWidth: 3)
        }
        .background(NRTPalette.stripeGround)
    }
}
