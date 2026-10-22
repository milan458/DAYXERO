import Foundation

/// Identifies one program day, e.g. quit day 3 or maintenance day 12.
public struct ProgramDayID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let phase: ProgramPhase
    /// 1-based within the phase.
    public let index: Int

    public init(phase: ProgramPhase, index: Int) {
        self.phase = phase
        self.index = index
    }

    public var description: String { "\(phase.rawValue)-\(index)" }
}

public enum ProgramDayState: Equatable, Sendable {
    case completed
    /// The next day to do. Exactly one day is available until the program is finished.
    case available
    case locked
}

/// Day locking: a day unlocks only after the previous day in the outline is completed.
/// Slips are not an input here, by design.
public struct ProgramEngine: Sendable {
    /// Every program day in order: prep days, then quit days, then maintenance.
    public let outline: [ProgramDayID]

    public init(outline: [ProgramDayID]) {
        self.outline = outline
    }

    public func state(of day: ProgramDayID, completed: Set<ProgramDayID>) -> ProgramDayState {
        if completed.contains(day) { return .completed }
        return day == nextDay(completed: completed) ? .available : .locked
    }

    /// The first day in the outline that isn't completed, or nil when the program is finished.
    public func nextDay(completed: Set<ProgramDayID>) -> ProgramDayID? {
        outline.first { !completed.contains($0) }
    }

    public func canStart(_ day: ProgramDayID, completed: Set<ProgramDayID>) -> Bool {
        state(of: day, completed: completed) != .locked
    }

    /// Fraction of the outline completed, for progress visuals.
    public func fractionComplete(completed: Set<ProgramDayID>) -> Double {
        guard !outline.isEmpty else { return 0 }
        return Double(outline.filter(completed.contains).count) / Double(outline.count)
    }
}
