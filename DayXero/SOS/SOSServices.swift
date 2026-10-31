import ActivityKit
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

/// The session on the Lock Screen and in the Dynamic Island (S6.4): time ridden, counting up.
enum SOSLiveActivity {
    /// Replaces any session left from an earlier one, so there's only ever one.
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
