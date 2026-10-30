import DayXeroCore
import SwiftData
import SwiftUI

/// One program v2 session, a step at a time (handoff 4.2): intro, before-audio activities, the audio,
/// the activities, today's mission, then the completion moment. Every change is saved, so closing and
/// reopening resumes exactly there; closing never asks "are you sure".
struct SessionFlowView: View {
    let sessionId: String
    let profile: UserProfile
    /// Replays show saved answers, never change unlock state, never re-run commits and don't count as finishing.
    var isReplay = false

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var steps: [FlowStep] = []
    @State private var index = 0
    @State private var record: SessionRecord?
    @State private var completed = false

    enum FlowStep: Hashable {
        case intro, beat(String), audio, mission, completion
    }

    private var store: ProgramStore { ProgramStore(context: context, profile: profile) }
    private var session: ProgramContent.Session? { store.content?.session(sessionId) }

    var body: some View {
        VStack(spacing: 0) {
            if let session, steps.indices.contains(index) {
                if steps[index] != .completion { header(session) }
                stepView(steps[index], session: session)
                    .id(steps[index])
                    .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                                       removal: .opacity))
            }
        }
        .padding(.horizontal, DX.Space.l)
        .dxReadableColumn()
        .padding(.top, DX.Space.s)
        .padding(.bottom, DX.Space.xs)
        .dxCanvas()
        .animation(DX.Motion.animation(DX.Motion.glide, reduceMotion: reduceMotion), value: index)
        .onAppear(perform: start)
    }

    // MARK: Steps

    private func start() {
        guard let session, steps.isEmpty else { return }
        let ctx = context(for: session)
        let visible = { (beats: [Beat]) in beats.filter { ctx.shows($0) }.map { FlowStep.beat($0.id) } }
        var built: [FlowStep] = [.intro] + visible(session.beatsBeforeAudio) + [.audio] + visible(session.beatsAfterAudio)
        if session.mission != nil { built.append(.mission) }
        built.append(.completion)
        steps = built
        let firstAfterAudio = (built.firstIndex(of: .audio) ?? 0) + 1
        let record = store.open(session, firstStepAfterAudio: firstAfterAudio)
        self.record = record
        // A replay starts at the beginning; a finished session opened normally is a replay too.
        if isReplay || record.completedAt != nil {
            index = 0
        } else {
            index = min(record.currentStep, built.count - 1)
        }
        Analytics.track(isReplay || record.completedAt != nil ? .programReplayStarted(sessionId: session.id)
                        : .programSessionStarted(sessionId: session.id, variant: ctx.variant.rawValue))
    }

    private func advance() {
        guard index + 1 < steps.count else { dismiss(); return }
        index += 1
        if !isReplay, let record, record.completedAt == nil {
            record.currentStep = index
            try? context.save()
        }
        if steps[index] == .completion, !isReplay, record?.completedAt == nil, let session {
            store.complete(session.id)
            completed = true
            let minutes = Int(Date.now.timeIntervalSince(record?.startedAt ?? .now) / 60)
            Analytics.track(.programSessionCompleted(sessionId: session.id, minutesBucket: Analytics.minutesBucket(minutes)))
        }
    }

    private func close() {
        if !isReplay, let record { record.currentStep = index; try? context.save() }
        dismiss()
    }

    func context(for session: ProgramContent.Session) -> BeatContext {
        BeatContext(store: store, session: session, variant: store.variant, nrtActive: store.nrtActive(),
                    placeholders: store.placeholders(), isReplay: isReplay)
    }

    // MARK: Chrome

    private func header(_ session: ProgramContent.Session) -> some View {
        VStack(spacing: DX.Space.s) {
            HStack(spacing: 4) {
                ForEach(steps.indices, id: \.self) { i in
                    Capsule().fill(i <= index ? DX.Palette.text : DX.Palette.track).frame(height: 4)
                }
            }
            .accessibilityHidden(true)
            HStack {
                Button(action: close) {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .semibold)).foregroundStyle(DX.Palette.text2)
                        .frame(width: 44, height: 44)
                        .background(DX.Palette.surface1, in: Circle())
                        .overlay(Circle().strokeBorder(DX.Palette.hairline))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(isReplay ? "Close" : "Close. Your place is saved."))
                Spacer()
                Text(verbatim: "\(session.label) · \(index + 1) of \(steps.count)").dxText(.micro)
                Spacer()
                if isReplay {
                    Text("Replay").font(.custom(DX.Typeface.bold, size: 11, relativeTo: .caption2)).tracking(1).textCase(.uppercase)
                        .foregroundStyle(DX.Palette.text2)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(DX.Palette.surface2, in: Capsule())
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .padding(.bottom, DX.Space.s)
    }

    @ViewBuilder
    private func stepView(_ step: FlowStep, session: ProgramContent.Session) -> some View {
        let ctx = context(for: session)
        switch step {
        case .intro:
            SessionIntro(session: session, variant: ctx.variant, isReplay: isReplay, onBegin: advance)
        case let .beat(id):
            if let beat = (session.beats + (session.mission?.followUp ?? [])).first(where: { $0.id == id }) {
                BeatScreen(beat: beat, ctx: ctx, onDone: advance)
            }
        case .audio:
            ProgramAudioStep(session: session, ctx: ctx, record: record, onDone: advance)
        case .mission:
            if let mission = session.mission {
                MissionCard(mission: mission, ctx: ctx) {
                    if !isReplay { store.missionShown(session.id) }
                    advance()
                }
            }
        case .completion:
            SessionCompletion(session: session, ctx: ctx, isReplay: isReplay, onDone: { dismiss() })
        }
    }
}

// MARK: - Intro

struct SessionIntro: View {
    let session: ProgramContent.Session
    let variant: ProgramVariant
    let isReplay: Bool
    let onBegin: () -> Void

    var body: some View {
        VStack(spacing: DX.Space.m) {
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.s) {
                    Spacer(minLength: DX.Space.xl)
                    ZStack {
                        Circle().fill(DX.Palette.accentSoft).frame(width: 132, height: 132)
                        Image(systemName: "headphones").font(.system(size: 50, weight: .regular)).foregroundStyle(DX.Palette.accentInk)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, DX.Space.m)
                    .accessibilityHidden(true)
                    Text(verbatim: session.label).dxText(.micro).foregroundStyle(DX.Palette.accentInk)
                    Text(verbatim: session.title.resolve(variant) ?? "")
                        .font(.custom(DX.Typeface.bold, size: 30, relativeTo: .largeTitle)).tracking(-0.6)
                        .foregroundStyle(DX.Palette.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: session.subtitle.resolve(variant) ?? "").dxText(.subtitle)
                    Text("\(session.durationMinutes) min · Audio, activities and today's mission").dxText(.subtitle)
                    if let hint = session.listenHint?.resolve(variant) {
                        HStack(spacing: DX.Space.s) {
                            Image(systemName: "clock").foregroundStyle(DX.Palette.accentInk)
                            Text(verbatim: hint).font(.custom(DX.Typeface.regular, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                        }
                        .padding(DX.Space.m)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(DX.Palette.hairline))
                        .padding(.top, DX.Space.xs)
                    }
                }
            }
            Button(isReplay ? "Replay" : "Begin", action: onBegin).buttonStyle(.dxPrimary)
        }
    }
}

// MARK: - Audio

/// The guided audio. With a recording in the bundle it plays with the cloud wave and captions, and Continue appears
/// only when it ends (no skipping). Until the recordings arrive it shows "Audio coming soon" and lets the session go on.
struct ProgramAudioStep: View {
    let session: ProgramContent.Session
    let ctx: BeatContext
    let record: SessionRecord?
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @State private var finished = false

    struct Transcript: Decodable {
        struct Segment: Decodable { let start: Double; let end: Double; let text: String }
        let segments: [Segment]
    }

    private var variantName: String { session.audio.pick(for: ctx.variant, nrtActive: ctx.nrtActive) }

    private func bundled(_ name: String) -> URL? {
        let base = (name as NSString).deletingPathExtension, ext = (name as NSString).pathExtension
        return Bundle.main.url(forResource: base, withExtension: ext, subdirectory: ctx.store.content?.audio.folder)
            ?? Bundle.main.url(forResource: base, withExtension: ext)
    }

    private var narrator: LessonNarrator? {
        guard let naming = ctx.store.content?.audio,
              let audio = bundled(naming.file(session: session.id, variant: variantName)) else { return nil }
        let segments: [(start: Double, text: String)] = bundled(naming.transcript(session: session.id, variant: variantName))
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode(Transcript.self, from: $0) }?
            .segments.map { ($0.start, $0.text) } ?? []
        let seconds = Double(session.durationMinutes * 60)
        return LessonNarrator(segments: segments.isEmpty ? [(0, session.title.resolve(ctx.variant) ?? "")] : segments,
                              url: audio, seconds: seconds)
    }

    var body: some View {
        VStack(spacing: DX.Space.s) {
            if let narrator {
                LessonAudioStep(title: session.title.resolve(ctx.variant) ?? "", narrator: narrator,
                                startAt: ctx.isReplay ? 0 : record?.audioPosition ?? 0,
                                onPosition: { seconds in
                                    guard !ctx.isReplay, let record else { return }
                                    record.audioPosition = seconds
                                    record.audioVariant = variantName
                                    try? context.save()
                                },
                                onFinish: { finished = true })
                    .frame(maxHeight: .infinity)
                if finished || ctx.isReplay {
                    Button("Continue", action: onDone).buttonStyle(.dxPrimary)
                }
            } else {
                comingSoon
            }
        }
    }

    private var comingSoon: some View {
        VStack(spacing: DX.Space.m) {
            Text(verbatim: session.title.resolve(ctx.variant) ?? "").dxText(.title).multilineTextAlignment(.center)
            CloudWave(level: { _ in 0.35 }, playing: false)
                .frame(height: 190)
                .opacity(0.6)
            Label("Audio coming soon", systemImage: "headphones")
                .font(.custom(DX.Typeface.bold, size: 13, relativeTo: .footnote))
                .foregroundStyle(Color(light: 0xB07A14, dark: 0xE5A93C))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(DX.Palette.amber.opacity(0.2), in: Capsule())
            Text("The guided audio for this session is on its way. Everything after it works now, so carry on.")
                .dxText(.subtitle).multilineTextAlignment(.center)
            Spacer()
            Button("Continue", action: onDone).buttonStyle(.dxPrimary)
        }
        .onAppear {
            guard !ctx.isReplay, let record else { return }
            record.audioVariant = variantName
            try? context.save()
        }
    }
}

// MARK: - Mission

struct MissionCard: View {
    let mission: ProgramContent.Mission
    let ctx: BeatContext
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: DX.Space.m) {
            Spacer()
            VStack(alignment: .leading, spacing: DX.Space.m) {
                Text("Today's mission").dxText(.micro).foregroundStyle(DX.Palette.accentInk)
                VStack(alignment: .leading, spacing: DX.Space.m) {
                    Image(systemName: "scope").font(.system(size: 36)).foregroundStyle(DX.Palette.accentInk).accessibilityHidden(true)
                    Text(verbatim: ctx.text(mission.text))
                        .font(.custom(DX.Typeface.semibold, size: 22, relativeTo: .title2)).tracking(-0.3)
                        .foregroundStyle(DX.Palette.text)
                    Text(mission.followUp == nil ? "It stays on your Today card until the next session."
                         : "When you log it, we'll ask two quick questions. It stays on your Today card until the next session.")
                        .dxText(.subtitle)
                }
                .padding(DX.Space.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(DX.Palette.hairline))
            }
            Spacer()
            Button("Got it", action: onDone).buttonStyle(.dxPrimary)
        }
    }
}

// MARK: - Completion

struct SessionCompletion: View {
    let session: ProgramContent.Session
    let ctx: BeatContext
    let isReplay: Bool
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    private var next: String? {
        guard let next = ctx.store.content?.session(after: session.id) else { return nil }
        let title = next.title.resolve(ctx.variant) ?? ""
        return switch ctx.store.state(of: next.id) {
        case .available, .inProgress: String(localized: "Next: \(next.label) · \(title), ready now")
        case .scheduled(.tomorrow): String(localized: "Next: \(next.label) · \(title), tomorrow")
        case let .scheduled(.dayXero(date)): String(localized: "Day Xero is \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
        case let .scheduled(.quitDay(day)): String(localized: "Next session on Day \(day)")
        default: nil
        }
    }

    var body: some View {
        VStack(spacing: DX.Space.m) {
            Spacer()
            ZStack {
                Circle().fill(DX.Palette.accentSoft).frame(width: 150, height: 150)
                    .scaleEffect(shown || reduceMotion ? 1 : 0.7)
                Image(systemName: "checkmark").font(.system(size: 56, weight: .semibold)).foregroundStyle(DX.Palette.accentInk)
            }
            .accessibilityHidden(true)
            Text("\(session.label) done").dxText(.micro).padding(.top, DX.Space.m)
            Text(verbatim: ctx.text(session.completionText))
                .font(.custom(DX.Typeface.bold, size: 26, relativeTo: .title)).tracking(-0.5)
                .multilineTextAlignment(.center)
                .foregroundStyle(DX.Palette.text)
            Spacer()
            if let next, !isReplay {
                Text(verbatim: next).dxText(.subtitle)
                    .padding(DX.Space.m)
                    .frame(maxWidth: .infinity)
                    .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(DX.Palette.hairline))
            }
            Button("Done", action: onDone).buttonStyle(.dxPrimary)
        }
        .sensoryFeedback(.success, trigger: shown)
        .onAppear {
            withAnimation(DX.Motion.animation(DX.Motion.glide, reduceMotion: reduceMotion)) { shown = true }
        }
    }
}
