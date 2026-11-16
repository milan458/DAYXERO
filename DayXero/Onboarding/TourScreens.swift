import DayXeroCore
import SwiftUI

// What DayXero is, shown where it answers a question the person has just then (16 Nov 2026). Before these, the only
// explanation was one sentence on Welcome, and the hard paywall named things nobody had been shown.
//   How it works   after Welcome: prep, Quit Day, four weeks.
//   Craving SOS    after the triggers: what they'll have when their own trigger hits.
//   Your day       before the Quit Day pick: the morning pledge and the night check-in.
// None of them asks anything, so Continue is never held back. Only Xero is drawn at size; Jelli and Glim stay
// 40 pt avatars until their own first moments (design doc §3).

// MARK: How it works · apricot

/// The three parts of the program on one road. The sky above it starts as hazy as prep and clears as each part
/// lands, which is the app's own measure of progress.
struct HowItWorksScreen: View {
    let model: OnboardingModel
    @State private var shown = 0
    private let motion = MotionPolicy()
    private let ground = DX.Ground.apricot

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
                  detail: "Keep using as normal. One session a day shows you how your cravings work and builds your plan.",
                  clarity: Double(CrewGrowth.prepClarity)),
            Phase(id: 1, name: "Quit Day", span: "the day you pick",
                  detail: "You stop, with your first hours already planned.",
                  clarity: 48),
            Phase(id: 2, name: "Four weeks", span: "after Quit Day",
                  detail: "A session for what each week tends to bring, a morning pledge and a night check-in.",
                  clarity: 100),
        ]
    }

    private var clarity: Double {
        shown == 0 ? Double(CrewGrowth.prepClarity) : phases[min(shown, phases.count) - 1].clarity
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    MarkedTitle(String(localized: "How your quit "), marking: String(localized: "works"),
                                color: DX.Mark.color(on: ground))
                        .dxType(.large)
                        .foregroundStyle(ground.ink)
                        .dxArrive(0)
                    ClearingSky(clarity: clarity)
                        .frame(height: 148)
                        .clipShape(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
                        .padding(.top, DX.Space.m)
                        .dxArrive(1)
                    Text("Your sky starts hazy. It clears a little with every day you stay clear.")
                        .dxType(.footnote)
                        .foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                        .dxArrive(1)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(phases) { phase in
                            stop(phase, last: phase.id == phases.count - 1)
                                .opacity(shown > phase.id ? 1 : 0)
                                .offset(y: shown > phase.id || motion.reduce ? 0 : DX.Move.arriveRise)
                        }
                    }
                    .padding(.top, DX.Space.l)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, DX.Space.m)
                .padding(.bottom, DX.Space.l)
                .dxReadableColumn()
            }
            .scrollBounceBehavior(.basedOnSize)
            Button("Continue") { model.next() }
                .buttonStyle(.dx(.primary, on: ground))
                .padding(.horizontal, DX.Layout.buttonGutter)
                .dxReadableColumn()
                .padding(.bottom, DX.Space.xs)
        }
        .task {
            // The parts land one at a time and the sky clears with them. Reduce Motion shows the end state at once.
            if motion.reduce {
                shown = phases.count
                return
            }
            try? await Task.sleep(for: .seconds(0.5))
            for count in 1...phases.count {
                withAnimation(DX.Move.settle) { shown = count }
                try? await Task.sleep(for: .seconds(0.7))
            }
        }
    }

    /// One stop on the road: its marker and the line down to the next one, then the name, how long, and what happens.
    private func stop(_ phase: Phase, last: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(phase.name).dxType(.headline).foregroundStyle(ground.ink)
                    Text(phase.span).dxType(.footnote).foregroundStyle(ground.muted)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(phase.name).dxType(.headline).foregroundStyle(ground.ink)
                    Text(phase.span).dxType(.footnote).foregroundStyle(ground.muted)
                }
            }
            Text(phase.detail)
                .dxType(.body)
                .foregroundStyle(ground.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 40)
        .padding(.bottom, last ? 0 : 22)
        .background(alignment: .topLeading) {
            VStack(spacing: 0) {
                marker(phase.id)
                    .frame(width: 24, height: 24)
                if !last {
                    Rectangle().fill(ground.ink.opacity(0.28)).frame(width: 2)
                }
            }
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    /// Prep is an open ring, Quit Day the one solid stop, the four weeks a smaller solid one.
    @ViewBuilder
    private func marker(_ id: Int) -> some View {
        switch id {
        case 0: Circle().strokeBorder(ground.ink, lineWidth: 2.5).frame(width: 14, height: 14)
        case 1: Circle().fill(ground.ink).frame(width: 22, height: 22)
        default: Circle().fill(ground.ink).frame(width: 12, height: 12)
        }
    }
}

/// The dawn horizon with a clarity SwiftUI can animate, so the haze lifts smoothly instead of jumping.
private struct ClearingSky: View, Animatable {
    /// Nonisolated so it can satisfy `Animatable` from a main-actor view under Swift 6.
    nonisolated var animatableData: Double

    init(clarity: Double) {
        animatableData = clarity
    }

    var body: some View {
        HorizonScene(.dawn, clarity: Int(animatableData.rounded()), fit: .bottom)
    }
}

// MARK: Craving SOS · ocean

/// What they'll have when their own trigger hits: the SOS breath, running, on Jelli's ground. Calm tier (design doc
/// §4.1): no countdown, no prediction, and Jelli stays a 40 pt avatar until the first real craving.
struct CravingSOSIntroScreen: View {
    let model: OnboardingModel
    private let motion = MotionPolicy()
    private let ground = DX.Ground.ocean

    /// Their triggers in the order the plan lists them ("Something else" has no moment to name).
    private var named: [Trigger] {
        Trigger.allCases.filter { model.triggers.contains($0) && $0 != .other }
    }

    private var title: String {
        if let first = named.first {
            return String(localized: "If it's \(String(localized: first.situation)), you'll have this.")
        }
        return String(localized: "When a craving hits, you'll have this.")
    }

    /// "coffee and stress": the two the plan will call their waves to watch.
    private var moments: String? {
        let names = named.prefix(2).map { String(localized: $0.title).lowercased() }
        return names.isEmpty ? nil : ListFormatter.localizedString(byJoining: Array(names))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .dxType(.large)
                        .foregroundStyle(ground.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .dxArrive(0)
                    breath
                        .frame(maxWidth: .infinity)
                        .padding(.top, DX.Space.s)
                        .dxArrive(1)
                    Text("\(Text("Craving SOS.").fontWeight(.bold).foregroundStyle(ground.ink)) Open it from the tab bar and breathe with Jelli, in for 4 and out for 6. Most cravings pass within a few minutes.")
                        .dxType(.body)
                        .foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, DX.Space.s)
                        .dxArrive(2)
                    HStack(alignment: .center, spacing: 12) {
                        JelliView(mood: .calm, stage: 1, size: .avatar, animate: false)
                            .background(DX.Fill.oceanSecondary, in: Circle())
                            .clipShape(Circle())
                            .accessibilityHidden(true)
                        Text(plan)
                            .dxType(.footnote)
                            .foregroundStyle(ground.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .dxCardOnColour(on: ground)
                    .padding(.top, DX.Space.m)
                    .dxArrive(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, DX.Space.m)
                .padding(.bottom, DX.Space.l)
                .dxReadableColumn()
            }
            .scrollBounceBehavior(.basedOnSize)
            Button("Continue") { model.next() }
                .buttonStyle(.dx(.primary, on: ground))
                .padding(.horizontal, DX.Layout.buttonGutter)
                .dxReadableColumn()
                .padding(.bottom, DX.Space.xs)
        }
    }

    private var plan: String {
        if let moments {
            return String(localized: "Jelli rides each wave with you and never judges. In prep you'll also plan for your biggest moments: \(moments).")
        }
        return String(localized: "Jelli rides each wave with you and never judges. In prep you'll also plan for your biggest moments.")
    }

    /// The rings and the words on the one breathing clock, as SOS runs them. With Reduce Motion the rings rest and
    /// the words carry the rhythm.
    private var breath: some View {
        ZStack {
            TimelineView(.animation(paused: !motion.breathes)) { timeline in
                let p = motion.breathes ? DX.Move.breath(at: timeline.date.timeIntervalSinceReferenceDate) : 0.5
                ZStack {
                    ForEach(0..<3) { ring in
                        Circle()
                            .fill(DX.Fill.cream.opacity(0.11 - Double(ring) * 0.03))
                            .frame(width: 140 + CGFloat(ring) * 46, height: 140 + CGFloat(ring) * 46)
                            .scaleEffect(0.74 + 0.26 * p)
                    }
                }
            }
            .accessibilityHidden(true)
            BreathingWords(inhale: String(localized: "Breathe in"), exhale: String(localized: "…and out"))
                .foregroundStyle(ground.ink)
                // The words sit inside the rings, so they stop growing before they would spill out of them.
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
        .frame(height: 236)
    }
}

// MARK: Your day · apricot over violet

/// A day opens with Xero and closes with Glim. The morning sits on Xero's apricot; the night is a violet sheet that
/// settles up from the bottom after it, the hand-over the two make every evening.
struct YourDayScreen: View {
    let model: OnboardingModel
    @State private var night = false
    private let motion = MotionPolicy()
    private let ground = DX.Ground.apricot
    private let dusk = DX.Ground.violet

    private var reason: String {
        model.why.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    morning
                        .padding(.horizontal, DX.Layout.gutter)
                        .padding(.top, DX.Space.m)
                        .padding(.bottom, DX.Space.l)
                        .dxReadableColumn()
                    evening
                        .offset(y: night || motion.reduce ? 0 : 56)
                        .opacity(night ? 1 : 0)
                }
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        // Violet under the sheet, so a bounce at the bottom of a long page never shows apricot below the night.
        .background(alignment: .bottom) {
            dusk.background.frame(height: 120).opacity(night ? 1 : 0)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("Continue") { model.next() }
                .buttonStyle(.dx(.primary, on: dusk))
                .padding(.horizontal, DX.Layout.buttonGutter)
                .dxReadableColumn()
                .padding(.top, DX.Space.xs)
                .padding(.bottom, DX.Space.xs)
                .background(dusk.background.ignoresSafeArea(edges: .bottom))
                .opacity(night ? 1 : 0)
        }
        .task {
            if motion.reduce {
                night = true
                return
            }
            try? await Task.sleep(for: .seconds(0.7))
            withAnimation(DX.Move.settle) { night = true }
        }
    }

    private var morning: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Each day opens and closes the same way")
                .dxType(.large)
                .foregroundStyle(ground.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .dxArrive(0)
            HStack(alignment: .top, spacing: 14) {
                XeroView(mood: .hello, stage: 1, size: .card)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Morning, with Xero").dxType(.headline).foregroundStyle(ground.ink)
                    Text("A ten-second pledge. You hold the button and mean it.")
                        .dxType(.body)
                        .foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, DX.Space.l)
            .accessibilityElement(children: .combine)
            .dxArrive(1)
            VStack(alignment: .leading, spacing: 6) {
                Text("“Today, I won't use nicotine.”")
                    .dxType(.headline)
                    .foregroundStyle(ground.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !reason.isEmpty {
                    Text("Because: \(reason)")
                        .dxType(.footnote)
                        .foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dxCardOnColour(on: ground)
            .padding(.top, DX.Space.s)
            .accessibilityElement(children: .combine)
            .dxArrive(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var evening: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                GlimView(mood: .hello, stage: 1, size: .avatar, animate: false)
                    .background(DX.Fill.onColourCard(for: dusk), in: Circle())
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Night, with Glim").dxType(.headline).foregroundStyle(dusk.ink)
                    Text("A one-minute check-in. One question, then rest.")
                        .dxType(.body)
                        .foregroundStyle(dusk.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            VStack(alignment: .leading, spacing: 12) {
                Text("How was today, really?")
                    .dxType(.headline)
                    .foregroundStyle(dusk.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    ForEach(CheckInMood.allCases, id: \.self) { mood in
                        VStack(spacing: 6) {
                            MoodFace(mood)
                                .stroke(dusk.ink, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                                .frame(width: 32, height: 32)
                                .background(DX.Fill.onColourCard(for: dusk), in: Circle())
                            Text(mood.label).dxType(.caption).foregroundStyle(dusk.ink)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                // A picture of the check-in, not the check-in: nothing here can be chosen.
                .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dxCardOnColour(on: dusk)
            .padding(.top, DX.Space.s)
            .accessibilityElement(children: .combine)
            Text("Miss one and nothing breaks. No guilt, ever.")
                .dxType(.footnote)
                .foregroundStyle(dusk.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, DX.Space.s)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DX.Layout.gutter)
        .padding(.top, 46)
        .padding(.bottom, DX.Space.m)
        .dxReadableColumn()
        // The sheet runs to the bottom of the screen however short the night's content is.
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            NightSheet()
                .fill(dusk.background)
                .shadow(color: Color(hex: 0x1A0B2E).opacity(0.26), radius: 6, x: 0, y: -4)
        }
    }
}

/// The night's ground with the paper edge along its top: the horizon curve from the hero scenes, turned into a rise.
private struct NightSheet: Shape {
    func path(in rect: CGRect) -> Path {
        let rise: CGFloat = 24
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + rise))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rise),
                   control1: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY),
                   control2: CGPoint(x: rect.minX + rect.width * 0.72, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
