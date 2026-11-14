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

// MARK: F04 Quit Day · apricot (v5, 010)

/// The prep week on one card (a tile per prep day, today in a coral disc, a prep dot under each), the Quit Day row that
/// opens the date wheel, Xero on his hill with a flag, and the hold.
///
/// Motion (010): title, the week card (tiles rise 45 ms apart, dots pop left to right), the Quit Day row, Xero and the
/// hold arrive in order. Holding fills the button over 1500 ms; on complete it shows "Quit Day set", the flag runs up
/// its pole (34 pt, 700 ms) while Xero bumps, and the row's caption swaps to "Quit Day set" with a green tick. 1200 ms
/// later the button crossfades into Continue.
struct QuitDayScreen: View {
    @Bindable var model: OnboardingModel
    @State private var picking = false
    @State private var committed = false
    @State private var showContinue = false
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
                Text(model.name.isEmpty ? "Pick your Quit Day" : "Pick your Quit Day, \(model.name)")
                    .dxType(.large).foregroundStyle(ground.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .dxArrive(0)
                Text("I recommend a full week of prep first. Keep using as normal until then.")
                    .dxType(.body).foregroundStyle(ground.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .dxArrive(1)
                weekCard.padding(.top, 12).dxArrive(2)
                hero.padding(.top, 2)
            }
            .padding(.horizontal, DX.Layout.gutter)
            .dxReadableColumn()
            .padding(.top, DX.Space.m)
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
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your prep week").dxFace(.body, 15, weight: 700).foregroundStyle(ground.ink)
                Spacer()
                Text("^[\(prepDays.count) short session](inflect: true)").dxType(.footnote).foregroundStyle(ground.muted)
            }
            .padding(.horizontal, 4).padding(.bottom, 10)
            if !prepDays.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(prepDays.enumerated()), id: \.element) { i, day in
                        dayTile(day, today: i == 0)
                            .dxArrive(0, delay: 0.225 + Double(i) * 0.045)
                    }
                    // Keep the tiles a week wide when prep is shorter.
                    ForEach(prepDays.count..<7, id: \.self) { _ in Color.clear.frame(maxWidth: .infinity, minHeight: 82) }
                }
            }
            quitRow.padding(.top, 8).dxArrive(6)
        }
        .padding(.top, 14).padding(.horizontal, 12).padding(.bottom, 12)
        .background(ground.card, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(Onb.chipLine, lineWidth: 1))
    }

    private func dayTile(_ day: Date, today: Bool) -> some View {
        VStack(spacing: 4) {
            Text(today ? String(localized: "Today") : day.formatted(.dateTime.weekday(.abbreviated)))
                .dxFace(.body, 13, weight: today ? 700 : 600)
                .foregroundStyle(today ? ground.ink : ground.muted)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(day, format: .dateTime.day())
                .dxFace(.display, today ? 18 : 22, weight: 800, tracking: today ? -0.4 : -0.5)
                .foregroundStyle(today ? Color.white : ground.ink)
                .frame(width: today ? 30 : nil, height: today ? 30 : nil)
                .background { if today { Circle().fill(DX.Fill.coral) } }
                .padding(.vertical, today ? -4 : 0)
            Circle().fill(Color(hex: 0xFF9A5C)).frame(width: 8, height: 8).padding(.top, 2)
                .dxPop(0, delay: 0.7 + Double(prepDays.firstIndex(of: day) ?? 0) * 0.09)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .background(ground.card2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(day, format: .dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityValue(Text("Prep day"))
    }

    /// The tappable Quit Day: a cream card with an apricot date page, the date, its caption and "Change".
    private var quitRow: some View {
        Button { picking = true } label: {
            HStack(spacing: 14) {
                VStack(spacing: 0) {
                    Text(model.quitDay, format: .dateTime.month(.abbreviated))
                        .dxFace(.body, 11, weight: 700).tracking(0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 16)
                        .background(Color(hex: 0xFF7155))
                    Text(model.quitDay, format: .dateTime.day())
                        .dxFace(.display, 24, weight: 800, tracking: -0.6)
                        .foregroundStyle(DX.Fill.navy)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 48, height: 52)
                .background(Color(hex: 0xFFC38A))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color(red: 110 / 255, green: 50 / 255, blue: 20 / 255).opacity(0.16), radius: 0, y: 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.quitDay, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .dxFace(.display, 20, weight: 700, tracking: -0.2).foregroundStyle(ground.ink)
                        .lineLimit(1).minimumScaleFactor(0.8)
                    ZStack(alignment: .leading) {
                        Text(recommended ? "Quit Day, recommended" : "Quit Day")
                            .foregroundStyle(ground.muted)
                            .opacity(committed ? 0 : 1)
                        HStack(spacing: 4) {
                            Text("Quit Day set").foregroundStyle(ground.ink)
                            DXIcon(.check, size: 11, weight: 3.4).foregroundStyle(.white)
                                .frame(width: 16, height: 16).background(DX.Fill.done, in: Circle())
                                .padding(.leading, 2)
                        }
                        .dxFace(.body, 13, weight: 700)
                        .opacity(committed ? 1 : 0)
                    }
                    .dxType(.caption)
                    .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.3), value: committed)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 2) {
                    Text("Change").dxFace(.body, 14, weight: 600)
                    DXIcon(.chev, size: 18)
                }
                .foregroundStyle(ground.muted)
            }
            .padding(.leading, 10).padding(.trailing, 14).padding(.vertical, 10)
            .frame(minHeight: 70)
            .background(Color(light: 0xFFF8EE, dark: 0x212A41), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(light: (0x1E1A3A, 0.12), dark: (0xFFFFFF, 0.14)), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.dxPress)
        .accessibilityLabel(Text("Quit Day, \(model.quitDay.formatted(.dateTime.weekday(.wide).day().month(.wide)))"))
        .accessibilityHint(Text("Change the date"))
    }

    /// Xero on his own small paper hill, holding a yellow flag that runs up its pole when Quit Day is set.
    private var hero: some View {
        Color.clear
            .frame(height: 230)
            .overlay(alignment: .top) {
                QuitHill()
                    .frame(width: 390, height: 104)
                    .offset(y: 118)
            }
            .overlay(alignment: .top) {
                XeroView(mood: .hello, stage: 0, points: 128, pose: .holdFlag)
                    .background(alignment: .topLeading) {
                        FlagPole(raised: committed)
                            .frame(width: 128, height: 128)
                    }
                    .offset(x: -4, y: 30)
                    .dxBump(committed)
                    .dxSettle(delay: 0.45)
            }
            .accessibilityHidden(true)
    }
}

/// The yellow pennant on its pole (010), in Xero's 200-unit space, so it scales with him.
private struct FlagPole: View {
    let raised: Bool

    var body: some View {
        GeometryReader { proxy in
            let s = proxy.size.width / 200
            ZStack(alignment: .topLeading) {
                Path { p in p.move(to: CGPoint(x: 188, y: 154)); p.addLine(to: CGPoint(x: 188, y: 30)) }
                    .stroke(Color(hex: 0x8A5A3C), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                Circle().fill(Color(hex: 0xF5B83D)).frame(width: 8, height: 8).offset(x: 184, y: 24)
                Pennant().fill(Color(hex: 0xFFD966))
                    .overlay(Pennant().stroke(Color(hex: 0xF5B83D), style: StrokeStyle(lineWidth: 2, lineJoin: .round)))
                    .offset(y: raised ? 0 : 34)
            }
            .frame(width: 200, height: 200, alignment: .topLeading)
            .scaleEffect(s, anchor: .topLeading)
        }
    }

    private struct Pennant: Shape {
        func path(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: CGPoint(x: 190, y: 33)); p.addLine(to: CGPoint(x: 216, y: 42)); p.addLine(to: CGPoint(x: 190, y: 52)); p.closeSubpath()
            }
        }
    }
}

/// Xero's small hill: apricot fading into the ground before the dock, with a soft light edge.
private struct QuitHill: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        let top = dark ? Color(hex: 0x212A41) : Color(hex: 0xFFAE7A)
        let g = DX.Ground.apricot.background
        ZStack {
            HillShape(closed: true)
                .fill(LinearGradient(stops: [.init(color: top, location: 0), .init(color: top, location: 0.22),
                                             .init(color: top.mix(with: g, by: 0.38), location: 0.5),
                                             .init(color: top.mix(with: g, by: 0.8), location: 0.78), .init(color: g, location: 1)],
                                     startPoint: .top, endPoint: .bottom))
            HillShape(closed: false)
                .stroke(LinearGradient(stops: [.init(color: dark ? Color(red: 190 / 255, green: 205 / 255, blue: 1).opacity(0.22) : .white.opacity(0.6), location: 0),
                                               .init(color: .clear, location: 0.7)], startPoint: .top, endPoint: .bottom), lineWidth: 2)
        }
    }

    private struct HillShape: Shape {
        let closed: Bool
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: 10, y: 104))
            p.addCurve(to: CGPoint(x: 195, y: 26), control1: CGPoint(x: 50, y: 52), control2: CGPoint(x: 130, y: 26))
            p.addCurve(to: CGPoint(x: 380, y: 104), control1: CGPoint(x: 260, y: 26), control2: CGPoint(x: 340, y: 52))
            if closed { p.closeSubpath() }
            return p.applying(CGAffineTransform(translationX: (rect.width - 390) / 2, y: 0))
        }
    }
}

// MARK: F05 Your plan builds · apricot (v5)

struct BuildingScreen: View {
    let model: OnboardingModel
    @State private var shown = 0
    @State private var friends = false
    private let motion = MotionPolicy()
    private let ground = DX.Ground.apricot

    private struct Row: Identifiable {
        let id: Int
        let kicker: String
        let value: String
        /// A plain line under the row, e.g. what a wave is the first time the plan says it (S27.10).
        var detail: String? = nil
    }

    private var rows: [Row] {
        let first = model.today
        let last = model.calendar.date(byAdding: .day, value: -1, to: model.calendar.startOfDay(for: model.quitDay)) ?? first
        let usage = ListFormatter.localizedString(byJoining: model.orderedProducts.map { product in
            switch product {
            case .cigarettes: String(localized: "cigarettes")
            case .vape: String(localized: "vape")
            case .pouches: String(localized: "pouches")
            }
        })
        let waves = Trigger.allCases.filter(model.triggers.contains).prefix(2).map { String(localized: $0.title).lowercased() }
        var all = [
            Row(id: 0, kicker: String(localized: "Prep week"),
                value: model.prepDays > 1 ? "\(first.formatted(shortDate)) to \(last.formatted(shortDate))" : first.formatted(shortDate)),
            Row(id: 1, kicker: String(localized: "Quit Day"),
                value: String(localized: "\(model.quitDay.formatted(shortDate)) · no more \(usage)")),
        ]
        if !waves.isEmpty {
            all.append(Row(id: 2, kicker: String(localized: "Waves to watch"), value: ListFormatter.localizedString(byJoining: waves).capitalizedFirst,
                           detail: String(localized: "A wave is a craving: it rises, peaks and passes.")))
        }
        // What gets in the way shapes the plan (S27.10).
        let obstacles = Obstacle.allCases.filter { model.obstacles.contains($0) && $0 != .other }.prefix(3)
            .map { String(localized: $0.title).lowercased() }
        if !obstacles.isEmpty {
            all.append(Row(id: 3, kicker: String(localized: "Watch out for"),
                           value: ListFormatter.localizedString(byJoining: Array(obstacles)).capitalizedFirst))
        }
        let why = model.why.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !why.isEmpty {
            all.append(Row(id: 4, kicker: String(localized: "Your reason"), value: "“\(why)”"))
        }
        return all
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 12) {
                        XeroView(mood: .hello, stage: 1, size: .card)
                        Text("Your plan, built around you").dxType(.title).foregroundStyle(ground.ink)
                            .accessibilityAddTraits(.isHeader)
                    }
                    ForEach(rows.prefix(shown)) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            PlanStepRow(kicker: row.kicker, value: row.value, ground: ground)
                            if let detail = row.detail {
                                Text(detail).dxType(.footnote).foregroundStyle(ground.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    if friends {
                        HStack(spacing: 12) {
                            HStack(spacing: -10) {
                                JelliView(mood: .hello, stage: 1, size: .avatar, animate: false)
                                    .background(DX.Ground.ocean.background, in: Circle()).clipShape(Circle())
                                GlimView(mood: .hello, stage: 1, size: .avatar, animate: false)
                                    .background(DX.Ground.violet.background, in: Circle()).clipShape(Circle())
                            }
                            .accessibilityHidden(true)
                            Text("Two friends join later. **Jelli** at your first craving, **Glim** on your first evening.")
                                .dxType(.footnote).foregroundStyle(ground.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .dxCardOnColour()
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, DX.Space.m)
                .dxReadableColumn()
            }
            Button("See my plan") { model.next() }
                .buttonStyle(.dx(.primary, on: ground))
                .disabled(!friends)
                .padding(.horizontal, DX.Layout.buttonGutter)
                .dxReadableColumn()
                .padding(.bottom, DX.Space.xs)
        }
        .task {
            let step = motion.reduce ? 0.15 : 0.6
            for i in 1...rows.count {
                try? await Task.sleep(for: .seconds(step))
                withAnimation(motion.animation(DX.Move.settle)) { shown = i }
            }
            try? await Task.sleep(for: .seconds(step))
            withAnimation(motion.animation(DX.Move.arrive)) { friends = true }
        }
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

// MARK: F06 Your plan is ready · mint

/// Prep 1 to 3 are free; the 7-day trial is offered at Prep 4 (MON-01, replacing decision 15), so with the usual week of
/// prep it runs past the Quit Day. Nothing is charged here.
struct PlanRevealScreen: View {
    let model: OnboardingModel
    let onContinue: () -> Void

    @Environment(Entitlement.self) private var entitlement
    @State private var paywall: PaywallModel?
    @State private var showPlans = false
    private let ground = DX.Ground.apricot

    private var annual: PlanOption? { paywall?.plans.first { $0.plan == .annual } }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Step \(model.stepNumber) of \(model.stepTotal)").dxType(.caption).foregroundStyle(ground.muted)
                    MarkedTitle(String(localized: "Your plan is "), marking: String(localized: "ready"), color: DX.Mark.color(on: ground))
                        .dxType(.large).foregroundStyle(ground.ink)
                        .dxArrive(0)
                    Text(entitlement.isPro ? "Everything is unlocked." : "Prep 1 to 3 are on us. Nothing is charged today.")
                        .dxType(.body).foregroundStyle(ground.muted)
                        .dxArrive(1)
                    revealHero
                    savings
                    builtAround
                    includes
                    if !entitlement.isPro { trialCard }
                    // Set apart from the cards above and clear of the pinned buttons below (QW9).
                    Text(HealthInfoView.oneLine).dxType(.caption).foregroundStyle(ground.muted)
                        .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                        .padding(.top, DX.Space.s)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, DX.Space.m)
                .padding(.bottom, DX.Space.l)
                .dxReadableColumn()
            }
            VStack(spacing: 4) {
                Button("Start my prep week", action: onContinue)
                    .buttonStyle(.dx(.primary, on: ground))
                if !entitlement.isPro, let annual {
                    Button {
                        showPlans = true
                    } label: {
                        Text("See all plans · \(plansLine(annual))")
                    }
                    .buttonStyle(.dx(.quiet, on: ground))
                }
            }
            .padding(.horizontal, DX.Layout.buttonGutter)
            .dxReadableColumn()
            .padding(.bottom, DX.Space.xs)
        }
        .task {
            guard paywall == nil, !entitlement.isPro else { return }
            let loading = PaywallModel(store: entitlement.store, entitlement: entitlement)
            await loading.load(trackView: false)
            paywall = loading
        }
        .fullScreenCover(isPresented: $showPlans) {
            if paywall != nil {
                // Its own model, so its load tracks the paywall view.
                PaywallView(name: model.name, quitDay: model.quitDay,
                            model: PaywallModel(store: entitlement.store, entitlement: entitlement), onClose: { showPlans = false },
                            spend: PaywallModel.Spend(perYear: model.stats.moneyPerYear, currencyCode: model.currencyCode,
                                                      products: model.orderedProducts))
            }
        }
    }

    private func plansLine(_ annual: PlanOption) -> String {
        let others = (paywall?.plans ?? []).filter { $0.plan != .annual }.map { option -> String in
            switch option.plan {
            case .monthly: String(localized: "\(option.priceText) a month")
            case .lifetime: String(localized: "\(option.priceText) lifetime")
            default: option.priceText
            }
        }
        return others.joined(separator: " · ")
    }

    /// 012: the Day Xero medallion waiting in a warm glow, Xero cheering on the hill beside it, the date under them.
    private var revealHero: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomLeading) {
                ZStack {
                    Circle().fill(Color(light: (0xFFF8EE, 0.35), dark: (0xFFC38A, 0.06))).frame(width: 220, height: 220)
                    Circle().fill(Color(light: (0xFFF8EE, 0.6), dark: (0xFFC38A, 0.10))).frame(width: 180, height: 180)
                    DXBadge(.xero, state: .next(nil), size: 148)
                        .dxStamp(delay: 0.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.leading, 70)
                .padding(.bottom, 28)
                // The hill runs off both edges without widening the column.
                Knoll(kind: .big)
                    .frame(height: 70)
                    .padding(.horizontal, -40)
                    .offset(y: 10)
                XeroView(mood: .cheer, stage: 1, points: 104)
                    .frame(width: 104, height: 104)
                    .dxSettle(delay: 0.3)
                    .padding(.leading, 18)
                    .padding(.bottom, 26)
            }
            .frame(height: 236)
            .clipped()
            .accessibilityHidden(true)
            Text(verbatim: "Day Xero · \(model.quitDay.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))")
                .dxType(.headline)
                .foregroundStyle(ground.ink)
                .frame(maxWidth: .infinity)
                .dxArrive(2)
        }
        .padding(.vertical, 6)
    }

    private var savings: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Money you'll keep in year 1").dxType(.caption).foregroundStyle(ground.muted)
            Text(verbatim: model.stats.moneyPerYear.formatted(.currency(code: model.currencyCode).precision(.fractionLength(0))))
                .dxType(.display).foregroundStyle(ground.ink)
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dxCardOnColour(radius: DX.Layout.cardRadius)
        .accessibilityElement(children: .combine)
    }

    /// One line per obstacle picked, saying what the plan does about it (S27.10). Hidden when none were picked.
    @ViewBuilder
    private var builtAround: some View {
        let lines = Obstacle.planLines(for: model.obstacles)
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Built around what gets in your way").dxType(.caption).foregroundStyle(ground.muted)
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Label {
                        Text(line).dxType(.footnote).foregroundStyle(ground.ink).fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(ground.ink)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dxCardOnColour()
            .accessibilityElement(children: .combine)
        }
    }

    private var includes: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("**Always free:** Prep 1 to 3, your counter, Craving SOS, a 60-second breathing timer and evening check-ins")
            Text("**With the full program:** Prep 4 to 7, your Day Xero launch kit, Weeks 1 to 4, Jelli's voice coaching, if-then slip plans, a 12-week NRT schedule and trigger heatmaps")
        }
        .dxType(.footnote)
        .foregroundStyle(ground.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dxCardOnColour()
    }

    /// The 7-day trial at Prep 4 (MON-01): Prep 1 is today, so Prep 4 opens three days from now at the earliest.
    private var trialCard: some View {
        let start = FullProgram.earliestPaywallDay(firstDay: .now, calendar: model.calendar)
        let days = annual?.trialDays ?? FullProgram.trialDays
        let end = model.calendar.date(byAdding: .day, value: days, to: start) ?? start
        let lead = TrialReminder.leadDays(trialEndsAt: end, now: start)
        let remind = model.calendar.date(byAdding: .day, value: -lead, to: end) ?? end
        let after = FullProgram.trialEndsDaysAfterQuitDay(trialEnd: end, quitDay: model.quitDay, calendar: model.calendar)
        let (s, e, r) = (start.formatted(shortDate), end.formatted(shortDate), remind.formatted(shortDate))
        let runs: String = switch after {
        case 2...: String(localized: "If you start it at Prep 4 on \(s), it runs to \(e), \(after) days after your Quit Day. I'll remind you on \(r).")
        case 1: String(localized: "If you start it at Prep 4 on \(s), it runs to \(e), the day after your Quit Day. I'll remind you on \(r).")
        case 0: String(localized: "If you start it at Prep 4 on \(s), it runs to \(e), your Quit Day. I'll remind you on \(r).")
        default: String(localized: "If you start it at Prep 4 on \(s), it runs to \(e). I'll remind you on \(r).")
        }
        return VStack(alignment: .leading, spacing: 6) {
            Text("At Prep 4 · \(start.formatted(shortDate))").dxType(.caption)
                .foregroundStyle(DX.Fill.cream.opacity(0.85))
            if let annual {
                Text("\(days) days free, then \(annual.priceText) a year").dxType(.headline).foregroundStyle(DX.Fill.cream)
                if let perMonth = annual.perMonthText {
                    Text("That's \(perMonth) a month. I'll ask you at Prep 4, not before.")
                        .dxType(.footnote).foregroundStyle(DX.Fill.cream.opacity(0.85))
                }
            } else {
                Text("I'll ask you about the full program at Prep 4, not before.").dxType(.headline).foregroundStyle(DX.Fill.cream)
            }
            Text("\(runs) Cancel any time in Settings › Apple ID › Subscriptions.")
                .dxType(.caption).foregroundStyle(DX.Fill.cream.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DX.Fill.navy, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: F07 Reminders · apricot

/// Two small nudges a day: Xero's morning pledge and Glim's evening check-in.
struct TrialScreen: View {
    let name: String
    let quitDay: Date
    let dualUse: Bool
    let onDone: () -> Void

    @State private var asking = false
    private let ground = DX.Ground.apricot

    private func time(_ minute: Int) -> String {
        let date = Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: .now) ?? .now
        return date.formatted(.dateTime.hour().minute())
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Two small nudges a day").dxType(.large).foregroundStyle(ground.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .dxArrive(0)
                    Text("Xero says good morning, Glim checks in at night. Anything more is your choice, in Settings. No guilt, ever, and quiet hours by default.")
                        .dxType(.body).foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    NotificationPreview(sender: "Xero", time: time(DailyReminderSettings.pledgeMinute ?? DailyReminderSettings.defaultPledge),
                                        message: "\(NotificationCopy.pledge.0). \(NotificationCopy.pledge.1)") {
                        XeroView(mood: .hello, stage: 1, size: .avatar, animate: false).background(DX.Ground.apricot.background)
                    }
                    .dxArrive(1)
                    NotificationPreview(sender: "Glim", time: time(DailyReminderSettings.checkInMinute ?? DailyReminderSettings.defaultCheckIn),
                                        message: "\(NotificationCopy.checkIn.0) \(NotificationCopy.checkIn.1)") {
                        GlimView(mood: .hello, stage: 1, size: .avatar, animate: false).background(DX.Ground.violet.background)
                    }
                    .dxArrive(2)
                    Text("You can change the times in Settings.").dxType(.footnote).foregroundStyle(ground.muted)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, DX.Space.m)
                .dxReadableColumn()
            }
            VStack(spacing: 4) {
                Button("Yes, remind me") {
                    asking = true
                    Task {
                        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                        onDone()
                    }
                }
                .buttonStyle(.dx(.primary, on: ground))
                .disabled(asking)
                Button("Not right now", action: onDone)
                    .buttonStyle(.dx(.quiet, on: ground))
            }
            .padding(.horizontal, DX.Layout.buttonGutter)
            .dxReadableColumn()
            .padding(.bottom, DX.Space.xs)
        }
    }
}
