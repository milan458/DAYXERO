import DayXeroCore
import SwiftUI

/// What an activity needs: the person's wording, their saved answers and somewhere to save new ones.
@MainActor
struct BeatContext {
    let store: ProgramStore
    let session: ProgramContent.Session
    let variant: ProgramVariant
    let nrtActive: Bool
    let placeholders: ProgramPlaceholders
    let isReplay: Bool

    /// The person's version of a string, with numbers filled in and anything unknown left out.
    /// Program v3 text may carry inline product wording (`{s: … | v: … | p: …}`), resolved before the numbers fill.
    func text(_ value: Varied<String>?) -> String {
        value?.resolve(variant).map { placeholders.fillDropping(ProgramInline.resolve($0, variant)) } ?? ""
    }

    func answer(_ key: String?) -> ProgramAnswerValue? { key.flatMap { store.answer($0) } }

    /// Saves an answer. Replays may edit answers too; the change shows everywhere it's used.
    func save(_ key: String?, _ value: ProgramAnswerValue) {
        guard let key else { return }
        store.save(key, value, session: session.id)
    }

    /// The value saved on the activity itself (quiz and scenario picks), for replays.
    func recorded(_ beat: Beat) -> ProgramAnswerValue? {
        store.beatRecord(session: session.id, beat: beat.id)?.value
    }

    func finish(_ beat: Beat, skipped: Bool = false, value: ProgramAnswerValue? = nil) {
        guard !isReplay else { return }
        store.finishBeat(session: session.id, beat: beat.id, skipped: skipped, value: value)
        Analytics.track(.programBeatCompleted(sessionId: session.id, beatId: beat.id, type: beat.type.rawValue, skipped: skipped))
    }

    /// Whether an activity is shown at all: its NRT condition holds, and a note or card set has something to show.
    func shows(_ beat: Beat) -> Bool {
        switch beat.showIf {
        case .nrtActive?: if !nrtActive { return false }
        case .nrtNotActive?: if nrtActive { return false }
        case nil: break
        }
        if beat.type == .note, beat.skipIfEmpty, answer(beat.textFrom)?.isEmpty ?? true { return false }
        return true
    }
}

/// The frame every activity shares (handoff 5): its content, then Continue right under it, and Skip for optional ones.
/// The buttons scroll with the content instead of being pinned to the bottom, so there's no gap between the last
/// option and Continue (S27.14); spare room sits below the buttons.
struct BeatFrame<Content: View>: View {
    let beat: Beat
    var canContinue = true
    var continueTitle: LocalizedStringKey = "Continue"
    let onContinue: () -> Void
    var onSkip: (() -> Void)?
    @ViewBuilder let content: () -> Content

    /// v5 (026-031): the step scrolls; Continue (and Skip on an optional step) sits in the dock below it.
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                    .padding(.bottom, DX.Space.m)
                    // Room for shadows inside the clipped scroll area, without moving the column.
                    .padding(.horizontal, DX.Layout.gutter)
            }
            .padding(.horizontal, -DX.Layout.gutter)
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 4) {
                Button(continueTitle, action: onContinue)
                    .buttonStyle(.dx(.primary, on: .table))
                    .disabled(!canContinue)
                if beat.optional, let onSkip {
                    Button("Skip", action: onSkip).buttonStyle(.dx(.quiet, on: .table))
                }
            }
            // The buttons stay a readable size; everything above them grows and scrolls.
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .padding(.top, 10)
            .dxArrive(8)
        }
    }
}

/// The prompt at the top of most activities (kit `.t-title`), its eyebrow a muted line above it. A question with an
/// instruction after it ("What gets to you most? Pick the two…") shows as the question and a muted helper (026).
struct BeatPrompt: View {
    let text: String
    var eyebrow: LocalizedStringKey?

    static func split(_ text: String) -> (title: String, helper: String?) {
        guard let q = text.firstIndex(of: "?"), text.index(after: q) < text.endIndex else { return (text, nil) }
        let title = String(text[...q])
        let rest = text[text.index(after: q)...].trimmingCharacters(in: .whitespaces)
        return rest.isEmpty ? (text, nil) : (title, rest)
    }

    var body: some View {
        let parts = Self.split(text)
        VStack(alignment: .leading, spacing: 8) {
            if let eyebrow { Text(eyebrow).dxType(.footnote).foregroundStyle(DX.Ground.table.muted) }
            if !parts.title.isEmpty {
                Text(verbatim: parts.title)
                    .dxType(.title)
                    .foregroundStyle(DX.Ground.table.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .dxArrive(1)
            }
            if let helper = parts.helper {
                Text(verbatim: helper)
                    .dxType(.footnote)
                    .foregroundStyle(DX.Ground.table.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .dxArrive(2)
            }
        }
        .padding(.bottom, DX.Space.xs)
    }
}

/// The soft feedback panel. Announced to VoiceOver when it appears.
struct BeatFeedback: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            DXIcon(.sparkle, size: 18, weight: 2.4).foregroundStyle(DX.Fill.coral).accessibilityHidden(true)
            Text(verbatim: text).dxType(.body).foregroundStyle(DX.Ground.table.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(DX.Ground.table.line, lineWidth: 1))
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .onAppear { AccessibilityNotification.Announcement(text).post() }
    }
}

/// An option row (kit `.opt`): the words, an optional detail, and the radio on the right; chosen, the warm tint, a
/// 2 pt edge and a filled radio with a tick, and a 520 ms spring bump as it lands.
struct OptionRow<Detail: View>: View {
    let text: String
    var selected = false
    var outlined = false
    var dimmed = false
    let detail: () -> Detail
    private let motion = MotionPolicy()

    init(text: String, selected: Bool = false, outlined: Bool = false, dimmed: Bool = false, @ViewBuilder detail: @escaping () -> Detail) {
        self.text = text
        self.selected = selected
        self.outlined = outlined
        self.dimmed = dimmed
        self.detail = detail
    }

    var body: some View {
        let g = DX.Ground.table
        let shape = RoundedRectangle(cornerRadius: DX.Layout.optionRadius, style: .continuous)
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: text).dxType(.body).foregroundStyle(g.ink)
                    .fixedSize(horizontal: false, vertical: true)
                detail()
            }
            Spacer(minLength: 0)
            DXRadio(isOn: selected, ground: g)
        }
        .padding(.vertical, 12).padding(.horizontal, 16)
        .frame(minHeight: 64)
        .background(selected ? g.selTint : g.card, in: shape)
        .overlay(shape.strokeBorder(selected ? g.selEdge : outlined ? g.ink.opacity(0.4) : g.line, lineWidth: selected || outlined ? 2 : 1))
        .opacity(dimmed ? 0.5 : 1)
        .contentShape(shape)
        .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.3), value: selected)
        .phaseAnimator([1.0, 0.97, 1.0], trigger: selected) { view, scale in
            view.scaleEffect(motion.reduce || !selected ? 1 : scale)
        } animation: { _ in .timingCurve(0.3, 1.4, 0.5, 1, duration: 0.26) }
    }
}

extension OptionRow where Detail == EmptyView {
    init(text: String, selected: Bool = false, outlined: Bool = false, dimmed: Bool = false) {
        self.init(text: text, selected: selected, outlined: outlined, dimmed: dimmed) { EmptyView() }
    }
}

/// A chip that can be on or off (kit `.chip`): it hugs its words; on, the warm tint, a 2 pt edge and bold words, with a
/// 520 ms spring bump as it lands.
struct BeatChip: View {
    let text: String
    let on: Bool
    var muted = false
    let action: () -> Void
    private let motion = MotionPolicy()

    var body: some View {
        let g = DX.Ground.table
        let shape = RoundedRectangle(cornerRadius: DX.Layout.chipRadius, style: .continuous)
        Button(action: action) {
            Text(verbatim: text)
                .dxFace(.body, 15, weight: on ? 700 : 600)
                .foregroundStyle(g.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(on ? g.selTint : g.card, in: shape)
                .overlay(shape.strokeBorder(on ? g.selEdge : g.line, lineWidth: on ? 2 : 1))
                .opacity(muted ? 0.45 : 1)
                .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.25), value: on)
                .phaseAnimator([1.0, 1.1, 1.0], trigger: on) { view, scale in
                    view.scaleEffect(motion.reduce || !on ? 1 : scale)
                } animation: { _ in .timingCurve(0.3, 1.4, 0.5, 1, duration: 0.26) }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(DX.Haptic.select, trigger: on)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// The routing from an activity's type to its screen.
struct BeatScreen: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void
    /// Back to the previous step, when the flow allows it. Used by a choice with nothing to choose from.
    var onBack: (() -> Void)?

    var body: some View {
        Group {
            switch beat.type {
            case .statReveal: StatRevealBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .quiz: QuizBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .choice: ChoiceBeat(beat: beat, ctx: ctx, onDone: onDone, onBack: onBack)
            case .slider: SliderBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .sliderGroup: SliderGroupBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .reflect: ReflectBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .tapReveal: TapRevealBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .planBuilder: PlanBuilderBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .checklist: ChecklistBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .breathe: BreatheBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .commit: CommitBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .scenario: ScenarioBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .note: NoteBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .info: InfoBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .share: ShareBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .nrtChoice: NRTChoiceBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .nrtStepdown: NRTStepdownBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .slipDebriefPractice: SlipPracticeBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .planCard: PlanCardBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .bodyMap: BodyMapBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .scale: ScaleBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .timedHold: TimedHoldBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .sosPractice: SOSPracticeBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .perItem: PerItemBeat(beat: beat, ctx: ctx, onDone: onDone)
            }
        }
    }
}
