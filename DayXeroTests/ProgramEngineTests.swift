import DayXeroCore
import Testing

struct ProgramEngineTests {
    let engine = ProgramEngine(outline: [
        ProgramDayID(phase: .prep, index: 1),
        ProgramDayID(phase: .prep, index: 2),
        ProgramDayID(phase: .quit, index: 1),
        ProgramDayID(phase: .quit, index: 2),
    ])

    @Test func firstDayIsAvailableAndTheRestAreLocked() {
        let states = engine.outline.map { engine.state(of: $0, completed: []) }
        #expect(states == [.available, .locked, .locked, .locked])
    }

    @Test func dayUnlocksOnlyAfterThePreviousDayIsCompleted() {
        let done: Set = [ProgramDayID(phase: .prep, index: 1)]
        #expect(engine.state(of: ProgramDayID(phase: .prep, index: 2), completed: done) == .available)
        #expect(!engine.canStart(ProgramDayID(phase: .quit, index: 1), completed: done))
    }

    @Test func skippingAheadDoesNotUnlockLaterDays() {
        // Even if a later day were somehow completed, the next available day is still the first gap.
        let done: Set = [ProgramDayID(phase: .quit, index: 1)]
        #expect(engine.nextDay(completed: done) == ProgramDayID(phase: .prep, index: 1))
        #expect(engine.state(of: ProgramDayID(phase: .quit, index: 2), completed: done) == .locked)
    }

    @Test func finishedProgramHasNoNextDay() {
        let done = Set(engine.outline)
        #expect(engine.nextDay(completed: done) == nil)
        #expect(engine.fractionComplete(completed: done) == 1)
    }
}
