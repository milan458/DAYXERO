import DayXeroCore
import SwiftData
import SwiftUI

/// The calm tools list (S12.1, S12.3), opened from the Program tab and from Craving SOS.
struct CalmToolsView: View {
    let onClose: () -> Void
    /// From Craving SOS: offer to go back to the session rather than start a new one.
    var fromSOS = false
    /// Starts Craving SOS from "Still craving?". Passed in, since this can be presented above the app's environment.
    var startSOS: (() -> Void)?
    @State private var open: CalmTool?

    init(onClose: @escaping () -> Void, fromSOS: Bool = false, startSOS: (() -> Void)? = nil) {
        self.onClose = onClose
        self.fromSOS = fromSOS
        self.startSOS = startSOS
        #if DEBUG
        _open = State(initialValue: UserDefaults.standard.string(forKey: "dx.openCalm").flatMap(CalmTool.init(rawValue:)))
        #endif
    }

    private let ground = DX.Ground.periwinkle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                CalmHeaderArt()
                    .frame(maxWidth: .infinity)
                    .padding(.top, DX.Space.xs)
                // A plain title: the hand-drawn mark is kept for Today's greeting, milestones, the finale and onboarding (S27.15).
                Text("Calm tools")
                    .dxType(.large).foregroundStyle(ground.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Short things to do instead of reaching for nicotine.").dxType(.body).foregroundStyle(ground.muted)
                    .padding(.bottom, DX.Space.xs)
                ForEach(CalmTool.allCases) { tool in
                    Button { open = tool } label: { CalmToolRow(tool: tool) }.buttonStyle(.plain)
                }
                HelpLine(compact: true, ground: ground).padding(.top, DX.Space.s)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DX.Space.m)
            .dxReadableColumn()
            .padding(.bottom, DX.Space.l)
        }
        .scrollBounceBehavior(.basedOnSize)
        .overlay(alignment: .topLeading) {
            Button(action: onClose) { Image(systemName: "xmark") }
                .buttonStyle(.v4Icon).accessibilityLabel(Text("Close"))
                .padding(.leading, DX.Space.m).padding(.top, DX.Space.s)
        }
        .background(ground.background.ignoresSafeArea())
        .fullScreenCover(item: $open) { tool in
            CalmToolPlayer(tool: tool, fromSOS: fromSOS) { backToSOS in
                open = nil
                if backToSOS {
                    onClose()
                    if !fromSOS { startSOS?() }
                }
            }
        }
    }
}

/// The calm tools header: Glim breathing on a cloud, a dotted halo breathing on the 4 in, 6 out clock. Glim replaced the
/// person figure so the app has one illustration language, the crew (S27.15).
struct CalmHeaderArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breath = reduceMotion ? 0.5 : DX.Move.breath(at: t)
            ZStack {
                Circle()
                    .strokeBorder(DX.Fill.cream, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [2, 7]))
                    .frame(width: 104 + 20 * breath, height: 104 + 20 * breath)
                    .offset(y: -18)
                CalmCloud()
                    .fill(DX.Fill.cream)
                    .frame(width: 168, height: 56)
                    .offset(y: 56)
                GlimView(mood: .breathe, stage: 1, points: 104, animate: !reduceMotion)
                    .offset(y: 0)
            }
            .frame(width: 240, height: 196)
        }
        .accessibilityHidden(true)
    }
}

/// The cloud Glim rests on, from the canvas.
private struct CalmCloud: Shape {
    func path(in rect: CGRect) -> Path {
        SVGPath.path("M16 52 C4 52 0 34 14 30 C14 14 34 8 44 18 C50 2 76 0 84 16 C92 4 118 4 124 20 C136 12 156 18 154 34 C168 34 170 52 156 52 Z")
            .applying(CGAffineTransform(translationX: rect.minX, y: rect.minY).scaledBy(x: rect.width / 170, y: rect.height / 56))
    }
}

struct CalmToolRow: View {
    let tool: CalmTool
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: DX.Space.xs))
            : AnyLayout(HStackLayout(spacing: 14))
        layout {
            KitArt(CalmToolRow.art(tool), cornerRadius: 18)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 2) {
                Text(tool.title).dxFont(16, weight: 700, style: .body).foregroundStyle(DX.Ground.reading.ink)
                Text(tool.detail).dxType(.footnote).foregroundStyle(DX.Ground.reading.muted).multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if !typeSize.isAccessibilitySize {
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(DX.Ground.reading.ink)
                    .accessibilityHidden(true)
            }
        }
        .padding(8)
        .padding(.trailing, 8)
        .background(Color(light: 0xFFF8EE, dark: 0x221A52), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text("\(tool.minutes) min"))
    }

    /// Each tool's moving illustration (decision 31).
    static func art(_ tool: CalmTool) -> KitArt.Kind {
        switch tool {
        case .boxBreathing: .box
        case .longerOutBreath: .outbreath
        case .grounding: .grounding
        case .noticeAndName: .tag
        case .dropAnchor: .anchor
        }
    }
}

/// The plain line pointing to professional help (S12.3). No diagnosis, no clinical claims.
/// Compact on the calm tools list (decision 31); in full where a lesson or the evening needs it.
struct HelpLine: View {
    static let directory = URL(string: "https://findahelpline.com")!
    var compact = false
    var ground: DX.Ground = .reading
    @Environment(\.openURL) private var openURL

    var body: some View {
        if compact {
            Text("Feeling like too much? In a crisis, call your local emergency number. \(Text("Find a helpline").bold().underline())")
                .dxFont(12, weight: 400, style: .caption1).foregroundStyle(ground.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { openURL(Self.directory) }
                .accessibilityAddTraits(.isLink)
                .accessibilityHint(Text("Opens a helpline directory"))
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("If stress or anxiety is getting in the way of everyday life, talk to a doctor or a mental health professional. In a crisis, call your local emergency number.")
                    .v4Text(.subtitle)
                Link(destination: Self.directory) {
                    Text("Find a helpline near you").dxFont(14, weight: 400, style: .footnote).underline().foregroundStyle(Read4.accent)
                }
                .frame(minHeight: DX.Layout.touchTarget, alignment: .leading)
                .contentShape(Rectangle())
            }
            .padding(DX.Space.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Read4.faint, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
        }
    }
}

/// Runs one calm tool, then a light "a bit calmer?" close (S12.1).
struct CalmToolPlayer: View {
    let tool: CalmTool
    var fromSOS = false
    /// true when the person chose to go back to (or start) Craving SOS.
    let onDone: (Bool) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startedAt = Date.now
    @State private var finished = false
    @State private var step = 0
    @State private var ticked = 0
    @State private var thought: String?
    @State private var ownThought = ""
    @State private var writingOwn = false
    @State private var use: ToolUse?
    @State private var answered: Bool?

    init(tool: CalmTool, fromSOS: Bool = false, onDone: @escaping (Bool) -> Void) {
        self.tool = tool
        self.fromSOS = fromSOS
        self.onDone = onDone
        #if DEBUG
        let d = UserDefaults.standard
        _finished = State(initialValue: d.bool(forKey: "dx.calmDone"))
        _startedAt = State(initialValue: Date.now.addingTimeInterval(-d.double(forKey: "dx.calmElapsed")))
        _step = State(initialValue: d.integer(forKey: "dx.calmStep"))
        _ticked = State(initialValue: d.integer(forKey: "dx.calmTicked"))
        if tool == .noticeAndName, d.integer(forKey: "dx.calmStep") > 0 { _thought = State(initialValue: String(localized: NoticeAndName.thoughts[0])) }
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            if finished { done } else { running }
        }
        .padding(.horizontal, DX.Space.m)
        .dxReadableColumn()
        .padding(.bottom, DX.Space.xs)
        .background(Read4.background.ignoresSafeArea())
        .onAppear {
            let record = ToolUse(tool: tool.rawValue, startedAt: startedAt)
            context.insert(record)
            try? context.save()
            use = record
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: finished)
        .sensoryFeedback(DX.Haptic.select, trigger: ticked)
    }

    // MARK: Running

    @ViewBuilder
    private var running: some View {
        topBar
        switch tool {
        case .boxBreathing, .longerOutBreath:
            OrbBreathingPanel(pattern: tool.orbPattern ?? "box") { finish(early: false) }
        case .grounding: grounding
        case .noticeAndName: notice
        case .dropAnchor: anchor
        }
    }

    private var topBar: some View {
        VStack(spacing: DX.Space.s) {
            if let total = steps {
                HStack(spacing: 4) {
                    ForEach(0..<total, id: \.self) { i in
                        Capsule().fill(i <= step ? Read4.ink : Read4.track).frame(height: 4)
                    }
                }
                .accessibilityHidden(true)
            }
            HStack {
                Button { finish(early: true) } label: { Image(systemName: "xmark") }
                    .buttonStyle(.v4Icon).accessibilityLabel(Text("Stop"))
                Spacer()
                Text(tool.title).v4Text(.micro)
                Spacer()
                Color.clear.frame(width: 44, height: 1)
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .padding(.top, DX.Space.s)
    }

    private var steps: Int? {
        switch tool {
        case .grounding: Grounding.steps.count
        case .noticeAndName: 3
        case .dropAnchor: DropAnchor.steps.count
        case .boxBreathing, .longerOutBreath: nil
        }
    }

    private var grounding: some View {
        let current = Grounding.steps[min(step, Grounding.steps.count - 1)]
        return VStack(alignment: .leading, spacing: DX.Space.s) {
            Text(verbatim: "\(current.count)").dxFont(40, weight: 700, style: .largeTitle)
                .foregroundStyle(Read4.accent).padding(.top, DX.Space.l)
            Text(current.sense).v4Text(.title)
            Text(current.hint).v4Text(.subtitle)
            DXFlowLayout(spacing: DX.Space.xs) {
                ForEach(0..<current.count, id: \.self) { i in
                    Button { ticked = max(ticked, i + 1) } label: {
                        Image(systemName: "checkmark").font(.system(size: 15, weight: .bold))
                            .foregroundStyle(i < ticked ? DX.Fill.cream : .clear)
                            .frame(width: 44, height: 44)
                            .background(i < ticked ? Read4.accent : .clear, in: Circle())
                            .overlay(Circle().strokeBorder(i < ticked ? .clear : Read4.faint, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Found \(i + 1)"))
                }
            }
            .padding(.top, DX.Space.xs)
            // The button sits right under the content, not pinned to the bottom (S27.14).
            Button(step + 1 < Grounding.steps.count ? "Next: \(Grounding.steps[step + 1].count) \(String(localized: Grounding.steps[step + 1].sense))" : "Done") {
                ticked = 0
                if step + 1 < Grounding.steps.count { step += 1 } else { finish(early: false) }
            }
            .buttonStyle(.dx(.primary, on: .reading))
            .padding(.top, DX.Space.s)
            Spacer(minLength: 0)
        }
    }

    private var notice: some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            switch step {
            case 0:
                Text("What's your mind telling you?").v4Text(.title).padding(.top, DX.Space.l)
                Text("Pick the closest, or write your own.").v4Text(.subtitle)
                DXFlowLayout {
                    ForEach(NoticeAndName.thoughts.map { String(localized: $0) }, id: \.self) { t in
                        V4ToggleChip(LocalizedStringKey(t), isOn: Binding(get: { !writingOwn && thought == t }, set: { if $0 { thought = t; writingOwn = false } }))
                    }
                    V4ToggleChip("write my own", isOn: $writingOwn)
                }
                if writingOwn { V4TextField("The thought", prompt: "I'll never manage", text: $ownThought) }
                Button("Next") { step = 1 }.buttonStyle(.dx(.primary, on: .reading)).disabled(chosenThought == nil)
                    .dxDisabledReason("Pick a thought, or write your own.", shown: chosenThought == nil)
                    .padding(.top, DX.Space.s)
                Spacer(minLength: 0)
            case 1:
                VStack(alignment: .leading, spacing: 6) {
                    Text("Say it this way").v4Text(.micro)
                    Text("I'm noticing I'm having the thought \(Text(verbatim: "“\(chosenThought ?? "")”").foregroundStyle(Read4.accent))")
                        .dxFont(24, weight: 600, style: .title2).foregroundStyle(Read4.ink)
                }
                .padding(DX.Space.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Read4.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Read4.hairline))
                .padding(.top, DX.Space.l)
                Text("It's a thought, not an order. You can let it sit there while you get on with your day.").v4Text(.subtitle)
                Button("Next") { step = 2 }.buttonStyle(.dx(.primary, on: .reading))
                    .padding(.top, DX.Space.s)
                Spacer(minLength: 0)
            default:
                timedBreaths
                    .padding(.top, DX.Space.l)
                Button("Done") { finish(early: false) }.buttonStyle(.dx(.primary, on: .reading))
                    .padding(.top, DX.Space.s)
                Spacer(minLength: 0)
            }
        }
    }

    /// Three slow breaths with the thought, then done.
    private var timedBreaths: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 30)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startedAt)
            let breath = CravingWave.breath(at: elapsed)
            VStack(spacing: DX.Space.s) {
                Circle()
                    .fill(RadialGradient(colors: [Read4.accent.opacity(0.6), Read4.accent.opacity(0.2), .clear],
                                         center: .center, startRadius: 0, endRadius: 90))
                    .scaleEffect(reduceMotion ? 0.86 : 0.7 + 0.3 * breath.scale)
                    .overlay(Text("\(NoticeAndName.breaths) breaths").dxFont(19, weight: 600, style: .title3)
                        .foregroundStyle(Read4.ink))
                    .frame(width: 180, height: 180)
                Text(breath.phase == .breatheIn ? "Breathe in" : "Breathe out").v4Text(.subtitle)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var anchor: some View {
        let current = DropAnchor.steps[min(step, DropAnchor.steps.count - 1)]
        return VStack(alignment: .leading, spacing: DX.Space.s) {
            Image(systemName: "figure.stand").font(.system(size: 36)).foregroundStyle(Read4.accent)
                .frame(width: DX.CharacterSize.card.rawValue, height: DX.CharacterSize.card.rawValue)
                .background(Read4.accentSoft, in: Circle())
                .padding(.top, DX.Space.l)
                .accessibilityHidden(true)
            Text(current.title).v4Text(.title)
            Text(current.body).dxFont(16, weight: 400, style: .body).foregroundStyle(Read4.muted)
            Button(step + 1 < DropAnchor.steps.count ? "Next" : "Done") {
                if step + 1 < DropAnchor.steps.count { step += 1 } else { finish(early: false) }
            }
            .buttonStyle(.dx(.primary, on: .reading))
            .padding(.top, DX.Space.s)
            Spacer(minLength: 0)
        }
    }

    private var chosenThought: String? {
        if writingOwn {
            let text = ownThought.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        }
        return thought
    }

    // MARK: Done

    private var done: some View {
        // Top-anchored, with the buttons right under the choices (S27.14).
        VStack(spacing: DX.Space.s) {
            Image(systemName: "checkmark").font(.system(size: 30, weight: .bold)).foregroundStyle(Read4.accent)
                .frame(width: 76, height: 76).background(Read4.accentSoft, in: Circle())
                .padding(.top, DX.Space.xl)
                .accessibilityHidden(true)
            Text("Nicely done").v4Text(.title)
            Text("A bit calmer? \(Text("· optional").foregroundStyle(Read4.faint))").v4Text(.subtitle)
            HStack(spacing: DX.Space.xs) {
                calmerButton(true, "A bit")
                calmerButton(false, "Not really")
            }
            if answered == false {
                Text("That's okay. Try another tool, or ride it out with Craving SOS.").v4Text(.subtitle).multilineTextAlignment(.center)
            }
            Button("Done") { onDone(false) }.buttonStyle(.dx(.primary, on: .reading))
                .padding(.top, DX.Space.s)
            Button(fromSOS ? "Back to Craving SOS" : "Still craving? Start Craving SOS") {
                onDone(true)
            }
            .buttonStyle(.dx(.quiet, on: .reading))
            Spacer(minLength: 0)
        }
    }

    private func calmerButton(_ value: Bool, _ title: LocalizedStringKey) -> some View {
        let on = answered == value
        return Button {
            answered = value
            use?.calmer = value
            try? context.save()
        } label: {
            Text(title).dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Read4.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(on ? Read4.accent : Read4.hairline, lineWidth: on ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: Flow

    private func finish(early: Bool) {
        use?.finished = !early
        try? context.save()
        if early {
            onDone(false)
        } else {
            finished = true
        }
    }
}
