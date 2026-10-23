import AppIntents
import DayXeroCore

// Compiled into both the app and the widget extension: widgets, controls and the Live Activity refer to these
// types, and the system runs them in the app (S6.4, S6.5).

/// Opens Craving SOS. Used by Siri, Shortcuts, the Action button and the Control Center control.
struct StartCravingSOSIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Craving SOS"
    static let description = IntentDescription("Opens a three-minute session to ride out a craving.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SOSBridge.requestSession(source: "intent")
        return .result()
    }
}

/// "It passed" on the Lock Screen and in the Dynamic Island: saves the craving and ends the countdown.
struct CravingPassedIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "It passed"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        await SOSBridge.passedOutside()
        return .result()
    }
}
