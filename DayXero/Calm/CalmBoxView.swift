import DayXeroCore
import SwiftUI

/// Box breathing (v5, 057): one square track round the sea window, Jelli breathing inside it, the readout under it.
///
/// Motion (057): the dot walks the track at an even pace, 4 s a side (16 s a round), and only the straight side it is on
/// is lit, drawn on the frame line at 1.5× its weight with square ends. At each corner the lit stroke slides on to the
/// next side (400 ms) as the readout word cross-fades (220 ms); the numeral ticks 4 to 1 each second. The window and
/// Jelli swell over the in side, hold, shrink over the out side and hold. The round pips count completed rounds. A soft
/// haptic tick at every corner, nothing else. Four rounds, then done.
struct CalmBoxView: View {
    let startedAt: Date
    let onClose: () -> Void
    let onFinished: () -> Void

    static let rounds = 4
    private static let words: [LocalizedStringKey] = ["Breathe in", "Hold", "Breathe out", "Hold"]
    private static let cues: [LocalizedStringKey] = [
        "In through your nose. Let your belly fill.",
        "Soft and still. Let your shoulders drop.",
        "Out slowly through your mouth.",
        "Rest here. Nothing to do.",
    ]

    private let ground = DX.Ground.reading
    private let motion = MotionPolicy()
    @State private var lit: Double = 0
    @State private var corner = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                DXIconButton(.close, label: "Close", action: onClose)
                Text("Box breathing").dxType(.headline).foregroundStyle(ground.ink)
                    .frame(maxWidth: .infinity)
                    .dxArrive(0)
                Color.clear.frame(width: 44, height: 1)
            }
            .frame(height: 52)
            .padding(.horizontal, -6)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
                let elapsed = max(timeline.date.timeIntervalSince(startedAt), 0)
                content(elapsed: elapsed)
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: corner)
        .task {
            let left = Double(Self.rounds) * 16 - Date.now.timeIntervalSince(startedAt)
            if left > 0 { try? await Task.sleep(for: .seconds(left)) }
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }

    @ViewBuilder
    private func content(elapsed: Double) -> some View {
        let sides = Int(elapsed / 4)
        let side = sides % 4
        let count = 4 - Int(elapsed.truncatingRemainder(dividingBy: 4))
        let done = min(Int(elapsed / 16), Self.rounds)
        GeometryReader { geo in
            let box = min(360, geo.size.width + 2 * DX.Layout.gutter - 30)
            VStack(spacing: 0) {
                square(elapsed: elapsed, side: box)
                    .frame(width: box, height: box)
                    .dxFade(delay: 0.15)
                    .padding(.top, 10)
                Spacer(minLength: 16)
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(Self.words[side])
                        .dxFace(.display, 30, weight: 800, tracking: -0.6)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.22), value: side)
                    Text(verbatim: "\(count)")
                        .dxFace(.display, 64, weight: 800)
                        .monospacedDigit()
                }
                .foregroundStyle(ground.ink)
                .lineLimit(1).minimumScaleFactor(0.7)
                .accessibilityElement(children: .combine)
                .dxArrive(2)
                Text(Self.cues[side])
                    .dxType(.body).foregroundStyle(ground.muted)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.4), value: side)
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .dxArrive(3)
                Spacer(minLength: 16)
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        ForEach(0..<Self.rounds, id: \.self) { i in
                            Circle()
                                .fill(i < done ? ground.ink : .clear)
                                .overlay(Circle().strokeBorder(i < done ? .clear : ground.ink.opacity(0.55), lineWidth: 2))
                                .frame(width: 10, height: 10)
                        }
                    }
                    .accessibilityHidden(true)
                    Text("Round \(min(done + 1, Self.rounds)) of \(Self.rounds)").dxType(.footnote).foregroundStyle(ground.muted)
                }
                .dxArrive(4)
                Spacer(minLength: 16)
                Button("End session", action: onClose)
                    .buttonStyle(.dx(.ghost, on: ground))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .dxArrive(5)
            }
            .frame(maxWidth: .infinity)
        }
        .onChange(of: sides) { _, now in
            corner = now
            if motion.reduce { lit = Double(now) } else { withAnimation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.4)) { lit = Double(now) } }
        }
        .onAppear { lit = Double(sides) }
    }

    /// The window, Jelli, the track, the lit side and the dot, on the mockup's 360 stage.
    private func square(elapsed: Double, side box: CGFloat) -> some View {
        let k = box / 360
        let p = elapsed.truncatingRemainder(dividingBy: 16)
        let swell = motion.breathes ? Self.swell(p) : 1
        let track = BoxTrack.path(scale: k)
        let dot = track.trimmedPath(from: 0, to: max(p / 16, 0.0001)).currentPoint ?? .zero
        return ZStack(alignment: .topLeading) {
            CalmSea()
                .frame(width: 276 * k, height: 276 * k)
                .clipShape(RoundedRectangle(cornerRadius: 22 * k, style: .continuous))
                .scaleEffect(0.78 + 0.22 * swell)
                .offset(x: 42 * k, y: 42 * k)
            JelliView(mood: .breathe, stage: 1, points: 184 * k, animate: motion.breathes)
                .frame(width: 276 * k, height: 276 * k)
                .scaleEffect(0.84 + 0.18 * swell)
                .offset(x: 42 * k, y: 42 * k)
            track.stroke(Self.trackColor, lineWidth: 5 * k)
            BoxLitSide(position: lit, scale: k)
                .stroke(ground.ink, style: StrokeStyle(lineWidth: 7.5 * k, lineCap: .butt))
            ZStack {
                Circle().fill(ground.ink.opacity(0.22)).frame(width: 38 * k, height: 38 * k)
                Circle().fill(ground.background).frame(width: 34 * k, height: 34 * k)
                Circle().fill(ground.ink).frame(width: 24 * k, height: 24 * k)
            }
            .position(dot)
        }
        .frame(width: box, height: box, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    private static let trackColor = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(Color(hex: 0x5D6683)) : UIColor(Color(hex: 0x8E8A9E)) })

    /// 0 (smallest) to 1 (fullest) over a round: swell over the in side, hold, shrink over the out side, hold.
    static func swell(_ p: Double) -> Double {
        func ease(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
        switch p {
        case ..<4: return ease(p / 4)
        case ..<8: return 1
        case ..<12: return 1 - ease((p - 8) / 4)
        default: return 0
        }
    }
}

/// The square track (300 × 300, corners of 32, on a 360 stage), starting at the middle of the bottom-left corner and
/// running up the left side, so each side runs from one corner's middle to the next.
enum BoxTrack {
    /// Each side's straight run starts this far into its quarter (half a corner) and lasts `straight` of it.
    static let lead = 25.13 / 286.27
    static let straight = 236 / 286.27

    static func path(scale k: CGFloat) -> Path {
        var p = Path()
        let r = 32 * k
        let lo = 62 * k, hi = 298 * k
        p.move(to: CGPoint(x: lo - r * cos(.pi / 4), y: hi + r * sin(.pi / 4)))
        p.addArc(center: CGPoint(x: lo, y: hi), radius: r, startAngle: .degrees(135), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: 30 * k, y: lo))
        p.addArc(center: CGPoint(x: lo, y: lo), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.addLine(to: CGPoint(x: hi, y: 30 * k))
        p.addArc(center: CGPoint(x: hi, y: lo), radius: r, startAngle: .degrees(270), endAngle: .degrees(360), clockwise: false)
        p.addLine(to: CGPoint(x: 330 * k, y: hi))
        p.addArc(center: CGPoint(x: hi, y: hi), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: lo, y: 330 * k))
        p.addArc(center: CGPoint(x: lo, y: hi), radius: r, startAngle: .degrees(90), endAngle: .degrees(135), clockwise: false)
        return p
    }
}

/// The lit straight side. `position` counts sides walked, so it only ever moves forward round the square.
struct BoxLitSide: Shape {
    var position: Double
    let scale: CGFloat

    nonisolated var animatableData: Double {
        get { position }
        set { position = newValue }
    }

    nonisolated func path(in rect: CGRect) -> Path {
        let track = BoxTrack.path(scale: scale)
        let from = (position.truncatingRemainder(dividingBy: 4) + BoxTrack.lead) / 4
        let to = from + BoxTrack.straight / 4
        var p = track.trimmedPath(from: from, to: min(to, 1))
        if to > 1 { p.addPath(track.trimmedPath(from: 0, to: to - 1)) }
        return p
    }
}
