import DayXeroCore
import SwiftData
import SwiftUI

/// "I slipped" from Craving SOS (v5, 021): the paper-cut sea with Jelli half in the water, "Thanks for telling me.
/// Nothing resets.", how many days stay, then one small plan: "Next time after coffee, I'll…" with three ideas. The
/// moment is a token that opens the short list of moments. Save my plan, or Not now.
struct SOSSlipPlan: View {
    let entry: LogEntry?
    let profile: UserProfile?
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @State private var trigger: Trigger
    @State private var action: String?
    @State private var saved = false
    private let ground = DX.Ground.reading

    init(entry: LogEntry?, profile: UserProfile?, onDone: @escaping () -> Void) {
        self.entry = entry
        self.profile = profile
        self.onDone = onDone
        _trigger = State(initialValue: entry?.trigger ?? profile?.triggers.first ?? .stress)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SlipSeaCard()
                        .frame(height: 178)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .padding(.top, 6)
                        .accessibilityHidden(true)
                    Text("Thanks for telling me.\nNothing resets.")
                        .dxType(.title).foregroundStyle(ground.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 22)
                        .dxArrive(1)
                    note
                        .dxType(.body).foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                        .dxArrive(2)
                    ifThen.padding(.top, 22).dxArrive(5)
                    VStack(spacing: 10) {
                        ForEach(Array(ideas.enumerated()), id: \.element) { i, idea in
                            option(idea).dxSettle(i, delay: 0.5 + Double(i) * 0.12)
                        }
                    }
                    .padding(.top, 12)
                    .animation(DX.Move.settle, value: trigger)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    DXIconButton(.close, label: "Close", action: onDone)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .padding(.top, 8)
                .background(ground.background.ignoresSafeArea(edges: .top))
            }
            DXActionDock {
                Button { save() } label: {
                    HStack(spacing: 8) {
                        if saved { DXIcon(.check, size: 18, weight: 2.8) }
                        Text(saved ? "Plan saved" : "Save my plan")
                    }
                }
                .buttonStyle(.dx(.primary, on: .reading))
                .opacity(action == nil ? 0.45 : 1)
                .allowsHitTesting(action != nil && !saved)
                .dxArrive(8)
                Button("Not now", action: onDone)
                    .buttonStyle(.dx(.quiet, on: .reading))
                    .dxArrive(9)
            }
        }
        .background(ground.background.ignoresSafeArea())
        .dxGround(.reading)
        .sensoryFeedback(.success, trigger: saved)
    }

    /// "Your progress stays as it is, all 7 days of it."
    private var note: Text {
        let clock = DayClock(boundaryHour: profile?.dayBoundaryHour ?? 4)
        let stats = profile.map { ProgressStats(quitDay: $0.quitDay, baselines: [], clock: clock) }
        let days = stats.map { $0.isPrep(at: .now) ? 0 : $0.daysClear(at: .now) } ?? 0
        if days == 0 {
            return Text("Your prep stays as it is. One small plan makes the next wave easier.")
        }
        let bold = Text(days == 1 ? "1 day" : "\(days) days").fontWeight(.bold).foregroundColor(ground.ink)
        return Text("Your progress stays as it is, all \(bold) of it. One small plan makes the next wave easier.")
    }

    /// "Next time after [coffee ⌄], I'll…": the moment is a token that opens the list of moments.
    private var ifThen: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("Next time after")
            Menu {
                ForEach(moments, id: \.self) { t in
                    Button(String(localized: t.title)) { trigger = t; action = nil }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(verbatim: momentName(trigger))
                    DXIcon(.down, size: 14, weight: 2.6)
                }
                .foregroundStyle(ground.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(light: 0xFFE7D2, dark: 0x3A2A24), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color(light: 0xE8A07E, dark: 0x8C5A44), lineWidth: 1.5))
            }
            .accessibilityLabel(Text("Moment: \(momentName(trigger)). Change"))
            Text(", I'll…")
        }
        .dxType(.headline)
        .foregroundStyle(ground.ink)
    }

    private func option(_ idea: String) -> some View {
        let on = action == idea
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return Button { action = idea } label: {
            HStack(spacing: 12) {
                Text(verbatim: idea).dxType(.body).foregroundStyle(ground.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                DXRadio(isOn: on, ground: ground)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .background(on ? ground.selTint : ground.card, in: shape)
            .overlay(shape.strokeBorder(on ? ground.selEdge : ground.line, lineWidth: on ? 2 : 1))
            .contentShape(shape)
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: on)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    /// The person's own moments first, then the common ones; Something else last.
    private var moments: [Trigger] {
        var list = profile?.triggers.filter { $0 != .other } ?? []
        for t in [Trigger.coffee, .stress, .meals, .alcohol, .boredom] where !list.contains(t) { list.append(t) }
        return Array(list.prefix(6)) + [.other]
    }

    private var ideas: [String] {
        let all = trigger.nextTimeSuggestions.map { String(localized: $0) }.map { $0.prefix(1).uppercased() + $0.dropFirst() }
        return Array(all.filter { !$0.localizedCaseInsensitiveContains("Craving SOS") }.prefix(3))
    }

    private func momentName(_ t: Trigger) -> String {
        switch t {
        case .meals: String(localized: "a meal")
        case .other: String(localized: "this")
        default: String(localized: t.title).lowercased()
        }
    }

    private func save() {
        guard let chosen = action else { return }
        if let entry {
            entry.triggerRaw = trigger.rawValue
            entry.nextTime = chosen
            context.insert(IfThenPlan(situation: String(localized: trigger.situation), action: chosen))
            try? context.save()
        }
        saved = true
        Task {
            try? await Task.sleep(for: .seconds(0.9))
            onDone()
        }
    }
}
