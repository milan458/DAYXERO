#if DEBUG
import DayXeroCore
import SwiftUI

/// The v4 foundation, for side-by-side checks against the Design canvas.
/// `-dx.v4Gallery <page>`: v5 (components), controls, badges, sky, type, scenes, xero, jelli, glim, buttons, program;
/// anything else shows all.
/// Debug builds only.
struct V4Gallery: View {
    var page: String = "all"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                switch page {
                case "v5":
                    v5Buttons
                    v5Controls
                case "controls":
                    v5Controls
                    v5Cards
                case "badges":
                    v5Badges
                    v5Rings
                case "sky":
                    v5Sky
                case "type":
                    grounds
                    type
                case "scenes": scenes
                case "xero": crew(name: "Xero", ground: .apricot) { mood, stage, size in XeroView(mood: mood, stage: stage, size: size) }
                case "jelli": crew(name: "Jelli", ground: .ocean) { mood, stage, size in JelliView(mood: mood, stage: stage, size: size) }
                case "glim": crew(name: "Glim", ground: .violet) { mood, stage, size in GlimView(mood: mood, stage: stage, size: size) }
                case "buttons":
                    buttons
                    today
                case "program":
                    program
                    evening
                    chat
                default:
                    Text("v5 foundation").dxType(.large)
                    v5Buttons
                    v5Controls
                    v5Cards
                    v5Badges
                    v5Rings
                    v5Sky
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
            }
            .padding(DX.Layout.gutter)
        }
        .foregroundStyle(DX.Ground.reading.ink)
        .background(DX.Ground.reading.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { V4TabBar(selection: $tab, ground: .reading).padding(.bottom, 4) }
    }

    @State private var tab: V4Tab = .today
    @State private var mood: CheckInMood?
    @State private var answers: Set<String> = ["Coffee", "Stress"]
    @State private var chips: Set<String> = ["Coffee"]
    @State private var option = "Cigarettes"
    @State private var multi: Set<String> = ["Stress"]
    @State private var reminders = true
    @State private var quiet = false
    @State private var note = ""

    // MARK: v5

    private func section<Content: View>(_ title: String, on ground: DX.Ground, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: title).dxType(.headline)
            content()
        }
        .padding(DX.Layout.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dxGround(ground, paint: false)
        .background(ground.resolved == .ocean ? AnyShapeStyle(DX.Ground.oceanGradient) : AnyShapeStyle(ground.background),
                    in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius))
    }

    private var v5Buttons: some View {
        VStack(spacing: 14) {
            ForEach([DX.Ground.apricot, .reading, .ocean, .violet], id: \.self) { ground in
                section("Buttons on \(ground == .violet ? "night" : ground.rawValue)", on: ground) {
                    Button("Continue") {}.buttonStyle(.dx(.primary, on: ground))
                    Button("Not now") {}.buttonStyle(.dx(.ghost, on: ground))
                    HStack {
                        Button { } label: { Label { Text("Start") } icon: { DXIcon(.play, size: 16, weight: 1.5, filled: true) } }
                            .buttonStyle(.dx(.small, on: ground))
                        Spacer()
                        Button("Skip for now") {}.buttonStyle(.dx(.quiet, on: ground))
                    }
                    Button("Disabled") {}.buttonStyle(.dx(.primary, on: ground)).disabled(true)
                }
            }
            section("Hold to commit", on: .apricot) {
                HoldButton("Hold to set Quit Day", done: "Quit Day set", duration: DX.Move.hold, on: .apricot) {}
            }
        }
    }

    private var v5Controls: some View {
        VStack(spacing: 14) {
            ForEach([DX.Ground.reading, .apricot, .violet], id: \.self) { ground in
                section("Choices on \(ground == .violet ? "night" : ground.rawValue)", on: ground) {
                    DXFlowLayout(spacing: 8) {
                        ForEach(["Coffee", "Stress", "After meals", "Driving"], id: \.self) { c in
                            DXChip(verbatim: c, isOn: chips.contains(c)) {
                                if chips.contains(c) { chips.remove(c) } else { chips.insert(c) }
                            }
                        }
                    }
                    ForEach(["Cigarettes", "Vape"], id: \.self) { o in
                        DXOptionRow(Text(verbatim: o), detail: Text(verbatim: o == "Vape" ? "Disposable or refillable" : "12 a day"),
                                    isOn: option == o) { option = o }
                    }
                    DXOptionRow(Text(verbatim: "Stress"), isOn: multi.contains("Stress"), multi: true) {
                        if multi.contains("Stress") { multi.remove("Stress") } else { multi.insert("Stress") }
                    }
                    Toggle(isOn: $reminders) { Text(verbatim: "Morning reminder").dxType(.body) }.toggleStyle(.dx)
                    Toggle(isOn: $quiet) { Text(verbatim: "Quiet hours").dxType(.body) }.toggleStyle(.dx)
                    TextField(text: $note, prompt: Text(verbatim: "What helped?")) { Text(verbatim: "Note") }.textFieldStyle(.dx)
                }
            }
        }
    }

    private var v5Cards: some View {
        VStack(spacing: 14) {
            ForEach([DX.Ground.reading, .apricot, .mint], id: \.self) { ground in
                section("Cards on \(ground.rawValue)", on: ground) {
                    DXNavRow("Settings") {}
                    DXProgress(0.4, sun: true).padding(.horizontal, 8)
                    DXSteps(count: 5, current: 2)
                    DXCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: "Prep 4 · 5 cards · 28 min").dxType(.footnote).foregroundStyle(ground.muted)
                            Text(verbatim: "The stress loop").dxType(.headline)
                        }
                    }
                    DXCard(flat: true) { Text(verbatim: "A flat card on card-2").dxType(.body) }
                    DXList {
                        DXRow(Text(verbatim: "Log today's cigarettes"), detail: Text(verbatim: "Tonight · 1 min"), icon: .note)
                        DXRow(Text(verbatim: "Wind-down breath"), detail: Text(verbatim: "10 PM · 3 min"), icon: .leaf)
                    }
                    HStack(spacing: 10) {
                        StatTile(value: 49, label: "kept", ground: ground) { "$" + String(Int($0)) }
                        StatTile(value: 84, label: "not smoked", ground: ground)
                    }
                    DXToast(Text(verbatim: "Reminder saved")) { DXCheck(size: 24, delay: 0.3) }
                }
            }
        }
    }

    private var v5Badges: some View {
        VStack(spacing: 14) {
            ForEach([DX.Ground.reading, .apricot, .violet], id: \.self) { ground in
                section("Badges on \(ground == .violet ? "night" : ground.rawValue)", on: ground) {
                    HStack(spacing: 12) {
                        DXBadge(.prep, n: 3, size: 56, label: "Prep 3")
                        DXBadge(.xero, size: 56, label: "Day Xero")
                        DXBadge(.day, n: 7, size: 56, label: "7 days")
                        DXBadge(.wave, n: 25, size: 56, label: "25 waves")
                    }
                    HStack(spacing: 12) {
                        DXBadge(.night, n: 7, size: 56, label: "7 nights")
                        DXBadge(.day, n: 14, state: .next(0.5), size: 56, label: "14 days")
                        DXBadge(.xero, state: .next(nil), size: 56, label: "Day Xero")
                        DXBadge(.day, n: 365, state: .locked, size: 56, label: "1 year")
                    }
                }
            }
        }
    }

    private var v5Rings: some View {
        section("Ring, check, motion", on: .reading) {
            HStack(spacing: 18) {
                DXRing(p: 0.5, size: 96, stroke: 10, color: Color(hex: 0xE8603F), dot: true)
                DXCheck(size: 72)
                DXBadge(.day, n: 7, size: 72).dxStamp(delay: 0.4).dxShine(delay: 1.2)
                ZStack {
                    XeroView(mood: .cheer, stage: 2, size: .avatar).dxBob()
                    DXFloatUp("+1", trigger: 0).offset(y: -30)
                }
            }
            HStack(spacing: 12) {
                CountingText(49, prefix: "$", decimals: 2).dxFace(.display, 28, weight: 800)
                CountingText(4, from: 7, delay: 0.6).dxFace(.display, 28, weight: 800)
            }
        }
    }

    private var v5Sky: some View {
        VStack(spacing: 14) {
            section("Night sky (night ground)", on: .violet) {
                NightSky().frame(height: 300).clipShape(RoundedRectangle(cornerRadius: 18))
                NightSky(dawn: true).frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 18))
            }
            section("Horizon dawn (dark: pre-dawn sky)", on: .apricot) {
                HorizonScene(.dawn, clarity: 85).frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 18))
                XeroView(mood: .cheer, stage: 2, size: .card)
            }
        }
    }

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
            HoldButton("Hold to start Day Xero", done: "Day Xero started", duration: DX.Move.hold, on: .apricot) {}
                .padding(16).background(DX.Ground.apricot.background, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius))
        }
    }

    private var today: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today").dxType(.headline)
            TopCard(kicker: "Week 1 · Day 2", title: "The noisy passengers", detail: "Let them talk. Keep driving.", ground: .apricot) {}
            HStack(spacing: 8) {
                StatTile(value: 3, label: "days since Quit Day", ground: .apricot)
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
            // Card size, so the growth differences (S27.16) can be judged in the CI screenshots.
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(zip(1...4, ["Day 1–6", "7–13", "14–27", "28+"])), id: \.0) { stage, days in
                    VStack(spacing: 2) {
                        make(.hello, stage, .card)
                        Text(verbatim: days).dxType(.caption).foregroundStyle(ground.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
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
