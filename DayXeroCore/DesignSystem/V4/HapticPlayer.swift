import CoreHaptics
import Foundation

/// Core Haptics for the moments a system feedback can't carry (2 Nov 2026): the crescendo while a commitment is
/// held (CHAR-04), and the pulse under the finger on SOS's "Hold to feel" pad (CHAR-02). Phones without a Taptic
/// Engine stay quiet. The engine starts on first use and stops when `stop()` is called or the view goes.
@MainActor
public final class HapticPlayer {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    public init() {}

    /// Builds from a soft hum to a firm one over `duration`, with taps that come closer together as it grows,
    /// so the hold feels like it's gathering. Stop it if the finger lifts early.
    public func crescendo(duration: Double) {
        guard duration > 0 else { return }
        var events = [CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
        ], relativeTime: 0, duration: duration)]
        // Taps at 0, 30, 55, 75 and 90% of the hold, each a little stronger.
        for (index, share) in Self.crescendoTaps.enumerated() {
            let strength = Float(0.35 + 0.65 * Double(index) / Double(Self.crescendoTaps.count - 1))
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: strength),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25 + 0.4 * strength),
            ], relativeTime: duration * share))
        }
        let intensity = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
            .init(relativeTime: 0, value: 0.12),
            .init(relativeTime: duration, value: 0.9),
        ], relativeTime: 0)
        let sharpness = CHHapticParameterCurve(parameterID: .hapticSharpnessControl, controlPoints: [
            .init(relativeTime: 0, value: -0.2),
            .init(relativeTime: duration, value: 0.3),
        ], relativeTime: 0)
        play(events: events, curves: [intensity, sharpness], loop: false)
    }

    /// Where the crescendo's taps fall, as shares of the hold.
    public static let crescendoTaps: [Double] = [0, 0.3, 0.55, 0.75, 0.9]

    /// A slow heartbeat under the finger, about once a second, until `stop()`. `setPulse(strength:)` lifts it while
    /// the finger moves.
    public func startPulse() {
        let beat: [CHHapticEvent] = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25),
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15),
            ], relativeTime: 0.16),
            // A faint hum between beats, so the pad never feels dead.
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.18),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05),
            ], relativeTime: 0.3, duration: 0.6),
        ]
        play(events: beat, curves: [], loop: true, loopEnd: 0.95)
    }

    /// 0...1: how strongly the pulse plays right now.
    public func setPulse(strength: Double) {
        let value = Float(0.45 + 0.55 * min(max(strength, 0), 1))
        try? player?.sendParameters([CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: value, relativeTime: 0)],
                                    atTime: CHHapticTimeImmediate)
    }

    public func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
    }

    /// Stops and lets the engine go, for when the view leaves.
    public func shutDown() {
        stop()
        engine?.stop(completionHandler: nil)
        engine = nil
    }

    private func play(events: [CHHapticEvent], curves: [CHHapticParameterCurve], loop: Bool, loopEnd: Double = 0) {
        guard supported else { return }
        stop()
        do {
            let engine = try running()
            let player = try engine.makeAdvancedPlayer(with: CHHapticPattern(events: events, parameterCurves: curves))
            player.loopEnabled = loop
            if loop { player.loopEnd = loopEnd }
            try player.start(atTime: CHHapticTimeImmediate)
            self.player = player
        } catch {
            self.engine = nil
        }
    }

    private func running() throws -> CHHapticEngine {
        if let engine { return engine }
        let engine = try CHHapticEngine()
        engine.playsHapticsOnly = true
        // The engine stops when the app backgrounds; start it again rather than going quiet.
        engine.resetHandler = { [weak self] in Task { @MainActor in try? self?.engine?.start() } }
        engine.stoppedHandler = { [weak self] _ in Task { @MainActor in self?.engine = nil; self?.player = nil } }
        try engine.start()
        self.engine = engine
        return engine
    }
}
