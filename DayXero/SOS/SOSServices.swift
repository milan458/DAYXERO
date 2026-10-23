import ActivityKit
import CoreHaptics
import DayXeroCore
import Foundation
import Observation

/// Opens Craving SOS from anywhere: the dock, widgets, Siri, Control Center (S6.5).
@Observable @MainActor
final class SOSRouter {
    struct Launch: Identifiable {
        let id = UUID()
        let source: String
    }

    var launch: Launch?

    func open(source: String) {
        guard launch == nil else { return }
        launch = Launch(source: source)
    }
}

/// The countdown on the Lock Screen and in the Dynamic Island (S6.4).
enum SOSLiveActivity {
    /// Replaces any countdown left from an earlier session, so there's only ever one.
    static func start(startedAt: Date, endsAt: Date) async {
        await endAll()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let content = ActivityContent(state: CravingActivityAttributes.ContentState(endsAt: endsAt),
                                      staleDate: endsAt.addingTimeInterval(15 * 60))
        _ = try? Activity.request(attributes: CravingActivityAttributes(startedAt: startedAt), content: content)
    }

    static func update(endsAt: Date) async {
        let content = ActivityContent(state: CravingActivityAttributes.ContentState(endsAt: endsAt),
                                      staleDate: endsAt.addingTimeInterval(15 * 60))
        for activity in Activity<CravingActivityAttributes>.activities {
            await activity.update(content)
        }
    }

    static func endAll() async {
        for activity in Activity<CravingActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

/// A soft pulse that follows each breath: rising on the in-breath, fading on the out-breath (S6.2).
/// The breaths lengthen over the session, so the pulse slows with them.
@MainActor
final class BreathHaptics {
    private var engine: CHHapticEngine?
    private let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    func play(inhale: Double, exhale: Double) {
        guard supported else { return }
        do {
            if engine == nil {
                let engine = try CHHapticEngine()
                engine.isAutoShutdownEnabled = true
                self.engine = engine
            }
            try engine?.start()
            let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
            ], relativeTime: 0, duration: inhale + exhale)
            let curve = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
                .init(relativeTime: 0, value: 0.06),
                .init(relativeTime: inhale, value: 0.42),
                .init(relativeTime: inhale + exhale * 0.85, value: 0.02),
            ], relativeTime: 0)
            let pattern = try CHHapticPattern(events: [event], parameterCurves: [curve])
            try engine?.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            engine = nil
        }
    }

    func stop() {
        engine?.stop(completionHandler: nil)
        engine = nil
    }
}
