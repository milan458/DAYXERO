import DayXeroCore
import SwiftUI
import UIKit

/// Craving SOS colours (v5, cook/site/screens/019-021): SOS and its outcomes are all Jelli's ocean, a lit sea
/// (`DX.Ground.oceanGradient`); Passed stays on the ocean (the sky ground retired). Cards are the ocean's own card.
enum SOSColors {
    static let ocean = DX.Ground.ocean
    /// Passed: the ocean too (v5).
    static let sky = DX.Ground.ocean
    /// The solid fill on ocean: the reason card, the break menu, the hold pad (kit `--card`).
    static let solid = DX.Ground.ocean.card
    static let glow = Color(light: (0x9CCBFF, 0.30), dark: (0x2A52DB, 0.25))
    static let waveBack = Color(light: 0x2449CC, dark: 0x13286A)
    static let waveFront = Color(light: 0x1F40B8, dark: 0x1A3384)
    static let cream = DX.Fill.cream
    /// Cards and chips on Passed: the ocean's card and card-2.
    static let skyCard = DX.Ground.ocean.card
    static let skyChip = DX.Ground.ocean.card2
    static let bubble = Color(light: (0xFFF8EE, 0.85), dark: (0x9CCBFF, 0.45))
}

/// F13: the glow ring that breathes behind Jelli, and two slow waves along the bottom.
struct SOSWater: View {
    /// The breathing glow ring; off while the opening sighs draw their own (CHAR-01).
    var ring = true
    private let motion = MotionPolicy()

    var body: some View {
        let still = !motion.breathes
        TimelineView(.animation(paused: still)) { timeline in
            let t = still ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                SOSWater.draw(in: &context, size: size, time: t, still: still, ring: ring)
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    /// Drawn in the canvas's 390-wide space, scaled to the screen width.
    nonisolated static func draw(in context: inout GraphicsContext, size: CGSize, time t: Double, still: Bool, ring: Bool = true) {
        let k = size.width / 390
        // Glow ring: radius 125 → 165 on the 4 s in, 6 s out breath; 140 when still.
        if ring {
            let breath = still ? 0.375 : DX.Move.breath(at: t)
            let r = (125 + 40 * breath) * k
            let centre = CGPoint(x: size.width / 2, y: 196 * k)
            context.fill(Path(ellipseIn: CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2)),
                         with: .color(SOSColors.glow))
        }
        // Two waves rise and fall out of step: 7 s and 5.5 s.
        func wave(_ baseline: Double, depth: Double, period: Double) -> Path {
            let d = still ? 0 : depth * cos(2 * .pi * t / period)
            let y = size.height - (844 - baseline) * k
            var p = Path()
            p.move(to: CGPoint(x: 0, y: y))
            p.addCurve(to: CGPoint(x: size.width, y: y),
                       control1: CGPoint(x: 100 * k, y: y - d * k), control2: CGPoint(x: 290 * k, y: y + d * k))
            p.addLine(to: CGPoint(x: size.width, y: size.height))
            p.addLine(to: CGPoint(x: 0, y: size.height))
            p.closeSubpath()
            return p
        }
        context.fill(wave(730, depth: 16, period: 7), with: .color(SOSColors.waveBack))
        context.fill(wave(774, depth: -12, period: 5.5), with: .color(SOSColors.waveFront))
    }
}

/// F13 breathing words on the 4 in, 6 out rhythm, in step with Jelli's breath (both run on the same clock).
struct SOSBreathWords: View {
    private let motion = MotionPolicy()

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: DX.Move.inhale + DX.Move.exhale)
            let breathingIn = t < DX.Move.inhale
            let into = breathingIn ? t : t - DX.Move.inhale
            let fade = motion.breathes ? min(1, into / 0.6) : 1
            ZStack {
                Text("Breathe in").opacity(breathingIn ? fade : 1 - fade)
                Text("and out").opacity(breathingIn ? 1 - fade : fade)
            }
            .dxType(.large)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.7)
            .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Breathe in for 4, and out for 6."))
    }
}

/// One soft tap as each breath turns, on the same clock as the words.
struct SOSBreathHaptics: ViewModifier {
    let enabled: Bool
    @State private var tick = 0

    func body(content: Content) -> some View {
        content
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.55), trigger: tick)
            .task(id: enabled) {
                guard enabled else { return }
                while !Task.isCancelled {
                    let cycle = DX.Move.inhale + DX.Move.exhale
                    let t = Date.now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle)
                    let next = t < DX.Move.inhale ? DX.Move.inhale - t : cycle - t
                    try? await Task.sleep(for: .seconds(next))
                    if Task.isCancelled { return }
                    tick += 1
                }
            }
    }
}

/// A choice chip with the old v4 call shape; v5 draws the one kit chip (`DXChip`) for the ground it sits on
/// (`.dxGround`), so the colour arguments are kept for call sites but no longer used.
struct V4Chip: View {
    let text: String
    let isOn: Bool
    var fill: Color = DX.Fill.surface
    var ink: Color = DX.Ground.reading.ink
    var selectedFill: Color = DX.Ground.reading.ink
    var selectedInk: Color = DX.Ground.reading.background
    let action: () -> Void

    var body: some View {
        DXChip(verbatim: text, isOn: isOn, action: action)
    }
}

/// "What set it off?": the person's own triggers first, then "More…" opens the rest.
struct TriggerPicker: View {
    let mine: [Trigger]
    @Binding var selection: Trigger?
    var fill: Color = DX.Fill.surface
    var ink: Color = DX.Ground.reading.ink
    var selectedFill: Color = DX.Ground.reading.ink
    var selectedInk: Color = DX.Ground.reading.background
    @State private var showAll = false

    private var shown: [Trigger] {
        let own = mine.isEmpty ? [Trigger.stress, .coffee] : mine
        let all = own + Trigger.allCases.filter { !own.contains($0) }
        if showAll { return all }
        // The chosen trigger stays visible even if it isn't one of theirs.
        return own + (selection.map { own.contains($0) ? [] : [$0] } ?? [])
    }

    var body: some View {
        DXFlowLayout(spacing: 8) {
            ForEach(shown, id: \.self) { t in
                V4Chip(text: String(localized: t.title), isOn: selection == t, fill: fill, ink: ink,
                       selectedFill: selectedFill, selectedInk: selectedInk) {
                    selection = selection == t ? nil : t
                }
            }
            if !showAll && shown.count < Trigger.allCases.count {
                V4Chip(text: String(localized: "More…"), isOn: false, fill: fill, ink: ink) { showAll = true }
                    .accessibilityLabel(Text("More triggers"))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Trigger"))
    }
}

/// F13 reason card on the solid ocean fill: the kicker, then the reason in 19 pt. A photo sits beside it.
struct SOSReasonCard: View {
    let reason: Reason
    let canAdvance: Bool
    let next: () -> Void

    var body: some View {
        Button(action: next) {
            // v5 (019): a heart tile, "Your reason" and the reason in their own words, on the ocean card.
            HStack(alignment: .center, spacing: 14) {
                DXIcon(.heart, size: 20)
                    .foregroundStyle(SOSColors.cream)
                    .frame(width: 34, height: 34)
                    .background(SOSColors.ocean.card2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your reason").dxType(.caption).foregroundStyle(SOSColors.ocean.muted)
                    Text(verbatim: "“\(reason.text)”")
                        .dxType(.footnote)
                        .foregroundStyle(SOSColors.cream)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let data = reason.photo, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(SOSColors.solid.opacity(0.7), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(SOSColors.ocean.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!canAdvance)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Your reason: \(reason.text)"))
        .accessibilityHint(canAdvance ? Text("Shows your next reason") : Text(verbatim: ""))
    }
}

/// The break menu on the solid ocean fill while a wave rides (S27.18): the person's own breaks, most helpful first,
/// or three of the program's suggestions before they've saved a menu. For anyone with gum, a lozenge or an inhaler,
/// a row reminding them it works in minutes. Read-only: the breaks are things to go and do.
struct SOSBreakMenuCard: View {
    let items: [String]
    /// The person saved these; false shows the program's suggestions and when their own menu comes.
    let isOwn: Bool
    /// "Day 9", the day the session that builds the menu opens.
    let buildingDay: String?
    let fastActingNRT: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isOwn ? LocalizedStringKey("Your break menu") : LocalizedStringKey("Try one while it passes"))
                .dxType(.caption).foregroundStyle(SOSColors.ocean.muted)
                .accessibilityAddTraits(.isHeader)
            DXFlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(verbatim: item)
                        .dxFont(16, weight: 600, style: .body)
                        .foregroundStyle(SOSColors.cream)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(SOSColors.ocean.card2,
                                    in: RoundedRectangle(cornerRadius: DX.Layout.chipRadius, style: .continuous))
                }
            }
            if !isOwn, let buildingDay {
                Text("\(buildingDay) helps you save your own break menu. It will show here.")
                    .dxType(.footnote).foregroundStyle(SOSColors.ocean.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if fastActingNRT {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use your gum or a lozenge now").dxFont(16, weight: 700, style: .body).foregroundStyle(SOSColors.cream)
                    Text("Fast-acting NRT helps in minutes. Follow the label.").dxType(.footnote).foregroundStyle(SOSColors.ocean.muted)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(SOSColors.ocean.muted.opacity(0.5)))
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(SOSColors.solid.opacity(0.7), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(SOSColors.ocean.line, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }
}

/// The pacer (019): one ring round Jelli that shows the breath. A cream arc sweeps round from the top over the 4 s
/// in-breath while a soft inner fill swells, then unwinds and ebbs over the 6 s out-breath; ring and Jelli scale with
/// it. Calm, no springs. With Reduce Motion the ring holds a quarter and the words carry the pace.
struct SOSPacer<Content: View>: View {
    var diameter: CGFloat = 276
    /// Passed (020): the arc closes from the top gap and stays full.
    var closed = false
    @ViewBuilder let content: Content
    private let motion = MotionPolicy()

    var body: some View {
        let still = !motion.breathes || closed
        TimelineView(.animation(minimumInterval: 1 / 30, paused: still)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let cycle = DX.Move.inhale + DX.Move.exhale
            let phase = t.truncatingRemainder(dividingBy: cycle)
            let arc = still ? (closed ? 1 : 0.25) : phase < DX.Move.inhale
                ? easeInOut(phase / DX.Move.inhale) : 1 - easeInOut((phase - DX.Move.inhale) / DX.Move.exhale)
            let breath = still ? 0.4 : DX.Move.breath(at: t)
            ZStack {
                Circle().fill(Color.white.opacity(0.06 + 0.06 * breath))
                    .shadow(color: Color(hex: 0xBFD7FF).opacity(0.35), radius: 24)
                Circle().fill(Color.white.opacity(0.05 + 0.07 * breath)).padding(diameter * 0.09)
                Circle().stroke(Color.white.opacity(0.22), lineWidth: 4)
                Circle().trim(from: 0, to: arc)
                    .stroke(SOSColors.cream, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .white.opacity(0.5), radius: 4)
                content
            }
            .frame(width: diameter, height: diameter)
            .scaleEffect(still ? 1 : 0.96 + 0.06 * breath)
        }
        .accessibilityHidden(true)
    }

    private func easeInOut(_ x: Double) -> Double { 0.5 - 0.5 * cos(.pi * max(0, min(1, x))) }
}

/// F14: small rings rising through the sky.
struct RisingBubbles: View {
    private let motion = MotionPolicy()

    var body: some View {
        let still = motion.reduce
        TimelineView(.animation(paused: still)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                RisingBubbles.draw(in: &context, size: size, time: t, still: still)
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    /// x, radius, period and delay from the canvas; still positions when motion is reduced.
    private nonisolated static let bubbles: [(x: Double, r: Double, period: Double, delay: Double, still: Double)] = [
        (44, 5, 6, 0, 300), (120, 8, 8, 1.2, 180), (262, 6, 7, 0.6, 420), (346, 4, 5, 2, 250),
    ]

    nonisolated static func draw(in context: inout GraphicsContext, size: CGSize, time t: Double, still: Bool) {
        let k = size.width / 390
        for b in bubbles {
            let y: Double
            if still {
                y = b.still * k
            } else {
                let p = ((t - b.delay) / b.period).truncatingRemainder(dividingBy: 1)
                let progress = p < 0 ? p + 1 : p
                y = (size.height + 56 * k) - progress * (size.height + 76 * k)
            }
            let r = b.r * k
            context.stroke(Path(ellipseIn: CGRect(x: b.x * k - r, y: y - r, width: r * 2, height: r * 2)),
                           with: .color(SOSColors.bubble), lineWidth: 2.5)
        }
    }
}

extension View {
    func sosBreathHaptics(_ enabled: Bool) -> some View { modifier(SOSBreathHaptics(enabled: enabled)) }
}
