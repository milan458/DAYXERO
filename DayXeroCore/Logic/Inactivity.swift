import Foundation

/// Pause and replay after a break (S5.7, Milan's rule: no reset to Day 1).
///
/// After `idleDays` whole days without finishing or opening a lesson, the program pauses. The next lesson
/// waits until the person replays the last day they finished. Days clear, money and progress never change.
public enum Inactivity {
    public static let idleDays = 3

    /// The day to replay, or nil if no pause is due.
    /// - Parameters:
    ///   - lastActive: last time a lesson was opened or finished.
    ///   - lastCompleted: the most recently finished day; nothing to replay without one.
    ///   - programFinished: no pauses once the whole program is done.
    public static func replayDue(lastActive: Date?, lastCompleted: ProgramDayID?, programFinished: Bool,
                                 now: Date, clock: DayClock) -> ProgramDayID? {
        guard !programFinished, let lastActive, let lastCompleted else { return nil }
        let idle = clock.calendar.dateComponents([.day], from: clock.day(containing: lastActive), to: clock.day(containing: now)).day ?? 0
        return idle >= idleDays ? lastCompleted : nil
    }
}
