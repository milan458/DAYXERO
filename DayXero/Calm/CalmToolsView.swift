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
    @State private var rewardCard = false

    /// v5: Calm is a tab, which has no close button.
    var showsClose = true

    init(onClose: @escaping () -> Void, fromSOS: Bool = false, startSOS: (() -> Void)? = nil, showsClose: Bool = true) {
        self.showsClose = showsClose
        self.onClose = onClose
        self.fromSOS = fromSOS
        self.startSOS = startSOS
        #if DEBUG
        _open = State(initialValue: UserDefaults.standard.string(forKey: "dx.openCalm").flatMap(CalmTool.init(rawValue:)))
        #endif
    }

    private var ground: DX.Ground { showsClose ? .periwinkle : .reading }
    @Query private var uses: [ToolUse]

    /// v5 (056): the title and its line, then the four tools as tiles, each with its own little scene; the quiet This
    /// week row last. Motion: the title arrives, then the tiles on the 90 ms stagger; each cast member settles into its
    /// scene 120 ms after its tile; the This week row fades in last and its minutes count up (850 ms).
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // The sheet opened from SOS and Today keeps its header art.
                if showsClose {
                    CalmHeaderArt()
                        .frame(maxWidth: .infinity)
                        .padding(.top, DX.Space.xs)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Calm tools")
                        .dxType(.large).foregroundStyle(ground.ink)
                        .accessibilityAddTraits(.isHeader)
                        .dxArrive(0)
                    Text("A few minutes instead of reaching for nicotine.").dxType(.footnote).foregroundStyle(ground.muted)
                        .dxArrive(1)
                }
                .padding(.top, showsClose ? 0 : 22)
                // CLIN-04: from SOS and Today, the reward card for the moment straight after finishing something.
                if showsClose {
                    Button { rewardCard = true } label: { RewardCardRow() }.buttonStyle(.plain)
                        .padding(.top, 16)
                }
                // A plain Grid, not a lazy one: every tool is built, so each one is there for VoiceOver and UI tests.
                let tools = CalmTool.shelf
                Grid(horizontalSpacing: 12, verticalSpacing: 16) {
                    ForEach(Array(stride(from: 0, to: tools.count, by: 2)), id: \.self) { start in
                        GridRow(alignment: .top) {
                            ForEach(start..<min(start + 2, tools.count), id: \.self) { index in
                                Button { open = tools[index] } label: {
                                    CalmToolCard(tool: tools[index], castDelay: Double(index + 2) * DX.Move.arriveStagger + 0.12)
                                }
                                .buttonStyle(.dxPress)
                                .sensoryFeedback(.impact(weight: .light), trigger: open) { _, now in now == tools[index] }
                                .dxArrive(index + 2)
                            }
                        }
                    }
                }
                .padding(.top, 26)
                weekRow
                    .padding(.top, 16)
                    .dxArrive(6)
                if showsClose {
                    HelpLine(compact: true, ground: ground).padding(.top, DX.Space.s)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DX.Layout.gutter)
            .dxReadableColumn()
            .padding(.bottom, DX.Space.l)
        }
        .scrollBounceBehavior(.basedOnSize)
        .overlay(alignment: .topLeading) {
            if showsClose {
                Button(action: onClose) { Image(systemName: "xmark") }
                    .buttonStyle(.v4Icon).accessibilityLabel(Text("Close"))
                    .padding(.leading, DX.Space.m).padding(.top, DX.Space.s)
            }
        }
        .background(ground.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $rewardCard) {
            RewardDefusionView { rewardCard = false }
        }
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

    /// "This week: 24 min of calm", in its own soft container.
    private var weekRow: some View {
        let week = Calendar.current.dateInterval(of: .weekOfYear, for: .now)
        let minutes = CalmTool.minutes(in: uses.filter { week?.contains($0.startedAt) ?? false })
        return HStack(spacing: 10) {
            DXIcon(.leaf, size: 18).foregroundStyle(ground.muted)
            HStack(spacing: 0) {
                Text("This week: ")
                CountingText(Double(minutes), delay: 0.7) { v in String(localized: "\(Int(v.rounded())) min") }
                    .dxFace(.body, 15, weight: 700).foregroundStyle(ground.ink)
                Text(" of calm")
            }
            .dxType(.footnote).foregroundStyle(ground.muted)
            .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(ground.card2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("This week: \(minutes) min of calm"))
    }
}

/// The calm tools header: Glim breathing on a cloud, a dotted halo breathing on the 4 in, 6 out clock. Glim replaced the
/// person figure so the app has one illustration language, the crew (S27.15).
struct CalmHeaderArt: View {
    private let motion = MotionPolicy()

    var body: some View {
        TimelineView(.animation(paused: !motion.breathes)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breath = motion.breathes ? DX.Move.breath(at: t) : 0.5
            ZStack {
                Circle()
                    .strokeBorder(DX.Fill.cream, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [2, 7]))
                    .frame(width: 104 + 20 * breath, height: 104 + 20 * breath)
                    .offset(y: -18)
                CalmCloud()
                    .fill(DX.Fill.cream)
                    .frame(width: 168, height: 56)
                    .offset(y: 56)
                GlimView(mood: .breathe, stage: 1, points: 104, animate: motion.breathes)
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

/// A calm tool as a tile (v5, 056): its scene on top, the title and "N min · detail" under it on the card.
struct CalmToolCard: View {
    let tool: CalmTool
    var castDelay: Double = 0
    private let ground = DX.Ground.reading

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CalmTileArt(tool: tool, castDelay: castDelay)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(tool.title).dxType(.headline).foregroundStyle(ground.ink)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(verbatim: "\(String(localized: "\(tool.minutes) min")) · \(String(localized: tool.detail))")
                    .dxType(.caption).foregroundStyle(ground.muted)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .padding(EdgeInsets(top: 12, leading: 14, bottom: 14, trailing: 14))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(ground.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(ground.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(tool.title))
        .accessibilityValue(Text("\(tool.minutes) min. \(Text(tool.detail))"))
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
        .background(DX.Ground.reading.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(DX.Ground.reading.line, lineWidth: 1))
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

/// Runs one calm tool, then the done screen (S12.1; v5, 057-060).
struct CalmToolPlayer: View {
    let tool: CalmTool
    var fromSOS = false
    /// true when the person chose to go back to (or start) Craving SOS.
    let onDone: (Bool) -> Void

    @Environment(\.modelContext) private var context
    @State private var startedAt = Date.now
    @State private var finished = false
    @State private var step = 0
    @State private var ticked = 0
    @State private var use: ToolUse?
    /// Debug stills: open a tool part way through.
    private var still = false

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
        still = tool == .noticeAndName && d.integer(forKey: "dx.calmStep") > 0
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            if finished {
                CalmDoneView(tool: tool, fromSOS: fromSOS, use: use, onDone: onDone)
            } else {
                running
            }
        }
        .padding(.horizontal, DX.Layout.gutter)
        .dxReadableColumn()
        .padding(.bottom, DX.Space.xs)
        .dxGround(.reading)
        .onAppear {
            let record = ToolUse(tool: tool.rawValue, startedAt: startedAt, finished: finished)
            context.insert(record)
            try? context.save()
            use = record
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: finished) { _, now in now }
    }

    // MARK: Running

    @ViewBuilder
    private var running: some View {
        switch tool {
        case .boxBreathing:
            CalmBoxView(startedAt: startedAt, onClose: { finish(early: true) }, onFinished: { finish(early: false) })
        case .grounding:
            CalmGroundingView(step: $step, ticked: $ticked, onClose: { finish(early: true) }, onFinished: { finish(early: false) })
        case .noticeAndName:
            CalmUrgeView(still: still, onClose: { finish(early: true) }, onPassing: { finish(early: false) }, onMoreHelp: {
                use?.finished = false
                try? context.save()
                onDone(true)
            })
        case .longerOutBreath:
            topBar
            BreathPacerPanel(pattern: tool.orbPattern ?? "478", cycles: tool.cycles) { finish(early: false) }
            Spacer(minLength: 0)
        case .dropAnchor:
            topBar
            anchor
        }
    }

    private var topBar: some View {
        VStack(spacing: DX.Space.s) {
            if tool == .dropAnchor {
                DXSteps(count: DropAnchor.steps.count, current: step + 1)
                    .accessibilityHidden(true)
            }
            HStack {
                DXIconButton(.close, label: "Close") { finish(early: true) }
                Spacer()
                Text(tool.title).dxType(.headline)
                Spacer()
                Color.clear.frame(width: 44, height: 1)
            }
            .padding(.horizontal, -6)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .padding(.top, DX.Space.xs)
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

    // MARK: Flow

    private func finish(early: Bool) {
        use?.finished = !early
        try? context.save()
        if early {
            onDone(false)
        } else {
            withAnimation(DX.Move.fade) { finished = true }
        }
    }
}

/// The reward card's row on the calm tools list (CLIN-04).
struct RewardCardRow: View {
    var body: some View {
        HStack(spacing: 14) {
            KitArt(.sparkle, cornerRadius: 18)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 2) {
                Text("Just finished something?").dxFont(16, weight: 700, style: .body).foregroundStyle(DX.Ground.reading.ink)
                Text("\u{201C}\(Text(RewardDefusion.thought))\u{201D} Unhook from it.")
                    .dxType(.footnote).foregroundStyle(DX.Ground.reading.muted).multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(DX.Ground.reading.ink)
                .accessibilityHidden(true)
        }
        .padding(8)
        .padding(.trailing, 8)
        .background(DX.Ground.reading.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(DX.Ground.reading.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text("1 min"))
    }
}

/// "Don't I deserve a reward?" (CLIN-04): notice the thought, see what it's offering, pick a real reward.
struct RewardDefusionView: View {
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @State private var step = 0
    @State private var reward: String?
    @State private var use: ToolUse?
    @State private var finished = false

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            HStack(spacing: 4) {
                ForEach(0..<RewardDefusion.steps.count, id: \.self) { i in
                    Capsule().fill(i <= step ? Read4.ink : Read4.track).frame(height: 4)
                }
            }
            .accessibilityHidden(true)
            .padding(.top, DX.Space.s)
            HStack {
                Button { close(finished: false) } label: { Image(systemName: "xmark") }
                    .buttonStyle(.v4Icon).accessibilityLabel(Text("Close"))
                Spacer()
                Text("With Glim").v4Text(.micro)
                Spacer()
                Color.clear.frame(width: 44, height: 1)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.s) {
                    let current = RewardDefusion.steps[min(step, RewardDefusion.steps.count - 1)]
                    if step == 0 {
                        Text("\u{201C}\(Text(RewardDefusion.thought))\u{201D}")
                            .dxFont(24, weight: 600, style: .title2).foregroundStyle(Read4.accent)
                            .padding(.top, DX.Space.m)
                    }
                    Text(current.title).v4Text(.title).padding(.top, step == 0 ? 0 : DX.Space.m)
                    Text(current.body).dxFont(16, weight: 400, style: .body).foregroundStyle(Read4.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if step == RewardDefusion.steps.count - 1 {
                        DXFlowLayout {
                            ForEach(RewardDefusion.rewards.map { String(localized: $0) }, id: \.self) { r in
                                V4ToggleChip(LocalizedStringKey(r), isOn: Binding(get: { reward == r }, set: { if $0 { reward = r } }))
                            }
                        }
                        .padding(.top, DX.Space.xs)
                        if let reward {
                            Text("Enjoy it: \(reward.lowercased()). You earned it.")
                                .dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                                .padding(.top, DX.Space.xs)
                        }
                    }
                    Button(step + 1 < RewardDefusion.steps.count ? "Next" : "Done") {
                        if step + 1 < RewardDefusion.steps.count { step += 1 } else { close(finished: true) }
                    }
                    .buttonStyle(.dx(.primary, on: .reading))
                    .padding(.top, DX.Space.s)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.horizontal, DX.Layout.gutter)
        .dxReadableColumn()
        .padding(.bottom, DX.Space.xs)
        .background(Read4.background.ignoresSafeArea())
        .onAppear {
            let record = ToolUse(tool: RewardDefusion.toolID)
            context.insert(record)
            try? context.save()
            use = record
        }
        .sensoryFeedback(DX.Haptic.select, trigger: step)
        .sensoryFeedback(DX.Haptic.commit, trigger: finished)
    }

    private func close(finished done: Bool) {
        use?.finished = done
        try? context.save()
        finished = done
        onDone()
    }
}
