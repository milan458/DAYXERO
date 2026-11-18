import DayXeroCore
import SwiftUI
import UserNotifications

// v4 onboarding screens (design doc §10, F01–F07). Copy follows the canvas except where the code
// and the canvas disagree, where it follows the code (decision 17): prices come from the store,
// the check-in reminder time from DailyReminderSettings, notification copy from NotificationCopy.

private let shortDate = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated)

// MARK: F01 Breathe · apricot (v5, 001)

/// One slow breath before any question. Skip is there from the start (S27.10).
///
/// Motion (001): Xero settles up 48 pt (900 ms) inside three soft rings, then the rings and Xero breathe together for
/// one 10 s cycle, 4 s in (scale .82 to 1.06) and 6 s out. "Breathe in" swaps for "And out" at 4 s (500 ms fade and
/// 6 pt rise). On the out-breath two cream puffs drift from his mouth. A hairline fills over the 10 s above a quiet
/// Skip. A gentle haptic at 0 and 4 s; the screen moves on at 10.4 s.
struct BreatheScreen: View {
    let onDone: () -> Void
    private let motion = MotionPolicy()
    @State private var opened = Date.now
    @State private var turned = false
    @State private var settled = false
    @Environment(\.colorScheme) private var scheme

    private let ground = DX.Ground.apricot

    var body: some View {
        GeometryReader { proxy in
            let h = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            let y = { (v: CGFloat) in v / 844 * h - proxy.safeAreaInsets.top }
            ZStack(alignment: .top) {
                TimelineView(.animation(paused: motion.reduce)) { timeline in
                    let t = motion.reduce ? 4 : timeline.date.timeIntervalSince(opened)
                    let scale = Self.breathScale(at: t)
                    // The rings are the pacer; Xero breathes in his own pose inside them.
                    ZStack {
                        rings.scaleEffect(scale)
                        XeroView(mood: .breathe, stage: 0, points: 176, pose: .breathPuffs, since: opened)
                            .padding(.top, 12)
                            .offset(y: settled ? 0 : 48)
                            .opacity(settled ? 1 : 0)
                    }
                    .frame(width: 300, height: 300)
                }
                .position(x: proxy.size.width / 2, y: y(212 + 150))
                .accessibilityHidden(true)
                VStack(spacing: 12) {
                    ZStack {
                        Text("Breathe in")
                            .opacity(turned ? 0 : 1).offset(y: turned ? 6 : 0)
                        Text("And out")
                            .opacity(turned ? 1 : 0).offset(y: turned ? 0 : 6)
                    }
                    .dxType(.large)
                    .foregroundStyle(ground.ink)
                    .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.5), value: turned)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(turned ? "And out" : "Breathe in"))
                    .accessibilityAddTraits(.isHeader)
                    .dxArrive(1)
                    Text("One slow breath before we start.")
                        .dxType(.body)
                        .foregroundStyle(ground.muted)
                        .multilineTextAlignment(.center)
                        .dxArrive(2)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .frame(width: proxy.size.width)
                .offset(y: y(556))
                VStack(spacing: 14) {
                    // A hairline that fills over the breath: the screen moves on by itself.
                    TimelineView(.animation(minimumInterval: 1 / 30, paused: motion.reduce)) { timeline in
                        let p = motion.reduce ? 0.6 : min(1, max(0, timeline.date.timeIntervalSince(opened) / 10))
                        ZStack(alignment: .leading) {
                            Capsule().fill(ground.ink.opacity(0.2))
                            Capsule().fill(ground.ink).frame(width: 132 * p)
                        }
                        .frame(width: 132, height: 3)
                    }
                    .accessibilityHidden(true)
                    .dxArrive(3)
                    Button("Skip", action: onDone)
                        .buttonStyle(.dx(.quiet, on: ground))
                        .dxArrive(4)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, max(0, 30 - proxy.safeAreaInsets.bottom))
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: turned)
        .task {
            opened = .now
            withAnimation(motion.animation(DX.Move.settle)) { settled = true }
            guard !motion.reduce else {
                turned = true
                try? await Task.sleep(for: .seconds(5))
                if !Task.isCancelled { onDone() }
                return
            }
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            turned = true
            try? await Task.sleep(for: .seconds(6.4))
            guard !Task.isCancelled else { return }
            onDone()
        }
    }

    /// Three rings, 300, 244 and 188 pt: card-2 at 38, 62 and 100% on apricot; in dark, soft amber glows with rims.
    private var rings: some View {
        let dark = scheme == .dark
        return ZStack {
            ForEach(0..<3, id: \.self) { i in
                let size: CGFloat = [300, 244, 188][i]
                if dark {
                    let g1 = [0.0, 0.01, 0.02][i], g2 = [0.025, 0.035, 0.05][i], rim = [0.16, 0.2, 0.28][i]
                    Circle()
                        .fill(RadialGradient(colors: [Color(hex: 0xFFC24D).opacity(g1), Color(hex: 0xFFC24D).opacity(g2)],
                                             center: .center, startRadius: 0, endRadius: size / 2))
                        .overlay(Circle().strokeBorder(Color(red: 1, green: 200 / 255, blue: 120 / 255).opacity(rim), lineWidth: 1))
                        .frame(width: size, height: size)
                } else {
                    Circle().fill(ground.card2.opacity([0.38, 0.62, 1][i])).frame(width: size, height: size)
                }
            }
        }
    }

    /// The kit's `dx-breathe`: .82 to 1.06 over the first 4 s, back to .82 by 10 s, eased on each leg.
    static func breathScale(at t: Double) -> CGFloat {
        let curve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.45, y: 0), endControlPoint: UnitPoint(x: 0.55, y: 1))
        let c = t.truncatingRemainder(dividingBy: 10)
        if c < 4 { return 0.82 + 0.24 * curve.value(at: c / 4) }
        return 1.06 - 0.24 * curve.value(at: (c - 4) / 6)
    }
}

// MARK: F02 Welcome · apricot (v5, 002)

/// The promise, a restore link for returning buyers, and the 18+ line with Terms and Privacy.
///
/// Motion (002): continues the launch scene. The two paper hills settle up (0 and 120 ms, 900 ms) and the sun climbs
/// 60 pt (1200 ms). Xero settles onto the crest from 300 ms, then waves twice from 1.2 s. At 1.1 s the speech bubble
/// rises in. Headline, body and dock arrive in reading order from 500 ms. Light haptic on Get started.
struct WelcomeScreen: View {
    let model: OnboardingModel
    @Environment(Entitlement.self) private var entitlement
    @State private var restoreNote: LocalizedStringKey?
    @State private var restoring = false
    @State private var opened = Date.now
    @State private var started = 0
    private let motion = MotionPolicy()

    @Environment(\.dynamicTypeSize) private var typeSize

    private let ground = DX.Ground.apricot

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 390
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    WelcomeArt(opened: opened)
                        .frame(width: proxy.size.width, height: 450 * scale)
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 0) {
                                Text("Quit on your ")
                                Text("own day.").dxMark(color: DX.Mark.color(on: .apricot))
                            }
                            Text("We'll get you ready.")
                        }
                        .dxType(.large)
                        .foregroundStyle(ground.ink)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                        .minimumScaleFactor(0.8)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isHeader)
                        .dxArrive(6, delay: 0)
                        Text("Short prep sessions for up to 7 days, while you still smoke or vape.")
                            .dxType(.body)
                            .foregroundStyle(ground.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .dxArrive(7, delay: 0)
                        if let restoreNote {
                            Text(restoreNote).dxType(.footnote).foregroundStyle(ground.muted)
                        }
                    }
                    .padding(.horizontal, DX.Layout.gutter)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDisabled(!typeSize.isAccessibilitySize)
            .ignoresSafeArea(.container, edges: .top)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Button("Get started") {
                        started += 1
                        model.next()
                    }
                    .buttonStyle(.dx(.primary, on: ground))
                    .padding(.bottom, 4)
                    .dxArrive(8, delay: 0)
                    Button("Restore purchases") { Task { await restore() } }
                        .dxFace(.body, 14, weight: 500)
                        .foregroundStyle(ground.muted)
                        .frame(height: 34)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .disabled(restoring)
                        .dxArrive(9, delay: 0)
                    legal
                        .dxType(.caption)
                        .foregroundStyle(ground.muted)
                        .tint(ground.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.top, 2)
                        .frame(maxWidth: .infinity)
                        .dxArrive(10, delay: 0)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, 24)
                .padding(.bottom, 4)
            }
        }
        .dxReadableColumn()
        .sensoryFeedback(.impact(weight: .light), trigger: started)
        .onAppear { opened = .now }
    }

    /// The 18+ line with the Terms and Privacy links (S15.4, S27.1), underlined as in 002.
    private var legal: Text {
        let terms = "[\(String(localized: "Terms"))](\(AppLinks.terms.absoluteString))"
        let line: String
        if let privacy = AppLinks.privacy {
            let policy = "[\(String(localized: "Privacy"))](\(privacy.absoluteString))"
            line = String(localized: "18+ only. By continuing you agree to our \(terms) and \(policy).")
        } else {
            line = String(localized: "18+ only. By continuing you agree to our \(terms).")
        }
        var text = (try? AttributedString(markdown: line)) ?? AttributedString(line)
        for run in text.runs where run.link != nil { text[run.range].underlineStyle = .single }
        return Text(text)
    }

    /// Someone who bought before (new phone, reinstall) gets Pro back now.
    private func restore() async {
        restoring = true
        defer { restoring = false }
        do {
            if try await entitlement.store.restore() {
                entitlement.grant()
                restoreNote = "Your purchase is restored. Set up your plan and everything is unlocked."
            } else {
                restoreNote = "No purchases found for this Apple ID."
            }
        } catch {
            restoreNote = "Couldn't reach the App Store. You can restore later in Settings."
        }
    }
}

// MARK: F04 Quit Day · apricot (canvas "Evidence story", board 6)

/// The date on one card (the sun badge, the date, "Change", then the prep week as numbered days ending on the sun),
/// the one trial that compared stopping all at once with cutting down as two groups of 100, and the hold.
///
/// Motion: title, the date card (the days pop left to right), the evidence card and the hold arrive in order. Holding
/// fills the button over 1500 ms; on complete it shows "Quit Day set", the sun badge bumps and the caption swaps to
/// "Quit Day set" with a green tick. 1200 ms later the button crossfades into Continue.
struct QuitDayScreen: View {
    @Bindable var model: OnboardingModel
    @State private var picking = false
    @State private var committed = false
    @State private var showContinue = false
    @State private var research = false
    private let motion = MotionPolicy()
    private let ground = DX.Ground.apricot

    /// The prep days, today to the day before Quit Day (at most seven).
    private var prepDays: [Date] {
        let quit = model.calendar.startOfDay(for: model.quitDay)
        var days: [Date] = []
        var day = model.today
        while day < quit, days.count < 7 {
            days.append(day)
            day = model.calendar.date(byAdding: .day, value: 1, to: day) ?? quit
        }
        return days
    }

    private var recommended: Bool { model.calendar.isDate(model.quitDay, inSameDayAs: model.recommendedQuitDay) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(model.name.isEmpty ? "Pick your\nQuit Day" : "Pick your\nQuit Day, \(model.name)")
                    .dxType(.large).foregroundStyle(ground.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .dxArrive(0)
                Text("I recommend a full week of prep first. Keep using as normal until then.")
                    .dxType(.body).foregroundStyle(ground.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .dxArrive(1)
                dateCard.padding(.top, 8).dxArrive(2)
                EvDotsCard(kicker: "Still quit at six months, in one trial",
                           aLabel: "Stopped all at once", a: 22, bLabel: "Cut down first", b: 16,
                           note: "That is one trial. Across 22 trials neither way came out ahead, so a clean stop on a set day works at least as well as cutting down.",
                           source: "Lindson-Hawley et al., 2016") { research = true }
                    .padding(.top, 2)
                    .dxArrive(4)
            }
            .padding(.horizontal, DX.Layout.gutter)
            .dxReadableColumn()
            .padding(.top, DX.Space.m)
            .padding(.bottom, DX.Space.s)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 10) {
                ZStack {
                    HoldButton(String(localized: "Hold to set your Quit Day"), done: String(localized: "Quit Day set"),
                               duration: 1.5, on: ground) {
                        withAnimation(motion.animation(DX.Move.settle.speed(0.9 / 0.7))) { committed = true }
                        Task {
                            try? await Task.sleep(for: .seconds(1.2))
                            withAnimation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.35)) { showContinue = true }
                        }
                    }
                    .accessibilityIdentifier("onboarding.hold")
                    .disabled(!model.canContinue)
                    .opacity(showContinue ? 0 : 1)
                    .allowsHitTesting(!showContinue)
                    Button("Continue") { model.next() }
                        .buttonStyle(.dx(.primary, on: ground))
                        .opacity(showContinue ? 1 : 0)
                        .offset(y: showContinue ? 0 : 6)
                        .allowsHitTesting(showContinue)
                        .accessibilityHidden(!showContinue)
                }
                .dxArrive(8)
                Text("Quit Day comes on this date, even if prep runs short. You can change it later.")
                    .dxType(.caption).foregroundStyle(ground.muted)
                    .multilineTextAlignment(.center)
                    .dxArrive(9)
            }
            .padding(.horizontal, DX.Layout.gutter)
            .dxReadableColumn()
            .padding(.top, 28)
            .padding(.bottom, DX.Space.xs)
            .background {
                LinearGradient(stops: [.init(color: ground.background.opacity(0), location: 0), .init(color: ground.background, location: 0.34)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .sensoryFeedback(.success, trigger: committed) { _, done in done }
        .onChange(of: model.quitDay) {
            // A new date has to be held again.
            committed = false
            showContinue = false
        }
        .sheet(isPresented: $picking) {
            NavigationStack {
                ScrollView {
                    QuitDayCalendar(quitDay: $model.quitDay, today: model.today, range: model.quitDayRange, calendar: model.calendar)
                        .padding(DX.Layout.gutter)
                }
                .background(DX.Ground.reading.background)
                .navigationTitle("Pick your Quit Day")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { picking = false } } }
            }
            .presentationDetents([.medium, .large])
        }
        .researchSheet(isPresented: $research, product: model.evidenceProduct)
    }

    /// The sun badge, the date and "Change" over a hairline, then the prep week.
    private var dateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { picking = true } label: {
                HStack(spacing: 12) {
                    SunBadge(size: 44).dxBump(committed)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(model.quitDay, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                            .dxFace(.display, 26, weight: 800, tracking: -0.7).foregroundStyle(ground.ink)
                            .lineLimit(1).minimumScaleFactor(0.7)
                        ZStack(alignment: .leading) {
                            Text(recommended ? "Recommended" : "Your Quit Day")
                                .dxFace(.body, 14, weight: 500).foregroundStyle(ground.muted)
                                .opacity(committed ? 0 : 1)
                            HStack(spacing: 4) {
                                Text("Quit Day set").foregroundStyle(ground.ink)
                                DXIcon(.check, size: 11, weight: 3.4).foregroundStyle(.white)
                                    .frame(width: 16, height: 16).background(DX.Fill.done, in: Circle())
                                    .padding(.leading, 2)
                            }
                            .dxFace(.body, 14, weight: 700)
                            .opacity(committed ? 1 : 0)
                        }
                        .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.3), value: committed)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Change")
                        .dxFace(.body, 15, weight: 600).foregroundStyle(ground.ink)
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background(Color(light: 0xFFDCC2, dark: 0x2E3957), in: Capsule())
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.dxPress)
            .accessibilityLabel(Text("Quit Day, \(model.quitDay.formatted(.dateTime.weekday(.wide).day().month(.wide)))"))
            .accessibilityHint(Text("Change the date"))
            Rectangle().fill(Color(light: (0x1E1A3A, 0.12), dark: (0xFFFFFF, 0.12))).frame(height: 1)
            HStack(alignment: .firstTextBaseline) {
                Text("Your prep week").dxFace(.body, 15, weight: 700).foregroundStyle(ground.ink)
                Spacer()
                Text("^[\(prepDays.count) short session](inflect: true)").dxFace(.body, 14, weight: 500).foregroundStyle(ground.muted)
            }
            HStack(spacing: 2) {
                ForEach(Array(prepDays.enumerated()), id: \.element) { i, day in
                    dayStop(day, n: i + 1).dxPop(0, delay: 0.35 + Double(i) * 0.06)
                }
                VStack(spacing: 5) {
                    SunBadge(size: 32)
                    Text(initial(model.quitDay)).dxFace(.body, 13, weight: 700).foregroundStyle(ground.ink)
                }
                .frame(maxWidth: .infinity)
                .dxPop(0, delay: 0.35 + Double(prepDays.count) * 0.06)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Quit Day, \(model.quitDay.formatted(.dateTime.weekday(.wide).day().month(.wide)))"))
            }
        }
        .padding(.top, 14).padding(.horizontal, 16).padding(.bottom, 16)
        .evCard()
    }

    /// One prep day: its number in a ring (today's filled with ink) over the weekday's initial.
    private func dayStop(_ day: Date, n: Int) -> some View {
        let today = n == 1
        return VStack(spacing: 5) {
            Text(verbatim: "\(n)")
                .dxFace(.display, 14, weight: 700)
                .foregroundStyle(today ? Ev.selFg : ground.muted)
                .frame(width: 32, height: 32)
                .background { if today { Circle().fill(Ev.sel) } else { Circle().strokeBorder(Color(light: (0x1E1A3A, 0.42), dark: (0xFFFFFF, 0.42)), lineWidth: 1.5) } }
            Text(initial(day)).dxFace(.body, 13, weight: 600).foregroundStyle(ground.muted)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(day, format: .dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityValue(Text("Prep day \(n)"))
    }

    /// "W" for Wednesday.
    private func initial(_ day: Date) -> String {
        day.formatted(.dateTime.weekday(.narrow))
    }
}

/// The Quit Day sun: a yellow disc with an amber ring and a line sun inside.
private struct SunBadge: View {
    let size: CGFloat

    var body: some View {
        EvGlyph(d: "M12 8 a4 4 0 1 0 0.01 0 M12 2 v2 M12 20 v2 M2 12 h2 M20 12 h2 M4.9 4.9 l1.4 1.4 M17.7 17.7 l1.4 1.4 M4.9 19.1 l1.4 -1.4 M17.7 6.3 l1.4 -1.4",
                size: size / 2, weight: 2.3)
            .foregroundStyle(Color(hex: 0x1E1A3A))
            .frame(width: size, height: size)
            .background(Color(hex: 0xFFC93C), in: Circle())
            .overlay(Circle().strokeBorder(Color(hex: 0xF29A2E), lineWidth: 2.5))
            .shadow(color: Color(hex: 0xFFC93C).opacity(size > 40 ? 0.45 : 0), radius: 6)
            .accessibilityHidden(true)
    }
}

// MARK: F05 Your plan builds · apricot (v5, 011)

/// A short build beat: the title with Xero (proud) beside it, then three plan pieces settle up one by one, then the
/// status line says it's built and the button arrives.
///
/// Motion (011): the pieces settle 420 ms apart (900 ms each) from 450 ms, a light haptic as each lands. At 2.1 s the
/// status swaps to "Built from your answers" with the screen's one green check (420 ms pop), Xero bumps (success
/// haptic) and the button arrives.
struct BuildingScreen: View {
    let model: OnboardingModel
    @State private var built = false
    @State private var landed = 0
    private let motion = MotionPolicy()
    private let ground = DX.Ground.apricot

    private struct Row: Identifiable {
        let id: Int
        let art: PlanPieceArt.Kind
        let kicker: String
        let value: String
        var detail: String? = nil
        var quit = false
    }

    private var rows: [Row] {
        var all = [Row(id: 0, art: .flag, kicker: String(localized: "Quit Day"),
                       value: model.quitDay.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()), quit: true)]
        let waves = Trigger.allCases.filter(model.triggers.contains).prefix(2)
            .map { $0 == .other ? String(localized: "other moments") : String(localized: $0.title).lowercased() }
        if !waves.isEmpty {
            all.append(Row(id: 1, art: .wave, kicker: String(localized: "Waves to watch"),
                           value: BaselineScreenCopy.list(Array(waves)).capitalizedFirst,
                           detail: String(localized: "When your cravings tend to rise")))
        }
        let why = model.why.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !why.isEmpty {
            all.append(Row(id: 2, art: .heart, kicker: String(localized: "Your reason"), value: "“\(why)”"))
        }
        return all
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 6) {
                    Text("Your plan,\nbuilt around you")
                        .dxFace(.display, 30, weight: 800, tracking: -1)
                        .foregroundStyle(ground.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .dxArrive(0)
                    XeroView(mood: .cheer, stage: 0, points: 120)
                        .dxBob()
                        .dxBump(built)
                        .frame(width: 120, height: 120)
                        .padding(.trailing, -6)
                        .dxSettle(delay: 0.2)
                        .accessibilityHidden(true)
                }
                ZStack(alignment: .leading) {
                    Text("Putting the pieces together")
                        .dxType(.footnote).foregroundStyle(ground.muted)
                        .opacity(built ? 0 : 1).offset(y: built ? -6 : 0)
                    HStack(spacing: 8) {
                        DXCheck(size: 20).scaleEffect(built ? 1 : 0.4).opacity(built ? 1 : 0)
                            .animation(.timingCurve(0.3, 1.4, 0.5, 1, duration: 0.42), value: built)
                        (Text("Built from your answers.").dxRun(15, weight: 700).foregroundStyle(ground.ink) + Text(" All yours."))
                            .dxType(.footnote).foregroundStyle(ground.ink)
                    }
                    .opacity(built ? 1 : 0).offset(y: built ? 0 : 6)
                }
                .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.4), value: built)
                .frame(height: 32, alignment: .leading)
                .dxArrive(1)
                VStack(spacing: 16) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { i, row in
                        piece(row)
                            .dxSettle(0, delay: 0.45 + Double(i) * 0.42)
                            .task {
                                try? await Task.sleep(for: .seconds(motion.reduce ? 0 : 0.45 + Double(i) * 0.42 + 0.6))
                                landed += 1
                            }
                    }
                }
                .padding(.top, 34)
            }
            .padding(.horizontal, DX.Layout.gutter)
            .padding(.top, DX.Space.s)
            .dxReadableColumn()
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("See my plan") { model.next() }
                .buttonStyle(.dx(.primary, on: ground))
                .opacity(built ? 1 : 0)
                .offset(y: built ? 0 : 18)
                .allowsHitTesting(built)
                .accessibilityHidden(!built)
                .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.6), value: built)
                .padding(.horizontal, DX.Layout.gutter)
                .dxReadableColumn()
                .padding(.top, 28)
                .padding(.bottom, DX.Space.xs)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: landed)
        .sensoryFeedback(.success, trigger: built) { _, done in done }
        .task {
            try? await Task.sleep(for: .seconds(motion.reduce ? 0.3 : 2.1))
            built = true
        }
    }

    private func piece(_ row: Row) -> some View {
        HStack(spacing: 14) {
            PlanPieceArt(kind: row.art)
                .frame(width: 48, height: 48)
                .background(ground.card2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: row.kicker).dxType(.caption).foregroundStyle(ground.muted)
                Text(verbatim: row.value)
                    .dxFace(.display, row.quit ? 22 : 17, weight: row.quit ? 800 : 700, tracking: row.quit ? -0.4 : -0.2)
                    .foregroundStyle(ground.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = row.detail {
                    Text(verbatim: detail).dxType(.caption).foregroundStyle(ground.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16).padding(.vertical, 18)
        .frame(minHeight: 102)
        .background(row.quit ? Color(light: 0xFFF8EE, dark: 0x212A41) : ground.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(row.quit ? Color(light: (0x1E1A3A, 0.12), dark: (0xFFFFFF, 0.14)) : Onb.chipLine, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

// MARK: F06 Your plan is ready · apricot (canvas "Evidence story", board 7)

/// The dawn across the top with the Day 0 medallion as its sun and Xero cheering beside it, the plan in one sentence
/// (prep days, the date, the money back in a year), what the plan is built on (each method with what was found for
/// it, and the plain line that DayXero itself hasn't been trialled), and the first prep stamp.
/// The hard paywall follows onboarding (16 Nov 2026): yearly with a 3-day trial, or 3 months, and it carries the terms.
/// Nothing is charged here.
///
/// Motion: the medallion pops in (700 ms spring, from 300 ms), Xero settles beside it (from 450 ms) and cheers; the
/// underline draws under "ready"; the lead, the two cards and the button arrive in order. A light haptic as the
/// medallion lands.
struct PlanRevealScreen: View {
    let model: OnboardingModel
    let onContinue: () -> Void

    @Environment(Entitlement.self) private var entitlement
    @Environment(\.colorScheme) private var scheme
    @State private var showPlans = false
    @State private var landed = false
    @State private var research = false
    private let motion = MotionPolicy()
    private let ground = DX.Ground.apricot

    /// The scene's height from the top of the screen, status bar and the floating header included: the canvas's 300
    /// plus the room the header takes above the medallion.
    private static let heroHeight: CGFloat = 356
    private static let heroDrop: CGFloat = 56

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero
                VStack(alignment: .leading, spacing: 0) {
                    MarkedTitle(String(localized: "Your plan is "), marking: String(localized: "ready"), color: DX.Mark.color(on: ground))
                        .dxType(.large).foregroundStyle(ground.ink)
                        .accessibilityAddTraits(.isHeader)
                        .dxArrive(0)
                    lead
                        .dxType(.body).foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)
                        .dxArrive(1)
                    builtOn.padding(.top, 18).dxArrive(2)
                    stamps.padding(.top, 12).dxArrive(4)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, 6)
                .padding(.bottom, DX.Space.m)
                .dxReadableColumn()
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        // The dawn runs up under the status bar; the flow floats the header over it (`overlaysTopBar`).
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 6) {
                Button("Start my prep week") {
                    landed.toggle()
                    onContinue()
                }
                .buttonStyle(.dx(.primary, on: ground))
                .dxArrive(6)
                if !entitlement.isPro {
                    Button("See all plans") { showPlans = true }
                        .dxFace(.body, 15, weight: 600)
                        .foregroundStyle(ground.ink.opacity(0.85))
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .dxArrive(7)
                }
            }
            .padding(.horizontal, DX.Layout.gutter)
            .dxReadableColumn()
            .padding(.top, 28)
            .padding(.bottom, DX.Space.xs)
            .background {
                LinearGradient(stops: [.init(color: ground.background.opacity(0), location: 0), .init(color: ground.background, location: 0.34)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: landed)
        .task {
            try? await Task.sleep(for: .seconds(1.0))
            landed.toggle()
        }
        .fullScreenCover(isPresented: $showPlans) {
            PaywallView(name: model.name, quitDay: model.quitDay,
                        model: PaywallModel(store: entitlement.store, entitlement: entitlement), onClose: { showPlans = false },
                        spend: PaywallModel.Spend(perYear: model.stats.moneyPerYear, currencyCode: model.currencyCode,
                                                  products: model.orderedProducts))
        }
        .researchSheet(isPresented: $research, product: model.evidenceProduct)
        #if DEBUG
        // Screenshots: launch with `-dx.research YES` to open the research sheet over the plan.
        .onAppear { if UserDefaults.standard.bool(forKey: "dx.research") { research = true } }
        #endif
    }

    private var dateText: String { model.quitDay.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) }

    /// "Seven prep days, then your Quit Day on Wed, Nov 25. About $1,825 back in your pocket in a year."
    private var lead: Text {
        let n = max(model.prepDays, 0)
        let strong = { (s: String) in Text(verbatim: s).dxRun(16, weight: 700).foregroundStyle(ground.ink) }
        var text: Text
        if n == 0 {
            text = Text("Your Quit Day is today.")
        } else {
            let f = NumberFormatter()
            f.numberStyle = .spellOut
            let word = (f.string(from: n as NSNumber) ?? "\(n)").capitalizedFirst
            text = (n == 1 ? Text("One prep day, then your Quit Day on ") : Text("\(word) prep days, then your Quit Day on "))
                + strong(dateText) + Text(verbatim: ".")
        }
        let perYear = model.stats.moneyPerYear
        if perYear > 0 {
            let money = perYear.formatted(.currency(code: model.currencyCode).precision(.fractionLength(0)))
            text = text + Text(" About ") + strong(money) + Text(" back in your pocket in a year.")
        }
        return text
    }

    /// The dawn (dusk-dawn in dark) with the medallion and Xero, settling into the page through a paper edge.
    private var hero: some View {
        let dark = scheme == .dark
        let g = ground.background
        return GeometryReader { proxy in
            // The medallion and Xero keep their canvas spacing and stay centred on wider screens.
            let x0 = (proxy.size.width - 390) / 2
            ZStack(alignment: .topLeading) {
                if dark {
                    NightSky(dawn: true, animate: !motion.reduce,
                             options: .init(sunAt: 0.67, sunScale: 0, sunLift: 12, softSun: true, stars: false, fade: false))
                } else {
                    HorizonScene(.dawn, clarity: 100, fit: .bottom, animate: !motion.reduce,
                                 sun: .init(x: 262, radius: 0, drop: -20, clouds: false))
                }
                medallion
                    .offset(x: x0 + 192, y: 58 + Self.heroDrop)
                    .dxPop(delay: 0.3)
                Ellipse()
                    .fill(RadialGradient(colors: [dark ? Color.black.opacity(0.55) : Color(hex: 0x50140A).opacity(0.35), .clear],
                                         center: .center, startRadius: 0, endRadius: 44))
                    .frame(width: 88, height: 14)
                    .offset(x: x0 + 66, y: 250 + Self.heroDrop)
                XeroView(mood: .cheer, stage: 0, points: 116, animate: !motion.reduce)
                    .shadow(color: dark ? Color(hex: 0xFFAA5A).opacity(0.45) : Ev.cream.opacity(0.95), radius: dark ? 8 : 2.5,
                            x: dark ? 4 : 0, y: dark ? -2 : 0)
                    .shadow(color: dark ? .clear : Color(hex: 0x781E0A).opacity(0.22), radius: 10, y: 6)
                    .frame(width: 116, height: 116)
                    .offset(x: x0 + 52, y: 142 + Self.heroDrop)
                    .dxSettle(delay: 0.45)
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ZStack(alignment: .bottom) {
                        LinearGradient(colors: [g.opacity(0), g.opacity(0.85)], startPoint: .top, endPoint: .bottom).frame(height: 56)
                        PlanEdge().fill(g).frame(height: 30)
                    }
                }
            }
        }
        .frame(height: Self.heroHeight)
        .clipped()
        .accessibilityElement()
        .accessibilityLabel(Text("The Day Xero medallion, waiting for your Quit Day, with Xero cheering beside it."))
    }

    /// "DAY 0" on the sun-yellow coin, ringed twice, with a soft glow.
    private var medallion: some View {
        let dark = scheme == .dark
        return VStack(spacing: 0) {
            Text(verbatim: "DAY").dxFace(.body, 12, weight: 700, tracking: 1)
            Text(verbatim: "0").dxFace(.display, 46, weight: 800, tracking: -1).padding(.top, -6)
        }
        .foregroundStyle(Color(hex: 0x8A4A08))
        .frame(width: 140, height: 140)
        .background {
            ZStack {
                Circle().fill(dark ? Color(hex: 0xFFAA50).opacity(0.32) : Color(hex: 0xFFF0C8).opacity(0.7)).frame(width: 196, height: 196).blur(radius: 18)
                Circle().fill(dark ? Color(hex: 0xFFC93C).opacity(0.10) : Ev.cream.opacity(0.34)).frame(width: dark ? 160 : 164, height: dark ? 160 : 164)
                Circle().fill(Color(hex: 0xFFC93C))
                Circle().strokeBorder(Color(hex: 0xFFD966), lineWidth: 11)
                Circle().strokeBorder(Color(hex: 0xF29A2E), lineWidth: 5)
            }
        }
        .accessibilityHidden(true)
    }

    private struct BuiltRow: Identifiable {
        let id: Int
        let illo: EvIllo.Kind
        let title: LocalizedStringKey
        let detail: String
    }

    /// The methods this plan uses, from the answers given: nicotine replacement only if it was wanted, the when-then
    /// plans named by trigger.
    private var builtRows: [BuiltRow] {
        var rows: [BuiltRow] = []
        if model.nrtInterest == .using || model.nrtInterest == .wantIt {
            rows.append(BuiltRow(id: 0, illo: .patch, title: "Nicotine replacement",
                                 detail: model.pregnancy == .yes
                                     ? String(localized: "Talk to your midwife or doctor first.")
                                     : String(localized: "In trials, quit rates rose 50 to 60%.")))
        }
        let picked = Trigger.allCases.filter(model.triggers.contains).map(\.evPlanWord)
        if !picked.isEmpty {
            let detail: String
            switch picked.count {
            case 1: detail = String(localized: "For \(picked[0]).")
            case 2: detail = String(localized: "For \(picked[0]) and for \(picked[1]).")
            default: detail = String(localized: "For \(picked[0]), \(picked[1]) and \(picked.count - 2) more.")
            }
            rows.append(BuiltRow(id: 1, illo: .plan, title: "Your when-then plans", detail: detail))
        }
        rows.append(BuiltRow(id: 2, illo: .bubble, title: "A check-in every day", detail: String(localized: "A morning pledge and a night check-in.")))
        rows.append(BuiltRow(id: 3, illo: .sun, title: "A clean stop on Quit Day",
                             detail: String(localized: "First goal: 28 days. The NHS says that makes you 5 times more likely to stay quit.")))
        return rows
    }

    private var builtOn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What it’s built on")
                .dxFace(.display, 19, weight: 700, tracking: -0.2).foregroundStyle(ground.ink)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(builtRows) { row in
                    HStack(alignment: .top, spacing: 12) {
                        EvIllo(kind: row.illo, size: 36)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(row.title).dxFace(.display, 16, weight: 700, tracking: -0.2).foregroundStyle(ground.ink)
                            Text(verbatim: row.detail).dxFace(.body, 14, weight: 500).foregroundStyle(ground.muted)
                                .lineSpacing(2)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 1)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.top, 12)
            Rectangle().fill(Color(light: (0x1E1A3A, 0.12), dark: (0xFFFFFF, 0.12))).frame(height: 1)
                .padding(.top, 14).padding(.bottom, 10)
            Text("These methods were studied in trials. DayXero itself hasn’t been.")
                .dxFace(.body, 14, weight: 500).foregroundStyle(ground.muted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Button { research = true } label: {
                Text("See the research").underline()
                    .dxFace(.body, 14, weight: 600).foregroundStyle(ground.ink)
                    .frame(minHeight: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("reveal.research")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .evCard()
    }

    /// The first prep stamp, sun-yellow with a scalloped edge, and the line that it's waiting.
    private var stamps: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(Color(hex: 0xFFC93C), style: StrokeStyle(lineWidth: 7.3, lineCap: .round, dash: [0.01, 11.5]))
                    .frame(width: 44, height: 44)
                Circle().fill(Color(hex: 0xFFC93C)).frame(width: 40, height: 40)
                Circle().strokeBorder(Color(hex: 0xF29A2E), lineWidth: 2).frame(width: 34, height: 34)
                Text(verbatim: "1").dxFace(.display, 22, weight: 800).foregroundStyle(Color(hex: 0x5A2E06))
            }
            .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 1) {
                Text("Prep stamps").dxFace(.display, 17, weight: 700, tracking: -0.2).foregroundStyle(ground.ink)
                Text("One a day. Your first is waiting.").dxFace(.body, 14, weight: 500).foregroundStyle(ground.muted)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .evCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Prep stamps, one a day. Prep 1 is up next."))
    }
}

/// The paper edge where the dawn meets the page (390 × 30, stretched to the width).
private struct PlanEdge: Shape {
    func path(in rect: CGRect) -> Path {
        SVGPath.path("M0 16 C110 3 250 4 390 14 L390 30 L0 30 Z")
            .applying(CGAffineTransform(scaleX: rect.width / 390, y: rect.height / 30))
    }
}

// MARK: F07 Reminders · apricot (v5, 013)

/// Two small nudges a day: Xero's morning pledge and Glim's evening check-in, as the notifications will look, and the
/// quiet hours.
///
/// Motion (013): the bar fills to the end and the sun lands; title and helper arrive, then the two cards settle in 380 ms
/// apart with a soft haptic each. Glim's card carries a night scene as inset header art (stars twinkle). The quiet-hours
/// line arrives last (from 1.4 s).
struct TrialScreen: View {
    let name: String
    let quitDay: Date
    let dualUse: Bool
    let onDone: () -> Void

    @State private var asking = false
    @State private var landed = 0
    private let ground = DX.Ground.apricot

    private func time(_ minute: Int) -> String {
        let date = Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: .now) ?? .now
        return minute % 60 == 0 ? date.formatted(.dateTime.hour()) : date.formatted(.dateTime.hour().minute())
    }

    private func clock(_ minute: Int) -> String {
        let date = Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: .now) ?? .now
        return date.formatted(.dateTime.hour().minute())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Two small nudges a day").dxType(.large).foregroundStyle(ground.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .dxArrive(0)
                Text("Xero says good morning. Glim checks in at night. No guilt, ever.")
                    .dxType(.body).foregroundStyle(ground.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .dxArrive(1)
                VStack(spacing: 14) {
                    nudge(sender: "Xero", time: clock(DailyReminderSettings.pledgeMinute ?? DailyReminderSettings.defaultPledge),
                          message: "\(NotificationCopy.pledge.0). \(NotificationCopy.pledge.1)") {
                        XeroView(mood: .hello, stage: 0, points: 40, animate: false)
                            .frame(width: 40, height: 40)
                            .background(Color(hex: 0xFFC38A))
                    }
                    .dxSettle(0, delay: 0.65)
                    .task { try? await Task.sleep(for: .seconds(1.2)); landed += 1 }
                    glimCard
                        .dxSettle(0, delay: 1.03)
                        .task { try? await Task.sleep(for: .seconds(1.6)); landed += 1 }
                }
                .padding(.top, 30)
                HStack(spacing: 6) {
                    Text("Quiet hours").dxFace(.body, 15, weight: 700).foregroundStyle(ground.ink)
                    DXIcon(.moon, size: 17).foregroundStyle(ground.ink)
                    Text(verbatim: "\(time(DailyReminderSettings.plan.quietStart ?? DailyReminderSettings.defaultQuietStart)) \(String(localized: "to"))")
                    DXIcon(.sun, size: 17).foregroundStyle(ground.ink)
                    Text(verbatim: time(DailyReminderSettings.plan.quietEnd ?? DailyReminderSettings.defaultQuietEnd))
                }
                .dxType(.footnote).foregroundStyle(ground.muted)
                .frame(maxWidth: .infinity)
                .padding(.top, 26)
                .accessibilityElement(children: .combine)
                .dxArrive(0, delay: 1.4)
            }
            .padding(.horizontal, DX.Layout.gutter)
            .padding(.top, DX.Space.m)
            .dxReadableColumn()
        }
        .scrollBounceBehavior(.basedOnSize)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: landed)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 10) {
                Button("Yes, remind me") {
                    asking = true
                    Task {
                        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                        onDone()
                    }
                }
                .buttonStyle(.dx(.primary, on: ground))
                .disabled(asking)
                .dxArrive(5)
                Button("Not right now", action: onDone)
                    .dxFace(.body, 15, weight: 600)
                    .foregroundStyle(ground.ink.opacity(0.85))
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .dxArrive(6)
            }
            .padding(.horizontal, DX.Layout.gutter)
            .dxReadableColumn()
            .padding(.top, 28)
            .padding(.bottom, DX.Space.xs)
        }
    }

    /// A notification as it will look: the sender's tile, "DayXero · Xero", the time, the words.
    private func nudge(sender: String, time: String, message: String, @ViewBuilder icon: () -> some View) -> some View {
        HStack(alignment: .top, spacing: 12) {
            icon().clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: "DayXero · \(sender)")
                    Spacer()
                    Text(verbatim: time)
                }
                .dxType(.caption).foregroundStyle(ground.muted)
                Text(verbatim: message).dxFace(.body, 15, weight: 500).foregroundStyle(ground.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 14).padding(.horizontal, 16).padding(.bottom, 16)
        .background(ground.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Onb.chipLine, lineWidth: 1))
        .shadow(color: Color(light: (0x1E1A3A, 0.10), dark: (0x000000, 0)), radius: 12, y: 10)
        .accessibilityElement(children: .combine)
    }

    /// Glim's card: the same notification, with a night scene inset on top introducing Glim.
    private var glimCard: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                NightSky(moon: CGPoint(x: 296, y: 40))
                GlimView(mood: .hello, stage: 1, points: 72)
                    .offset(x: 18, y: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meet Glim").dxType(.headline).foregroundStyle(Color(hex: 0xF6EFE2))
                    Text("Your evening friend").dxType(.caption).foregroundStyle(Color(hex: 0xAEB8D3))
                }
                .offset(x: 100, y: 32)
            }
            .frame(height: 128)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .environment(\.colorScheme, .dark)
            .accessibilityElement(children: .combine)
            HStack(alignment: .top, spacing: 12) {
                GlimView(mood: .hello, stage: 1, points: 40, animate: false)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: 0x1E2D4C))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(verbatim: "DayXero · Glim")
                        Spacer()
                        Text(verbatim: clock(DailyReminderSettings.checkInMinute ?? DailyReminderSettings.defaultCheckIn))
                    }
                    .dxType(.caption).foregroundStyle(ground.muted)
                    Text(verbatim: "\(NotificationCopy.checkIn.0) \(NotificationCopy.checkIn.1)")
                        .dxFace(.body, 15, weight: 500).foregroundStyle(ground.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
            .padding(.top, 14).padding(.horizontal, 10).padding(.bottom, 16)
        }
        .padding([.top, .horizontal], 6)
        .background(ground.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Onb.chipLine, lineWidth: 1))
        .shadow(color: Color(light: (0x1E1A3A, 0.10), dark: (0x000000, 0)), radius: 12, y: 10)
    }
}
