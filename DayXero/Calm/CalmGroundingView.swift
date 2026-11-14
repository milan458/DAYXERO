import DayXeroCore
import SwiftUI

/// 5-4-3-2-1 grounding (v5, 058): one sense per step on a card, Jelli seated on its top edge, a pip to tap for each thing
/// noticed, and Next in the dock.
///
/// Motion (058): the step card arrives and Jelli settles onto its top edge (500 ms), her soft contact shadow fading in
/// under her; then a slow calm float (5 s), the shadow narrowing and fading as she lifts. A tapped pip fills with a small
/// bump and a light haptic. Next waits outlined (full-contrast label) and fills to the primary ink in 300 ms when the
/// last pip fills, with a soft success haptic. Tapping Next fills the bar's segment and the next step slides in from the
/// right.
struct CalmGroundingView: View {
    @Binding var step: Int
    @Binding var ticked: Int
    let onClose: () -> Void
    let onFinished: () -> Void

    private let ground = DX.Ground.reading
    private let motion = MotionPolicy()
    @Environment(\.colorScheme) private var scheme

    private var current: Grounding.Step { Grounding.steps[min(step, Grounding.steps.count - 1)] }
    private var full: Bool { ticked >= current.count }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                DXIconButton(.close, label: "Close", action: onClose)
                // Done steps and this one are filled whole; tapping Next fills the next segment (500 ms).
                HStack(spacing: 5) {
                    ForEach(0..<Grounding.steps.count, id: \.self) { i in
                        Capsule().fill(i <= step ? ground.ink : ground.track).frame(height: 6)
                    }
                }
                .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.5), value: step)
                    .padding(.trailing, 56)
                    .accessibilityElement()
                    .accessibilityLabel(Text("Step \(step + 1) of \(Grounding.steps.count)"))
            }
            .frame(height: 52)
            .padding(.horizontal, -6)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("5-4-3-2-1 grounding").dxType(.footnote).foregroundStyle(ground.muted)
                        .padding(.top, 12)
                        .dxArrive(0)
                    stepCard
                        .id(step)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))
                        .padding(.top, 190)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.bottom, DX.Space.m)
            }
            .padding(.horizontal, -DX.Layout.gutter)
            .scrollBounceBehavior(.basedOnSize)

            Button(nextTitle) {
                if step + 1 < Grounding.steps.count {
                    withAnimation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.5)) {
                        ticked = 0
                        step += 1
                    }
                } else {
                    onFinished()
                }
            }
            .buttonStyle(.dx(full ? .primary : .secondary, on: ground))
            .animation(.easeOut(duration: 0.3), value: full)
            .accessibilityLabel(full ? Text(nextTitle) : Text("\(Text(nextTitle)). Waiting for \(current.count - ticked) more."))
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .padding(.top, 10)
            .dxArrive(3)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: ticked) { old, now in now > old }
        .sensoryFeedback(.success, trigger: full) { _, now in now }
    }

    private var nextTitle: LocalizedStringKey {
        if step + 1 < Grounding.steps.count {
            let next = Grounding.steps[step + 1]
            return "Next: \(next.count) \(String(localized: next.sense))"
        }
        return "Done"
    }

    private var stepCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Text(verbatim: "\(current.count)")
                    .dxFace(.display, 100, weight: 800, tracking: -3)
                    .frame(height: 86)
                Text(current.sense).dxType(.title).foregroundStyle(ground.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 140, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(ground.ink)
            .accessibilityElement(children: .combine)
            Text(current.line).dxType(.body).foregroundStyle(ground.ink)
            Text(current.hint).dxType(.footnote).foregroundStyle(ground.muted)
            pips.padding(.top, 12)
            Text("Tap one for each thing you notice").dxType(.caption).foregroundStyle(ground.muted)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 46, leading: 22, bottom: 28, trailing: 22))
        .background(ground.card, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(ground.line, lineWidth: 1))
        .overlay(alignment: .top) { seat }
        .overlay(alignment: .top) {
            // Jelli's tentacle tips meet the card's top edge.
            JelliView(mood: .calm, stage: 1, points: 176, animate: motion.breathes)
                .dxBob(motion.breathes ? 6 : 0, period: 5)
                .offset(y: -163)
                .dxSettle(0, delay: 0.5)
                .allowsHitTesting(false)
        }
        .dxArrive(1)
    }

    /// Her contact shadow, on the card just under the edge; it narrows and fades as she lifts.
    private var seat: some View {
        let dark = scheme == .dark
        return TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !motion.breathes)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let lift = motion.breathes ? (1 - cos(2 * .pi * t / 5)) / 2 : 0
            Ellipse()
                .fill(RadialGradient(colors: [dark ? Color(red: 2 / 255, green: 4 / 255, blue: 12 / 255).opacity(0.95)
                                                   : Color(red: 30 / 255, green: 26 / 255, blue: 58 / 255).opacity(0.2), .clear],
                                     center: .top, startRadius: 0, endRadius: 60))
                .frame(width: 120, height: dark ? 36 : 28)
                .frame(height: dark ? 18 : 14, alignment: .top)
                .clipped()
                .scaleEffect(x: 1 - 0.18 * lift, y: 1, anchor: .top)
                .opacity(1 - 0.45 * lift)
                .offset(y: 1)
        }
        .dxFade(delay: 0.7)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var pips: some View {
        let n = current.count
        return GeometryReader { geo in
            let size = min(58, (geo.size.width - CGFloat(n - 1) * 14) / CGFloat(n))
            HStack(spacing: 14) {
                ForEach(0..<n, id: \.self) { i in
                    GroundingPip(on: i < ticked, size: size)
                        .onTapGesture { if i >= ticked { withAnimation(.easeOut(duration: 0.3)) { ticked += 1 } } }
                        .accessibilityElement()
                        .accessibilityLabel(Text("Noticed \(i + 1)"))
                        .accessibilityAddTraits(i < ticked ? [.isButton, .isSelected] : .isButton)
                        .accessibilityAction { if i >= ticked { ticked += 1 } }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 58)
    }
}

/// One pip: an open ring, or noticed (the warm selection tint with an ink tick in light, a cream disc in dark).
private struct GroundingPip: View {
    let on: Bool
    let size: CGFloat
    private let ground = DX.Ground.reading
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        ZStack {
            Circle().fill(on ? (dark ? ground.sel : ground.selTint) : .clear)
            Circle().strokeBorder(on ? (dark ? .clear : ground.selEdge) : ground.ink.opacity(0.55), lineWidth: 2)
            if on {
                DXIcon(.check, size: 22 * size / 58).foregroundStyle(dark ? ground.selFg : ground.ink)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .dxBump(on)
    }
}
