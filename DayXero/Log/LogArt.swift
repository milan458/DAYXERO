import DayXeroCore
import SwiftUI

/// A small paper-cut object where an icon would sit on the log menu (v5, 041): a vape, a cigarette or a pouch tin, in
/// quiet cream and slate with a soft lift shadow.
struct PaperUseObject: View {
    let product: Product
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Canvas { ctx, size in
            let dark = scheme == .dark
            ctx.scaleBy(x: size.width / 34, y: size.height / 34)
            ctx.addFilter(.shadow(color: Color(hex: 0x1A0B2E).opacity(dark ? 0.55 : 0.2), radius: 1.2, x: 0, y: 1.4))
            let a: UInt32 = dark ? 0xC9C2B4 : 0xE9E1D3
            let b: UInt32 = dark ? 0x9E97A8 : 0xC9C0B2
            let c: UInt32 = dark ? 0x6E7896 : 0x8B8698
            let tip: UInt32 = dark ? 0xD8A48E : 0xE2A68C
            switch product {
            case .vape:
                var g = ctx
                g.translateBy(x: 17, y: 18); g.rotate(by: .degrees(-18)); g.translateBy(x: -17, y: -18)
                g.fill(Path(roundedRect: CGRect(x: 12.5, y: 4, width: 9, height: 6), cornerRadius: 2.2), with: .color(Color(hex: dark ? c : 0x5E5874)))
                g.fill(Path(roundedRect: CGRect(x: 11, y: 9, width: 12, height: 22), cornerRadius: 3.6), with: .color(Color(hex: dark ? a : 0xB4ADC2)))
                g.fill(Path(roundedRect: CGRect(x: 11, y: 9, width: 5, height: 22), cornerRadius: 2.6), with: .color(Color(hex: dark ? b : 0x857D99).opacity(0.6)))
                g.fill(CalmPaint.circle(17, 15.5, 1.7), with: .color(Color(hex: dark ? c : 0xFFB27A)))
            case .cigarettes:
                var g = ctx
                g.translateBy(x: 17, y: 17); g.rotate(by: .degrees(-24)); g.translateBy(x: -17, y: -17)
                g.fill(Path(roundedRect: CGRect(x: 3, y: 14, width: 28, height: 6.4), cornerRadius: 3.2), with: .color(Color(hex: a)))
                g.fill(Path(roundedRect: CGRect(x: 3, y: 14, width: 9, height: 6.4), cornerRadius: 3.2), with: .color(Color(hex: tip)))
                g.fill(Path(CGRect(x: 9, y: 14, width: 3, height: 6.4)), with: .color(Color(hex: tip)))
                g.stroke(SVGPath.path("M30 13 c2 -2 0 -4 2 -6"), with: .color(Color(hex: c).opacity(0.7)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            case .pouches:
                ctx.fill(CalmPaint.ellipse(17, 21, 13, 7), with: .color(Color(hex: b)))
                ctx.fill(CalmPaint.ellipse(17, 17, 13, 7), with: .color(Color(hex: a)))
                ctx.fill(CalmPaint.ellipse(17, 17, 8, 4), with: .color(Color(hex: c).opacity(0.35)))
            }
        }
        .accessibilityHidden(true)
    }
}

/// The evening check-in's little moons (v5, 042, 054): craters and a crescent shadow on each, in a calm non-emoji
/// palette: a navy Rough with cream features and tired lids, a cream Okay, a pale apricot Good, an apricot Proud.
struct MoodMoon: View {
    let mood: CheckInMood

    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 48, y: size.height / 48)
            let ink = Color(hex: 0x0F1B33), cream = Color(hex: 0xF6EFE2)
            let (c, sh, cr, ol): (UInt32, UInt32, UInt32, UInt32?) = switch mood {
            case .rough: (0x4C5C88, 0x26335A, 0x33416C, nil)
            case .okay: (0xEFE5CF, 0xBFAE8A, 0xD2C3A2, 0x8F7C55)
            case .good: (0xFFD8B0, 0xE9A673, 0xF2BF92, nil)
            case .proud: (0xFFB27A, 0xDC7E4E, 0xEE9A66, nil)
            }
            let disc = CalmPaint.circle(24, 25, 21)
            ctx.fill(disc, with: .color(Color(hex: c)))
            if let ol { ctx.stroke(disc, with: .color(Color(hex: ol)), lineWidth: 2) }
            CalmPaint.fill(&ctx, "M24 4 A21 21 0 0 1 24 46 A13 21 0 0 0 24 4Z", sh, opacity: 0.5)
            for (x, y, r) in [(13.0, 13.5, 2.6), (34.5, 12, 1.9), (37, 37.5, 2.3), (9.5, 34, 1.4)] {
                ctx.fill(CalmPaint.circle(x, y, r), with: .color(Color(hex: cr)))
            }
            ctx.stroke(SVGPath.path("M8 18a17 17 0 0 1 10-11"), with: .color(.white.opacity(0.45)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            let round = StrokeStyle(lineWidth: 2.6, lineCap: .round)
            func cheeks() {
                ctx.fill(CalmPaint.circle(12.5, 29, 3.2), with: .color(Color(hex: 0xFF8C6B).opacity(0.55)))
                ctx.fill(CalmPaint.circle(35.5, 29, 3.2), with: .color(Color(hex: 0xFF8C6B).opacity(0.55)))
            }
            switch mood {
            case .rough:
                ctx.fill(SVGPath.path("M15 22.6a3 3 0 0 0 6 .4zM27 23a3 3 0 0 0 6-.4z"), with: .color(cream))
                ctx.stroke(SVGPath.path("M13.6 23.6l8-1.6M26.4 22l8 1.6"), with: .color(cream), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                ctx.stroke(SVGPath.path("M15.2 29q2.5 1.3 5 0M27.8 29q2.5 1.3 5 0"), with: .color(cream.opacity(0.35)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                ctx.fill(CalmPaint.ellipse(24, 34.6, 2.4, 2), with: .color(cream))
            case .okay:
                ctx.fill(CalmPaint.circle(18, 22.5, 2.3), with: .color(ink))
                ctx.fill(CalmPaint.circle(30, 22.5, 2.3), with: .color(ink))
                ctx.stroke(SVGPath.path("M18 32h12"), with: .color(ink), style: round)
            case .good:
                cheeks()
                ctx.fill(CalmPaint.circle(18, 22, 2.4), with: .color(ink))
                ctx.fill(CalmPaint.circle(30, 22, 2.4), with: .color(ink))
                ctx.stroke(SVGPath.path("M16.5 29c3 5 12 5 15 0"), with: .color(ink), style: round)
            case .proud:
                cheeks()
                ctx.stroke(SVGPath.path("M14 23c1.8-3 5.2-3 7 0M27 23c1.8-3 5.2-3 7 0"), with: .color(ink), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                ctx.fill(SVGPath.path("M15.5 28.5h17c0 5.5-3.8 8.5-8.5 8.5s-8.5-3-8.5-8.5z"), with: .color(ink))
                ctx.stroke(SVGPath.path("M19.5 33.5c2.6 1.6 6.4 1.6 9 0"), with: .color(Color(hex: 0xFF8C6B)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                CalmPaint.fill(&ctx, "M41 4l1.2 2.6 2.6 1.2-2.6 1.2L41 11.6l-1.2-2.6-2.6-1.2 2.6-1.2z", 0xF5B83D)
            }
        }
        .accessibilityHidden(true)
    }
}

/// How strong a craving is (v5, 042): "5 of 10 · Moderate" beside the question, a track filling in Jelli's pink to an
/// apricot-ringed knob along ten step ticks, Mild and Intense under it. The fill slides in to its value on appear.
struct CravingStrengthSlider: View {
    @Binding var value: Int
    @State private var shown = false
    @GestureState private var dragging = false
    private let ground = DX.Ground.reading
    private let motion = MotionPolicy()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("How strong is it?").dxType(.headline).foregroundStyle(ground.ink)
                Spacer(minLength: 8)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(verbatim: "\(value)").dxFace(.display, 26, weight: 800, tracking: -0.5).foregroundStyle(ground.ink)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(value)))
                    Text("of 10 · \(Text(DXCravingSlider.word(for: value)))").dxFont(15, weight: 600, style: .subheadline)
                        .foregroundStyle(ground.muted)
                }
            }
            .padding(.bottom, 10)
            GeometryReader { geo in
                let w = geo.size.width
                let p = CGFloat(shown ? value - 1 : 0) / 9
                ZStack(alignment: .topLeading) {
                    Capsule().fill(ground.track).frame(height: 6).offset(y: 13)
                    Capsule().fill(Color(light: 0xE8607E, dark: 0xFF8FA3)).frame(width: max(6, w * p + 2), height: 6).offset(y: 13)
                    ForEach(0..<10, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2).fill(ground.muted.opacity(0.55))
                            .frame(width: 2, height: 7)
                            .offset(x: w * CGFloat(i) / 9 - 1, y: 25)
                    }
                    Circle().fill(.white)
                        .overlay(Circle().strokeBorder(Color(hex: 0xFFA766), lineWidth: 5))
                        .frame(width: 28, height: 28)
                        .shadow(color: Color(hex: 0x0E0B2B).opacity(0.25), radius: 4, y: 2)
                        .scaleEffect(dragging ? 1.1 : 1)
                        .offset(x: w * p - 14, y: 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($dragging) { _, state, _ in state = true }
                        .onChanged { g in
                            let raw = g.location.x / max(w, 1)
                            value = Int((min(max(raw, 0), 1) * 9).rounded()) + 1
                        }
                )
            }
            .frame(height: 36)
            .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.7), value: shown)
            .animation(DX.Move.settle, value: value)
            HStack {
                Text("Mild")
                Spacer()
                Text("Intense")
            }
            .dxFont(14, weight: 600, style: .footnote)
            .foregroundStyle(ground.muted)
        }
        .sensoryFeedback(DX.Haptic.select, trigger: value)
        .onAppear {
            if motion.reduce { shown = true; return }
            Task { try? await Task.sleep(for: .milliseconds(350)); shown = true }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Craving strength"))
        .accessibilityValue(Text("\(value) of 10, \(Text(DXCravingSlider.word(for: value)))"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(value + 1, 10)
            case .decrement: value = max(value - 1, 1)
            @unknown default: break
            }
        }
    }
}
