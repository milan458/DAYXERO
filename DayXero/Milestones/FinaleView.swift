import DayXeroCore
import SwiftData
import SwiftUI

/// F18 Finale (sun, celebration): the end of the program. The only screen with confetti. Xero, then Jelli,
/// then Glim enter in turn with Celebrate; three tiles count up, one per character; then the money and the
/// body change that's starting now, with its source. Shown inside the session flow, which pads it and sets the sun ground.
struct FinaleView: View {
    let profile: UserProfile
    /// "Day 31", the graduation session's label.
    let label: String
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \LogEntry.timestamp, order: .reverse) private var logs: [LogEntry]
    @Query private var checkIns: [CheckIn]
    @State private var entered = 0
    @State private var sharing = false

    private let ground = DX.Ground.sun

    var body: some View {
        let snap = HomeSnapshot(profile: profile, isPro: true, now: .now)
        let ridden = logs.filter { $0.kind == .craving && $0.outcome == .passed }.count
        let stats = MilestoneStats(profile: profile, logs: logs)
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    ZStack(alignment: .bottom) {
                        HeroScene(.dawn, clarity: 100, height: 300, edge: ground.background)
                        HStack(alignment: .bottom, spacing: 4) {
                            character(1) { JelliView(mood: .cheer, stage: CrewGrowth.stage(daysClear: snap.daysClear), size: .card) }
                            character(0) { XeroView(mood: .cheer, stage: CrewGrowth.stage(daysClear: snap.daysClear), size: .scene) }
                            character(2) { GlimView(mood: .cheer, stage: CrewGrowth.stage(daysClear: snap.daysClear), size: .card) }
                        }
                        .offset(y: -6)
                        .accessibilityHidden(true)
                    }
                    .overlay { Confetti().allowsHitTesting(false) }
                    .padding(.horizontal, -DX.Layout.gutter)
                    .ignoresSafeArea(edges: .top)
                    Text(verbatim: "\(label) · \(String(localized: "program complete")) · \(Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))".uppercased())
                        .dxType(.caption).foregroundStyle(ground.muted)
                    Text(snap.daysClear == 1 ? "1 day. Clear skies." : "\(snap.daysClear) days. Clear skies.")
                        .dxType(.display).foregroundStyle(ground.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    HStack(spacing: 8) {
                        tile(Double(snap.daysClear), snap.daysClear == 1 ? String(localized: "day clear · Xero") : String(localized: "days clear · Xero"))
                        tile(Double(ridden), String(localized: "waves ridden · Jelli"))
                        tile(Double(checkIns.count), String(localized: "check-ins · Glim"))
                    }
                    Text(verbatim: moneyLine(stats))
                        .dxType(.body).foregroundStyle(ground.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if let card = healthCard(now: .now) { card }
                }
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 4) {
                Button("Keep going", action: onDone).buttonStyle(.dx(.primary, on: ground))
                Button { sharing = true } label: { Label("Share my card", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.dx(.quiet, on: ground))
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .sensoryFeedback(.success, trigger: entered)
        .task {
            // Xero, then Jelli, then Glim, each with the Celebrate spring.
            for step in 1...3 {
                withAnimation(DX.Move.animation(DX.Move.celebrate, reduceMotion: reduceMotion)) { entered = step }
                try? await Task.sleep(for: .seconds(reduceMotion ? 0 : 0.45))
            }
        }
        .sheet(isPresented: $sharing) {
            ShareCardMaker(milestone: nil, stats: stats).presentationDetents([.large])
        }
    }

    private func character<V: View>(_ order: Int, @ViewBuilder _ view: () -> V) -> some View {
        view()
            .scaleEffect(entered > order || reduceMotion ? 1 : DX.Move.celebrateFromScale)
            .opacity(entered > order ? 1 : 0)
    }

    private func tile(_ value: Double, _ label: String) -> some View {
        StatTile(value: value, label: label, ground: ground)
    }

    /// "$211.45 kept and 362 cigarettes not smoked. Your reason: To keep up with Maya at the park."
    /// The reason is in their own words, so its capital stays; it just ends like a sentence.
    private func moneyLine(_ stats: MilestoneStats) -> String {
        let reason = profile.reasons.sorted { $0.createdAt < $1.createdAt }.first?.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let numbers = String(localized: "\(stats.money) kept and \(stats.counterValue) \(stats.counterLabel.lowercased()).")
        guard let reason, !reason.isEmpty else { return numbers }
        let sentence = ".!?…".contains(reason.last ?? ".") ? reason : reason + "."
        return numbers + " " + String(localized: "Your reason: \(sentence)")
    }

    /// The change starting now (or the next one), with the entry's own source label.
    private func healthCard(now: Date) -> HealthFactCard? {
        let product = profile.primaryProduct?.product ?? .cigarettes
        guard let timeline = HealthTimeline.bundled else { return nil }
        let items = timeline.items(for: product)
        let elapsed = HealthTimeline.elapsedHours(quitDay: profile.quitDay, now: now, clock: DayClock(boundaryHour: profile.dayBoundaryHour))
        let (current, next) = HealthTimeline.nowAndNext(items, elapsedHours: elapsed)
        guard let item = current ?? next else { return nil }
        return HealthFactCard(status: current != nil ? String(localized: "Starting now") : String(localized: "Next"),
                              when: item.when, title: item.title, line: "",
                              sourceLabel: timeline.source(item.source)?.label ?? "")
    }
}

/// Confetti for the finale only: the six confetti colours falling and turning. Still with Reduce Motion.
struct Confetti: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 1.2 : timeline.date.timeIntervalSince(start)
            Canvas { context, size in
                Confetti.draw(in: &context, size: size, time: t)
            }
        }
        .accessibilityHidden(true)
    }

    /// 42 pieces, each with its own column, speed and turn. They fall for about four seconds, then rest.
    nonisolated static func draw(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        let colors = DX.Fill.confetti
        for i in 0..<42 {
            let seed = Double(i)
            let x = (seed * 97).truncatingRemainder(dividingBy: 100) / 100 * size.width
            let speed = 140 + (seed * 37).truncatingRemainder(dividingBy: 90)
            let delay = (seed * 13).truncatingRemainder(dividingBy: 10) / 10 * 0.8
            let fall = max(0, min(t - delay, 4.2)) * speed
            let y = -20 + fall
            guard y < size.height + 20 else { continue }
            let sway = sin((t + seed) * 2.2) * 10
            let angle = Angle.degrees((t * 180 + seed * 40).truncatingRemainder(dividingBy: 360))
            var piece = context
            piece.translateBy(x: x + sway, y: y)
            piece.rotate(by: angle)
            piece.fill(Path(roundedRect: CGRect(x: -5, y: -3, width: 10, height: 6), cornerRadius: 1.5),
                       with: .color(colors[i % colors.count]))
        }
    }
}
