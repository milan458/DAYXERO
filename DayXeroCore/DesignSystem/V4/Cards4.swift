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
    func dxCardOnColour(radius: CGFloat = DX.Layout.smallCardRadius) -> some View {
        padding(16).background(DX.Fill.cardOnColour, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// A card on the reading ground.
    func dxReadingCard(radius: CGFloat = DX.Layout.smallCardRadius) -> some View {
        padding(16).background(DX.Fill.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
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
                    Text(kicker.uppercased()).dxType(.caption).dxInk(ground, muted: true)
                    Text(title).dxType(.headline).dxInk(ground)
                    Text(detail).dxType(.footnote).dxInk(ground, muted: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ground.ink)
                    .frame(width: 44, height: 44)
                    .background(DX.Fill.cardOnColour, in: Circle())
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

/// A number that counts up when it appears or changes (Count motion: 0.85 s, ease-out cubic).
/// Reduce Motion shows the final value at once.
public struct CountingText: View {
    let value: Double
    let format: (Double) -> String
    @State private var from: Double = 0
    @State private var start = Date()
    @State private var running = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(_ value: Double, format: @escaping (Double) -> String) {
        self.value = value
        self.format = format
    }

    public var body: some View {
        TimelineView(.animation(paused: !running || reduceMotion)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            let p = running && !reduceMotion ? min(1, max(0, elapsed / 0.85)) : 1
            let eased = 1 - pow(1 - p, 3)
            Text(format(from + (value - from) * eased)).monospacedDigit()
        }
        .onAppear { stopSoon() }
        .onChange(of: value) { old, _ in
            from = old
            start = Date()
            running = true
            stopSoon()
        }
    }

    private func stopSoon() {
        Task {
            try? await Task.sleep(for: .seconds(0.9))
            running = false
        }
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
        VStack(alignment: .leading, spacing: 2) {
            CountingText(value, format: format).dxType(.title).dxInk(ground)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label).dxType(.caption).dxInk(ground, muted: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dxCardOnColour()
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
                Text(kicker.uppercased()).dxType(.caption).dxInk(ground, muted: true)
                Text(value).dxType(.body).dxInk(ground)
            }
            Spacer(minLength: 0)
        }
        .dxCardOnColour()
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
                Text(kicker.uppercased()).dxType(.caption).dxInk(ground, muted: true)
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
            Text("\(status.uppercased()) · \(when.uppercased())").dxType(.caption).dxInk(.reading, muted: true)
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
        HStack(alignment: .top, spacing: 12) {
            avatar.frame(width: 40, height: 40).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("DAYXERO · \(sender.uppercased())").dxType(.caption)
                    Spacer()
                    Text(time).dxType(.caption)
                }
                .foregroundStyle(Color(hex: 0x5E5975))
                Text(message).dxType(.footnote).foregroundStyle(DX.Fill.navy)
            }
        }
        .padding(14)
        .background(DX.Fill.cream, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Hand-over chip: avatar plus "Xero passed you to Jelli". Fades out after about 3 s.
public struct HandOverChip<Avatar: View>: View {
    let text: String
    let avatar: Avatar
    @State private var visible = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            withAnimation(DX.Move.animation(.easeOut(duration: 0.6), reduceMotion: reduceMotion)) { visible = false }
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
                Button { selection = mood } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle().fill(on ? ground.ink : DX.Fill.cardOnColour)
                            MoodFace(mood).stroke(on ? ground.background : ground.ink, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                        }
                        .frame(width: 32, height: 32)
                        Text(mood.label).dxType(.caption).dxInk(ground)
                    }
                    .frame(maxWidth: .infinity, minHeight: 64)
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
