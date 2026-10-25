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

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onClose) { Image(systemName: "xmark") }.buttonStyle(.dxIcon).accessibilityLabel(Text("Close"))
                Spacer()
                Text("Calm tools").dxText(.micro)
                Spacer()
                Color.clear.frame(width: DX.Size.iconButton, height: 1)
            }
            .padding(.top, DX.Space.s)
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    Text("For stressful moments").dxText(.title)
                    Text("Short things to do instead of reaching for nicotine.").dxText(.subtitle).padding(.bottom, DX.Space.xs)
                    ForEach(CalmTool.allCases) { tool in
                        Button { open = tool } label: { CalmToolRow(tool: tool) }.buttonStyle(.plain)
                    }
                    HelpLine().padding(.top, DX.Space.s)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DX.Space.xs)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.horizontal, DX.Space.m)
        .dxCanvas()
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

struct CalmToolRow: View {
    let tool: CalmTool
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // At the largest text sizes the icon and minutes move above the words, so the words get the full width.
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: DX.Space.xs))
            : AnyLayout(HStackLayout(spacing: DX.Space.s))
        layout {
            HStack {
                Image(systemName: tool.systemImage).font(.system(size: 17)).foregroundStyle(DX.Palette.accentInk)
                    .frame(width: 40, height: 40).background(DX.Palette.accentSoft, in: Circle())
                if typeSize.isAccessibilitySize {
                    Spacer()
                    Text("\(tool.minutes) min").dxText(.subtitle)
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(tool.title).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                Text(tool.detail).dxText(.subtitle).multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if !typeSize.isAccessibilitySize {
                Text("\(tool.minutes) min").dxText(.subtitle).fixedSize()
            }
        }
        .padding(12)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(DX.Palette.hairline))
        .accessibilityElement(children: .combine)
    }
}

/// The plain line pointing to professional help (S12.3). No diagnosis, no clinical claims.
struct HelpLine: View {
    static let directory = URL(string: "https://findahelpline.com")!

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("If stress or anxiety is getting in the way of everyday life, talk to a doctor or a mental health professional. In a crisis, call your local emergency number.")
                .dxText(.subtitle)
            Link(destination: Self.directory) {
                Text("Find a helpline near you").font(DX.TextStyle.subtitle.font).underline().foregroundStyle(DX.Palette.accentInk)
            }
        }
        .padding(DX.Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(DX.Palette.faint, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
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
        .padding(.bottom, DX.Space.xs)
        .modifier(PlayerCanvas(orb: tool.orbPattern != nil && !finished))
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
                        Capsule().fill(i <= step ? DX.Palette.text : DX.Palette.track).frame(height: 4)
                    }
                }
                .accessibilityHidden(true)
            }
            HStack {
                Button { finish(early: true) } label: { Image(systemName: "xmark") }
                    .buttonStyle(.dxIcon).accessibilityLabel(Text("Stop"))
                Spacer()
                Text(tool.title).dxText(.micro)
                Spacer()
                Color.clear.frame(width: DX.Size.iconButton, height: 1)
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
            Text(verbatim: "\(current.count)").font(.custom(DX.Typeface.bold, size: 64, relativeTo: .largeTitle))
                .foregroundStyle(DX.Palette.accentInk).padding(.top, DX.Space.l)
            Text(current.sense).dxText(.title)
            Text(current.hint).dxText(.subtitle)
            DXFlowLayout(spacing: DX.Space.xs) {
                ForEach(0..<current.count, id: \.self) { i in
                    Button { ticked = max(ticked, i + 1) } label: {
                        Image(systemName: "checkmark").font(.system(size: 15, weight: .bold))
                            .foregroundStyle(i < ticked ? DX.Palette.onAccent : .clear)
                            .frame(width: 44, height: 44)
                            .background(i < ticked ? DX.Palette.sage : .clear, in: Circle())
                            .overlay(Circle().strokeBorder(i < ticked ? .clear : DX.Palette.faint, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Found \(i + 1)"))
                }
            }
            .padding(.top, DX.Space.xs)
            Spacer()
            Button(step + 1 < Grounding.steps.count ? "Next: \(Grounding.steps[step + 1].count) \(String(localized: Grounding.steps[step + 1].sense))" : "Done") {
                ticked = 0
                if step + 1 < Grounding.steps.count { step += 1 } else { finish(early: false) }
            }
            .buttonStyle(.dxPrimary)
        }
    }

    private var notice: some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            switch step {
            case 0:
                Text("What's your mind telling you?").dxText(.title).padding(.top, DX.Space.l)
                Text("Pick the closest, or write your own.").dxText(.subtitle)
                DXFlowLayout {
                    ForEach(NoticeAndName.thoughts.map { String(localized: $0) }, id: \.self) { t in
                        DXChip(LocalizedStringKey(t), isOn: Binding(get: { !writingOwn && thought == t }, set: { if $0 { thought = t; writingOwn = false } }))
                    }
                    DXChip("write my own", isOn: $writingOwn)
                }
                if writingOwn { DXTextField("The thought", prompt: "I'll never manage", text: $ownThought) }
                Spacer()
                Button("Next") { step = 1 }.buttonStyle(.dxPrimary).disabled(chosenThought == nil)
            case 1:
                VStack(alignment: .leading, spacing: 6) {
                    Text("Say it this way").dxText(.micro)
                    Text("I'm noticing I'm having the thought \(Text(verbatim: "“\(chosenThought ?? "")”").foregroundStyle(DX.Palette.accentInk))")
                        .font(.custom(DX.Typeface.semibold, size: 22, relativeTo: .title2)).foregroundStyle(DX.Palette.text)
                }
                .padding(DX.Space.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(DX.Palette.hairline))
                .padding(.top, DX.Space.l)
                Text("It's a thought, not an order. You can let it sit there while you get on with your day.").dxText(.subtitle)
                Spacer()
                Button("Next") { step = 2 }.buttonStyle(.dxPrimary)
            default:
                Spacer()
                timedBreaths
                Spacer()
                Button("Done") { finish(early: false) }.buttonStyle(.dxPrimary)
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
                    .fill(RadialGradient(colors: [DX.Palette.sage.opacity(0.6), DX.Palette.sage.opacity(0.2), .clear],
                                         center: .center, startRadius: 0, endRadius: 90))
                    .scaleEffect(reduceMotion ? 0.86 : 0.7 + 0.3 * breath.scale)
                    .overlay(Text("\(NoticeAndName.breaths) breaths").font(.custom(DX.Typeface.semibold, size: 20, relativeTo: .title3))
                        .foregroundStyle(DX.Palette.text))
                    .frame(width: 180, height: 180)
                Text(breath.phase == .breatheIn ? "Breathe in" : "Breathe out").dxText(.subtitle)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var anchor: some View {
        let current = DropAnchor.steps[min(step, DropAnchor.steps.count - 1)]
        return VStack(alignment: .leading, spacing: DX.Space.s) {
            Image(systemName: "figure.stand").font(.system(size: 30)).foregroundStyle(DX.Palette.accentInk)
                .frame(width: 70, height: 70).background(DX.Palette.accentSoft, in: Circle())
                .padding(.top, DX.Space.l)
                .accessibilityHidden(true)
            Text(current.title).dxText(.title)
            Text(current.body).font(DX.TextStyle.body.font).foregroundStyle(DX.Palette.text2)
            Spacer()
            Button(step + 1 < DropAnchor.steps.count ? "Next" : "Done") {
                if step + 1 < DropAnchor.steps.count { step += 1 } else { finish(early: false) }
            }
            .buttonStyle(.dxPrimary)
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
        VStack(spacing: DX.Space.s) {
            Spacer()
            Image(systemName: "checkmark").font(.system(size: 30, weight: .bold)).foregroundStyle(DX.Palette.accentInk)
                .frame(width: 76, height: 76).background(DX.Palette.accentSoft, in: Circle())
                .accessibilityHidden(true)
            Text("Nicely done").dxText(.title)
            Text("A bit calmer? \(Text("· optional").foregroundStyle(DX.Palette.faint))").dxText(.subtitle)
            HStack(spacing: DX.Space.xs) {
                calmerButton(true, "A bit")
                calmerButton(false, "Not really")
            }
            if answered == false {
                Text("That's okay. Try another tool, or ride it out with Craving SOS.").dxText(.subtitle).multilineTextAlignment(.center)
            }
            Spacer()
            Button("Done") { onDone(false) }.buttonStyle(.dxPrimary)
            Button(fromSOS ? "Back to Craving SOS" : "Still craving? Start Craving SOS") {
                onDone(true)
            }
            .buttonStyle(.dxQuiet)
        }
    }

    private func calmerButton(_ value: Bool, _ title: LocalizedStringKey) -> some View {
        let on = answered == value
        return Button {
            answered = value
            use?.calmer = value
            try? context.save()
        } label: {
            Text(title).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(on ? DX.Palette.accentInk : DX.Palette.hairline, lineWidth: on ? 1.5 : 1))
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

/// Breathing tools sit on the orb's black canvas; the rest use the app's canvas.
private struct PlayerCanvas: ViewModifier {
    let orb: Bool

    func body(content: Content) -> some View {
        if orb {
            content.background(Color.black.ignoresSafeArea()).environment(\.colorScheme, .dark)
        } else {
            content.dxCanvas()
        }
    }
}
