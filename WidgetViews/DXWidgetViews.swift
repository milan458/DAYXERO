import AppIntents
import DayXeroCore
import SwiftUI
import WidgetKit

/// The five DayXero widgets (S17.4–S17.8), built to `reference/widgets/`. Each view takes the rendering mode
/// explicitly so the app's debug gallery can show every mode; the widget extension passes the real one.
/// Rules: wins only (no zero or failure states), act without opening, no animation, nothing from the network.

private let sosURL = URL(string: "dayxero://sos?source=widget")!

/// Hides money and the word nicotine: on the Lock Screen when privacy mode is on, at home if that's on too (S17.11).
private func isPrivate(_ s: WidgetSnapshot, _ family: WidgetFamily) -> Bool {
    switch family {
    case .accessoryInline, .accessoryCircular, .accessoryRectangular: s.privacyMode
    default: s.privacyMode && s.privacyOnHomeScreen
    }
}

// MARK: - Day counter (S17.4)

struct DayCounterWidgetView: View {
    let snapshot: WidgetSnapshot
    let family: WidgetFamily
    let mode: WidgetRenderingMode
    /// StandBy hides the container background; the StandBy layout keeps the ring.
    var standBy = false

    var body: some View {
        let ink = WidgetInk(mode: mode)
        switch family {
        case .accessoryInline:
            inline
        default:
            if standBy { standByView(ink) } else { small(ink) }
        }
    }

    private var inline: some View {
        let s = snapshot
        let text: String
        switch s.phase {
        case .beforeDay1, .prep: text = String(localized: "Prep · Day \(max(s.prepDay, 1))")
        case .quit, .after:
            text = s.daysFree <= 1 ? String(localized: "Day Xero")
                : isPrivate(s, .accessoryInline) ? String(localized: "Day \(s.daysFree)")
                : String(localized: "Day \(s.daysFree) · \(s.moneyText) kept")
        }
        return Label { Text(verbatim: text) } icon: { Image(systemName: "circle") }
    }

    private func small(_ ink: WidgetInk) -> some View {
        let s = snapshot
        return VStack(alignment: .leading, spacing: 8) {
            switch s.phase {
            case .beforeDay1:
                big(String(localized: "Day 1"), size: 44)
                Text("Starts today").font(DX.Typeface4.swiftUIFont(.body, size: 17, weight: 600)).foregroundStyle(ink.sage)
            case .prep:
                big(String(localized: "Prep · Day \(max(s.prepDay, 1))"), size: 28)
                Text("Day Xero in \(s.daysUntilQuitDay) days").font(DX.Typeface4.swiftUIFont(.body, size: 17, weight: 600)).foregroundStyle(ink.sage)
                    .lineLimit(2).minimumScaleFactor(0.8)
            case .quit, .after:
                if s.daysFree <= 1 {
                    big(String(localized: "Day Xero"), size: 40)
                    Text("Starts today").font(DX.Typeface4.swiftUIFont(.body, size: 17, weight: 600)).foregroundStyle(ink.sage)
                } else {
                    big("\(s.daysFree)", size: 76)
                    Text("Since Quit Day").font(DX.Typeface4.swiftUIFont(.body, size: 17, weight: 600)).foregroundStyle(ink.sage)
                        .widgetAccentable()
                }
            }
        }
        .padding(.vertical, 16).padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(isPrivate(s, family) ? "\(s.daysFree) days" : "\(s.daysFree) days since Quit Day"))
    }

    private func big(_ text: String, size: CGFloat) -> some View {
        Text(verbatim: text)
            .font(DX.Typeface4.swiftUIFont(.display, size: size, weight: 800))
            .tracking(size >= 70 ? -3 : -1)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .widgetAccentable()
    }

    private func standByView(_ ink: WidgetInk) -> some View {
        let s = snapshot
        return HStack(spacing: 22) {
            ZStack {
                OrbGlyph(ink: ink, ringRadius: 62)
                Text(verbatim: s.daysFree <= 1 ? "0" : "\(s.daysFree)")
                    .font(DX.Typeface4.swiftUIFont(.display, size: 50, weight: 800)).foregroundStyle(.white)
            }
            .frame(width: 150, height: 150)
            VStack(alignment: .leading, spacing: 2) {
                Text("SINCE QUIT DAY").font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 600).monospacedDigit()).tracking(1).foregroundStyle(ink.sage)
                Text(s.currentDayStart, style: .timer)
                    .font(DX.Typeface4.swiftUIFont(.display, size: 40, weight: 800)).tracking(-1).foregroundStyle(.white)
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                Text("into day \(s.daysFree)").font(DX.Typeface4.swiftUIFont(.body, size: 14, weight: 500)).foregroundStyle(ink.secondary)
                if !isPrivate(s, .systemSmall) {
                    (Text(verbatim: s.moneyText).font(DX.Typeface4.swiftUIFont(.display, size: 22, weight: 800)).foregroundColor(.white)
                     + Text(" kept").font(DX.Typeface4.swiftUIFont(.body, size: 14, weight: 500)).foregroundColor(.white.opacity(0.55)))
                        .privacySensitive()
                        .padding(.top, 14)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Craving SOS (S17.5)

struct SOSWidgetView: View {
    let snapshot: WidgetSnapshot
    let family: WidgetFamily
    let mode: WidgetRenderingMode

    var body: some View {
        let ink = WidgetInk(mode: mode)
        if family == .accessoryCircular {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: "circle").font(.system(size: isPrivate(snapshot, family) ? 30 : 24, weight: .bold))
                    if !isPrivate(snapshot, family) {
                        Text("SOS").font(.system(size: 12, weight: .bold)).tracking(0.6)
                    }
                }
            }
            .accessibilityLabel(Text(isPrivate(snapshot, family) ? "Open DayXero help" : "Craving SOS"))
            .widgetURL(sosURL)
        } else {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    ZStack {
                        if ink.isFullColor {
                            // v4: Jelli owns SOS (decision 22). Tinted and vibrant modes keep the plain ring.
                            Circle().fill(Color(hex: 0x2A52DB)).frame(width: 96, height: 96)
                            JelliView(mood: .calm, stage: 1, points: 82, animate: false)
                        } else {
                            OrbGlyph(ink: ink)
                            Text("SOS").font(DX.Typeface4.swiftUIFont(.display, size: 13, weight: 800)).foregroundStyle(.white)
                        }
                    }
                    .frame(width: 120, height: 120)
                    .position(x: geo.size.width / 2, y: 60)
                    VStack(spacing: 6) {
                        Spacer(minLength: 0)
                        Text("Craving?").font(DX.Typeface4.swiftUIFont(.body, size: 13, weight: 600)).foregroundStyle(.white.opacity(0.7))
                        Button(intent: OpenSOSIntent()) {
                            Text("Ride it out").font(DX.Typeface4.swiftUIFont(.body, size: 14, weight: 600)).foregroundStyle(ink.onButton)
                                .frame(maxWidth: .infinity, minHeight: 34)
                                .background(ink.isFullColor ? WidgetTone.sage : .white, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .widgetAccentable()
                    }
                    .padding(14)
                }
            }
            .widgetURL(sosURL)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("Craving SOS. Ride it out."))
        }
    }
}

// MARK: - Today (S17.6)

struct TodayWidgetView: View {
    let snapshot: WidgetSnapshot
    let mode: WidgetRenderingMode

    var body: some View {
        let s = snapshot, ink = WidgetInk(mode: mode)
        let hidden = isPrivate(s, .systemMedium)
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if s.phase != .beforeDay1 {
                    VStack(spacing: 0) {
                        WidgetEyebrow(text: s.phase == .prep ? String(localized: "Prep day \(max(s.prepDay, 1))")
                                      : s.daysFree <= 1 ? String(localized: "Day Xero") : String(localized: "Day \(s.daysFree)"),
                                      color: ink.sage)
                        Text(verbatim: hidden ? "—" : s.moneyText)
                            .font(DX.Typeface4.swiftUIFont(.display, size: 32, weight: 800)).tracking(-1).foregroundStyle(.white)
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .privacySensitive()
                            .padding(.top, 6)
                        Text("kept").font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 500)).foregroundStyle(ink.secondary).padding(.top, 3)
                    }
                    .frame(width: 92)
                    .frame(maxHeight: .infinity)
                    Rectangle().fill(.white.opacity(0.1)).frame(width: 1).padding(.horizontal, 14)
                    VStack(spacing: 0) {
                        row(String(localized: "Cravings ridden out"), "\(s.cravingsRidden)")
                        Spacer(minLength: 0)
                        row(String(localized: "Water"), "\(s.glassesToday) / \(s.glassesGoal)")
                        Spacer(minLength: 0)
                        if let window = s.nextWindow {
                            row(String(localized: "Next window"), window.start.formatted(date: .omitted, time: .shortened).lowercased())
                        } else {
                            row(String(localized: "Water goal"), String(localized: "\(s.glassesGoal) glasses"))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("Your program starts with today's lesson.").font(DX.Typeface4.swiftUIFont(.body, size: 15, weight: 600))
                        .foregroundStyle(.white).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                VStack(spacing: 8) {
                    Button(intent: OpenSOSIntent()) {
                        WaveGlyph().stroke(ink.isFullColor ? Color.black : .black, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                            .frame(width: 20, height: 10)
                            .frame(width: 48, height: 48)
                            .background(ink.isFullColor ? WidgetTone.sage : .white, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Craving SOS"))
                    .widgetAccentable()
                    Button(intent: LogWaterIntent(from: .widget)) {
                        Image(systemName: "drop").font(.system(size: 18, weight: .semibold)).foregroundStyle(ink.sage)
                            .frame(width: 48, height: 48)
                            .background(.white.opacity(0.10), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Log a glass of water"))
                }
                .padding(.leading, 14)
            }
            .frame(maxHeight: .infinity)
            Rectangle().fill(.white.opacity(0.1)).frame(height: 0.5).padding(.top, 10)
            footer(ink).padding(.top, 10)
        }
        .padding(.top, 14).padding(.trailing, 14).padding(.bottom, 12).padding(.leading, 16)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(verbatim: label).foregroundStyle(.white.opacity(0.6)).lineLimit(1).minimumScaleFactor(0.8)
            Spacer(minLength: 6)
            Text(verbatim: value).fontWeight(.semibold).foregroundStyle(.white).lineLimit(1)
        }
        .font(DX.Typeface4.swiftUIFont(.body, size: 13, weight: 500))
    }

    @ViewBuilder
    private func footer(_ ink: WidgetInk) -> some View {
        HStack(spacing: 8) {
            Text("NEXT").font(DX.Typeface4.swiftUIFont(.body, size: 10, weight: 600).monospacedDigit()).tracking(0.8).foregroundStyle(.white.opacity(0.7))
            if let lesson = snapshot.nextLesson {
                Text(verbatim: lesson.title).font(DX.Typeface4.swiftUIFont(.body, size: 13, weight: 600)).foregroundStyle(.white).lineLimit(1)
                Text("· \(lesson.minutes) min").font(DX.Typeface4.swiftUIFont(.body, size: 13, weight: 500)).foregroundStyle(.white.opacity(0.5))
            } else if let milestone = snapshot.nextMilestone, snapshot.phase == .after {
                Text("\(milestone)-day milestone").font(DX.Typeface4.swiftUIFont(.body, size: 13, weight: 600)).foregroundStyle(.white)
            } else {
                Text("Weekly summary on Sunday").font(DX.Typeface4.swiftUIFont(.body, size: 13, weight: 600)).foregroundStyle(.white)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Water (S17.7)

struct WaterWidgetView: View {
    let snapshot: WidgetSnapshot
    let family: WidgetFamily
    let mode: WidgetRenderingMode

    var body: some View {
        let s = snapshot, ink = WidgetInk(mode: mode)
        let level = Double(s.glassesToday) / Double(s.glassesGoal)
        if family == .accessoryCircular {
            Button(intent: LogWaterIntent(from: .widget)) {
                Gauge(value: min(level, 1)) {
                    Image(systemName: "capsule.portrait.bottomhalf.filled")
                } currentValueLabel: {
                    VStack(spacing: 0) {
                        Image(systemName: "capsule.portrait.bottomhalf.filled").font(.system(size: 12, weight: .semibold))
                        Text(verbatim: "\(s.glassesToday)/\(s.glassesGoal)").font(.system(size: 13, weight: .bold)).minimumScaleFactor(0.7)
                    }
                }
                .gaugeStyle(.accessoryCircular)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Water, \(s.glassesToday) of \(s.glassesGoal) glasses. Log a glass."))
        } else {
            HStack(alignment: .center, spacing: 20) {
                WidgetPill(ink: ink, level: level, drink: s.lastDrink)
                    .frame(width: 56, height: 142)
                VStack(alignment: .leading, spacing: 0) {
                    WidgetEyebrow(text: String(localized: "Water"))
                    Spacer(minLength: 0)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(verbatim: "\(s.glassesToday)").font(DX.Typeface4.swiftUIFont(.display, size: 34, weight: 800))
                            .foregroundStyle(s.glassesToday >= s.glassesGoal ? ink.sage : .white)
                            .widgetAccentable()
                        Text(verbatim: "/ \(s.glassesGoal)").font(DX.Typeface4.swiftUIFont(.body, size: 17, weight: 700)).foregroundStyle(.white.opacity(0.5))
                    }
                    Text(s.glassesGoal == 1 ? "glass" : "glasses").font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 500)).foregroundStyle(ink.secondary)
                    Button(intent: LogWaterIntent(from: .widget)) {
                        Label("1", systemImage: "plus")
                            .labelStyle(PlusOneLabel())
                            .foregroundStyle(ink.onButton)
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background(ink.isFullColor ? WidgetTone.sage : .white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                    .accessibilityLabel(Text("Log a glass of water"))
                    .widgetAccentable()
                }
            }
            .padding(.top, 14).padding(.trailing, 14).padding(.bottom, 14).padding(.leading, 12)
            .accessibilityElement(children: .contain)
        }
    }
}

private struct PlusOneLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.font(.system(size: 13, weight: .bold))
            configuration.title.font(DX.Typeface4.swiftUIFont(.body, size: 15, weight: 600))
        }
    }
}

// MARK: - Craving forecast (S17.8)

struct ForecastWidgetView: View {
    let snapshot: WidgetSnapshot
    let family: WidgetFamily
    let mode: WidgetRenderingMode
    /// The timeline entry's date, to tell "now" from "next".
    let date: Date
    var guarding = false

    var body: some View {
        let ink = WidgetInk(mode: mode)
        if family == .accessoryRectangular { rectangular } else { small(ink) }
    }

    private var window: CravingPredictor.Window? { snapshot.nextWindow }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                ShieldGlyph(fill: .clear, stroke: .white, lineWidth: 1.4).frame(width: 12, height: 14)
                Text(isPrivate(snapshot, family) ? "Heads-up" : "Next window").font(.system(size: 12, weight: .semibold)).opacity(0.8)
            }
            if let window {
                if !isPrivate(snapshot, family) {
                    Text(verbatim: "\(hourText(window.start, prefix: false)) \(meridiem(window.start))").font(.system(size: 22, weight: .bold))
                }
                HStack(spacing: 0) {
                    if !isPrivate(snapshot, family), let trigger = window.trigger {
                        Text(trigger.title) + Text(verbatim: " · ")
                    }
                    Text("in \(Text(window.start, style: .relative))")
                }
                .font(.system(size: 12, weight: .medium)).opacity(0.75).lineLimit(1)
            } else {
                Text(snapshot.phase == .beforeDay1 ? "Learning your patterns" : "No risky windows today")
                    .font(.system(size: 15, weight: .bold)).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(URL(string: "dayxero://sos?source=forecast"))
    }

    private func small(_ ink: WidgetInk) -> some View {
        let now = window.map { date >= $0.start && date < $0.end } ?? false
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ShieldGlyph(fill: ink.moss.opacity(ink.isFullColor ? 0.5 : 1), stroke: ink.sage).frame(width: 16, height: 18)
                    .widgetAccentable()
                WidgetEyebrow(text: now ? String(localized: "Now") : String(localized: "Next window"))
            }
            Spacer(minLength: 0)
            if let window {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(verbatim: hourText(now ? window.end : window.start, prefix: now))
                        .font(DX.Typeface4.swiftUIFont(.display, size: now ? 26 : 34, weight: 800)).tracking(-1).foregroundStyle(.white)
                        .lineLimit(1).minimumScaleFactor(0.6)
                    Text(verbatim: meridiem(now ? window.end : window.start))
                        .font(DX.Typeface4.swiftUIFont(.display, size: 16, weight: 800)).foregroundStyle(.white.opacity(0.5))
                }
                HStack(spacing: 0) {
                    if let trigger = window.trigger { Text(trigger.title) + Text(verbatim: " · ") }
                    if now {
                        Text("ends \(Text(window.end, style: .relative))")
                    } else {
                        Text("in \(Text(window.start, style: .relative))")
                    }
                }
                .font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 500)).foregroundStyle(ink.secondary).lineLimit(1).minimumScaleFactor(0.8)
                Button(intent: GuardWindowIntent()) {
                    HStack(spacing: 4) {
                        Text(guarding ? "Guarding" : "Guard it")
                        if guarding { Image(systemName: "checkmark").accessibilityHidden(true) }
                    }
                    .font(DX.Typeface4.swiftUIFont(.body, size: 14, weight: 600)).foregroundStyle(ink.sage)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .background(ink.sage.opacity(0.16), in: Capsule())
                    .overlay(Capsule().strokeBorder(ink.sage.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(guarding)
                .padding(.top, 10)
            } else {
                Text(snapshot.phase == .beforeDay1 ? "Learning your patterns" : "No risky windows predicted today")
                    .font(DX.Typeface4.swiftUIFont(.body, size: 15, weight: 600)).foregroundStyle(.white).lineLimit(3)
                Text(snapshot.phase == .beforeDay1 ? "Log cravings to unlock" : "Enjoy the quiet.")
                    .font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 500)).foregroundStyle(ink.secondary).padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    /// "3:00" (and "until 3:40" during a window).
    private func hourText(_ date: Date, prefix: Bool) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return prefix ? String(localized: "until \(f.string(from: date))") : f.string(from: date)
    }

    private func meridiem(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "a"
        return f.string(from: date).lowercased()
    }
}
