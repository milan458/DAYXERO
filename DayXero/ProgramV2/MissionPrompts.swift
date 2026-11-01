import DayXeroCore
import SwiftData
import SwiftUI

extension Notification.Name {
    /// A use (not a slip) was just logged, from Home or the log sheet.
    static let dxUseLogged = Notification.Name("dx.useLogged")
    /// A Craving SOS session just ended.
    static let dxSOSEnded = Notification.Name("dx.sosEnded")
    /// A program session was closed; Home checks for a milestone to celebrate (Day Xero starts the counter).
    static let dxSessionClosed = Notification.Name("dx.sessionClosed")
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
                        .presentationDragIndicator(.visible)
                case let .question(session, type):
                    MissionQuestion(sessionId: session, type: type, profile: profile) { self.prompt = nil }
                        // The morning gap's four choices and "Not now" don't fit in half a screen.
                        .presentationDetents([type == .morningBuffer ? .large : .medium])
                        .presentationDragIndicator(.visible)
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
                Text("\(session.label) mission · \(index + 1) of \(beats.count)").v4Text(.micro).foregroundStyle(Read4.accent)
                    .padding(.top, DX.Space.l)
                // The mission in one line, so the sheet makes sense on its own (S27.14).
                if let mission = session.mission {
                    Text(verbatim: missionLine(mission, store: store)).v4Text(.subtitle).lineLimit(2)
                }
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
        .background(Read4.background.ignoresSafeArea())
    }

    private func missionLine(_ mission: ProgramContent.Mission, store: ProgramStore) -> String {
        store.placeholders().fillDropping(mission.text.resolve(store.variant) ?? "")
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
    /// After saving, the person's own numbers so far (S27.18). nil while asking.
    @State private var trend: MissionTrend.Summary?

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
        let store = ProgramStore(context: context, profile: profile)
        VStack(alignment: .leading, spacing: DX.Space.m) {
            Text("Today's mission").v4Text(.micro).foregroundStyle(Read4.accent).padding(.top, DX.Space.l)
            // The mission in one line, so the question makes sense on its own (S27.14).
            if let mission = store.content?.session(sessionId)?.mission {
                Text(verbatim: store.placeholders().fillDropping(mission.text.resolve(store.variant) ?? "")).v4Text(.subtitle).lineLimit(2)
            }
            if let trend {
                trendView(trend)
            } else {
                Text(question).dxFont(24, weight: 700, style: .title2).foregroundStyle(Read4.ink)
                if type == .surfPractice {
                    BeatSlider(value: $peak, minLabel: String(localized: "Barely there"), maxLabel: String(localized: "Overwhelming"), large: true)
                    Button("Save") { save(String(Int(peak))) }.buttonStyle(.dx(.primary, on: .reading))
                } else {
                    ForEach(choices, id: \.self) { choice in
                        Button { save(choice) } label: { OptionRow(text: choice) }.buttonStyle(.plain)
                    }
                }
                Button("Not now", action: onDone).buttonStyle(.dx(.quiet, on: .reading))
            }
            Spacer()
        }
        .padding(.horizontal, DX.Space.l)
        .background(Read4.background.ignoresSafeArea())
    }

    private func save(_ answer: String) {
        let store = ProgramStore(context: context, profile: profile)
        let key = "mission_\(sessionId)"
        let stamp = Date.now.formatted(.iso8601.year().month().day())
        let previous = store.answer(key)?.lines ?? []
        let lines = previous + ["\(stamp) \(answer)"]
        store.save(key, .list(lines), session: sessionId)
        // Peaks and morning gaps show the person's own numbers back once there are two to compare (S27.18).
        if type == .surfPractice || type == .morningBuffer, let summary = MissionTrend.summary(of: lines), summary.values.count >= 2 {
            withAnimation(DX.Move.settle) { trend = summary }
        } else {
            onDone()
        }
    }

    /// "Your peaks so far: 8 → 6 → 4 out of 10", with a line only when the numbers say so.
    private func trendView(_ summary: MissionTrend.Summary) -> some View {
        let peaks = type == .surfPractice
        let series = summary.values.map { peaks ? "\($0)" : ($0 >= 15 ? "15+" : "\($0)") }.joined(separator: " → ")
        return VStack(alignment: .leading, spacing: DX.Space.s) {
            Text("Saved").dxFont(24, weight: 700, style: .title2).foregroundStyle(Read4.ink).accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 6) {
                Text(peaks ? LocalizedStringKey("Your peaks so far") : LocalizedStringKey("Your morning gaps so far")).v4Text(.micro)
                Text(verbatim: peaks ? String(localized: "\(series) out of 10") : String(localized: "\(series) min"))
                    .dxFont(22, weight: 700, style: .title3).foregroundStyle(Read4.ink)
                    .accessibilityLabel(Text(verbatim: series.replacingOccurrences(of: "→", with: ",")))
                if peaks, summary.falling {
                    Text("Each one lower than the last.").v4Text(.subtitle)
                } else if !peaks, summary.latestIsBest {
                    Text("Your longest gap yet: \(summary.best >= 15 ? "15+" : "\(summary.best)") minutes after waking.").v4Text(.subtitle)
                }
            }
            .padding(DX.Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Read4.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Read4.hairline))
            Button("Done", action: onDone).buttonStyle(.dx(.primary, on: .reading))
        }
    }
}
