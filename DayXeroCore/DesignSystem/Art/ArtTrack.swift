import Foundation

/// One looping SVG-style animation track (`values`, `keyTimes`, `dur`, `begin`),
/// evaluated at a time in seconds. `spline` applies the canvas files' keySpline
/// "0.45 0 0.55 1" to every segment; otherwise segments are linear, as SMIL is by default.
public struct ArtTrack: Sendable {
    public let values: [[Double]]
    public let times: [Double]
    public let duration: Double
    public let spline: Bool
    public let begin: Double

    public init(_ values: [[Double]], times: [Double]? = nil, duration: Double, spline: Bool = false, begin: Double = 0) {
        self.values = values
        let n = values.count
        self.times = times ?? (n > 1 ? (0..<n).map { Double($0) / Double(n - 1) } : [0])
        self.duration = duration
        self.spline = spline
        self.begin = begin
    }

    /// Single-number tracks.
    public init(scalars: [Double], times: [Double]? = nil, duration: Double, spline: Bool = false, begin: Double = 0) {
        self.init(scalars.map { [$0] }, times: times, duration: duration, spline: spline, begin: begin)
    }

    /// The value at `time`; with `animate` off, the first value (the resting pose).
    public func value(at time: Double, animate: Bool = true) -> [Double] {
        guard animate, values.count > 1, duration > 0, time >= begin else { return values.first ?? [] }
        let local = (time - begin).truncatingRemainder(dividingBy: duration) / duration
        var segment = times.count - 2
        for i in 0..<(times.count - 1) where local <= times[i + 1] {
            segment = i
            break
        }
        let t0 = times[segment], t1 = times[segment + 1]
        var f = t1 > t0 ? (local - t0) / (t1 - t0) : 0
        f = max(0, min(1, f))
        if spline { f = Self.ease(f) }
        let a = values[segment], b = values[segment + 1]
        return zip(a, b).map { $0 + ($1 - $0) * f }
    }

    public func scalar(at time: Double, animate: Bool = true) -> Double {
        value(at: time, animate: animate).first ?? 0
    }

    /// cubic-bezier(0.45, 0, 0.55, 1), the canvas files' keySpline.
    public static func ease(_ x: Double) -> Double {
        cubic(x, 0.45, 0, 0.55, 1)
    }

    /// Any CSS cubic-bezier(x1, y1, x2, y2) at progress `x`, solved for x by bisection.
    public static func cubic(_ x: Double, _ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) -> Double {
        func bezier(_ s: Double, _ p1: Double, _ p2: Double) -> Double {
            let u = 1 - s
            return 3 * u * u * s * p1 + 3 * u * s * s * p2 + s * s * s
        }
        let x = max(0, min(1, x))
        var lo = 0.0, hi = 1.0
        for _ in 0..<24 {
            let mid = (lo + hi) / 2
            if bezier(mid, x1, x2) < x { lo = mid } else { hi = mid }
        }
        return bezier((lo + hi) / 2, y1, y2)
    }
}
