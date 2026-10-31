#if DEBUG
import DayXeroCore
import SwiftUI

/// The v4 foundation on one scrolling page: grounds, type steps and the crew in every
/// mood and stage, for side-by-side checks against the Design canvas
/// (`-dx.v4Gallery YES`). Debug builds only.
struct V4Gallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("v4 foundation").dxType(.large)
                scenes
                grounds
                type
                crew(name: "Xero", ground: .apricot) { mood, stage, size in XeroView(mood: mood, stage: stage, size: size) }
                crew(name: "Jelli", ground: .ocean) { mood, stage, size in JelliView(mood: mood, stage: stage, size: size) }
                crew(name: "Glim", ground: .violet) { mood, stage, size in GlimView(mood: mood, stage: stage, size: size) }
                buttons
                today
                program
                evening
                chat
            }
            .padding(DX.Layout.gutter)
        }
        .foregroundStyle(DX.Ground.reading.ink)
        .background(DX.Ground.reading.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { V4TabBar(selection: $tab) }
    }

    @State private var tab: V4Tab = .today
    @State private var mood: CheckInMood?
    @State private var answers: Set<String> = ["Coffee", "Stress"]

    // Persona: Sam, Quit Day Fri 6 Nov 2026, mock today Sun 8 Nov at 09:40 (decision 17 values).

    private var scenes: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scenes").dxType(.headline)
            // Quit Day hero: dawn at clarity 23 (1 day clear), apricot edge.
            HeroScene(.dawn, clarity: CrewGrowth.clarity(daysClear: 1), height: 260, edge: DX.Ground.apricot.background)
                .overlay(alignment: .bottom) { XeroView(mood: .hello, stage: 1, size: .scene).offset(y: -20) }
                .clipShape(RoundedRectangle(cornerRadius: DX.Layout.cardRadius))
            ForEach(HorizonKind.allCases, id: \.self) { kind in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(kind.rawValue.capitalized) · clarity 28 and 100").dxType(.caption).dxInk(.reading, muted: true)
                    HStack(spacing: 8) {
                        HorizonScene(kind, clarity: 28).frame(height: 120)
                        HorizonScene(kind, clarity: 100).frame(height: 120)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius))
                }
            }
        }
    }

    private var buttons: some View {
        VStack(spacing: 14) {
            Text("Buttons").dxType(.headline).frame(maxWidth: .infinity, alignment: .leading)
            Button("Begin") {}.buttonStyle(.dx(.primary, on: .apricot))
                .padding(16).background(DX.Ground.apricot.background, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius))
            VStack(spacing: 10) {
                Button("It passed") {}.buttonStyle(.dx(.primary, on: .ocean))
                Button("I slipped") {}.buttonStyle(.dx(.secondary, on: .ocean))
                HandOverChip("Xero passed you to Jelli") { JelliView(mood: .hello, stage: 1, size: .avatar, animate: false) }
                    .dxInk(.ocean)
            }
            .padding(16).background(DX.Ground.ocean.background, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius))
            HoldButton("Hold to start Day Xero", done: "Day Xero started ✓", duration: DX.Move.Hold.dayXeroCommit, on: .apricot) {}
                .padding(16).background(DX.Ground.apricot.background, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius))
        }
    }

    private var today: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today").dxType(.headline)
            TopCard(kicker: "Week 1 · Day 2", title: "The noisy passengers", detail: "Let them talk. Keep driving.", ground: .apricot) {}
            HStack(spacing: 8) {
                StatTile(value: 3, label: "days clear", ground: .apricot)
                StatTile(value: 26, label: "not smoked", ground: .apricot)
                StatTile(value: 15.65, label: "kept", ground: .apricot) { String(format: "$%.2f", $0) }
            }
            .padding(12)
            .background(DX.Ground.apricot.background, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius))
            HealthFactCard(status: "Happening now", when: "A few days", title: "Carbon monoxide in your blood drops to normal",
                           line: "More oxygen reaches your body.", sourceLabel: "Source: American Cancer Society")
            NotificationPreview(sender: "Glim", time: "now", message: "How did today go? A one-minute check-in, if you have it.") {
                GlimView(mood: .hello, stage: 1, size: .avatar, animate: false).background(DX.Ground.violet.background)
            }
        }
    }

    private var program: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Program").dxType(.headline)
            ProgramDayCard(kicker: "Week 1 · Day 1", title: "Look after the basics", state: .done)
            ProgramDayCard(kicker: "Week 1 · Day 2", title: "The noisy passengers", state: .today)
            ProgramDayCard(kicker: "Week 1 · Day 3", title: "Lower the bar", state: .locked)
            ProgramDayCard(kicker: "Sun 6 Dec", title: "Graduation", state: .graduation)
        }
    }

    private var evening: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Evening").dxType(.headline).dxInk(.violet)
            MoodPicker(selection: $mood)
            BreathingWords().dxInk(.violet).frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(DX.Ground.violet.background, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius))
    }

    private var chat: some View {
        VStack(spacing: 12) {
            TypingDots().frame(maxWidth: .infinity, alignment: .leading)
            ReplyBubble("Coffee and stress", onEdit: {})
            PlanStepRow(kicker: "Quit Day", value: "Fri 6 Nov", index: 0, ground: .lilac)
            AnswerTray(options: ["Waking up", "Coffee", "After meals", "Stress", "Drinking", "Boredom"],
                       selection: $answers, multiple: true, step: 2, of: 3, onMore: {}) {}
        }
        .padding(16)
        .background(DX.Ground.lilac.background, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius))
    }

    private var grounds: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grounds").dxType(.headline)
            ForEach(DX.Ground.allCases, id: \.self) { ground in
                HStack {
                    Text(ground.rawValue.capitalized).dxType(.headline).foregroundStyle(ground.ink)
                    Spacer()
                    Text("Muted text").dxType(.footnote).foregroundStyle(ground.muted)
                }
                .padding(16)
                .background(ground.background, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius))
            }
        }
    }

    private var type: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type steps").dxType(.headline)
            ForEach(DX.TypeStep.allCases, id: \.self) { step in
                Text("\(step.rawValue.capitalized) \(Int(step.size))").dxType(step)
            }
        }
    }

    private func crew<Art: View>(name: String, ground: DX.Ground,
                                       @ViewBuilder make: @escaping (CrewMood, Int, DX.CharacterSize) -> Art) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name).dxType(.title).foregroundStyle(ground.ink)
            Text("Moods").dxType(.caption).foregroundStyle(ground.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CrewMood.allCases, id: \.self) { mood in
                        VStack(spacing: 4) {
                            make(mood, 2, .card)
                            Text(mood.rawValue).dxType(.caption).foregroundStyle(ground.muted)
                        }
                    }
                }
            }
            Text("Stages 1 to 4").dxType(.caption).foregroundStyle(ground.muted)
            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { stage in make(.hello, stage, .avatar) }
            }
            Text("Hero").dxType(.caption).foregroundStyle(ground.muted)
            make(.hello, 1, .hero).frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(ground.background, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius))
    }
}

#Preview { V4Gallery() }
#endif
