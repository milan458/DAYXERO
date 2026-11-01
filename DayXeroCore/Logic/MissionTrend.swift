import Foundation

/// The person's own numbers from a mission's quick question, shown back after they save one (S27.18): a craving's
/// peak after surfing it, or the gap between the morning moment and the first use. Lines are factual: a comment
/// appears only when the numbers say so, and nothing is ever framed as worse or failed.
public enum MissionTrend {
    /// The answers as saved by the quick question: one line each, "2026-11-03 7" or "2026-11-03 15+ min".
    /// Returns the number after the date, in saved order; lines without one are skipped.
    public static func values(from lines: [String]) -> [Int] {
        lines.compactMap { line in
            let parts = line.split(separator: " ", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }
            let digits = parts[1].prefix { $0.isNumber }
            return Int(digits)
        }
    }

    public struct Summary: Equatable, Sendable {
        /// The last few values, oldest first.
        public let values: [Int]
        /// Every value lower than the one before (peaks), at least two of them.
        public let falling: Bool
        /// Every value higher than the one before (gaps), at least two of them.
        public let rising: Bool
        /// The highest value so far, across all answers.
        public let best: Int
        /// The latest value is the highest so far, and there was an earlier one to beat.
        public let latestIsBest: Bool
    }

    /// At most this many values are shown, the latest ones.
    public static let shown = 5

    /// nil when nothing has been saved yet.
    public static func summary(of lines: [String]) -> Summary? {
        let all = values(from: lines)
        guard let last = all.last, let best = all.max() else { return nil }
        let recent = Array(all.suffix(shown))
        let steps = zip(recent, recent.dropFirst()).map { (before: $0, after: $1) }
        let falling = recent.count >= 2 && steps.allSatisfy { $0.after < $0.before }
        let rising = recent.count >= 2 && steps.allSatisfy { $0.after > $0.before }
        let earlierBest = all.dropLast().max()
        return Summary(values: recent, falling: falling, rising: rising, best: best,
                       latestIsBest: earlierBest.map { last > $0 } ?? false)
    }
}
