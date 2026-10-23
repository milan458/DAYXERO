import AppIntents
import DayXeroCore
import WidgetKit

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

// MARK: - Logging (S7.1)

/// The products that can be logged with one tap.
enum LoggedProduct: String, AppEnum {
    case cigarette, puffSession, pouch

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Product" }
    static var caseDisplayRepresentations: [LoggedProduct: DisplayRepresentation] {
        [.cigarette: "Cigarette", .puffSession: "Puff session", .pouch: "Pouch"]
    }

    init(_ product: Product) {
        switch product {
        case .cigarettes: self = .cigarette
        case .vape: self = .puffSession
        case .pouches: self = .pouch
        }
    }

    var product: Product {
        switch self {
        case .cigarette: .cigarettes
        case .puffSession: .vape
        case .pouch: .pouches
        }
    }
}

/// Logs one use from the widget, Siri or Shortcuts. Before Quit Day it's tracking; after, it's a slip.
struct LogUseIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a use"
    static let description = IntentDescription("Logs a cigarette, puff session or pouch.")

    @Parameter(title: "Product") var product: LoggedProduct

    init() {}

    init(product: LoggedProduct) {
        self.product = product
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Log a \(\.$product)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try SOSBridge.container ?? DataStore.makeContainer()
        let entry = UseLog.log(product.product, in: container.mainContext)
        WidgetCenter.shared.reloadAllTimelines()
        if entry.kind == .slip {
            return .result(dialog: "Logged. A slip is one moment, not a restart. Nothing resets.")
        }
        let today = UseLog.counts(product.product, in: container.mainContext).today
        return .result(dialog: "Logged. \(today) today.")
    }
}

/// Opens the craving log in the app.
struct LogCravingIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a craving"
    static let description = IntentDescription("Notes a craving: how strong it was and what set it off.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SOSBridge.requestCravingLog()
        return .result()
    }
}
