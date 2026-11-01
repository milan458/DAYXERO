import DayXeroCore
import SwiftUI
import UIKit

/// v4 Craving SOS colours (design doc §10, F13 and F14). SOS is Jelli's ocean; Passed is the sky.
enum SOSColors {
    static let ocean = DX.Ground.ocean
    static let sky = DX.Ground.sky
    /// The solid secondary fill on ocean: buttons, the reason card. #1D3A9E replaced a 16% cream tint (3.29:1).
    static let solid = Color(light: 0x1D3A9E, dark: 0x1B2C66)
    static let glow = Color(light: (0x9CCBFF, 0.30), dark: (0x2A52DB, 0.25))
    static let waveBack = Color(light: 0x2449CC, dark: 0x13286A)
    static let waveFront = Color(light: 0x1F40B8, dark: 0x1A3384)
    static let cream = DX.Fill.cream
    /// Cards on the sky: cream at 72% in light, white at 8% in dark.
    static let skyCard = Color(light: (0xFFF8EE, 0.72), dark: (0xFFFFFF, 0.08))
    static let skyChip = Color(light: (0xFFFFFF, 1), dark: (0xFFFFFF, 0.08))
    static let bubble = Color(light: (0xFFF8EE, 0.85), dark: (0x9CCBFF, 0.45))
}

/// F13: the glow ring that breathes behind Jelli, and two slow waves along the bottom.
struct SOSWater: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                SOSWater.draw(in: &context, size: size, time: t, still: reduceMotion)
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    /// Drawn in the canvas's 390-wide space, scaled to the screen width.
    nonisolated static func draw(in context: inout GraphicsContext, size: CGSize, time t: Double, still: Bool) {
        let k = size.width / 390
        // Glow ring: radius 125 → 165 on the 4 s in, 6 s out breath; 140 when still.
        let breath = still ? 0.375 : DX.Move.breath(at: t)
        let r = (125 + 40 * breath) * k
        let centre = CGPoint(x: size.width / 2, y: 196 * k)
        context.fill(Path(ellipseIn: CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2)),
                     with: .color(SOSColors.glow))
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: DX.Move.inhale + DX.Move.exhale)
            let breathingIn = t < DX.Move.inhale
            let into = breathingIn ? t : t - DX.Move.inhale
            let fade = reduceMotion ? 1 : min(1, into / 0.5)
            ZStack {
                Text("Breathe in… 4").opacity(breathingIn ? fade : 1 - fade)
                Text("…and out, 6").opacity(breathingIn ? 1 - fade : fade)
            }
            .dxType(.display)
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

/// A v4 choice chip: 44 pt, radius 14, ink when chosen.
struct V4Chip: View {
    let text: String
    let isOn: Bool
    var fill: Color = DX.Fill.surface
    var ink: Color = DX.Ground.reading.ink
    var selectedFill: Color = DX.Ground.reading.ink
    var selectedInk: Color = DX.Ground.reading.background
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: text)
                .dxFont(16, weight: 600, style: .body)
                .foregroundStyle(isOn ? selectedInk : ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(isOn ? selectedFill : fill,
                            in: RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(DX.Haptic.select, trigger: isOn)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
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
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR REASON").dxType(.caption).foregroundStyle(SOSColors.ocean.muted)
                    Text(verbatim: reason.text)
                        .dxFont(19, weight: 700, style: .headline)
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
            .background(SOSColors.solid, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
            Text(isOwn ? LocalizedStringKey("YOUR BREAK MENU") : LocalizedStringKey("TRY ONE WHILE IT PASSES"))
                .dxType(.caption).foregroundStyle(SOSColors.ocean.muted)
                .accessibilityAddTraits(.isHeader)
            DXFlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(verbatim: item)
                        .dxFont(16, weight: 600, style: .body)
                        .foregroundStyle(SOSColors.cream)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(Color(light: (0xFFF8EE, 0.12), dark: (0xFFFFFF, 0.10)),
                                    in: RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous))
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
        .background(SOSColors.solid, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

/// F14: small rings rising through the sky.
struct RisingBubbles: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                RisingBubbles.draw(in: &context, size: size, time: t, still: reduceMotion)
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
