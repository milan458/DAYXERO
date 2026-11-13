import SwiftUI

/// v4 cards and rows (design doc §6, patterns 6–11, 13–17).

/// Shared ground for card content: reads the current ground to pick ink and muted.
private struct GroundInk: ViewModifier {
    let ground: DX.Ground
    let muted: Bool
    func body(content: Content) -> some View {
        content.foregroundStyle(muted ? ground.muted : ground.ink)
    }
}

public extension View {
    func dxInk(_ ground: DX.Ground, muted: Bool = false) -> some View {
        modifier(GroundInk(ground: ground, muted: muted))
    }

    /// A translucent card laid on a coloured ground.
    func dxCardOnColour(radius: CGFloat = DX.Layout.smallCardRadius, on ground: DX.Ground? = nil) -> some View {
        padding(16).dxCardChrome(on: ground ?? .apricot, radius: radius)
    }

    /// v5: the ground's card fill and, where the kit draws one, its hairline; no padding.
    func dxCardChrome(on ground: DX.Ground, radius: CGFloat = DX.Layout.cardRadius) -> some View {
        modifier(CardChrome(ground: ground, radius: radius))
    }

    /// A card on the reading ground.
    func dxReadingCard(radius: CGFloat = DX.Layout.smallCardRadius) -> some View {
        padding(16).dxCardChrome(on: .reading, radius: radius)
    }
}

private struct CardChrome: ViewModifier {
    let ground: DX.Ground
    let radius: CGFloat
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(ground.resolved.card, in: shape)
            .overlay { if ground.resolved.tokens(dark: scheme == .dark).hairline { shape.strokeBorder(ground.resolved.line, lineWidth: 1) } }
    }
}

/// Today's top card: coloured action card with kicker, 19 pt title, 14 pt body and a chevron in a 44 pt circle.
public struct TopCard: View {
    let kicker: String
    let title: String
    let detail: String
    let ground: DX.Ground
    let action: () -> Void

    public init(kicker: String, title: String, detail: String, ground: DX.Ground, action: @escaping () -> Void) {
        self.kicker = kicker
        self.title = title
        self.detail = detail
        self.ground = ground
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(kicker).dxType(.caption).dxInk(ground, muted: true)
                    Text(title).dxType(.headline).dxInk(ground)
                    Text(detail).dxType(.footnote).dxInk(ground, muted: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ground.ink)
                    .frame(width: 44, height: 44)
                    .background(DX.Fill.onColourCard(for: ground), in: Circle())
                    .accessibilityHidden(true)
            }
            .padding(18)
            .background {
                // The lip shadow sits on the card shape only, so text is never doubled.
                RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous)
                    .fill(ground.background)
                    .shadow(color: .black.opacity(0.14), radius: 0, x: 0, y: 5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

/// A number that counts up when it appears or changes (Count motion: 0.85 s, ease-out).
/// Reduce Motion shows the final value at once.
///
/// The count is a SwiftUI animation of the number itself, so the model value is always the real one and only the
/// frames in between are interpolated. The old version drew frames from a `TimelineView` and relied on a timer to
/// finish; when the timeline stopped ticking part-way (seen on the Progress tab), the tile froze on an early frame:
/// ₹20,697 for a ₹1,47,304 year, and 0 for 5 prep done or 7 days to Quit Day.
public struct CountingText: View {
    let value: Double
    let from: Double
    let delay: Double
    let duration: Double
    let format: (Double) -> String
    @State private var appeared = false
    private let motion = MotionPolicy()

    public init(_ value: Double, from: Double = 0, delay: Double = 0, duration: Double = 0.85, format: @escaping (Double) -> String) {
        self.value = value
        self.from = from
        self.delay = delay
        self.duration = duration
        self.format = format
    }

    /// v5 (kit `data-count`): a prefix, a suffix and fixed decimals, grouped like the locale, counting from `from`.
    public init(_ value: Double, from: Double = 0, prefix: String = "", suffix: String = "", decimals: Int = 0,
                delay: Double = 0.3, duration: Double = 0.85) {
        self.init(value, from: from, delay: delay, duration: duration) { v in
            prefix + v.formatted(.number.precision(.fractionLength(decimals))) + suffix
        }
    }

    private var curve: Animation { .timingCurve(0.33, 1, 0.68, 1, duration: duration) }

    public var body: some View {
        CountingNumber(animatableData: appeared || !motion.counts ? value : from, format: format)
            .animation(motion.counts ? curve : nil, value: value)
            .onAppear {
                guard !appeared else { return }
                if !motion.counts {
                    appeared = true
                } else {
                    withAnimation(curve.delay(delay)) { appeared = true }
                }
            }
    }
}

/// The number SwiftUI interpolates for `CountingText`.
private struct CountingNumber: View, Animatable {
    /// Nonisolated so it can satisfy `Animatable` from a main-actor view under Swift 6.
    nonisolated var animatableData: Double
    let format: (Double) -> String

    var body: some View {
        Text(format(animatableData)).monospacedDigit()
    }
}

/// Stat tile: 24 pt Bricolage number over a 12 pt label, counting up on first appearance.
public struct StatTile: View {
    let value: Double
    let label: String
    let format: (Double) -> String
    let ground: DX.Ground

    public init(value: Double, label: String, ground: DX.Ground, format: @escaping (Double) -> String = { String(Int($0.rounded(.down))) }) {
        self.value = value
        self.label = label
        self.ground = ground
        self.format = format
    }

    public var body: some View {
        // v5 kit `.stat`: a 28 pt display number over a 13 pt muted caption, on the ground's card, radius 20.
        VStack(alignment: .leading, spacing: 6) {
            CountingText(value, format: format).dxFace(.display, 28, weight: 800, tracking: -0.5).dxInk(ground)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label).dxType(.caption).dxInk(ground, muted: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14).padding(.horizontal, 16)
        .dxCardChrome(on: ground, radius: 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(format(value)) \(label)")
    }
}

/// Day row: a 22 pt status dot (green when done), label and meta, with a hairline under it.
public struct DayRow: View {
    let label: String
    let meta: String
    let done: Bool
    let ground: DX.Ground

    public init(_ label: String, meta: String, done: Bool, ground: DX.Ground = .reading) {
        self.label = label
        self.meta = meta
        self.done = done
        self.ground = ground
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(done ? DX.Fill.green : Color.clear)
                Circle().strokeBorder(done ? Color.clear : ground.muted, lineWidth: 2)
                if done {
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy)).foregroundStyle(.white)
                }
            }
            .frame(width: 22, height: 22)
            .accessibilityHidden(true)
            Text(label).dxType(.body).dxInk(ground)
            Spacer(minLength: 8)
            Text(meta).dxType(.footnote).dxInk(ground, muted: true)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { Rectangle().fill(ground.muted.opacity(0.25)).frame(height: 1) }
        .accessibilityElement(children: .combine)
        .accessibilityValue(done ? "Done" : "")
    }
}

/// Plan row: tick circle, caption kicker and body value. Rows settle in one by one via `index`.
public struct PlanStepRow: View {
    let kicker: String
    let value: String
    let index: Int
    let ground: DX.Ground

    public init(kicker: String, value: String, index: Int = 0, ground: DX.Ground = .mint) {
        self.kicker = kicker
        self.value = value
        self.index = index
        self.ground = ground
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(DX.Fill.cream)
                .frame(width: 26, height: 26)
                .background(DX.Fill.green, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(kicker).dxType(.caption).dxInk(ground, muted: true)
                Text(value).dxType(.body).dxInk(ground)
            }
            Spacer(minLength: 0)
        }
        .dxCardOnColour(on: ground)
        .accessibilityElement(children: .combine)
        .dxArrive(index)
    }
}

/// Program day card: a 40 pt icon box (done, play, lock, star), kicker and title. Today's card is apricot with a lip.
public struct ProgramDayCard: View {
    public enum Kind: Sendable { case done, today, locked, graduation }

    let kicker: String
    let title: String
    let state: Kind

    public init(kicker: String, title: String, state: Kind) {
        self.kicker = kicker
        self.title = title
        self.state = state
    }

    public var body: some View {
        let ground: DX.Ground = state == .today ? .apricot : .reading
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(iconInk)
                .frame(width: 40, height: 40)
                .background(iconBox, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(kicker).dxType(.caption).dxInk(ground, muted: true)
                Text(title).dxType(.headline).dxInk(ground)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous)
                .fill(state == .today ? DX.Ground.apricot.background : DX.Fill.raised)
                .shadow(color: .black.opacity(state == .today ? 0.14 : 0), radius: 0, x: 0, y: 5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(stateLabel)
    }

    private var icon: String {
        switch state {
        case .done: "checkmark"
        case .today: "play.fill"
        case .locked: "lock.fill"
        case .graduation: "star.fill"
        }
    }

    private var iconBox: Color {
        switch state {
        case .done: DX.Fill.green
        case .today: Color(light: 0x1E1A3A, dark: 0xFFC38A)
        case .locked, .graduation: DX.Fill.surface
        }
    }

    private var iconInk: Color {
        switch state {
        case .done: DX.Fill.cream
        case .today: Color(light: 0xFFF8EE, dark: 0x241433)
        case .locked, .graduation: DX.Ground.reading.muted
        }
    }

    private var stateLabel: String {
        switch state {
        case .done: "Done"
        case .today: "Today"
        case .locked: "Locked"
        case .graduation: "Graduation"
        }
    }
}

/// Health fact card: status kicker with the JSON's `when`, title, the JSON's `line`, and the entry's own
/// source label from health-timeline.json (for example "Source: American Cancer Society"), shown as is.
public struct HealthFactCard: View {
    let status: String
    let when: String
    let title: String
    let line: String
    let sourceLabel: String

    public init(status: String, when: String, title: String, line: String, sourceLabel: String) {
        self.status = status
        self.when = when
        self.title = title
        self.line = line
        self.sourceLabel = sourceLabel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(status) · \(when)").dxType(.caption).dxInk(.reading, muted: true)
            Text(title).dxType(.headline).dxInk(.reading)
            if !line.isEmpty { Text(line).dxType(.body).dxInk(.reading) }
            Text(sourceLabel).dxType(.caption).dxInk(.reading, muted: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dxReadingCard()
        .accessibilityElement(children: .combine)
    }
}

/// Notification preview: cream card, 40 pt character avatar on its colour, app and character name, time, message.
public struct NotificationPreview<Avatar: View>: View {
    let sender: String
    let time: String
    let message: String
    let avatar: Avatar

    public init(sender: String, time: String, message: String, @ViewBuilder avatar: () -> Avatar) {
        self.sender = sender
        self.time = time
        self.message = message
        self.avatar = avatar()
    }

    public var body: some View {
        // v5 (013): a cream card (the navy card in dark), "DayXero · Xero" and the time, then the message.
        HStack(alignment: .top, spacing: 12) {
            avatar.frame(width: 40, height: 40).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(verbatim: "DayXero · \(sender)").dxType(.caption)
                    Spacer()
                    Text(time).dxType(.caption)
                }
                .foregroundStyle(Color(light: 0x1E1A3A, dark: 0xFFF8EE))
                Text(message).dxType(.body).foregroundStyle(Color(light: 0x1E1A3A, dark: 0xFFF8EE))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color(light: 0xFFFCF7, dark: 0x182034), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color(light: (0x1E1A3A, 0), dark: (0xFFFFFF, 0.12)), lineWidth: 1))
        .shadow(color: Color(light: (0x4A2810, 0.08), dark: (0x000000, 0)), radius: 10, y: 6)
        .accessibilityElement(children: .combine)
    }
}

/// Hand-over chip: avatar plus "Xero passed you to Jelli". Fades out after about 3 s.
public struct HandOverChip<Avatar: View>: View {
    let text: String
    let avatar: Avatar
    @State private var visible = true
    private let motion = MotionPolicy()

    public init(_ text: String, @ViewBuilder avatar: () -> Avatar) {
        self.text = text
        self.avatar = avatar()
    }

    public var body: some View {
        HStack(spacing: 8) {
            avatar.frame(width: 28, height: 28)
            Text(text).dxType(.footnote).foregroundStyle(Color(light: 0x1E1A3A, dark: 0xFFF8EE))
        }
        .padding(.vertical, 6)
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .background(DX.Fill.cardOnColour, in: Capsule())
        .opacity(visible ? 1 : 0)
        .task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation(motion.animation(.easeOut(duration: 0.6))) { visible = false }
        }
    }
}

/// Breathing words: two stacked real-text layers cross-fading on the 4 s in / 6 s out clock.
/// VoiceOver reads both words once rather than following the fade.
public struct BreathingWords: View {
    let inhale: String
    let exhale: String

    public init(inhale: String = "Breathe in", exhale: String = "Breathe out") {
        self.inhale = inhale
        self.exhale = exhale
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let cycle = DX.Move.inhale + DX.Move.exhale
            let phase = t.truncatingRemainder(dividingBy: cycle)
            let breathingIn = phase < DX.Move.inhale
            // Cross-fade over the first 0.6 s of each half.
            let into = breathingIn ? phase : phase - DX.Move.inhale
            let fade = min(1, into / 0.6)
            ZStack {
                Text(inhale).opacity(breathingIn ? fade : 1 - fade)
                Text(exhale).opacity(breathingIn ? 1 - fade : fade)
            }
            .dxType(.large)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(inhale) for 4 seconds, \(exhale) for 6.")
    }
}

/// Drawn mood faces (no emoji): Rough, Okay, Good, Proud, used as a radio group.
public enum CheckInMood: String, CaseIterable, Sendable {
    case rough, okay, good, proud
    public var label: String { rawValue.capitalized }
}

public struct MoodFace: Shape {
    let mood: CheckInMood
    public init(_ mood: CheckInMood) { self.mood = mood }

    /// Drawn in a 32 × 32 box: two eyes and one of four mouths.
    public func path(in rect: CGRect) -> Path {
        let s = rect.width / 32
        var p = Path()
        p.addEllipse(in: CGRect(x: 10 * s, y: 11 * s, width: 3 * s, height: 3 * s))
        p.addEllipse(in: CGRect(x: 19 * s, y: 11 * s, width: 3 * s, height: 3 * s))
        let mouth: String = switch mood {
        case .rough: "M11 22 Q16 18 21 22"
        case .okay: "M11 20.5 L21 20.5"
        case .good: "M11 19 Q16 23 21 19"
        case .proud: "M10 18 Q16 26 22 18"
        }
        p.addPath(SVGPath.path(mouth), transform: CGAffineTransform(scaleX: s, y: s))
        return p.offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

public struct MoodPicker: View {
    /// Each mood's face colour: a moonlit grey, pale, warm and bright (kit 054).
    static func faceColor(_ mood: CheckInMood) -> Color {
        switch mood {
        case .rough: Color(hex: 0x8C93B8)
        case .okay: Color(hex: 0xEDE6D6)
        case .good: Color(hex: 0xFFD9A8)
        case .proud: Color(hex: 0xFF9A6B)
        }
    }

    @Binding var selection: CheckInMood?
    let ground: DX.Ground

    public init(selection: Binding<CheckInMood?>, ground: DX.Ground = .violet) {
        _selection = selection
        self.ground = ground
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(CheckInMood.allCases, id: \.self) { mood in
                let on = selection == mood
                // v5 (054): each mood a tile on the ground's card; the chosen tile lifts with a cream edge.
                Button { selection = mood } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Self.faceColor(mood))
                            MoodFace(mood).stroke(Color(hex: 0x1E1A3A), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                                .padding(4)
                        }
                        .frame(width: 44, height: 44)
                        Text(mood.label).dxFace(.body, 15, weight: on ? 700 : 600).dxInk(ground)
                    }
                    .frame(maxWidth: .infinity, minHeight: 96)
                    .background(on ? ground.card2 : ground.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(on ? ground.selEdge : ground.line, lineWidth: on ? 2 : 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mood.label)
                .accessibilityAddTraits(on ? [.isSelected] : [])
            }
        }
        .accessibilityElement(children: .contain)
        .sensoryFeedback(DX.Haptic.select, trigger: selection)
    }
}
