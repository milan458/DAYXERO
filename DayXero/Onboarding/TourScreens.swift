import DayXeroCore
import SwiftUI

// What DayXero is, shown where it answers a question the person has just then (16 Nov 2026), drawn to the v5 canvas
// (artifact "DayXero onboarding: three new screens", critic-loop best, 16 Nov 2026).
//   How it works   after Welcome: a full-bleed sunrise with Xero, then prep, Quit Day, four weeks.
//   Craving SOS    after the triggers: Jelli breathing in the SOS ring, and where SOS lives in the tab bar.
//   Your day       before the Quit Day pick: two windows, the morning pledge with Xero and the night check-in with Glim.
// None of them asks anything, so Continue is never held back.

// MARK: How it works · apricot

/// The three parts of the program under a sunrise. The sky starts as hazy as prep and clears as each part lands.
///
/// Motion: the scene fades in full-bleed behind the header, hazy, and clears as the three phases settle one by one
/// (900 ms each, 700 ms apart); the sun rises; the Quit Day sun pops in with a spring; Xero idles. Dark: a pre-dawn
/// sky over the far ridge, stars twinkling. Reduce Motion shows the end state at once.
struct HowItWorksScreen: View {
    let model: OnboardingModel
    @State private var shown = 0
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()
    private let ground = DX.Ground.apricot

    /// The scene's height from the top of the screen, status bar included (canvas 356 of 844).
    private static let heroHeight: CGFloat = 356

    private struct Phase: Identifiable {
        let id: Int
        let name: LocalizedStringKey
        let span: LocalizedStringKey
        let detail: LocalizedStringKey
        /// Sky clarity once this part has landed.
        let clarity: Double
    }

    private var phases: [Phase] {
        [
            Phase(id: 0, name: "Prep", span: "up to 7 days",
                  detail: "Keep using as normal. One session a day maps your cravings and builds your plan.",
                  clarity: Double(CrewGrowth.prepClarity)),
            Phase(id: 1, name: "Quit Day", span: "the day you pick",
                  detail: "You stop, with your first hours planned.",
                  clarity: 48),
            Phase(id: 2, name: "Four weeks", span: "after Quit Day",
                  detail: "A weekly session, a morning pledge and a night check-in.",
                  clarity: 100),
        ]
    }

    private var clarity: Double {
        shown == 0 ? Double(CrewGrowth.prepClarity) : phases[min(shown, phases.count) - 1].clarity
    }

    /// The small "up to 7 days" beside each name.
    private let meta = Color(light: 0x5A3418, dark: 0xB8C0D2)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero
                VStack(alignment: .leading, spacing: 0) {
                    MarkedTitle(String(localized: "How your quit "), marking: String(localized: "works"), color: ground.mark)
                        .dxType(.large)
                        .foregroundStyle(ground.ink)
                        .accessibilityAddTraits(.isHeader)
                        .dxArrive(0)
                    Text("Your sky brightens every day you stay clear.")
                        .dxType(.body)
                        .foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)
                        .dxArrive(1)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(phases) { phase in
                            stop(phase, last: phase.id == phases.count - 1)
                                .opacity(shown > phase.id ? 1 : 0)
                                .offset(y: shown > phase.id || motion.reduce ? 0 : DX.Move.arriveRise)
                        }
                    }
                    .padding(.top, 30)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, 16)
                .padding(.bottom, DX.Space.l)
                .dxReadableColumn()
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        // The sunrise runs up under the status bar; the flow floats the header over it (`overlaysTopBar`).
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("Continue") { model.next() }
                .buttonStyle(.dx(.primary, on: ground))
                .padding(.horizontal, DX.Layout.buttonGutter)
                .dxReadableColumn()
                .padding(.top, 20)
                .padding(.bottom, DX.Space.xs)
                .background {
                    LinearGradient(stops: [.init(color: ground.background.opacity(0), location: 0),
                                           .init(color: ground.background, location: 0.34)],
                                   startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea(edges: .bottom)
                }
        }
        .task {
            // The parts land one at a time and the sky clears with them.
            if motion.reduce {
                shown = phases.count
                return
            }
            try? await Task.sleep(for: .seconds(0.55))
            for count in 1...phases.count {
                withAnimation(DX.Move.settle) { shown = count }
                try? await Task.sleep(for: .seconds(0.7))
            }
        }
    }

    /// Full-bleed sunrise: Xero on the near ridge, the sun to his right, the art blending into the page through a
    /// paper-cut edge. Positions follow the 390 pt canvas and scale with the width.
    private var hero: some View {
        let dark = scheme == .dark
        return GeometryReader { proxy in
            let w = proxy.size.width
            let k = w / 390
            ZStack(alignment: .topLeading) {
                if dark {
                    NightSky(dawn: true, options: .init(sunAt: 0.68, sunScale: 2.1, sunLift: 14, softSun: true, denseStars: true,
                                                        clear: CGRect(x: 0, y: 40, width: w, height: 70), fade: false))
                    ground.background.opacity((1 - clarity / 100) * 0.55)
                } else {
                    ClearingSky(clarity: clarity)
                }
                // Xero's contact shadow on the ridge, then Xero.
                Ellipse()
                    .fill(RadialGradient(colors: [dark ? Color.black.opacity(0.55) : Color(hex: 0x50140A).opacity(0.4), .clear],
                                         center: .center, startRadius: 0, endRadius: 48))
                    .frame(width: 96, height: 16)
                    .offset(x: (dark ? 60 : 46) * k, y: dark ? 244 : 248)
                XeroView(mood: .hello, stage: 1, points: 112, animate: !motion.reduce)
                    .shadow(color: dark ? Color(hex: 0xFFAA5A).opacity(0.45) : Color(hex: 0xFFF8EE).opacity(0.95),
                            radius: dark ? 8 : 2.5, x: dark ? 4 : 0, y: dark ? -2 : 0)
                    .shadow(color: dark ? .clear : Color(hex: 0x781E0A).opacity(0.22), radius: 10, y: 6)
                    .frame(width: 112, height: 112)
                    .offset(x: (dark ? 52 : 38) * k, y: dark ? 140 : 145)
                    .accessibilityHidden(true)
                // The scene settles into the page: a soft blend, then the paper edge in the ground colour.
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ZStack(alignment: .bottom) {
                        LinearGradient(colors: [ground.background.opacity(0), ground.background.opacity(0.72)],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: 70)
                        TourEdge().fill(ground.background).frame(height: 44)
                    }
                }
            }
            .frame(width: w, height: proxy.size.height)
            .clipped()
        }
        .frame(height: Self.heroHeight)
        .accessibilityHidden(true)
    }

    /// One stop: its marker and the line down to the next one, then the name, how long, and what happens.
    private func stop(_ phase: Phase, last: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(phase.name).dxType(.headline).foregroundStyle(ground.ink)
                    Text(phase.span).dxFace(.body, 14, weight: 500).foregroundStyle(meta)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(phase.name).dxType(.headline).foregroundStyle(ground.ink)
                    Text(phase.span).dxFace(.body, 14, weight: 500).foregroundStyle(meta)
                }
            }
            Text(phase.detail)
                .dxFace(.body, 15, weight: 500)
                .foregroundStyle(ground.muted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 38)
        .padding(.bottom, last ? 0 : 28)
        .background(alignment: .topLeading) {
            VStack(spacing: 0) {
                marker(phase.id)
                    .frame(width: 24, height: 26)
                if !last {
                    Rectangle().fill(ground.ink.opacity(0.3)).frame(width: 2).padding(.top, 2)
                }
            }
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    /// Prep an open ring, Quit Day the sun (the one emphasis), the four weeks a filled dot.
    @ViewBuilder
    private func marker(_ id: Int) -> some View {
        switch id {
        case 0: Circle().strokeBorder(ground.ink, lineWidth: 2.5).frame(width: 16, height: 16)
        case 1:
            Circle()
                .fill(Color(hex: 0xFFC93C))
                .overlay(Circle().strokeBorder(Color(hex: 0xF29A2E), lineWidth: 2.5))
                .shadow(color: Color(hex: 0xFFC93C).opacity(0.5), radius: 6)
                .frame(width: 24, height: 24)
                .scaleEffect(shown >= 2 || motion.reduce ? 1 : 0.4)
                .animation(motion.reduce ? nil : .spring(response: 0.5, dampingFraction: 0.55), value: shown)
        default: Circle().fill(ground.ink).frame(width: 16, height: 16)
        }
    }
}

/// The dawn horizon with a clarity SwiftUI can animate, so the haze lifts smoothly instead of jumping. The sun sits to
/// Xero's right, a little smaller, with no clouds (the canvas's `sun-x 254`).
private struct ClearingSky: View, Animatable {
    /// Nonisolated so it can satisfy `Animatable` from a main-actor view under Swift 6.
    nonisolated var animatableData: Double

    init(clarity: Double) {
        animatableData = clarity
    }

    var body: some View {
        HorizonScene(.dawn, clarity: Int(animatableData.rounded()), fit: .bottom,
                     sun: .init(x: 254, radius: 70, drop: 0, clouds: false))
    }
}

/// The paper-cut edge where the sunrise meets the page: "M0 22 C110 4 250 6 390 20 L390 44 L0 44 Z", scaled.
private struct TourEdge: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 390, sy = rect.height / 44
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + 22 * sy))
        p.addCurve(to: CGPoint(x: rect.minX + 390 * sx, y: rect.minY + 20 * sy),
                   control1: CGPoint(x: rect.minX + 110 * sx, y: rect.minY + 4 * sy),
                   control2: CGPoint(x: rect.minX + 250 * sx, y: rect.minY + 6 * sy))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: Craving SOS · ocean

/// What they'll have when a craving hits: Jelli breathing in the SOS ring, and where SOS lives. Calm tier (design doc
/// §4.1): no countdown, no prediction.
///
/// Motion: Jelli and the ring breathe as one, 4 s in (scale up) and 6 s out; a cream arc sweeps round the ring on the
/// in-breath and unwinds on the out-breath; "Breathe in" crossfades to "and out" in time; the halo round the SOS button
/// in the tab-bar preview swells with the same breath. With Reduce Motion everything rests and the words stay.
struct CravingSOSIntroScreen: View {
    let model: OnboardingModel
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()
    private let ground = DX.Ground.ocean
    private let cream = DX.Fill.cream

    /// Their triggers in the order the plan lists them ("Something else" has no moment to name).
    private var named: [Trigger] {
        Trigger.allCases.filter { model.triggers.contains($0) && $0 != .other }
    }

    /// "coffee and stress": the two the plan will call their waves to watch.
    private var moments: String? {
        let names = named.prefix(2).map { String(localized: $0.title).lowercased() }
        return names.isEmpty ? nil : ListFormatter.localizedString(byJoining: Array(names))
    }

    private var planLine: String {
        if let moments { return String(localized: "In prep, you'll plan for \(moments).") }
        return String(localized: "In prep, you'll plan for your biggest moments.")
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Text("When a craving hits,")
                        MarkedTitle(marking: String(localized: "Jelli has you."), color: Color(hex: 0xFFD966))
                    }
                    .dxType(.large)
                    .foregroundStyle(cream)
                    .multilineTextAlignment(.center)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                    .dxArrive(0)
                    SOSBreathRing(dark: scheme == .dark)
                        .frame(width: 248, height: 248)
                        .padding(.top, 18)
                        .dxArrive(1)
                    VStack(spacing: 0) {
                        Text("In for 4, out for 6.")
                        Text("Most cravings pass in a few minutes.")
                    }
                    .dxFace(.body, 17, weight: 500)
                    .foregroundStyle(cream)
                    .multilineTextAlignment(.center)
                    .padding(.top, 18)
                    .dxArrive(2)
                    Spacer(minLength: 24)
                    VStack(spacing: 14) {
                        TabBarPreview(dark: scheme == .dark)
                        VStack(spacing: 0) {
                            Text("Craving SOS is one tap away in your tab bar.")
                            Text(verbatim: planLine)
                        }
                        .dxFace(.body, 15, weight: 500)
                        .foregroundStyle(cream.opacity(0.88))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .dxArrive(3)
                    Spacer(minLength: 16)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height)
                .padding(.horizontal, DX.Layout.gutter)
                .dxReadableColumn()
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.top, DX.Space.xs)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("Continue") { model.next() }
                .buttonStyle(.dx(.primary, on: ground))
                .padding(.horizontal, DX.Layout.buttonGutter)
                .dxReadableColumn()
                .padding(.top, 12)
                .padding(.bottom, DX.Space.xs)
        }
        // A lit sea: lighter at the top and behind the ring, deep at the bottom so Continue sits on calm water.
        .background {
            ZStack {
                LinearGradient(colors: scheme == .dark ? [Color(hex: 0x13295F), Color(hex: 0x0E1F4C), Color(hex: 0x0A1638)]
                                                       : [Color(hex: 0x2E5AB8), Color(hex: 0x24469E), Color(hex: 0x1A3480)],
                               startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [Color.white.opacity(scheme == .dark ? 0.06 : 0.12), .clear],
                               center: UnitPoint(x: 0.5, y: 0.36), startRadius: 0, endRadius: 260)
            }
            .ignoresSafeArea()
        }
    }
}

/// The SOS breath at onboarding size: the ring, the arc that fills on the in-breath, Jelli, and the breath word.
private struct SOSBreathRing: View {
    let dark: Bool
    private let motion = MotionPolicy()

    var body: some View {
        TimelineView(.animation(paused: !motion.breathes)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let p = motion.breathes ? DX.Move.breath(at: t) : 0.7
            let cycle = DX.Move.inhale + DX.Move.exhale
            let phase = t.truncatingRemainder(dividingBy: cycle)
            let breathingIn = !motion.breathes || phase < DX.Move.inhale
            let into = breathingIn ? phase : phase - DX.Move.inhale
            let fade = motion.breathes ? min(1, into / 0.6) : 1
            ZStack {
                Circle()
                    .fill(dark ? Color(hex: 0xFFF8EE).opacity(0.07) : Color(hex: 0x0A1A55).opacity(0.2))
                    .frame(width: 128 + 104 * p, height: 128 + 104 * p)
                Circle().strokeBorder(Color(hex: 0xFFF8EE).opacity(0.36), lineWidth: 3.5)
                Circle()
                    .inset(by: 1.75)
                    .trim(from: 0, to: max(0.001, p))
                    .stroke(Color(hex: 0xFFF8EE), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color(hex: 0xFFF8EE).opacity(0.5), radius: 6)
                VStack(spacing: 0) {
                    JelliView(mood: .breathe, stage: 1, points: 144, animate: motion.breathes)
                        .frame(width: 144, height: 144)
                    ZStack {
                        Text("Breathe in").opacity(breathingIn ? fade : 1 - fade)
                        Text("and out").opacity(breathingIn ? 1 - fade : fade)
                    }
                    .dxFace(.display, 22, weight: 800, tracking: -0.5)
                    .foregroundStyle(Color(hex: 0xFFF8EE))
                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                    .padding(.top, 10)
                }
                .offset(y: -8)
            }
            .scaleEffect(0.88 + 0.16 * p)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Jelli breathing: in for 4 seconds, out for 6."))
    }
}

/// A picture of the tab bar with Craving SOS raised in the middle: where the real button lives.
private struct TabBarPreview: View {
    let dark: Bool
    private let motion = MotionPolicy()

    var body: some View {
        let icon = Color(hex: 0xFFF8EE).opacity(dark ? 0.7 : 0.78)
        HStack(spacing: 0) {
            DXIcon(.sun, size: 22, weight: 2).foregroundStyle(icon).frame(maxWidth: .infinity)
            DXIcon(.path, size: 22, weight: 2).foregroundStyle(icon).frame(maxWidth: .infinity)
            sos.frame(maxWidth: .infinity)
            DXIcon(.leaf, size: 22, weight: 2).foregroundStyle(icon).frame(maxWidth: .infinity)
            DXIcon(.chart, size: 22, weight: 2).foregroundStyle(icon).frame(maxWidth: .infinity)
        }
        .frame(width: 300, height: 62)
        .background(Color.white.opacity(dark ? 0.08 : 0.14), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color(hex: 0xFFF8EE).opacity(0.18), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Craving SOS is the raised button in the middle of your tab bar"))
    }

    /// The raised SOS button, its halo swelling with the breath, and its label inside the bar.
    private var sos: some View {
        ZStack(alignment: .top) {
            Color.clear.frame(height: 62)
            TimelineView(.animation(paused: !motion.breathes)) { timeline in
                let p = motion.breathes ? DX.Move.breath(at: timeline.date.timeIntervalSinceReferenceDate) : 0.6
                Circle()
                    .strokeBorder(Color(hex: 0xFFF8EE).opacity(0.5), lineWidth: 2)
                    .frame(width: 66, height: 66)
                    .scaleEffect(1 + 0.25 * (1 - p))
                    .opacity(0.3 + 0.6 * p)
            }
            .offset(y: -28)
            DXIcon(.wave, size: 26, weight: 2.4)
                .foregroundStyle(Color(hex: 0x1F3C8C))
                .frame(width: 50, height: 50)
                .background(Color(hex: 0xFFF8EE), in: Circle())
                .shadow(color: Color(hex: 0x081234).opacity(0.4), radius: 8, y: 6)
                .offset(y: -20)
            Text("SOS")
                .dxFace(.body, 13, weight: 700)
                .foregroundStyle(Color(hex: 0xFFF8EE))
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 8)
        }
        .frame(height: 62)
    }
}

// MARK: Your day · apricot

/// A day opens with Xero and closes with Glim: two windows, a dawn over the pledge and a moonlit hill over the
/// check-in. Each window keeps its own colours, so morning and night still read apart in dark mode.
///
/// Motion: the morning window arrives first (Xero idles, the sun glows); at 500 ms the night window settles up from
/// below (900 ms), stars twinkling and Glim's wings fluttering. Proud is shown as the example answer.
struct YourDayScreen: View {
    let model: OnboardingModel
    @State private var night = false
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()
    private let ground = DX.Ground.apricot

    private var reason: String {
        model.why.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var dark: Bool { scheme == .dark }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                MarkedTitle(String(localized: "Each day opens and closes the "), marking: String(localized: "same way"), color: ground.mark)
                    .dxType(.large)
                    .foregroundStyle(ground.ink)
                    .accessibilityAddTraits(.isHeader)
                    .dxArrive(0)
                morning
                    .padding(.top, 22)
                    .dxArrive(1)
                evening
                    .padding(.top, 18)
                    .offset(y: night || motion.reduce ? 0 : 48)
                    .opacity(night || motion.reduce ? 1 : 0)
                Text("Miss one and nothing breaks. No guilt, ever.")
                    .dxFace(.body, 15, weight: 500)
                    .foregroundStyle(ground.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 24)
                    .dxArrive(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DX.Layout.gutter)
            .padding(.top, DX.Space.m)
            .padding(.bottom, DX.Space.l)
            .dxReadableColumn()
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("Continue") { model.next() }
                .buttonStyle(.dx(.primary, on: ground))
                .padding(.horizontal, DX.Layout.buttonGutter)
                .dxReadableColumn()
                .padding(.top, 20)
                .padding(.bottom, DX.Space.xs)
                .background {
                    LinearGradient(stops: [.init(color: ground.background.opacity(0), location: 0),
                                           .init(color: ground.background, location: 0.34)],
                                   startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea(edges: .bottom)
                }
        }
        .task {
            if motion.reduce {
                night = true
                return
            }
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(DX.Move.settle) { night = true }
        }
    }

    // MARK: Morning

    private var morning: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // A window onto the morning: the daylight dawn in both modes.
                HorizonScene(.dawn, fit: .middle, animate: !motion.reduce,
                             sun: .init(x: 292, radius: 32, drop: -4, clouds: false), daylightInDark: true)
                XeroView(mood: .hello, stage: 1, points: 70, animate: !motion.reduce)
                    .frame(width: 70, height: 70)
                    .offset(x: 56, y: 4)
                    .accessibilityHidden(true)
            }
            .frame(height: 80)
            .clipped()
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        DXIcon(.sun, size: 15, weight: 2.6).foregroundStyle(Color(light: 0xE2742F, dark: 0xFFC93C))
                        Text("\(Text("Morning").fontWeight(.bold).foregroundStyle(ground.ink)) with Xero")
                            .foregroundStyle(Color(light: 0x3E2E24, dark: 0xCFC8C2))
                    }
                    .dxFace(.body, 14, weight: 500)
                    Spacer(minLength: 4)
                    WindowChip(icon: .hand, text: "10-second hold",
                               fill: Color(light: (0xFFE2CF, 1), dark: (0xFFB27A, 0.18)),
                               ink: Color(light: 0x5A200A, dark: 0xFFD2B0))
                }
                Text("“Today, I won't use nicotine.”")
                    .dxType(.headline)
                    .foregroundStyle(ground.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                if !reason.isEmpty {
                    Text("Because: \(reason)")
                        .dxFace(.body, 15, weight: 500)
                        .foregroundStyle(Color(light: 0x3E2E24, dark: 0xCFC8C2))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(light: (0xFFFFFF, 0.94), dark: (0x262029, 1)))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(Color(light: (0xFFC38A, 0), dark: (0xFFC38A, 0.42)), lineWidth: 1))
        .shadow(color: dark ? .clear : Color(hex: 0x783C14).opacity(0.12), radius: 11, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Morning with Xero: a ten-second pledge you hold. Today, I won't use nicotine."))
    }

    // MARK: Night

    private var evening: some View {
        let ink = Color(hex: 0xF6EFE2)
        let muted = Color(light: 0xCBD2E4, dark: 0xC8CFE0)
        let face = Color(light: 0x33496F, dark: 0x2F4270)
        return VStack(alignment: .leading, spacing: 0) {
            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    NightSky(moon: CGPoint(x: proxy.size.width - 56, y: 28), animate: !motion.reduce,
                             options: .init(moonRadius: 12, fireflies: 0, fade: false))
                    GlimView(mood: .hello, stage: 1, points: 70, animate: !motion.reduce)
                        .frame(width: 70, height: 70)
                        .offset(x: 70, y: 2)
                        .accessibilityHidden(true)
                }
            }
            .frame(height: 80)
            .clipped()
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        DXIcon(.moon, size: 15, weight: 2, filled: true).foregroundStyle(Color(hex: 0xFFD37A))
                        Text("\(Text("Night").fontWeight(.bold).foregroundStyle(ink)) with Glim")
                            .foregroundStyle(muted)
                    }
                    .dxFace(.body, 14, weight: 500)
                    Spacer(minLength: 4)
                    WindowChip(icon: .clock, text: "One minute", fill: Color.white.opacity(0.1), ink: ink)
                }
                Text("How was today, really?")
                    .dxType(.headline)
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                HStack(spacing: 8) {
                    ForEach(CheckInMood.allCases, id: \.self) { mood in
                        let picked = mood == .proud
                        VStack(spacing: 4) {
                            ZStack {
                                Circle().fill(picked ? Color(hex: 0xFFD37A).opacity(0.2) : face)
                                if picked { Circle().strokeBorder(Color(hex: 0xFFD37A), lineWidth: 3) }
                                MoodFace(mood)
                                    .stroke(picked ? Color(hex: 0xFFD37A) : ink,
                                            style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                                    .frame(width: 28, height: 28)
                            }
                            .frame(width: 40, height: 40)
                            Text(mood.label)
                                .dxFace(.body, 13, weight: picked ? 700 : 600)
                                .foregroundStyle(picked ? Color(hex: 0xFFD37A) : ink.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 10)
                // A picture of the check-in, not the check-in: nothing here can be chosen.
                .accessibilityHidden(true)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(light: 0x17243F, dark: 0x121D35))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(Color.white.opacity(dark ? 0.1 : 0), lineWidth: 1))
        .shadow(color: dark ? .clear : Color(hex: 0x783C14).opacity(0.16), radius: 11, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Night with Glim: a one-minute check-in. How was today, really?"))
    }
}

/// The small label chip on each window's header row ("10-second hold", "One minute").
private struct WindowChip: View {
    let icon: DX.Icon
    let text: LocalizedStringKey
    let fill: Color
    let ink: Color

    var body: some View {
        HStack(spacing: 6) {
            DXIcon(icon, size: 14, weight: 2.2)
            Text(text).lineLimit(1)
        }
        .dxFace(.body, 13, weight: 700)
        .foregroundStyle(ink)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(fill, in: Capsule())
        .fixedSize()
    }
}
