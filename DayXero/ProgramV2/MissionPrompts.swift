import DayXeroCore
import SwiftData
import SwiftUI

extension Notification.Name {
    /// A use (not a slip) was just logged, from Home or the log sheet.
    static let dxUseLogged = Notification.Name("dx.useLogged")
    /// A Craving SOS session just ended.
    static let dxSOSEnded = Notification.Name("dx.sosEnded")
}

/// What today's mission asks for when the person logs (handoff 4.4): the P3 follow-up after the next use,
/// the gap after the morning moment, whether the sighs came first, a craving's peak after SOS.
/// Asked only while the mission is current, i.e. before the next session is opened. Never marked failed or missed.
struct MissionPrompts: ViewModifier {
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @State private var prompt: Prompt?

    enum Prompt: Identifiable {
        case followUp(String)
        case question(String, ProgramContent.Mission.LogType)

        var id: String {
            switch self {
            case let .followUp(session): "follow-\(session)"
            case let .question(session, type): "\(session)-\(type.rawValue)"
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .dxUseLogged)) { _ in check(afterSOS: false) }
            .onReceive(NotificationCenter.default.publisher(for: .dxSOSEnded)) { _ in check(afterSOS: true) }
            .sheet(item: $prompt) { prompt in
                switch prompt {
                case let .followUp(session):
                    FollowUpSheet(sessionId: session, profile: profile) { self.prompt = nil }
                        .presentationDetents([.large])
                case let .question(session, type):
                    MissionQuestion(sessionId: session, type: type, profile: profile) { self.prompt = nil }
                        .presentationDetents([.medium])
                }
            }
    }

    private func check(afterSOS: Bool) {
        let store = ProgramStore(context: context, profile: profile)
        guard let content = store.content else { return }
        let finished = store.records().filter { $0.completedAt != nil }
        guard let latest = finished.max(by: { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }),
              let session = content.session(latest.sessionId), let mission = session.mission, let type = mission.logType else { return }
        // Dropped quietly once the next session has been opened.
        if let next = content.session(after: session.id), store.record(next.id) != nil { return }
        switch (type, afterSOS) {
        case (.mindfulUse, false):
            let sessionId = latest.sessionId
            var descriptor = FetchDescriptor<MissionRecord>(predicate: #Predicate { $0.sessionId == sessionId })
            descriptor.fetchLimit = 1
            let record = try? context.fetch(descriptor).first
            if record?.followUpCompletedAt == nil, mission.followUp?.isEmpty == false { prompt = .followUp(session.id) }
        case (.morningBuffer, false):
            // About the first one of the day only.
            let clock = store.clock
            let today = clock.day(containing: .now)
            let uses = (try? context.fetch(FetchDescriptor<LogEntry>()))?.filter { $0.kind == .use && clock.day(containing: $0.timestamp) == today } ?? []
            if uses.count == 1 { prompt = .question(session.id, type) }
        case (.stressSigh, false), (.surfPractice, true):
            prompt = .question(session.id, type)
        default:
            break
        }
    }
}

/// P3's follow-up: its beats as a short sheet, the first time the person logs a use after the session.
struct FollowUpSheet: View {
    let sessionId: String
    let profile: UserProfile
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @State private var index = 0

    var body: some View {
        let store = ProgramStore(context: context, profile: profile)
        VStack(alignment: .leading, spacing: DX.Space.s) {
            if let session = store.content?.session(sessionId), let beats = session.mission?.followUp, beats.indices.contains(index) {
                Text("\(session.label) mission · \(index + 1) of \(beats.count)").dxText(.micro).foregroundStyle(DX.Palette.accentInk)
                    .padding(.top, DX.Space.l)
                BeatScreen(beat: beats[index],
                           ctx: BeatContext(store: store, session: session, variant: store.variant, nrtActive: store.nrtActive(),
                                            placeholders: store.placeholders(), isReplay: false)) {
                    if index + 1 < beats.count { index += 1 } else { finish(store) }
                }
                .id(index)
            }
        }
        .padding(.horizontal, DX.Space.l)
        .padding(.bottom, DX.Space.s)
        .dxCanvas()
    }

    private func finish(_ store: ProgramStore) {
        let sessionId = sessionId
        var descriptor = FetchDescriptor<MissionRecord>(predicate: #Predicate { $0.sessionId == sessionId })
        descriptor.fetchLimit = 1
        let record = (try? context.fetch(descriptor).first) ?? {
            let new = MissionRecord(sessionId: sessionId)
            context.insert(new)
            return new
        }()
        record.followUpCompletedAt = .now
        try? context.save()
        Analytics.track(.programMissionFollowupDone(sessionId: sessionId))
        onDone()
    }
}

/// One quick question for the mission's log type. The answers stay in the program's history only.
struct MissionQuestion: View {
    let sessionId: String
    let type: ProgramContent.Mission.LogType
    let profile: UserProfile
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @State private var peak = 5.0

    private var question: LocalizedStringKey {
        switch type {
        case .morningBuffer: "How long was your gap?"
        case .stressSigh: "Did you do the sighs first?"
        case .surfPractice: "How strong was it at its peak?"
        default: ""
        }
    }

    private var choices: [String] {
        switch type {
        case .morningBuffer: ["0 min", "5 min", "10 min", "15+ min"].map { String(localized: String.LocalizationValue($0)) }
        case .stressSigh: [String(localized: "Yes"), String(localized: "Not this time")]
        default: []
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.m) {
            Text("Today's mission").dxText(.micro).foregroundStyle(DX.Palette.accentInk).padding(.top, DX.Space.l)
            Text(question).font(.custom(DX.Typeface.bold, size: 24, relativeTo: .title2)).tracking(-0.4).foregroundStyle(DX.Palette.text)
            if type == .surfPractice {
                BeatSlider(value: $peak, minLabel: String(localized: "Barely there"), maxLabel: String(localized: "Overwhelming"), large: true)
                Button("Save") { save(String(Int(peak))) }.buttonStyle(.dxPrimary)
            } else {
                ForEach(choices, id: \.self) { choice in
                    Button { save(choice) } label: { OptionRow(text: choice) }.buttonStyle(.plain)
                }
            }
            Button("Not now", action: onDone).buttonStyle(.dxQuiet)
            Spacer()
        }
        .padding(.horizontal, DX.Space.l)
        .dxCanvas()
    }

    private func save(_ answer: String) {
        let store = ProgramStore(context: context, profile: profile)
        let key = "mission_\(sessionId)"
        let stamp = Date.now.formatted(.iso8601.year().month().day())
        let previous = store.answer(key)?.lines ?? []
        store.save(key, .list(previous + ["\(stamp) \(answer)"]), session: sessionId)
        onDone()
    }
}
