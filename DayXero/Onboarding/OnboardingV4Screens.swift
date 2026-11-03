import DayXeroCore
import SwiftUI
import UserNotifications

// v4 onboarding screens (design doc §10, F01–F07). Copy follows the canvas except where the code
// and the canvas disagree, where it follows the code (decision 17): prices come from the store,
// the check-in reminder time from DailyReminderSettings, notification copy from NotificationCopy.

private let shortDate = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated)

// MARK: F01 Breathe · coral

/// One slow breath before any question. Skip is there from the start (S27.10); the screen carries on by itself after
/// two full 10 s breaths.
struct BreatheScreen: View {
    let onDone: () -> Void
    private let motion = MotionPolicy()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip", action: onDone)
                    .buttonStyle(.dx(.quiet, on: .coral))
            }
            .padding(.horizontal, DX.Layout.gutter)
            Spacer(minLength: 12)
            ZStack {
                // The rings, the words and Xero all breathe on the one reference clock (QW2). The rings used to count
                // from when the screen opened, so they could shrink under "Breathe in" and barely move on the way out.
                TimelineView(.animation(paused: !motion.breathes)) { timeline in
                    let p = motion.breathes ? DX.Move.breath(at: timeline.date.timeIntervalSinceReferenceDate) : 0.5
                    ZStack {
                        ForEach(0..<3) { ring in
                            Circle()
                                .fill(DX.Fill.cream.opacity(0.16 - Double(ring) * 0.04))
                                .frame(width: 170 + CGFloat(ring) * 60, height: 170 + CGFloat(ring) * 60)
                                .scaleEffect(0.72 + 0.28 * p)
                        }
                    }
                }
                XeroView(mood: .breathe, stage: 1, size: .hero)
                    .dxArrive(0)
            }
            .frame(height: 340)
            .accessibilityHidden(true)
            BreathingWords(inhale: String(localized: "Breathe in"), exhale: String(localized: "…and out"))
                .foregroundStyle(DX.Ground.coral.ink)
                .padding(.top, 8)
            Text("One slow breath before I ask anything. In for 4, out for 6.")
                .dxType(.body)
                .foregroundStyle(DX.Ground.coral.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 10)
            Spacer()
        }
        .padding(.vertical, DX.Space.s)
        .task {
            try? await Task.sleep(for: .seconds(motion.reduce ? 5 : Self.autoAdvance(at: .now)))
            guard !Task.isCancelled else { return }
            onDone()
        }
    }
}

extension BreatheScreen {
    /// Seconds until the screen carries on by itself: the end of a second full breath on the shared clock. A breath
    /// joined with more than half of it left counts as the first.
    static func autoAdvance(at now: Date) -> Double {
        let cycle = DX.Move.inhale + DX.Move.exhale
        let left = cycle - now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle)
        return left + (left > cycle / 2 ? cycle : 2 * cycle)
    }
}

// MARK: F02 Welcome · apricot

/// The promise, a restore link for returning buyers, and the 18+ line with Terms and Privacy.
struct WelcomeScreen: View {
    let model: OnboardingModel
    @Environment(Entitlement.self) private var entitlement
    @State private var restoreNote: LocalizedStringKey?
    @State private var restoring = false
    @State private var cheer = false
    @State private var bubble = false
    private let motion = MotionPolicy()

    @Environment(\.dynamicTypeSize) private var typeSize

    private let ground = DX.Ground.apricot

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                // At the largest sizes the page scrolls, with a shorter hero, so nothing is cut off.
                ScrollView { page(heroHeight: 240) }
                    .scrollBounceBehavior(.basedOnSize)
                    .ignoresSafeArea(edges: .top)
            } else {
                page(heroHeight: 360)
            }
        }
        .task {
            // Xero rises and says hello, then cheers once after his last line: three lines (BET-3), or the one
            // callout at accessibility sizes, where the shorter hero has no room for three.
            let lines = typeSize.isAccessibilitySize ? 1.0 : 3.0
            try? await Task.sleep(for: .seconds(motion.reduce ? 0.2 : 1.3))
            withAnimation(motion.animation(DX.Move.arrive)) { bubble = true }
            try? await Task.sleep(for: .seconds(CrewBubble.gap * lines))
            cheer = !motion.reduce
            try? await Task.sleep(for: .seconds(1.4))
            cheer = false
        }
    }

    private func page(heroHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                HeroScene(.dawn, clarity: CrewGrowth.prepClarity, height: heroHeight, edge: ground.background)
                if !typeSize.isAccessibilitySize {
                    // BET-3 (Screen Lab, 3 Nov 2026): Xero left of centre, his three lines on his right over the sky.
                    XeroView(mood: cheer ? .cheer : .hello, stage: 1, size: .hero)
                        .offset(y: -18)
                        .dxArrive(0)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 24)
                    if bubble {
                        VStack(alignment: .leading, spacing: 8) {
                            CrewBubble(String(localized: "Hi! I'm Xero."), on: ground, size: .callout, fill: .cream, order: 0, start: 0)
                            CrewBubble(String(localized: "I'll get you ready for your Quit Day."), on: ground, fill: .cream, order: 1, start: 0)
                            CrewBubble(String(localized: "A few questions, then your plan."), on: ground, fill: .cream, order: 2, start: 0)
                        }
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .frame(width: 168)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.trailing, 16)
                        .padding(.top, max(heroHeight - 18 - 200 - 60, 60))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("Xero says: Hi! I'm Xero. I'll get you ready for your Quit Day. A few questions, then your plan."))
                    }
                } else {
                XeroView(mood: cheer ? .cheer : .hello, stage: 1, size: .hero)
                    .offset(y: -18)
                    .dxArrive(0)
                    .overlay(alignment: .topTrailing) {
                        if bubble {
                            Text("Hi! I'm Xero.")
                                .dxType(.headline)
                                .foregroundStyle(DX.Fill.navy)
                                // A short callout over the art; it is capped so it stays beside Xero.
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(DX.Fill.cream, in: UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 4,
                                                                                     bottomTrailingRadius: 18, topTrailingRadius: 18))
                                .offset(x: 70, y: 10)
                                .transition(.scale(scale: 0.6, anchor: .bottomLeading).combined(with: .opacity))
                        }
                    }
                }
            }
            .frame(height: heroHeight)
            .ignoresSafeArea(edges: .top)
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Don't quit today.")
                    Text("Quit on your Quit Day.")
                }
                .dxType(.large)
                .foregroundStyle(ground.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                .dxArrive(1)
                Text("Prep for up to 7 days while you still use as normal, then quit on the day you choose.")
                    .dxType(.body)
                    .foregroundStyle(ground.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .dxArrive(2)
                if let restoreNote {
                    Text(restoreNote).dxType(.footnote).foregroundStyle(ground.muted)
                }
                Spacer(minLength: 8)
                Button("Get started") { model.next() }
                    .buttonStyle(.dx(.primary, on: ground))
                    .dxArrive(3)
                Button("Restore purchases") { Task { await restore() } }
                    .buttonStyle(.dx(.quiet, on: ground))
                    .frame(maxWidth: .infinity)
                    .disabled(restoring)
                legal
                    .dxType(.caption)
                    .foregroundStyle(ground.muted)
                    .tint(ground.ink)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, DX.Layout.buttonGutter)
            .dxReadableColumn()
            .padding(.bottom, DX.Space.xs)
        }
    }

    /// The 18+ line with the Terms and Privacy Policy links (S15.4, S27.1).
    private var legal: Text {
        let terms = "[\(String(localized: "Terms"))](\(AppLinks.terms.absoluteString))"
        let line: String
        if let privacy = AppLinks.privacy {
            let policy = "[\(String(localized: "Privacy Policy"))](\(privacy.absoluteString))"
            line = String(localized: "Takes 2 minutes and stays private on this phone. By continuing you confirm you're 18+ and agree to the \(terms) and \(policy).")
        } else {
            line = String(localized: "Takes 2 minutes and stays private on this phone. By continuing you confirm you're 18+ and agree to the \(terms).")
        }
        return Text((try? AttributedString(markdown: line)) ?? AttributedString(line))
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

// MARK: F04 Quit Day · apricot

struct QuitDayScreen: View {
    @Bindable var model: OnboardingModel
    @State private var picking = false
    @State private var committed = false
    private let ground = DX.Ground.apricot

    /// The eight days from today to the recommended Quit Day (or the chosen one, if sooner).
    private var strip: [Date] {
        let end = model.calendar.startOfDay(for: max(model.quitDay, model.recommendedQuitDay))
        var days: [Date] = []
        var day = model.today
        while day <= end, days.count < 8 {
            days.append(day)
            day = model.calendar.date(byAdding: .day, value: 1, to: day) ?? end.addingTimeInterval(1)
        }
        return days
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                HeroScene(.dawn, clarity: CrewGrowth.prepClarity, height: 250, edge: ground.background)
                XeroView(mood: .hello, stage: 1, size: .scene).offset(y: -14)
            }
            .ignoresSafeArea(edges: .top)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(model.name.isEmpty ? "Pick your Quit Day" : "Pick your Quit Day, \(model.name)")
                        .dxType(.title).foregroundStyle(ground.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("I recommend \(Text(model.recommendedQuitDay, format: shortDate).bold()) for a full 7-day prep. Ready sooner? Any day from \(Text(model.quitDayRange.lowerBound, format: shortDate).bold()) works. Keep using as normal until then.")
                        .dxType(.body).foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    dateStrip
                    HStack {
                        legend(DX.Fill.cardOnColour, "Prep · \(max(model.prepDays, 0)) days")
                        Spacer()
                        legend(ground.ink, "Quit Day")
                    }
                    Button("Pick another date") { picking = true }
                        .buttonStyle(.dx(.quiet, on: ground))
                }
                .padding(.horizontal, DX.Layout.gutter)
                .dxReadableColumn()
            }
            VStack(spacing: 6) {
                HoldButton("Hold to set \(model.quitDay.formatted(shortDate))",
                           done: String(localized: "Quit Day set · \(model.quitDay.formatted(shortDate))"),
                           duration: DX.Move.hold, on: ground) {
                    committed = true
                    Task {
                        try? await Task.sleep(for: .seconds(0.8))
                        model.next()
                    }
                }
                .accessibilityIdentifier("onboarding.hold")
                .disabled(!model.canContinue)
                Text("Hold for 1 second. Quit Day comes on this date, even if prep runs short. You can change it later.")
                    .dxType(.caption).foregroundStyle(ground.muted)
            }
            .padding(.horizontal, DX.Layout.buttonGutter)
            .dxReadableColumn()
            .padding(.bottom, DX.Space.xs)
        }
        // Back and progress come from the flow's shared header, which floats over the art inside the safe area (QW3).
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

    private var dateStrip: some View {
        HStack(spacing: 4) {
            ForEach(strip, id: \.self) { day in
                let quit = model.calendar.isDate(day, inSameDayAs: model.quitDay)
                let prep = day < model.calendar.startOfDay(for: model.quitDay)
                let selectable = model.quitDayRange.contains(day)
                Button { model.quitDay = day } label: {
                    VStack(spacing: 2) {
                        Text(day, format: .dateTime.weekday(.abbreviated)).dxType(.caption)
                        Text(day, format: .dateTime.day()).dxType(.headline)
                    }
                    .foregroundStyle(quit ? ground.background : ground.ink)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(quit ? ground.ink : (prep ? DX.Fill.cardOnColour : Color.clear),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.dxPress)
                .disabled(!selectable)
                // Only the day becoming Quit Day buzzes, not the one it leaves.
                .sensoryFeedback(DX.Haptic.select, trigger: quit) { _, isQuit in isQuit }
                .accessibilityLabel(Text(day, format: .dateTime.weekday(.wide).day().month(.wide)))
                .accessibilityValue(Text(quit ? "Quit Day" : (prep ? "Prep day" : "")))
                .accessibilityAddTraits(quit ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    private func legend(_ color: Color, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4).fill(color).frame(width: 14, height: 14)
            Text(title).dxType(.caption).foregroundStyle(ground.muted)
        }
    }
}

// MARK: F05 Your plan builds · mint

struct BuildingScreen: View {
    let model: OnboardingModel
    @State private var shown = 0
    @State private var friends = false
    @State private var ready = false
    private let motion = MotionPolicy()
    private let ground = DX.Ground.mint

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
                    // BET-3 (Screen Lab, 3 Nov 2026): Xero talks while the rows land, then hands over to the friends.
                    CrewBubble(friends ? String(localized: "That's your plan. Two friends will help too.")
                                       : String(localized: "Fitting this around your answers…"),
                               on: ground, tail: .topLeading, order: nil)
                        .id(friends)
                        .transition(.opacity)
                        .padding(.top, -4)
                        .accessibilityLabel(Text(friends ? "Xero says: That's your plan. Two friends will help too." : "Xero says: Fitting this around your answers…"))
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
                        VStack(alignment: .leading, spacing: 10) {
                            CrewSpeech(String(localized: "Jelli"), lines: [.init(String(localized: "I'm Jelli. I'll be there at your first craving."))],
                                       on: ground, firstOrder: 0) {
                                JelliView(mood: .hello, stage: 1, size: .avatar, animate: false)
                                    .background(DX.Ground.ocean.background, in: Circle()).clipShape(Circle())
                            }
                            CrewSpeech(String(localized: "Glim"), lines: [.init(String(localized: "I'm Glim. I'll see you on your first evening."))],
                                       on: ground, firstOrder: 1) {
                                GlimView(mood: .hello, stage: 1, size: .avatar, animate: false)
                                    .background(DX.Ground.violet.background, in: Circle()).clipShape(Circle())
                            }
                        }
                        .padding(.top, 4)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, DX.Space.m)
                .dxReadableColumn()
            }
            Button("See my plan") { model.next() }
                .buttonStyle(.dx(.primary, on: ground))
                .disabled(!ready)
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
            // "See my plan" turns on once Glim has spoken (BET-3); at once with motion reduced.
            try? await Task.sleep(for: .seconds(motion.reduce ? 0 : 0.4 + CrewBubble.gap))
            ready = true
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
    private let ground = DX.Ground.mint

    private var annual: PlanOption? { paywall?.plans.first { $0.plan == .annual } }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Step \(model.stepNumber) of \(model.stepTotal)").dxType(.caption).textCase(.uppercase).foregroundStyle(ground.muted)
                    MarkedTitle(String(localized: "Your plan is "), marking: String(localized: "ready"), color: DX.Mark.color(on: ground))
                        .dxType(.title).foregroundStyle(ground.ink)
                    Text(entitlement.isPro ? "Everything is unlocked." : "Two cards from each prep day are on us. Nothing is charged today.")
                        .dxType(.body).foregroundStyle(ground.muted)
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

    private var savings: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Money you'll keep in year 1").dxType(.caption).textCase(.uppercase).foregroundStyle(ground.muted)
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
                Text("Built around what gets in your way").dxType(.caption).textCase(.uppercase).foregroundStyle(ground.muted)
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
            Text("**Always free:** your counter, Craving SOS, a 60-second breathing timer, evening check-ins and two cards from each prep day")
            Text("**With the full program:** every prep session in full, your Day Xero launch kit, Weeks 1 to 4, Jelli's voice coaching, if-then slip plans, a 12-week NRT schedule and trigger heatmaps")
        }
        .dxType(.footnote)
        .foregroundStyle(ground.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dxCardOnColour()
    }

    /// The 7-day trial (BET-1): offered after today's two free cards of Prep 1, so it can start today.
    private var trialCard: some View {
        let start = model.calendar.startOfDay(for: .now)
        let days = annual?.trialDays ?? FullProgram.trialDays
        let end = model.calendar.date(byAdding: .day, value: days, to: start) ?? start
        let lead = TrialReminder.leadDays(trialEndsAt: end, now: start)
        let remind = model.calendar.date(byAdding: .day, value: -lead, to: end) ?? end
        let after = FullProgram.trialEndsDaysAfterQuitDay(trialEnd: end, quitDay: model.quitDay, calendar: model.calendar)
        let (e, r) = (end.formatted(shortDate), remind.formatted(shortDate))
        let runs: String = switch after {
        case 2...: String(localized: "If you start it today, it runs to \(e), \(after) days after your Quit Day. I'll remind you on \(r).")
        case 1: String(localized: "If you start it today, it runs to \(e), the day after your Quit Day. I'll remind you on \(r).")
        case 0: String(localized: "If you start it today, it runs to \(e), your Quit Day. I'll remind you on \(r).")
        default: String(localized: "If you start it today, it runs to \(e). I'll remind you on \(r).")
        }
        return VStack(alignment: .leading, spacing: 6) {
            Text("7-day free trial").dxType(.caption).textCase(.uppercase)
                .foregroundStyle(DX.Fill.cream.opacity(0.85))
            if let annual {
                Text("\(days) days free, then \(annual.priceText) a year").dxType(.headline).foregroundStyle(DX.Fill.cream)
                if let perMonth = annual.perMonthText {
                    Text("That's \(perMonth) a month. I'll ask after today's two free cards, not before.")
                        .dxType(.footnote).foregroundStyle(DX.Fill.cream.opacity(0.85))
                }
            } else {
                Text("I'll ask you about the full program after today's two free cards, not before.").dxType(.headline).foregroundStyle(DX.Fill.cream)
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
                    Text("Two small nudges a day").dxType(.title).foregroundStyle(ground.ink)
                        .accessibilityAddTraits(.isHeader)
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
