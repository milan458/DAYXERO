import Foundation
import Testing
@testable import DayXeroCore

struct ReviewAskTests {
    private let calendar = Calendar(identifier: .gregorian)
    private func day(_ n: Int, hour: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: n, hour: hour))!
    }

    @Test func onlyPrepOneAndDayXeroAreSessionMoments() {
        #expect(ReviewAsk.moment(forSession: "P1") == .prepOne)
        #expect(ReviewAsk.moment(forSession: "DX") == .dayXero)
        #expect(ReviewAsk.moment(forSession: "P2") == nil)
        #expect(ReviewAsk.moment(forSession: "W1D1") == nil)
    }

    @Test func prepOneAsksOnTheFirstDay() {
        #expect(ReviewAsk.shouldAsk(.prepOne, asked: [], lastAsked: nil, joined: day(1), now: day(1, hour: 20), calendar: calendar))
    }

    @Test func sosWaitsForTheThirdDay() {
        #expect(!ReviewAsk.shouldAsk(.sosPassed, asked: [], lastAsked: nil, joined: day(1), now: day(1, hour: 22), calendar: calendar))
        #expect(!ReviewAsk.shouldAsk(.sosPassed, asked: [], lastAsked: nil, joined: day(1), now: day(2), calendar: calendar))
        #expect(ReviewAsk.shouldAsk(.sosPassed, asked: [], lastAsked: nil, joined: day(1, hour: 23), now: day(3, hour: 1), calendar: calendar))
        #expect(ReviewAsk.shouldAsk(.sosPassed, asked: [.prepOne], lastAsked: day(1), joined: day(1), now: day(9), calendar: calendar))
    }

    @Test func eachMomentAsksOnce() {
        #expect(!ReviewAsk.shouldAsk(.prepOne, asked: [.prepOne], lastAsked: day(1), joined: day(1), now: day(5), calendar: calendar))
        #expect(!ReviewAsk.shouldAsk(.dayXero, asked: [.prepOne, .dayXero], lastAsked: day(8), joined: day(1), now: day(9), calendar: calendar))
    }

    @Test func neverTwiceOnTheSameDay() {
        #expect(!ReviewAsk.shouldAsk(.dayXero, asked: [.sosPassed], lastAsked: day(8, hour: 9), joined: day(1), now: day(8, hour: 21), calendar: calendar))
        #expect(ReviewAsk.shouldAsk(.dayXero, asked: [.sosPassed], lastAsked: day(8, hour: 9), joined: day(1), now: day(9), calendar: calendar))
    }
}
