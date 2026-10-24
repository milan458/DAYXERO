import AVFoundation
import CoreHaptics
import DayXeroCore
import QuartzCore
import SwiftUI
import UIKit

/// The Bio-Orb (S6.7): a glowing plasma ring with a dark lens and a centred readout, drawn per DAYXERO_BIO_ORB_SPEC.md.
/// `OrbEngine` holds the motion; `OrbClock` advances it once per display frame.
struct BioOrbView: View {
    let engine: OrbEngine
    var mini = false
    /// The orb's size in points; use `BioOrbView.side(mini:available:)`.
    let side: CGFloat
    var onTap: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Full 320 or mini 180, or narrower when the container is: min(target, width − 36).
    static func side(mini: Bool, available: CGFloat, data: OrbData = .bundled) -> CGFloat {
        let target = mini ? data.geometry.sizeMini : data.geometry.sizeFull
        return max(120, min(target, available - 36))
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 / 30 : nil)) { _ in
            ZStack {
                Canvas(rendersAsynchronously: false) { context, size in
                    draw(in: &context, size: size)
                }
                // Glow and halo spill past the orb's frame; give the canvas room instead of clipping.
                .frame(width: side + 120, height: side + 120)
                .allowsHitTesting(false)
                OrbReadout(engine: engine, mini: mini)
            }
            .frame(width: side, height: side)
        }
        .contentShape(Circle())
        .onTapGesture(perform: onTap)
        .onAppear { engine.reduceMotion = reduceMotion }
        .onChange(of: reduceMotion) { _, on in engine.reduceMotion = on }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Breathing guide"))
        .accessibilityValue(Text(accessibilityValue))
        .accessibilityHint(Text("Double-tap to hear a coaching line"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(perform: onTap)
    }

    private var accessibilityValue: String {
        let session = engine.session
        let phase = String(localized: String.LocalizationValue(session.phase.rawValue))
        if session.finished { return String(localized: "Done") }
        if session.isSOS {
            let left = Duration.seconds(session.sosRemaining).formatted(.units(allowed: [.minutes, .seconds], width: .wide))
            return String(localized: "\(phase), \(left) left")
        }
        return String(localized: "\(phase), \(session.remaining) seconds left, cycle \(session.cycle) of \(engine.pattern.recommendedCycles)")
    }

    // MARK: Drawing (spec §2–§3)

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let data = engine.data
        let g = data.geometry
        let S = side
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let ringBaseR = S * g.ringBaseFactor * engine.breathScale
        let reduce = reduceMotion
        let E = engine.drawEnergy
        let T = engine.orbTime

        // 1. Moss halo, breathing with the ring.
        let haloOuter = ringBaseR * g.haloOuter
        context.fill(circle(center, haloOuter), with: .radialGradient(
            gradient(data.tokens.haloGradient), center: center, startRadius: ringBaseR * g.haloInner, endRadius: haloOuter))

        // 2. Plasma rings: crisp strokes with a glow, screen-blended.
        for (idx, layer) in data.plasmaLayers.enumerated() {
            let speechMod = reduce ? 0 : (sin(T * 11 + Double(idx)) * 0.5 + 0.5) * E
            var path = Path()
            let steps = g.vertices
            for i in 0...steps {
                let theta = Double(i) / Double(steps) * 2 * .pi
                var r = ringBaseR * layer.radiusMult
                if !reduce {
                    let w1 = sin(theta * layer.freq1 + T * layer.speed) * layer.amp * (0.4 + speechMod)
                    let w2 = cos(theta * layer.freq2 - T * layer.speed * 1.3) * (layer.amp * 0.6) * speechMod
                    let w3 = sin(theta * 2 + T * 0.7) * 2
                    r += w1 + w2 + w3
                }
                let point = CGPoint(x: center.x + cos(theta) * r, y: center.y + sin(theta) * r)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            var ring = context
            ring.blendMode = .screen
            // Canvas shadowBlur is about 2σ, so half of it is the matching SwiftUI radius.
            ring.addFilter(.shadow(color: Color(orbHex: layer.glowHex), radius: (mini ? layer.glowMini : layer.glowFull) / 2))
            ring.stroke(path, with: .color(Color(orbHex: layer.hex).opacity(layer.opacity)),
                        style: StrokeStyle(lineWidth: (mini ? layer.widthMini : layer.widthFull) * (1 + E * 0.22), lineJoin: .round))
        }

        // 3. Dark lens with a feathered edge; no outline.
        let lensDraw = ringBaseR * g.lensFactor * g.lensFeather
        context.fill(circle(center, lensDraw), with: .radialGradient(
            gradient(data.tokens.lensGradient), center: center, startRadius: 0, endRadius: lensDraw))
    }

    private func circle(_ c: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    }

    private func gradient(_ stops: [OrbData.GradientStop]) -> Gradient {
        Gradient(stops: stops.map { .init(color: Color(orbHex: $0.hex).opacity($0.alpha), location: $0.stop) })
    }
}

/// The centred readout (spec §3.4): label, numeral and cycle row, fixed size, with the numeral's cap height
/// exactly halfway between the two rows.
private struct OrbReadout: View {
    let engine: OrbEngine
    let mini: Bool

    var body: some View {
        let data = engine.data
        let r = mini ? data.readout.mini : data.readout.full
        let session = engine.session
        let heroSize = session.isSOS ? r.heroSizeSOS : r.heroSize
        let capHeight = UIFont(name: DX.Typeface.extraBold, size: heroSize)?.capHeight ?? heroSize * 0.73
        VStack(spacing: 0) {
            Text(verbatim: label)
                .font(.custom(DX.Typeface.medium, fixedSize: r.labelSize))
                .foregroundStyle(Color(orbHex: data.tokens.sage).opacity(data.readout.labelOpacity))
                .lineLimit(1)
                .frame(height: r.rowHeight)
            // The numeral's baseline sits on the box's bottom edge, so the box is exactly the digits' height.
            Color.clear
                .frame(height: capHeight)
                .overlay(alignment: .bottom) {
                    Text(verbatim: numeral)
                        .font(.custom(DX.Typeface.extraBold, fixedSize: heroSize))
                        .tracking(-0.02 * heroSize)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .fixedSize()
                        .alignmentGuide(.bottom) { $0[.lastTextBaseline] }
                }
                .padding(.vertical, r.gap)
            HStack(spacing: r.cycleToBars) {
                Text(verbatim: "CYCLE \(session.cycle) OF \(engine.pattern.recommendedCycles)")
                    .font(.custom(DX.Typeface.mono, fixedSize: r.cycleSize))
                    .tracking(r.cycleTracking * r.cycleSize)
                    .foregroundStyle(.white.opacity(data.readout.cycleOpacity))
                    .lineLimit(1)
                OrbBars(engine: engine, size: r)
            }
            .frame(height: r.rowHeight)
        }
        .fixedSize()
        .allowsHitTesting(false)
    }

    private var label: String {
        let session = engine.session
        if session.finished { return session.isSOS ? engine.data.labels.sosDoneLabel : engine.data.labels.breathingDoneLabel }
        return String(localized: "\(engine.pattern.seconds(session.phase)) seconds · \(session.phase.word)")
    }

    private var numeral: String {
        let session = engine.session
        if session.isSOS {
            return String(format: "%02d:%02d", session.sosRemaining / 60, session.sosRemaining % 60)
        }
        return session.finished ? "✓" : "\(session.remaining)"
    }
}

/// Four waveform bars beside the cycle row, alternating sage and white.
private struct OrbBars: View {
    let engine: OrbEngine
    let size: OrbData.ReadoutSize

    var body: some View {
        Canvas { context, canvas in
            let E = engine.drawEnergy
            let T = engine.orbTime
            let k = engine.motionSpeaking ? 6.5 : 2.2
            for b in 0..<4 {
                let h = engine.reduceMotion ? 4
                    : 3 + (size.barMaxHeight - 3) * min(1, E * 1.2) * (0.35 + 0.65 * abs(sin(T * k + Double(b) * 1.3)))
                let rect = CGRect(x: Double(b) * (size.barWidth + size.barGap), y: (canvas.height - h) / 2, width: size.barWidth, height: h)
                context.fill(Path(roundedRect: rect, cornerRadius: 2),
                             with: .color(b.isMultiple(of: 2) ? Color(orbHex: engine.data.tokens.sage) : .white))
            }
        }
        .frame(width: size.barWidth * 4 + size.barGap * 3, height: size.barMaxHeight)
        .accessibilityHidden(true)
    }
}

/// The white transcript pill under the orb (spec §3.5): status dot, the line, and the badge. Wraps, never truncates.
struct OrbTranscriptPill: View {
    let engine: OrbEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let data = engine.data
        HStack(spacing: 10) {
            dot
            Text(verbatim: engine.transcript)
                .font(.custom(DX.Typeface.semibold, size: 12, relativeTo: .caption))
                .foregroundStyle(.black)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: engine.coachSpeaking ? data.labels.badgeSpeaking : data.labels.badgeIdle)
                .font(.custom(DX.Typeface.mono, size: 9, relativeTo: .caption2))
                .tracking(0.36)
                .foregroundStyle(.black)
                .lineLimit(1)
                .fixedSize()
                .padding(.vertical, 4).padding(.horizontal, 8)
                .background(Color(orbHex: data.tokens.sage), in: Capsule())
        }
        .padding(.top, 11).padding(.trailing, 12).padding(.bottom, 11).padding(.leading, 16)
        .frame(maxWidth: .infinity)
        .background(Color(orbHex: data.tokens.porcelain), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .combine)
        .onChange(of: engine.transcript) { _, text in
            AccessibilityNotification.Announcement(text).post()
        }
    }

    @ViewBuilder
    private var dot: some View {
        let circle = Circle().fill(.black).frame(width: 8, height: 8)
        if engine.coachSpeaking && !reduceMotion {
            PhaseAnimator([0.85, 1.25]) { scale in
                circle.scaleEffect(scale)
            } animation: { _ in .easeInOut(duration: 0.5) }
        } else {
            circle.scaleEffect(0.85)
        }
    }
}

/// Advances an `OrbEngine` once per display frame, at up to 120Hz.
@MainActor
final class OrbClock: NSObject {
    private var link: CADisplayLink?
    private weak var engine: OrbEngine?

    func attach(_ engine: OrbEngine, reduceMotion: Bool) {
        self.engine = engine
        link?.invalidate()
        let link = CADisplayLink(target: self, selector: #selector(step))
        link.preferredFrameRateRange = reduceMotion
            ? CAFrameRateRange(minimum: 15, maximum: 30, preferred: 30)
            : CAFrameRateRange(minimum: 30, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func step(_ link: CADisplayLink) {
        engine?.advance(to: link.targetTimestamp)
    }
}

/// Reads coaching lines aloud with on-device speech (spec §6). Nothing goes to a server.
@MainActor
final class OrbCoach: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var current: ObjectIdentifier?
    private weak var engine: OrbEngine?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func attach(_ engine: OrbEngine) { self.engine = engine }

    /// Plays a line, cancelling any line already playing. With voice off it shows as a caption only.
    func play(_ line: OrbData.CoachingLine, voice: Bool) {
        stop()
        engine?.beginLine(line, voiced: voice)
        guard voice else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
        let utterance = AVSpeechUtterance(string: line.text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.46
        utterance.pitchMultiplier = 0.96
        current = ObjectIdentifier(utterance)
        synthesizer.speak(utterance)
    }

    func stop() {
        current = nil
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        deactivate()
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.ended(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.ended(id) }
    }

    /// Only the line that's playing can end it; a cancelled earlier line can't end its replacement.
    private func ended(_ id: ObjectIdentifier) {
        guard id == current else { return }
        current = nil
        engine?.lineEnded()
        deactivate()
    }

    private func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

/// One continuous haptic per phase, ramping between the data file's intensities (spec §6).
@MainActor
final class OrbHaptics {
    private var engine: CHHapticEngine?
    private let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    /// `progress` 0...1 through an SOS session softens later cycles (S6.2).
    func play(_ phase: BreathPhase, pattern: OrbData.Pattern, progress: Double = 0) {
        guard supported, let h = pattern.haptic(phase) else { return }
        let seconds = Double(pattern.seconds(phase))
        let scale = 1 - 0.3 * min(max(progress, 0), 1)
        guard seconds > 0, max(h.intensityStart, h.intensityEnd) > 0 else { return }
        do {
            let engine = try running()
            let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(h.sharpness)),
            ], relativeTime: 0, duration: seconds)
            let curve = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
                .init(relativeTime: 0, value: Float(h.intensityStart * scale)),
                .init(relativeTime: seconds, value: Float(h.intensityEnd * scale)),
            ], relativeTime: 0)
            try engine.makePlayer(with: CHHapticPattern(events: [event], parameterCurves: [curve])).start(atTime: CHHapticTimeImmediate)
        } catch {
            self.engine = nil
        }
    }

    func stop() {
        engine?.stop(completionHandler: nil)
        engine = nil
    }

    private func running() throws -> CHHapticEngine {
        if let engine { return engine }
        let engine = try CHHapticEngine()
        // The engine stops when the app backgrounds; start it again rather than going quiet.
        engine.resetHandler = { [weak self] in Task { @MainActor in try? self?.engine?.start() } }
        engine.stoppedHandler = { [weak self] _ in Task { @MainActor in self?.engine = nil } }
        try engine.start()
        self.engine = engine
        return engine
    }
}

extension Color {
    /// "#BCC388" from the orb's data file.
    init(orbHex: String) {
        self.init(hex: UInt32(orbHex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0)
    }
}
