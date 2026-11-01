import DayXeroCore
import SwiftData
import SwiftUI

/// F09 Pledge (apricot): Xero at dawn, "Today, I won't use nicotine.", one of your reasons, and a
/// one-second hold. Optional, and it never changes days clear (S11.1). In prep week, when the plan is to use as
/// normal, it pledges to the prep instead and the wording chips are hidden (S27.5).
struct PledgeView: View {
    let profile: UserProfile
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// "Won't use nicotine" or "One wave at a time"; remembered for tomorrow.
    @AppStorage("dx.pledgeWording") private var wording = Wording.wontUse.rawValue
    @State private var pledged = false
    @State private var risen = false

    private let ground = DX.Ground.apricot

    enum Wording: String, CaseIterable {
        case wontUse, oneWave

        var chip: String {
            switch self {
            case .wontUse: String(localized: "Won't use nicotine")
            case .oneWave: String(localized: "One wave at a time")
            }
        }

        var headline: String {
            switch self {
            case .wontUse: String(localized: "Today, I won't use nicotine.")
            case .oneWave: String(localized: "Today, I'll take it one wave at a time.")
            }
        }
    }

    /// Prep week: nobody is asked to stop before Quit Day.
    static let prepHeadline = String(localized: "Today, I'll notice my cravings and get ready.")

    var body: some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: clock)
        let day = clock.days(fromDate: profile.quitDay, to: .now) + 1
        // The same days clear as Today: Quit Day is 1, prep is 0.
        let daysClear = stats.daysClear(at: .now)
        let chosen = Wording(rawValue: wording) ?? .wontUse
        let prep = stats.isPrep(at: .now)
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                HeroScene(.dawn, clarity: stats.isPrep(at: .now) ? CrewGrowth.prepClarity : CrewGrowth.clarity(daysClear: daysClear),
                          height: 330, edge: ground.background)
                XeroView(mood: pledged ? .cheer : .hello, stage: CrewGrowth.stage(daysClear: daysClear), size: .hero)
                    .offset(y: risen || reduceMotion ? -10 : 40)
                    .opacity(risen ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .topTrailing) {
                Button(action: onDone) {
                    Image(systemName: "xmark").font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DX.Fill.navy)
                        .frame(width: 44, height: 44)
                        .background(DX.Fill.cream.opacity(0.85), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Close"))
                .padding(.trailing, 10)
                .padding(.top, 50)
            }
            .ignoresSafeArea(edges: .top)
            ScrollView {
                VStack(spacing: 10) {
                    Text(verbatim: dayLine(day, clock: clock))
                        .dxFont(14, weight: 700, style: .footnote)
                        .foregroundStyle(ground.muted)
                        .dxArrive(4)
                    Text(verbatim: prep ? Self.prepHeadline : chosen.headline)
                        .dxType(.large)
                        .foregroundStyle(ground.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                        .accessibilityAddTraits(.isHeader)
                        .dxArrive(5)
                    if !prep {
                        HStack(spacing: 6) {
                            ForEach(Wording.allCases, id: \.self) { w in
                                V4Chip(text: w.chip, isOn: chosen == w, fill: DX.Fill.onColourCard(for: ground), ink: ground.ink,
                                       selectedFill: ground.ink, selectedInk: ground.background) {
                                    withAnimation(DX.Move.animation(.easeInOut(duration: 0.25), reduceMotion: reduceMotion)) { wording = w.rawValue }
                                }
                            }
                        }
                        .disabled(pledged)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(Text("Pledge wording"))
                        .dxArrive(6)
                    }
                    if let reason = todaysReason(dayNumber: day) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BECAUSE").dxType(.caption).foregroundStyle(ground.muted)
                            Text(verbatim: reason.text)
                                .dxFont(19, weight: 700, style: .headline)
                                .foregroundStyle(ground.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .accessibilityElement(children: .combine)
                        .padding(.top, 6)
                        .dxArrive(7)
                    }
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, 6)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 8) {
                HoldButton(String(localized: "Hold to pledge"), done: String(localized: "Pledged for today"),
                           duration: DX.Move.Hold.pledge, on: ground, action: pledge)
                    .accessibilityLabel(Text("Pledge for today. Hold for one second, or double-tap with VoiceOver."))
                if let line = checkInLine {
                    Text(verbatim: line)
                        .dxType(.footnote)
                        .foregroundStyle(ground.muted)
                        .multilineTextAlignment(.center)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, DX.Layout.buttonGutter)
            .padding(.bottom, DX.Space.xs)
            .dxArrive(8)
        }
        .dxReadableColumn()
        .background(ground.background.ignoresSafeArea())
        .sensoryFeedback(DX.Haptic.commit, trigger: pledged)
        .onAppear {
            withAnimation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion)) { risen = true }
        }
    }

    /// "Sunday · Day 3", or the weekday alone before Quit Day. The weekday follows the day boundary: 1am is still last night.
    private func dayLine(_ day: Int, clock: DayClock) -> String {
        let weekday = DailyRhythm(clock: clock).day(at: .now).formatted(.dateTime.weekday(.wide))
        return day > 0 ? String(localized: "\(weekday) · Day \(day)") : weekday
    }

    /// "Glim will check in tonight at 9:00 PM. No pressure." Only when the check-in reminder is on.
    private var checkInLine: String? {
        guard let minute = DailyReminderSettings.checkInMinute,
              let time = Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: .now) else { return nil }
        return String(localized: "Glim will check in tonight at \(time.formatted(date: .omitted, time: .shortened)). No pressure.")
    }

    private func todaysReason(dayNumber: Int) -> Reason? {
        let reasons = profile.reasons.sorted { $0.createdAt < $1.createdAt }
        return DailyRhythm.reasonIndex(hasPhoto: reasons.map { $0.photo != nil }, dayNumber: dayNumber).map { reasons[$0] }
    }

    private func pledge() {
        guard !pledged else { return }
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        context.insert(Pledge(day: clock.day(containing: .now)))
        try? context.save()
        pledged = true
        DailyReminders.refresh(in: context)
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            onDone()
        }
    }
}
