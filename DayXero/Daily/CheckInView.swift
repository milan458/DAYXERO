import DayXeroCore
import SwiftData
import SwiftUI

/// The evening check-in (S11.2): how today went, cravings and mood. About a minute; never changes days clear.
struct CheckInView: View {
    let profile: UserProfile
    let onDone: () -> Void

    enum Stage {
        case form, slip, done
    }

    @Environment(\.modelContext) private var context
    @Query(sort: \LogEntry.timestamp, order: .reverse) private var logs: [LogEntry]
    @Query private var checkIns: [CheckIn]
    @State private var stage = Stage.form
    @State private var clearDay = true
    @State private var mindful = true
    @State private var cravings: Int?
    @State private var mood: Mood?
    @State private var note = ""
    @State private var slipEntry: LogEntry?
    @State private var showDayEnd = false
    @State private var saved = false

    var body: some View {
        Group {
            switch stage {
            case .form: form
            case .slip: SlipFlow(entry: slipEntry, profile: profile, startInTalkThrough: true) { stage = .done }
            case .done: done
            }
        }
        .dxCanvas()
        .sensoryFeedback(DX.Haptic.commit, trigger: saved)
        .sheet(isPresented: $showDayEnd) {
            DayEndSettings(profile: profile).presentationDetents([.large])
        }
        .onAppear {
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "dx.checkInDone") { stage = .done }
            #endif
        }
    }

    // MARK: Form

    private var form: some View {
        let today = todaysLogs
        let logged = today.filter { $0.kind == .craving }
        let ridden = logged.filter { $0.outcome == .passed }.count
        return VStack(spacing: DX.Space.xs) {
            HStack {
                Button(action: onDone) { Image(systemName: "xmark") }.buttonStyle(.dxIcon).accessibilityLabel(Text("Close"))
                Spacer()
                Text("\(Date.now.formatted(.dateTime.weekday(.wide))) check-in").dxText(.micro)
                Spacer()
                Color.clear.frame(width: DX.Size.iconButton, height: 1)
            }
            .padding(.top, DX.Space.s)
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    if prep {
                        prepHeader
                    } else {
                        Text("How did today go?").dxText(.title)
                        HStack(spacing: DX.Space.xs) {
                            dayOption(true, title: "Clear day", detail: "no nicotine")
                            dayOption(false, title: "Had a slip", detail: "it happens")
                        }
                        .padding(.top, DX.Space.xs)
                    }
                    if !prep, !clearDay {
                        Text(today.contains { $0.kind == .slip }
                             ? "You've already logged it. Nothing resets."
                             : "We'll help you log it after this. Nothing resets.")
                            .dxText(.subtitle)
                    }
                    if prep { usedToday(today) }
                    Text("Cravings today").dxText(.micro).padding(.top, DX.Space.s)
                    let count = cravings ?? logged.count
                    HStack {
                        Button { cravings = max(count - 1, 0) } label: { Image(systemName: "minus") }
                            .buttonStyle(.dxIcon).accessibilityLabel(Text("Fewer"))
                        Spacer()
                        VStack(spacing: 0) {
                            Text(verbatim: count.formatted()).font(.custom(DX.Typeface.bold, size: 26, relativeTo: .title)).foregroundStyle(DX.Palette.text)
                            if !logged.isEmpty {
                                Text("\(logged.count) logged, \(ridden) ridden out").dxText(.subtitle)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        Spacer()
                        Button { cravings = count + 1 } label: { Image(systemName: "plus") }
                            .buttonStyle(.dxIcon).accessibilityLabel(Text("More"))
                    }
                    .padding(DX.Space.xs)
                    .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(DX.Palette.hairline))
                    Text("Mood").dxText(.micro).padding(.top, DX.Space.s)
                    HStack(spacing: 6) {
                        ForEach(Mood.allCases, id: \.self) { m in moodButton(m) }
                    }
                    Text("Anything to remember? \(Text("· optional").foregroundStyle(DX.Palette.faint))").dxText(.micro).padding(.top, DX.Space.s)
                    TextField("", text: $note, prompt: Text(prep ? "My 4 pm one didn't really help the stress" : "Busy day at work, coffee was hard").foregroundStyle(DX.Palette.faint), axis: .vertical)
                        .lineLimit(2...4)
                        .font(DX.TextStyle.subtitle.font)
                        .padding(DX.Space.s)
                        .background(DX.Palette.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    Button { showDayEnd = true } label: {
                        Text("Your day ends at \(DayEndSettings.label(profile.dayBoundaryHour)) · change")
                            .font(DX.TextStyle.subtitle.font).underline().foregroundStyle(DX.Palette.text2)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, DX.Space.xs)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            Button(prep ? "Save prep day \(prepDay) check-in" : "Save") {
                save(defaultCount: logged.count, slipLogged: today.contains { $0.kind == .slip })
            }
                .buttonStyle(.dxPrimary)
                .disabled(mood == nil)
        }
        .padding(.horizontal, DX.Space.m)
        .padding(.bottom, DX.Space.xs)
    }

    // MARK: Prep week (before Quit Day using is part of the plan, so there's no "clear day" or "slip")

    private var stats: ProgressStats {
        ProgressStats(quitDay: profile.quitDay, baselines: [], clock: DayClock(boundaryHour: profile.dayBoundaryHour))
    }

    private var prep: Bool { stats.isPrep(at: .now) }

    private var prepDay: Int {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        return max(clock.days(fromDate: profile.createdAt, to: .now) + 1, 1)
    }

    private var prepHeader: some View {
        let left = stats.daysUntilQuitDay(at: .now)
        return VStack(alignment: .leading, spacing: DX.Space.xs) {
            Text("Prep day \(prepDay) check-in · \(left) days to Quit Day").dxText(.micro)
            Text("How did your prep go today?").dxText(.title)
            Text("Using normally is part of prep week. No guilt, just noticing.").dxText(.subtitle)
            HStack(spacing: DX.Space.xs) {
                prepOption(true, title: "Mindful & observant", detail: "Noticed my triggers")
                prepOption(false, title: "Mostly autopilot", detail: "Busy day, that's fine")
            }
            .padding(.top, DX.Space.xs)
        }
    }

    private func prepOption(_ value: Bool, title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        let on = mindful == value
        return Button { mindful = value } label: {
            VStack(spacing: 2) {
                Text(title).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                    .multilineTextAlignment(.center)
                Text(detail).dxText(.subtitle).multilineTextAlignment(.center)
            }
            .padding(.horizontal, DX.Space.xs)
            .padding(.vertical, DX.Space.xs)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(on ? DX.Palette.accentSoft : DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(on ? DX.Palette.accentInk : DX.Palette.hairline, lineWidth: on ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    /// What was used today, per product, with steppers for anything not logged at the time.
    private func usedToday(_ today: [LogEntry]) -> some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            Text("Logged today").dxText(.micro).padding(.top, DX.Space.s)
            ForEach(profile.products.map(\.product), id: \.self) { product in
                let uses = today.filter { $0.kind != .craving && $0.product == product }
                HStack {
                    Text(verbatim: String(localized: product.unit).localizedCapitalized)
                        .font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                    Spacer()
                    Button {
                        if let last = uses.first { UseLog.undo(last, in: context) }
                    } label: { Image(systemName: "minus") }
                        .buttonStyle(.dxIcon).disabled(uses.isEmpty).accessibilityLabel(Text("One fewer"))
                    Text(verbatim: uses.count.formatted())
                        .font(.custom(DX.Typeface.bold, size: 20, relativeTo: .title3)).foregroundStyle(DX.Palette.text)
                        .frame(minWidth: 36)
                    Button { UseLog.log(product, in: context) } label: { Image(systemName: "plus") }
                        .buttonStyle(.dxIcon).accessibilityLabel(Text("One more"))
                }
                .padding(.horizontal, DX.Space.s).padding(.vertical, 6)
                .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(DX.Palette.hairline))
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text("\(uses.count) \(Text(product.unit)) today"))
            }
        }
    }

    private func dayOption(_ value: Bool, title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        let on = clearDay == value
        return Button { clearDay = value } label: {
            VStack(spacing: 2) {
                Text(title).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                Text(detail).dxText(.subtitle)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(on ? DX.Palette.accentInk : DX.Palette.hairline, lineWidth: on ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func moodButton(_ m: Mood) -> some View {
        let on = mood == m
        return Button { mood = m } label: {
            VStack(spacing: 4) {
                Circle().fill(on ? DX.Palette.sage : DX.Palette.track).frame(width: 22, height: 22)
                Text(m.title).font(.custom(DX.Typeface.medium, size: 11, relativeTo: .caption2))
                    .foregroundStyle(on ? DX.Palette.text : DX.Palette.text2)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DX.Space.xs)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(on ? DX.Palette.accentInk : DX.Palette.hairline, lineWidth: on ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(m.title))
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: Done

    private var done: some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let rhythm = DailyRhythm(clock: clock)
        let week = rhythm.weekCheckIns(checkIns.map(\.day), at: .now)
        let day = clock.days(fromDate: profile.quitDay, to: .now) + 1
        let letters = HeatMap.weekdayLetters
        return VStack(spacing: DX.Space.s) {
            Spacer()
            Image(systemName: "moon").font(.system(size: 30)).foregroundStyle(DX.Palette.accentInk)
                .frame(width: 76, height: 76).background(DX.Palette.accentSoft, in: Circle())
                .accessibilityHidden(true)
            Text(day > 0 ? "Day \(day), done" : prep ? "Prep day \(prepDay), done" : "Check-in saved").dxText(.title)
            Text("Rest well. Tomorrow's pledge will be here in the morning.").dxText(.subtitle).multilineTextAlignment(.center)
            DXCard(padding: 14) {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    Text("This week's check-ins").dxText(.micro)
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { i in
                            VStack(spacing: 4) {
                                Text(verbatim: letters[i]).dxText(.subtitle)
                                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(week.indices.contains(i) && week[i] ? DX.Palette.onAccent : .clear)
                                    .frame(width: 26, height: 26)
                                    .background(week.indices.contains(i) && week[i] ? DX.Palette.sage : DX.Palette.track, in: Circle())
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("\(week.filter { $0 }.count) check-ins this week"))
                }
            }
            .padding(.top, DX.Space.s)
            Spacer()
            Button("Done", action: onDone).buttonStyle(.dxPrimary)
        }
        .padding(.horizontal, DX.Space.m)
        .padding(.bottom, DX.Space.xs)
    }

    // MARK: Data

    private var todaysLogs: [LogEntry] {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let today = clock.day(containing: .now)
        return logs.prefix(200).filter { clock.day(containing: $0.timestamp) == today }
    }

    private func save(defaultCount: Int, slipLogged: Bool) {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let prep = prep
        context.insert(CheckIn(day: clock.day(containing: .now), mood: mood ?? .okay, cravingCount: cravings ?? defaultCount,
                               note: note.isEmpty ? nil : note, clearDay: prep ? true : clearDay,
                               prepMindful: prep ? mindful : nil))
        try? context.save()
        saved.toggle()
        DailyReminders.refresh(in: context)
        // "Had a slip" with nothing logged today: log it and open the talk-through (S8).
        if !prep, !clearDay, !slipLogged, let product = profile.primaryProduct?.product {
            slipEntry = UseLog.log(product, in: context)
            Analytics.track(.slipLogged(source: "checkin"))
            stage = .slip
        } else {
            stage = .done
        }
    }
}

/// When "today" ends (S11.3). Days clear, lessons and check-ins all follow it.
struct DayEndSettings: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            Text("When does your day end?").dxText(.title).padding(.top, DX.Space.xl)
            Text("Up late? A check-in before this time still counts for the day you've just had.").dxText(.subtitle)
                .padding(.bottom, DX.Space.s)
            ForEach(DailyRhythm.boundaryChoices, id: \.self) { hour in
                DXOptionCard(LocalizedStringResource(stringLiteral: Self.label(hour)),
                             detail: hour == 4 ? "Default" : hour == 6 ? "For night shifts and late finishes" : nil,
                             isSelected: profile.dayBoundaryHour == hour) {
                    profile.dayBoundaryHour = hour
                    try? context.save()
                    DailyReminders.refresh(in: context)
                }
            }
            Spacer()
            Text("Days clear, lessons and check-ins all follow this.").dxText(.subtitle).frame(maxWidth: .infinity)
            Button("Done") { dismiss() }.buttonStyle(.dxPrimary)
        }
        .padding(.horizontal, DX.Space.m)
        .padding(.bottom, DX.Space.xs)
        .dxCanvas()
    }

    static func label(_ hour: Int) -> String {
        if hour == 0 { return String(localized: "midnight") }
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return date.formatted(.dateTime.hour())
    }
}
