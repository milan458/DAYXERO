import DayXeroCore
import SwiftUI

// Program v2 activities, part two: plans, checklists, breathing, commit, scenario, note, info, share,
// NRT, slip practice and the plan card (handoff 5.8–5.19).

// MARK: - plan_builder

/// "If …, then I will …" lines. The "if" half is free text, prefilled when the prompt sets it.
struct PlanBuilderBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var plans: [ProgramAnswerValue.PlanLine] = []
    @State private var situation = ""
    @State private var action = ""
    @State private var typingOwn = false

    /// "If today gets hard, then I will…" sets the situation to "today gets hard".
    private var promptSituation: String {
        let prompt = ctx.text(beat.prompt)
        guard prompt.hasPrefix("If "), let range = prompt.range(of: ", then I will") else { return "" }
        return String(prompt[prompt.index(prompt.startIndex, offsetBy: 3)..<range.lowerBound])
    }

    private var canAdd: Bool {
        !situation.trimmingCharacters(in: .whitespaces).isEmpty && !action.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        BeatFrame(beat: beat, canContinue: !plans.isEmpty || canAdd, onContinue: finish) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                BeatPrompt(text: ctx.text(beat.prompt))
                ForEach(Array(plans.enumerated()), id: \.offset) { i, plan in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Plan \(i + 1)").dxType(.caption).foregroundStyle(DX.Ground.table.muted).foregroundStyle(DX.Ground.table.ink)
                            Text(verbatim: ProgramAnswerValue.plans([plan]).lines.first ?? "")
                                .dxFace(.body, 16, weight: 400).foregroundStyle(DX.Ground.table.ink)
                        }
                        Spacer()
                        Button { plans.remove(at: i) } label: {
                            DXIcon(.close, size: 12, weight: 2.6).foregroundStyle(DX.Ground.table.muted)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Remove plan \(i + 1)"))
                    }
                    .padding(DX.Space.m)
                    .background(DX.Ground.table.selTint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Plan \(plans.count + 1)").dxType(.caption).foregroundStyle(DX.Ground.table.muted)
                    Text("If").dxFace(.body, 14, weight: 600).foregroundStyle(DX.Ground.table.ink)
                    TextField("what happens", text: $situation)
                        .dxFace(.body, 16, weight: 500)
                        .padding(12)
                        .background(DX.Ground.table.card2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text("Then I will").dxFace(.body, 14, weight: 600).foregroundStyle(DX.Ground.table.ink)
                    DXFlowLayout(spacing: 8) {
                        ForEach(beat.suggestions ?? [], id: \.self) { suggestion in
                            BeatChip(text: suggestion, on: !typingOwn && action == suggestion) {
                                typingOwn = false
                                action = suggestion
                            }
                        }
                        BeatChip(text: String(localized: "Type my own"), on: typingOwn) {
                            typingOwn = true
                            action = ""
                        }
                    }
                    if typingOwn {
                        TextField("what you'll do", text: $action)
                            .dxFace(.body, 16, weight: 500)
                            .padding(12)
                            .background(DX.Ground.table.card2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(DX.Space.m)
                .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DX.Ground.table.line))
                Button(action: addPlan) {
                    HStack(spacing: 6) {
                        DXIcon(.plus, size: 16)
                        Text("Add another plan")
                    }.dxFace(.body, 16, weight: 600)
                        .foregroundStyle(DX.Ground.table.ink).frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .disabled(!canAdd)
            }
        }
        .onAppear {
            if case let .plans(saved)? = ctx.answer(beat.saveAs) { plans = saved }
            situation = promptSituation
        }
    }

    private func addPlan() {
        guard canAdd else { return }
        plans.append(.init(situation: situation.trimmingCharacters(in: .whitespaces), action: action.trimmingCharacters(in: .whitespaces)))
        situation = promptSituation
        action = ""
        typingOwn = false
    }

    private func finish() {
        addPlan()
        ctx.save(beat.saveAs, .plans(plans))
        ctx.finish(beat)
        onDone()
    }
}

// MARK: - checklist

/// Tap to tick. Continue is always on: what's left unticked isn't a failure, and carries over where a later list asks.
struct ChecklistBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var ticked: Set<String> = []

    private var items: [String] { beat.checklist?.resolve(ctx.variant) ?? [] }

    /// Items left unticked on the earlier list this one carries over from.
    private var carried: [String] {
        guard let key = beat.carryOverFrom,
              let source = ctx.store.content?.sessions.flatMap(\.everyBeat).first(where: { $0.saveAs == key }),
              let all = source.checklist?.resolve(ctx.variant) else { return [] }
        let done = Set(ctx.answer(key)?.lines ?? [])
        return all.filter { !done.contains($0) }
    }

    var body: some View {
        BeatFrame(beat: beat, onContinue: finish) {
            VStack(alignment: .leading, spacing: 10) {
                BeatPrompt(text: ctx.text(beat.title))
                if !carried.isEmpty {
                    Text("Still open from before").dxType(.caption).foregroundStyle(DX.Ground.table.muted)
                    ForEach(carried, id: \.self) { row($0) }
                    Text("Tonight").dxType(.caption).foregroundStyle(DX.Ground.table.muted).padding(.top, DX.Space.xs)
                } else {
                    Text("Tick what you've done. The rest can wait.").dxType(.footnote).foregroundStyle(DX.Ground.table.muted)
                }
                ForEach(items, id: \.self) { row($0) }
                if let footer = beat.footer.map({ ctx.text($0) }), !footer.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "battery.100.bolt").foregroundStyle(Color(light: 0x8A5E0E, dark: 0xE5A93C)).accessibilityHidden(true)
                        Text(verbatim: footer).dxFace(.body, 14, weight: 400).foregroundStyle(DX.Ground.table.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(DX.Space.s)
                    .background(Read4.amber.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .sensoryFeedback(DX.Haptic.select, trigger: ticked)
        .onAppear { ticked = Set(ctx.answer(beat.saveAs)?.lines ?? []) }
    }

    private func row(_ item: String) -> some View {
        let on = ticked.contains(item)
        return Button {
            if on { ticked.remove(item) } else { ticked.insert(item) }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(on ? .clear : DX.Ground.table.line, lineWidth: 1.5)
                    if on {
                        RoundedRectangle(cornerRadius: 8, style: .continuous).fill(DX.Ground.table.sel)
                        DXIcon(.check, size: 13, weight: 2.8).foregroundStyle(DX.Ground.table.selFg)
                    }
                }
                .frame(width: 26, height: 26)
                Text(verbatim: item).dxFace(.body, 16, weight: 500)
                    .foregroundStyle(on ? DX.Ground.table.muted : DX.Ground.table.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12).padding(.horizontal, DX.Space.m)
            .frame(minHeight: 56)
            .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DX.Ground.table.line))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? [.isSelected] : [])
        .accessibilityValue(Text(on ? "Done" : "Not done"))
    }

    private func finish() {
        // Everything ticked, carried items included, so a later carry-over sees them as done.
        ctx.save(beat.saveAs, .list((carried + items).filter { ticked.contains($0) }))
        if let key = beat.carryOverFrom {
            let previous = Set(ctx.answer(key)?.lines ?? [])
            ctx.save(key, .list(Array(previous.union(carried.filter { ticked.contains($0) })).sorted()))
        }
        ctx.finish(beat)
        onDone()
    }
}

// MARK: - breathe

/// The Bio-Orb for a set number of cycles, voice off: the session audio just played.
struct BreatheBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @AppStorage("dx.voiceGuidance") private var voiceOn = true
    @State private var savedVoice: Bool?

    /// The deck card this breath belongs to (P4's "A breath that works in the moment"), for its title.
    private var card: DeckCard? {
        ctx.session.deck?.first { card in card.beats.contains { $0.id == beat.id } || card.before.contains { $0.id == beat.id } }
    }

    var body: some View {
        if beat.pattern == "sigh" {
            TryBreathCard(title: card.map { ctx.text($0.title) } ?? ctx.text(beat.label), cycles: beat.cycles ?? 18) {
                ctx.finish(beat)
                onDone()
            }
        } else {
            VStack(spacing: DX.Space.s) {
                Text(verbatim: ctx.text(beat.label)).dxFace(.display, 19, weight: 600)
                    .foregroundStyle(DX.Ground.table.ink).multilineTextAlignment(.center)
                OrbBreathingPanel(pattern: beat.pattern ?? "box", cycles: beat.cycles) {
                    ctx.finish(beat)
                    onDone()
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                // A reading card with a hairline, no longer a black panel (S27.12).
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(DX.Ground.table.line))
            }
            .onAppear {
                savedVoice = voiceOn
                voiceOn = false
            }
            .onDisappear { if let savedVoice { voiceOn = savedVoice } }
        }
    }
}

/// The Try card (030): two sighs, guided. The breath's shape is drawn across the mint card and is its pacer: the ink
/// lights along it in time with each breath (in, a little more, the long slow out), with a playhead riding it. The
/// player shows the time, small Xero breathes beside it, three notes sit under the card, and the dock holds a quiet
/// skip that turns into "Next card" at 80%.
struct TryBreathCard: View {
    let title: String
    let cycles: Int
    let onDone: () -> Void

    /// Two in through the nose (2 s), a top-up sip (1 s), a long slow breath out (6 s).
    private static let phases: [(seconds: Double, end: Double)] = [(2, 0.3), (1, 0.42), (6, 1)]
    private static var cycle: Double { phases.reduce(0) { $0 + $1.seconds } }

    @State private var started: Date?
    @State private var pausedAt: Double = 0
    @State private var playing = false
    @State private var breaths = 0
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()

    private var total: Double { Double(cycles) * Self.cycle }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !playing)) { timeline in
            let elapsed = min(playing ? pausedAt + timeline.date.timeIntervalSince(started ?? timeline.date) : pausedAt, total)
            let within = elapsed.truncatingRemainder(dividingBy: Self.cycle)
            let lit = Self.curveFraction(within)
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 14) {
                        face(lit: lit, elapsed: elapsed)
                        notes
                    }
                    .padding(.bottom, DX.Space.m)
                    .padding(.horizontal, DX.Layout.gutter)
                }
                .padding(.horizontal, -DX.Layout.gutter)
                .scrollBounceBehavior(.basedOnSize)
                gate(open: elapsed >= total * 0.8)
                    .padding(.top, 8)
            }
            .onChange(of: Int(elapsed / Self.cycle)) { _, n in breaths = n }
            .onChange(of: elapsed >= total) { _, done in if done { playing = false } }
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: breaths)
        .task {
            try? await Task.sleep(for: .seconds(0.4))
            play()
        }
    }

    private func play() {
        started = .now
        playing = true
    }

    private func toggle() {
        if playing {
            pausedAt += Date.now.timeIntervalSince(started ?? .now)
            playing = false
        } else {
            play()
        }
    }

    /// Where the lit ink has reached along the curve for a moment within one breath.
    static func curveFraction(_ t: Double) -> Double {
        var start = 0.0, from = 0.0
        for phase in phases {
            if t < start + phase.seconds {
                let p = (t - start) / phase.seconds
                let eased = UnitCurve.easeInOut.value(at: p)
                return from + (phase.end - from) * eased
            }
            start += phase.seconds
            from = phase.end
        }
        return 1
    }

    private func face(lit: Double, elapsed: Double) -> some View {
        let dark = scheme == .dark
        let ink = dark ? DX.Fill.cream : DX.Fill.navy
        return VStack(alignment: .leading, spacing: 0) {
            BreathCurve(lit: lit, ink: ink)
                .frame(height: 150)
                .padding(.top, 10)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 14) {
                Text(verbatim: title).dxType(.title).foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: 12) {
                    Button(action: toggle) {
                        DXIcon(playing ? .pause : .play, size: 20, weight: 2.4, filled: !playing)
                            .foregroundStyle(dark ? DX.Fill.navy : DX.Fill.cream)
                            .frame(width: 44, height: 44)
                            .background(dark ? Color(hex: 0x9FE3BC) : DX.Fill.navy, in: Circle())
                    }
                    .buttonStyle(.dxPress)
                    .accessibilityLabel(Text(playing ? "Pause" : "Play"))
                    VStack(alignment: .leading, spacing: 1) {
                        (Text(verbatim: DeckListenView.clock(elapsed)).dxRun(15, weight: 700)
                         + Text(verbatim: " / \(DeckListenView.clock(total))"))
                            .monospacedDigit()
                        Text("Guided: two sighs")
                    }
                    .dxType(.footnote)
                    .foregroundStyle(ink)
                    Spacer()
                    XeroView(mood: .breathe, stage: 0, points: 52)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 20).padding(.top, 4)
        }
        .background {
            if dark {
                ZStack {
                    LinearGradient(colors: [Color(hex: 0x27325C), Color(hex: 0x19223F)], startPoint: .top, endPoint: .bottom)
                    RadialGradient(colors: [Color(hex: 0x9FE3BC).opacity(0.18), .clear], center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: 200)
                }
            } else {
                LinearGradient(colors: [Color(hex: 0xC8F1D9), Color(hex: 0x9FE3BC)], startPoint: .top, endPoint: .bottom)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: dark ? .black.opacity(0.45) : Color(red: 40 / 255, green: 70 / 255, blue: 50 / 255).opacity(0.14), radius: 15, y: 14)
        .dxSettle()
    }

    private var notes: some View {
        let rows: [(DX.Icon, LocalizedStringKey, LocalizedStringKey)] = [
            (.wave, "Why it works", "A long breath out slows your heart."),
            (.clock, "In a tense moment", "Two or three sighs take thirty seconds."),
            (.drop, "Feeling light-headed?", "Breathe normally for a moment, then rejoin."),
        ]
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        DXIcon(row.0, size: 16, weight: 2.4).foregroundStyle(Color(hex: 0x1E1A3A))
                            .frame(width: 28, height: 28)
                            .background(Color(hex: 0xC8F1D9), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text(row.1).dxFace(.display, 16, weight: 700).foregroundStyle(DX.Ground.table.ink)
                    }
                    Text(row.2).dxType(.footnote).foregroundStyle(DX.Ground.table.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) { if i > 0 { Rectangle().fill(DX.Ground.table.line).frame(height: 1) } }
                .dxArrive(3 + i)
            }
        }
        .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(DX.Ground.table.line, lineWidth: 1))
    }

    private func gate(open: Bool) -> some View {
        ZStack {
            Button(String(localized: "Skip to next card"), action: onDone)
                .dxFace(.body, 15, weight: 600)
                .foregroundStyle(DX.Ground.table.muted)
                .frame(maxWidth: .infinity, minHeight: 58)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .opacity(open ? 0 : 1)
                .allowsHitTesting(!open)
                .accessibilityHidden(open)
            Button(String(localized: "Next card"), action: onDone)
                .buttonStyle(.dx(.primary, on: .table))
                .opacity(open ? 1 : 0)
                .allowsHitTesting(open)
                .accessibilityHidden(!open)
        }
        .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.3), value: open)
        .sensoryFeedback(.impact(weight: .light), trigger: open) { _, now in now }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

/// The two-sighs breath as a shape (030): in and level, a top-up sip, then the long slow out. Drawn faint; the lit ink
/// runs along it to `lit`, each point lighting its label as the ink reaches it.
private struct BreathCurve: View {
    let lit: Double
    let ink: Color

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            let curve = BreathShape()
            ZStack(alignment: .topLeading) {
                curve.stroke(ink.opacity(0.18), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                curve.trim(from: 0, to: lit).stroke(ink, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                dot(at: BreathShape.point(0.3, w, h), on: lit >= 0.28, color: ink)
                dot(at: BreathShape.point(0.42, w, h), on: lit >= 0.4, color: DX.Fill.coral)
                dot(at: BreathShape.point(0.86, w, h), on: lit >= 0.84, color: ink)
                label("In", at: BreathShape.point(0.3, w, h), dy: -22, on: lit >= 0.28)
                label("A little more", at: BreathShape.point(0.42, w, h), dy: -22, on: lit >= 0.4)
                label("Long, slow out", at: BreathShape.point(0.86, w, h), dy: 22, on: lit >= 0.84)
            }
        }
        .padding(.horizontal, 22)
    }

    private func dot(at p: CGPoint, on: Bool, color: Color) -> some View {
        Circle().fill(on ? color : ink.opacity(0.25)).frame(width: 12, height: 12).position(p)
            .animation(.easeOut(duration: 0.25), value: on)
    }

    private func label(_ text: LocalizedStringKey, at p: CGPoint, dy: CGFloat, on: Bool) -> some View {
        Text(text).dxFace(.body, 13, weight: 700).foregroundStyle(ink)
            .fixedSize()
            .position(x: p.x, y: p.y + dy)
            .opacity(on ? 1 : 0.45)
            .animation(.easeOut(duration: 0.25), value: on)
    }
}

private struct BreathShape: Shape {
    /// The curve on a unit box: rise and level, a small sip up, the long fall.
    static func path(_ w: CGFloat, _ h: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: h * 0.85))
        p.addCurve(to: CGPoint(x: w * 0.24, y: h * 0.38), control1: CGPoint(x: w * 0.1, y: h * 0.85), control2: CGPoint(x: w * 0.14, y: h * 0.4))
        p.addLine(to: CGPoint(x: w * 0.34, y: h * 0.36))
        p.addCurve(to: CGPoint(x: w * 0.44, y: h * 0.18), control1: CGPoint(x: w * 0.38, y: h * 0.36), control2: CGPoint(x: w * 0.4, y: h * 0.18))
        p.addCurve(to: CGPoint(x: w, y: h * 0.86), control1: CGPoint(x: w * 0.62, y: h * 0.18), control2: CGPoint(x: w * 0.8, y: h * 0.82))
        return p
    }

    static func point(_ f: Double, _ w: CGFloat, _ h: CGFloat) -> CGPoint {
        path(w, h).trimmedPath(from: 0, to: max(f, 0.001)).currentPoint ?? .zero
    }

    func path(in rect: CGRect) -> Path { Self.path(rect.width, rect.height) }
}

// MARK: - commit

/// Press and hold: a ring fills over a few seconds with rising haptics; let go early and it drains back with no message.
/// VoiceOver gets a "Commit" action instead of holding. On replay it shows when it was done.
struct CommitBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    private let motion = MotionPolicy()
    @State private var doneAt: Date?
    @State private var settled = false

    /// One hold duration everywhere (S27.20); program.json's `holdSeconds` is no longer used for timing.
    private var seconds: Double { DX.Move.hold }
    /// DX.2 starts the counter: Q1, Xero at dawn on apricot (design doc §10.2). No celebration here.
    private var startsDayXero: Bool { beat.sets == "quit_timestamp" }

    var body: some View {
        if startsDayXero { dayXero } else { plain }
    }

    /// Any other commitment: the words, then the hold (v4 hold button with a linear fill).
    private var plain: some View {
        VStack(spacing: DX.Space.l) {
            Spacer()
            Text(verbatim: doneAt == nil ? ctx.text(beat.text) : String(localized: "Committed."))
                .dxType(.title)
                .multilineTextAlignment(.center)
                .foregroundStyle(DX.Ground.table.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let doneAt {
                Label {
                    Text("Done on \(doneAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
                } icon: {
                    DXIcon(.check, size: 20, weight: 2.6).foregroundStyle(DX.Ground.table.mark)
                }
                .dxType(.footnote).foregroundStyle(DX.Ground.table.muted)
            }
            Spacer()
            if doneAt == nil {
                HoldButton(String(localized: "Hold to commit"), done: String(localized: "Committed"),
                           duration: seconds, on: .reading, action: commit)
                    .accessibilityLabel(Text(verbatim: ctx.text(beat.text)))
                Text("Hold for 1 second").dxType(.footnote).foregroundStyle(DX.Ground.table.muted)
            } else {
                Button("Continue", action: onDone).buttonStyle(.dx(.primary, on: .reading))
            }
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: doneAt)
        .onAppear(perform: restore)
    }

    /// Q1 Day Xero: the dawn at Day 1's clarity, Xero 200 settling in, the date and session line, your reason,
    /// and a three-second hold that ends on "Day Xero started" and a checkmark.
    private var dayXero: some View {
        let ground = DX.Ground.apricot
        let session = ctx.session
        let reasons = ctx.store.profile.reasons.sorted { $0.createdAt < $1.createdAt }
        let reason = reasons.first { $0.photo == nil } ?? reasons.first
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ZStack(alignment: .bottom) {
                        HorizonScene(.dawn, clarity: CrewGrowth.clarity(daysClear: 1), fit: .bottom)
                        XeroView(mood: doneAt == nil ? .hello : .cheer, stage: 1, size: .hero)
                            .offset(y: settled || motion.reduce ? -2 : 40)
                            .opacity(settled ? 1 : 0)
                    }
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
                    .accessibilityHidden(true)
                    Text(verbatim: "\(Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))) · \(String(localized: "Quit Day")) · \(ctx.store.minutes(of: session)) \(String(localized: "min"))")
                        .dxType(.caption).foregroundStyle(ground.muted)
                        .padding(.top, DX.Space.xs)
                    Text(verbatim: session.title.resolve(ctx.variant) ?? "").dxType(.large).foregroundStyle(ground.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: [session.subtitle.resolve(ctx.variant), session.listenHint?.resolve(ctx.variant)]
                        .compactMap { $0 }.map { $0.hasSuffix(".") ? $0 : $0 + "." }.joined(separator: " "))
                        .dxType(.body).foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if let reason {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BECAUSE").dxType(.caption).foregroundStyle(ground.muted)
                            Text(verbatim: reason.text).dxFace(.display, 19, weight: 700).foregroundStyle(ground.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 6) {
                if doneAt == nil {
                    HoldButton(String(localized: "Hold to start Day Xero"), done: String(localized: "Day Xero started"),
                               duration: seconds, on: ground, action: commit)
                        .accessibilityLabel(Text("Start Day Xero. Hold for one second, or double-tap with VoiceOver."))
                } else {
                    Label("Day Xero started", systemImage: "checkmark.circle.fill")
                        .dxFace(.body, 16, weight: 700).foregroundStyle(ground.ink)
                        .frame(minHeight: 44)
                    Button("Continue", action: onDone).buttonStyle(.dx(.primary, on: ground))
                }
            }
            .padding(.top, DX.Space.xs)
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: doneAt)
        .onAppear {
            restore()
            withAnimation(motion.animation(DX.Move.settle)) { settled = true }
        }
    }

    private func restore() {
        if case let .date(date)? = ctx.recorded(beat) { doneAt = date }
        else if let key = beat.sets, case let .date(date)? = ctx.answer(key) { doneAt = date }
    }

    private func commit() {
        guard doneAt == nil else { return }
        let now = Date.now
        doneAt = now
        guard !ctx.isReplay else { return }
        if let key = beat.sets { ctx.store.commit(key, at: now) }
        if beat.sets == "graduated_at", let quit = ctx.store.profile.progress?.quitTimestamp {
            Analytics.track(.programGraduated(daysSinceQuit: ctx.store.clock.calendar.dateComponents([.day], from: quit, to: now).day ?? 0))
        }
        ctx.finish(beat, value: .date(now))
    }
}

// MARK: - scenario

/// Every option is valid: the pick stays highlighted and its own feedback shows. Nothing is marked right.
struct ScenarioBeat: View {
    private let motion = MotionPolicy()
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var picked: String?

    private var options: [Beat.Option] { beat.options?.resolve(ctx.variant) ?? [] }

    var body: some View {
        BeatFrame(beat: beat, canContinue: picked != nil, onContinue: {
            ctx.finish(beat, value: picked.map { .text($0) })
            onDone()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                BeatPrompt(text: ctx.text(beat.prompt), eyebrow: "Picture it")
                ForEach(options) { option in
                    Button { withAnimation(motion.animation(DX.Move.settle)) { picked = option.id } } label: {
                        OptionRow(text: option.text, selected: picked == option.id, dimmed: picked != nil && picked != option.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(picked == option.id ? .isSelected : [])
                }
                if let feedback = options.first(where: { $0.id == picked })?.feedback {
                    BeatFeedback(text: feedback).padding(.top, DX.Space.xs).id(picked)
                }
            }
        }
        .sensoryFeedback(DX.Haptic.select, trigger: picked)
        .onAppear { if case let .text(id)? = ctx.recorded(beat) { picked = id } }
    }
}

// MARK: - note

/// A saved answer as a quiet card; the highlighted item first and emphasised.
struct NoteBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    private var lines: (highlight: String?, rest: [String]) {
        let all = ctx.answer(beat.textFrom)?.lines ?? []
        guard let key = beat.highlightFrom, case let .text(top)? = ctx.answer(key), !top.isEmpty else { return (nil, all) }
        return (top, all.filter { $0 != top })
    }

    var body: some View {
        BeatFrame(beat: beat, onContinue: { ctx.finish(beat); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                Spacer(minLength: DX.Space.xl)
                Text(verbatim: ctx.text(beat.title)).dxType(.caption).foregroundStyle(DX.Ground.table.muted)
                VStack(alignment: .leading, spacing: DX.Space.m) {
                    if let top = lines.highlight {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Matters most").dxType(.caption).foregroundStyle(DX.Ground.table.muted).foregroundStyle(DX.Ground.table.ink)
                            Text(verbatim: top).dxFace(.display, 24, weight: 700)
                                .foregroundStyle(DX.Ground.table.ink)
                        }
                        if !lines.rest.isEmpty { Divider() }
                    }
                    ForEach(lines.rest, id: \.self) { line in
                        Text(verbatim: line).dxFace(.body, 16, weight: 400).foregroundStyle(DX.Ground.table.ink)
                    }
                }
                .padding(DX.Space.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(beat.id.hasPrefix("DX") ? DX.Ground.table.selTint : DX.Ground.table.card,
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(DX.Ground.table.line))
            }
        }
    }
}

// MARK: - info

struct InfoBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    var body: some View {
        BeatFrame(beat: beat, onContinue: { ctx.finish(beat); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                Spacer(minLength: DX.Space.xl)
                VStack(alignment: .leading, spacing: DX.Space.s) {
                    DXIcon(.heart, size: 30).foregroundStyle(DX.Ground.table.mark).accessibilityHidden(true)
                    Text(verbatim: ctx.text(beat.title)).dxFace(.display, 24, weight: 700)
                        .foregroundStyle(DX.Ground.table.ink).accessibilityAddTraits(.isHeader)
                    Text(verbatim: ctx.text(beat.body)).dxFace(.body, 16, weight: 400)
                        .foregroundStyle(DX.Ground.table.ink).fixedSize(horizontal: false, vertical: true)
                    if beat.link == "helplines" { HelpLine() }
                }
                .padding(DX.Space.l)
                .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(DX.Ground.table.line))
            }
        }
    }
}

// MARK: - share

/// Always optional. A support message opens the share sheet with editable text; milestone cards are images with
/// nothing personal on them unless switched on.
struct ShareBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var message = ""
    @State private var quote: String?

    private var days: Int {
        switch beat.cardType {
        case "milestone_7": 7
        case "milestone_14": 14
        case "milestone_21": 21
        default: 30
        }
    }

    /// Sentences from the saved letter, for the graduation card's optional quote.
    private var sentences: [String] {
        guard let key = beat.quoteFrom else { return [] }
        let text = ctx.answer(key)?.lines.joined(separator: " ") ?? ""
        return text.split(whereSeparator: { ".!?".contains($0) }).map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.count > 3 }
    }

    private var card: Image? {
        let renderer = ImageRenderer(content: ShareCard(days: days, lines: quote.map { ["“\($0).”"] } ?? [])
            .frame(width: ShareCard.size.width, height: ShareCard.size.height)
            .environment(\.colorScheme, .light))
        renderer.scale = 1080 / ShareCard.size.width
        return renderer.uiImage.map(Image.init(uiImage:))
    }

    var body: some View {
        BeatFrame(beat: beat, canContinue: true, continueTitle: "Done", onContinue: { ctx.finish(beat); onDone() },
                  onSkip: { ctx.finish(beat, skipped: true); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                if beat.cardType == "support_message" {
                    BeatPrompt(text: String(localized: "Give someone a heads-up?"))
                    Text("A message from a friend helps more than you'd think. Change it however you like.").dxType(.footnote).foregroundStyle(DX.Ground.table.muted)
                    TextField("", text: $message, axis: .vertical)
                        .lineLimit(4...8)
                        .dxFace(.body, 16, weight: 400)
                        .padding(DX.Space.m)
                        .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(DX.Ground.table.selEdge, lineWidth: 1.5))
                    ShareLink(item: message) {
                        HStack(spacing: 8) {
                            DXIcon(.share, size: 18)
                            Text("Send it")
                        }.frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.dx(.ghost, on: .table))
                } else {
                    BeatPrompt(text: String(localized: "Share it, if you like"))
                    if let card {
                        card.resizable().scaledToFit().frame(maxWidth: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(Text("Share card: \(days) days into my quit"))
                        if !sentences.isEmpty {
                            Text("Add a line from your note").dxType(.caption).foregroundStyle(DX.Ground.table.muted).padding(.top, DX.Space.xs)
                            ForEach(sentences.prefix(4), id: \.self) { sentence in
                                BeatChip(text: sentence, on: quote == sentence) { quote = quote == sentence ? nil : sentence }
                            }
                        }
                        ShareLink(item: card, preview: SharePreview(Text("DayXero"), image: card)) {
                            HStack(spacing: 8) {
                                DXIcon(.share, size: 18)
                                Text("Share")
                            }.frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.dx(.ghost, on: .table))
                    }
                }
            }
        }
        .onAppear { message = ctx.text(beat.prefill) }
    }
}

// MARK: - nrt_choice

/// Option cards with the safety text always showing. "Set it up" and "Step down first" open the co-pilot and come back here.
struct NRTChoiceBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var picked: String?
    @State private var showSetup = false
    @State private var showTaper = false

    private var options: [Beat.Option] { beat.options?.resolve(ctx.variant) ?? [] }

    var body: some View {
        BeatFrame(beat: beat, canContinue: picked != nil, onContinue: finish) {
            VStack(alignment: .leading, spacing: 10) {
                BeatPrompt(text: String(localized: "Want nicotine replacement for the first weeks?"))
                ForEach(options) { option in
                    Button { pick(option.id) } label: {
                        OptionRow(text: option.text, selected: picked == option.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(picked == option.id ? .isSelected : [])
                }
                SafetyNote(text: ctx.text(beat.safetyText)).padding(.top, DX.Space.xs)
            }
        }
        .fullScreenCover(isPresented: $showSetup) { NRTSetupView(profile: ctx.store.profile) { showSetup = false } }
        .fullScreenCover(isPresented: $showTaper) { TaperSetupView(profile: ctx.store.profile) { showTaper = false } }
        .onAppear { if case let .text(id)? = ctx.answer(beat.saveAs) { picked = id } }
    }

    private func pick(_ id: String) {
        picked = id
        if id == "setup" { showSetup = true }
        if id == "taper" { showTaper = true }
    }

    private func finish() {
        if let picked { ctx.save(beat.saveAs, .text(picked)) }
        ctx.finish(beat)
        onDone()
    }
}

struct SafetyNote: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle").foregroundStyle(DX.Ground.table.muted).accessibilityHidden(true)
            Text(verbatim: text).dxFace(.body, 14, weight: 400).foregroundStyle(DX.Ground.table.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Ground.table.card2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - nrt_stepdown

/// Shown only with an active NRT plan. Opens the co-pilot, which plans the label's step-down and sets reminders.
struct NRTStepdownBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var showPlanner = false

    var body: some View {
        BeatFrame(beat: beat, onContinue: { ctx.finish(beat); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                BeatPrompt(text: ctx.text(beat.title))
                Text(verbatim: ctx.text(beat.body)).dxType(.footnote).foregroundStyle(DX.Ground.table.muted)
                Button { showPlanner = true } label: {
                    HStack(spacing: 8) {
                        DXIcon(.calendar, size: 18)
                        Text("Plan my step-down")
                    }.frame(maxWidth: .infinity)
                }
                .buttonStyle(.dx(.ghost, on: .table))
                SafetyNote(text: ctx.text(beat.safetyText))
            }
        }
        .fullScreenCover(isPresented: $showPlanner) { NRTSetupView(profile: ctx.store.profile) { showPlanner = false } }
    }
}

// MARK: - slip_debrief_practice

/// Runs the real slip debrief in practice mode: the same questions, a "Practice" tag, nothing logged.
struct SlipPracticeBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var practising = false
    @State private var practised = false

    var body: some View {
        BeatFrame(beat: beat, canContinue: practised || ctx.isReplay, onContinue: { ctx.finish(beat); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.m) {
                Spacer(minLength: DX.Space.xl)
                BeatPrompt(text: ctx.text(practised ? beat.outro : beat.intro))
                if !practised {
                    Button { practising = true } label: {
                        Label("Start the practice", systemImage: "figure.walk.motion").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.dx(.ghost, on: .table))
                    Text("Nothing here is logged as a slip.").dxType(.footnote).foregroundStyle(DX.Ground.table.muted)
                }
            }
        }
        .fullScreenCover(isPresented: $practising) {
            SlipFlow(entry: nil, profile: ctx.store.profile, practice: true) {
                practising = false
                practised = true
            }
        }
    }
}

// MARK: - plan_card

/// One tall card with each saved part of the plan, editable in place. Private by default; can be saved as an image.
struct PlanCardBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var editing: String?
    @State private var draft = ""
    @State private var refresh = 0

    static func heading(_ key: String) -> String {
        switch key {
        case "identity_statement": String(localized: "Who I am now")
        case "primary_reason": String(localized: "Why I'm doing this")
        case "no_line": String(localized: "My no-line")
        case "rough_day_plan": String(localized: "On a rough day")
        case "heavy_day_plan": String(localized: "If something big goes wrong")
        case "bad_day_line": String(localized: "My hard-day line")
        case "break_menu": String(localized: "My breaks")
        case "wind_down": String(localized: "My wind-down")
        // Program v3 plan cards (P4, P6).
        case "stress_triggers": String(localized: "What stresses me")
        case "stress_plan_1": String(localized: "When the first one hits")
        case "stress_plan_2": String(localized: "When the second one hits")
        case "stress_signals": String(localized: "My early signs")
        case "trigger_plans": String(localized: "My if-then plans")
        case "support_person": String(localized: "Who's in my corner")
        case "urge_signals": String(localized: "Where I feel a craving")
        case "autopilot_triggers": String(localized: "My autopilot moments")
        case "autopilot_map": String(localized: "When, where and how it feels")
        case "morning_anchor": String(localized: "My morning moment")
        case "morning_wait_minutes": String(localized: "How long I'll wait")
        case "morning_wait_plan": String(localized: "What I'll do while I wait")
        case "note_to_dayxero": String(localized: "My note for Day Xero")
        case "dx_first_trigger": String(localized: "My first trigger tomorrow")
        case "dx_first_hour_plan": String(localized: "My first hour")
        case "dx_today_trigger": String(localized: "Today's biggest trigger")
        case "dx_today_plan": String(localized: "When it comes, I'll")
        case "dx_told_someone": String(localized: "Who I told")
        case "dx_basics": String(localized: "The basics")
        case "dx_nrt_check": String(localized: "My NRT today")
        case "dx_nrt_ready": String(localized: "NRT ready")
        default: key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    /// Who I am first, then the rest in the file's order; empty ones hidden.
    private var rows: [(key: String, lines: [String])] {
        _ = refresh
        let keys = (beat.fields ?? []).sorted { a, _ in a == "identity_statement" }
        return keys.compactMap { key in
            let lines = ctx.answer(key)?.lines ?? []
            return lines.isEmpty ? nil : (key, lines)
        }
    }

    private var image: Image? {
        let card = PlanCardImage(rows: rows.map { (Self.heading($0.key), $0.lines) })
        let renderer = ImageRenderer(content: card.frame(width: 1080))
        renderer.scale = 1
        return renderer.uiImage.map(Image.init(uiImage:))
    }

    var body: some View {
        BeatFrame(beat: beat, onContinue: { ctx.finish(beat); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                // v5 (029): the promise, each part of the plan on its own card, and the Day Xero medal it leads to.
                BeatPrompt(text: ctx.text(beat.title))
                Text("A promise to yourself, with a plan behind it.")
                    .dxType(.footnote).foregroundStyle(DX.Ground.table.muted)
                    .padding(.top, -14)
                    .dxArrive(2)
                VStack(spacing: 8) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                        HStack(alignment: .center, spacing: 12) {
                            DXIcon(.sparkle, size: 16, weight: 2.6).foregroundStyle(Color(hex: 0x1E1A3A))
                                .frame(width: 34, height: 34)
                                .background(Color(hex: 0xB8EBCD), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: Self.heading(row.key)).dxType(.caption).foregroundStyle(DX.Ground.table.muted)
                                ForEach(row.lines, id: \.self) { line in
                                    Text(verbatim: line)
                                        .dxFace(.display, 17, weight: 700)
                                        .foregroundStyle(DX.Ground.table.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer(minLength: 0)
                            if beat.editable, isEditable(row.key) {
                                Button { startEditing(row.key) } label: {
                                    DXIcon(.note, size: 18).foregroundStyle(DX.Ground.table.muted).frame(width: 44, height: 44)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text("Edit \(Self.heading(row.key))"))
                            }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DX.Ground.table.line, lineWidth: 1))
                        .accessibilityElement(children: .combine)
                        .dxArrive(3 + i)
                    }
                }
                medal.padding(.top, 10)
                if let image {
                    ShareLink(item: image, preview: SharePreview(Text("My plan"), image: image)) {
                        HStack(spacing: 6) {
                            DXIcon(.share, size: 16, weight: 2.4)
                            Text("Save to Photos or share")
                        }
                        .dxFace(.body, 15, weight: 600)
                        .foregroundStyle(DX.Ground.table.ink.opacity(0.85))
                        .frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: Binding(get: { editing.map(EditKey.init) }, set: { editing = $0?.key })) { item in
            NavigationStack {
                Form {
                    TextField(Self.heading(item.key), text: $draft, axis: .vertical).lineLimit(2...8)
                    if case .list? = ctx.answer(item.key) { Text("One per line.").dxType(.footnote).foregroundStyle(DX.Ground.table.muted) }
                }
                .navigationTitle(Self.heading(item.key))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { editing = nil } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { saveEdit(item.key) } }
                }
            }
            .presentationDetents([.medium])
        }
    }

    struct EditKey: Identifiable {
        let key: String
        var id: String { key }
    }

    /// The Day Xero medal on its gold, with the date and the days to it (029). Shown before the Quit Day.
    @ViewBuilder private var medal: some View {
        let profile = ctx.store.profile
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let days = clock.calendar.dateComponents([.day], from: clock.day(containing: .now), to: clock.startOfDate(profile.quitDay)).day ?? 0
        if days > 0 {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [Color(hex: 0xFFE9A8), Color(hex: 0xF5B83D)], center: .center, startRadius: 0, endRadius: 100))
                        .frame(width: 196, height: 196)
                    Circle().strokeBorder(Color(hex: 0xF5B83D), lineWidth: 4).frame(width: 196, height: 196)
                    Circle().fill(Color(hex: 0xFFF4DE)).frame(width: 150, height: 150)
                    XeroMarkBadge()
                }
                .dxPop(0, delay: 0.5)
                Text(verbatim: profile.quitDay.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .dxFace(.display, 20, weight: 700).foregroundStyle(DX.Ground.table.ink)
                Text(verbatim: String(AttributedString(localized: "^[\(days) day](inflect: true) to Day Xero").characters))
                    .dxType(.footnote).foregroundStyle(DX.Ground.table.muted)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }

    private func isEditable(_ key: String) -> Bool {
        switch ctx.answer(key) {
        case .text?, .list?: true
        default: false
        }
    }

    private func startEditing(_ key: String) {
        draft = ctx.answer(key)?.lines.joined(separator: "\n") ?? ""
        editing = key
    }

    private func saveEdit(_ key: String) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        switch ctx.answer(key) {
        case .list?: ctx.save(key, .list(text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }))
        default: ctx.save(key, .text(text))
        }
        editing = nil
        refresh += 1
    }
}

/// The plan card as an image, for Photos. Nothing on it but the plan and the wordmark.
struct PlanCardImage: View {
    let rows: [(String, [String])]

    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            Text(verbatim: "DayXero · My plan").dxFace(.display, 44, weight: 800).foregroundStyle(Color(hex: 0xFFC38A))
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: 10) {
                    Text(verbatim: row.0).dxFace(.display, 26, weight: 700).tracking(2)
                        .foregroundStyle(Color(hex: 0xFFC38A))
                    ForEach(row.1, id: \.self) { line in
                        Text(verbatim: line).dxFace(.display, 40, weight: 500).foregroundStyle(DX.Fill.cream)
                    }
                }
            }
        }
        .padding(80)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Fill.navy)
    }
}

/// Day Xero's mark (the kit's Xero coin face) for the commitment medal.
private struct XeroMarkBadge: View {
    var body: some View {
        DXBadge(.xero, size: 140)
    }
}
