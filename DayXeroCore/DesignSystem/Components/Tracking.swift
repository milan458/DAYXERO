import SwiftUI

/// Day state in the week strip. There is deliberately no "slip" state: slips never change the streak visual.
public enum DXDayState: Sendable {
    case prep, clear, today, upcoming
    /// Quit Day while it's still ahead: outlined so it stands out in the strip.
    case quitDay
}

public struct DXWeekDay: Identifiable, Sendable {
    public let date: Date
    public let state: DXDayState
    public var id: Date { date }

    public init(date: Date, state: DXDayState) {
        self.date = date
        self.state = state
    }
}
