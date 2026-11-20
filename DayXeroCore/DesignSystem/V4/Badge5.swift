import SwiftUI

/// The one medallion family (kit.js `badge`): milestones only, no XP or points.
/// - `prep` 1-7: scalloped stamps, one per finished prep session.
/// - `xero`: Day Xero, the zero with a sunrise in its window, earned when the Day Xero commit is held.
/// - `day` 1, 3, 7, 14, 30, 60, 90, 180, 365; `wave` 1, 10, 25, 50, 100; `night` 3, 7, 14, 30.
/// States: earned (full colour), next (dashed ring, or a progress arc toward it), locked (dashed outline and a padlock).
/// Everything is drawn in the kit's 100 × 100 box and scaled to `size`.
public struct DXBadge: View {
    public enum Kind: String, Sendable { case prep, xero, day, wave, night }
    public enum Status: Equatable, Sendable {
        case earned
        /// Next up; `progress` draws the arc toward it, nil the dashed ring.
        case next(Double?)
        case locked
    }

    let kind: Kind
    let n: String
    let state: Status
    let size: CGFloat
    let label: String?
    /// Lifts the numeral 5 points (the Today hero, so the badge's sun never crowds it).
    let liftNumeral: Bool
    /// The waiting ring's colour, when a screen sets its own (012: dark gold on the cream coin in light).
    var ringColor: Color?
    @Environment(\.dxGround) private var ground
    private let motion = MotionPolicy()

    public init(_ kind: Kind, n: String = "", state: Status = .earned, size: CGFloat = 72, label: String? = nil, liftNumeral: Bool = false) {
        self.kind = kind
        self.n = n
        self.state = state
        self.size = size
        self.label = label
        self.liftNumeral = liftNumeral
    }

    public init(_ kind: Kind, n: Int, state: Status = .earned, size: CGFloat = 72, label: String? = nil, liftNumeral: Bool = false) {
        self.init(kind, n: String(n), state: state, size: size, label: label, liftNumeral: liftNumeral)
    }

    struct Palette {
        let edge: UInt32, face: UInt32, hill: UInt32, ink: UInt32, sun: UInt32
    }

    var pal: Palette {
        switch kind {
        case .prep: Palette(edge: 0xFF9A5C, face: 0xFFC38A, hill: 0xFFAE73, ink: 0x1E1A3A, sun: 0xFFD966)
        case .xero: Palette(edge: 0xF5B83D, face: 0xFFD966, hill: 0xFFC38A, ink: 0x1E1A3A, sun: 0xFF7A55)
        case .day: Palette(edge: 0xFF7155, face: 0xFFC38A, hill: 0xFF9A6B, ink: 0x1E1A3A, sun: 0xFFD966)
        case .wave: Palette(edge: 0x1D3A9E, face: 0x2A52DB, hill: 0x5C7FF0, ink: 0xFFF8EE, sun: 0x9CCBFF)
        case .night: Palette(edge: 0x0D182E, face: 0x1C2C4E, hill: 0x2C3D6A, ink: 0xF6EFE2, sun: 0xFFD37A)
        }
    }

    public var body: some View {
        VStack(spacing: 6) {
            medal
                .frame(width: size, height: size)
            if let label {
                Text(verbatim: label).dxType(.caption).foregroundStyle(ground.resolved.muted)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(label ?? kind.rawValue) \(stateWord)"))
    }

    private var stateWord: String {
        switch state {
        case .earned: String(localized: "earned")
        case .next: String(localized: "next")
        case .locked: String(localized: "locked")
        }
    }

    private var current: Color { ground.resolved.ink }

    /// The same badge with its waiting ring in `color`.
    public func ring(_ color: Color) -> DXBadge {
        var copy = self
        copy.ringColor = color
        return copy
    }
    private var numeralSize: CGFloat { n.count > 2 ? 22 : 30 }

    @ViewBuilder private var medal: some View {
        let s = size / 100
        ZStack {
            switch state {
            case .locked: locked(s)
            case .earned: earned(s)
            case let .next(p): next(s, p: p)
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: states

    private func locked(_ s: CGFloat) -> some View {
        ZStack {
            Circle().stroke(current.opacity(0.35), style: StrokeStyle(lineWidth: 3 * s, dash: [6 * s, 6 * s]))
                .frame(width: 88 * s, height: 88 * s)
            // The kit sets this numeral on its baseline at y 50 (no middle alignment), above the padlock.
            if !n.isEmpty { numeral(s, color: current.opacity(0.45), y: 50 - numeralSize * 0.36) }
            Box(d: "M43 62v-3a7 7 0 0114 0v3M40 62h20v12H40z")
                .stroke(current.opacity(0.45), style: StrokeStyle(lineWidth: 3 * s, lineJoin: .round))
                .offset(y: (n.isEmpty ? -12 : 2) * s)
        }
    }

    private func earned(_ s: CGFloat) -> some View {
        ZStack {
            if kind == .xero { XeroRays(s: s, spins: !motion.reduce) }
            if kind == .prep {
                Box(d: Self.scallop(cx: 50, cy: 50, r: 48, n: 14, a: 4)).fill(Color(hex: pal.edge))
            } else {
                Circle().fill(Color(hex: pal.edge)).frame(width: 94 * s, height: 94 * s)
            }
            Circle().fill(Color(hex: pal.face)).frame(width: 78 * s, height: 78 * s)
            art(s).clipShape(Box(d: "M11 50a39 39 0 1078 0 39 39 0 10-78 0z"))
            Circle().stroke(.white.opacity(0.35), lineWidth: 2 * s).frame(width: 78 * s, height: 78 * s)
            if kind == .xero {
                XeroMark(s: s).opacity(1)
            } else {
                numeral(s, color: Color(hex: pal.ink), y: liftNumeral ? 45 : 50)
            }
        }
    }

    private func next(_ s: CGFloat, p: Double?) -> some View {
        let ringColor = self.ringColor ?? Color(hex: kind == .night ? pal.sun : pal.edge)
        return ZStack {
            Circle().fill(kind == .xero ? Color(hex: 0xFFF4DE).opacity(0.92) : current.opacity(0.06))
                .frame(width: 90 * s, height: 90 * s)
            Circle()
                .stroke(p == nil ? ringColor : ringColor.opacity(0.45),
                        style: StrokeStyle(lineWidth: 3.5 * s, dash: p == nil ? [6 * s, 5 * s] : []))
                .frame(width: 90 * s, height: 90 * s)
            if kind == .xero { XeroMark(s: s).opacity(0.8) } else { numeral(s, color: current, y: 50) }
            Circle().stroke(current.opacity(0.22), lineWidth: 3 * s).frame(width: 96 * s, height: 96 * s)
            if let p {
                Circle().trim(from: 0, to: p)
                    .stroke(current, style: StrokeStyle(lineWidth: 3 * s, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 96 * s, height: 96 * s)
            }
        }
    }

    private func numeral(_ s: CGFloat, color: Color, y: CGFloat) -> some View {
        Text(verbatim: n)
            .font(Font(DX.Typeface4.font(.display, size: numeralSize * s, weight: 800) as CTFont))
            .tracking(-1 * s)
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
            .offset(y: (y - 50) * s)
    }

    // MARK: art

    @ViewBuilder private func art(_ s: CGFloat) -> some View {
        ZStack {
            switch kind {
            case .wave:
                Box(d: "M8 66c8-7 16-7 24 0s16 7 24 0 16-7 24 0 12 5 16 2v40H8z").fill(Color(hex: pal.hill))
                Box(d: "M8 78c8-6 16-6 24 0s16 6 24 0 16-6 24 0 12 5 16 2v30H8z").fill(Color(hex: pal.edge)).opacity(0.7)
            case .night:
                Box(d: "M59 31a11 11 0 1022 0 11 11 0 10-22 0z").fill(Color(hex: pal.sun))
                Box(d: "M54 27a10 10 0 1020 0 10 10 0 10-20 0z").fill(Color(hex: pal.face))
                Box(d: "M28.4 30a1.6 1.6 0 103.2 0 1.6 1.6 0 10-3.2 0z").fill(.white)
                Box(d: "M40.8 20a1.2 1.2 0 102.4 0 1.2 1.2 0 10-2.4 0z").fill(.white.opacity(0.8))
                Box(d: "M0 72 C30 60 60 80 100 66 V100 H0z").fill(Color(hex: pal.hill))
            case .xero:
                Box(d: "M11 50a39 39 0 1078 0 39 39 0 10-78 0z").fill(Color(hex: 0xFFE9A8))
            case .prep, .day:
                if size >= 44 { Box(d: "M66 68.5a9 9 0 1018 0 9 9 0 10-18 0z").fill(Color(hex: pal.sun)) }
                Box(d: "M0 74 C24 62 48 66 70 72 S96 70 100 68 V100 H0z").fill(Color(hex: pal.hill))
                Box(d: "M0 84 C30 76 60 90 100 80 V100 H0z").fill(Color(hex: pal.edge)).opacity(0.55)
            }
        }
        .frame(width: 100 * s, height: 100 * s)
    }

    public static func scallop(cx: Double, cy: Double, r: Double, n: Int, a: Double) -> String {
        var d = ""
        for i in 0...(n * 2) {
            let ang = Double.pi * Double(i) / Double(n) - .pi / 2
            let rr = i % 2 == 1 ? r - a : r
            d += (i == 0 ? "M" : "L") + String(format: "%.1f %.1f", cx + rr * cos(ang), cy + rr * sin(ang))
        }
        return d + "Z"
    }
}

/// A path in the kit's 100 × 100 box, scaled to the frame.
public struct Box: Shape {
    let d: String
    public init(d: String) { self.d = d }
    public func path(in rect: CGRect) -> Path {
        SVGPath.path(d).applying(CGAffineTransform(scaleX: rect.width / 100, y: rect.height / 100))
            .offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

/// Day Xero's twelve rays, turning once every 26 s.
private struct XeroRays: View {
    let s: CGFloat
    let spins: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !spins)) { timeline in
            let angle = spins ? timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 26) / 26 * 360 : 0
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    Box(d: "M50 -4 L53 8 L47 8Z").fill(Color(hex: 0xF5B83D)).rotationEffect(.degrees(Double(i) * 30))
                }
            }
            .opacity(0.9)
            .rotationEffect(.degrees(angle))
        }
        .frame(width: 100 * s, height: 100 * s)
    }
}

/// The xero "zero": a coral 0 with a sunrise in its window (the app icon's mark).
struct XeroMark: View {
    let s: CGFloat
    static let zero = "M29 52 A21 29 0 1 0 71 52 A21 29 0 1 0 29 52 Z M39.5 52 A10.5 18 0 1 1 60.5 52 A10.5 18 0 1 1 39.5 52 Z"

    var body: some View {
        ZStack {
            ZStack {
                Box(d: "M20 20h60v64H20z").fill(Color(hex: 0xE85A3E))
                Box(d: "M27 51a20.5 28.6 0 1041 0 20.5 28.6 0 10-41 0z").fill(Color(hex: 0xFF7155))
            }
            .clipShape(Box(d: Self.zero), style: FillStyle(eoFill: true))
            ZStack {
                Box(d: "M38 33h24v38H38z").fill(Color(hex: 0xBFD7FF))
                Box(d: "M44.5 58a5.5 5.5 0 1011 0 5.5 5.5 0 10-11 0z").fill(Color(hex: 0xFFC93C))
                Box(d: "M38 61 C43 58 48 60 53 58 S60 58 62 59 V72 H38Z").fill(Color(hex: 0x3FB37F))
            }
            .clipShape(Box(d: "M39.5 52a10.5 18 0 1021 0 10.5 18 0 10-21 0z"))
            Box(d: "M33.5 41 C34.5 34 38 29 43 26.5")
                .stroke(Color(hex: 0xFFB09C), style: StrokeStyle(lineWidth: 2.6 * s, lineCap: .round))
        }
        .frame(width: 100 * s, height: 100 * s)
    }
}
