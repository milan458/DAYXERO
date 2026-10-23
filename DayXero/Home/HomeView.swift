import DayXeroCore
import SwiftData
import SwiftUI

/// The app after onboarding: Today, Program and Progress tabs in the floating dock, with Craving SOS always one tap away.
struct HomeView: View {
    let profile: UserProfile
    @State private var tab = "today"
    @State private var showSOS = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case "program":
                    ComingSoon(title: "Program", message: "Your full program, day by day, arrives in Section 5.", systemImage: "book.closed")
                case "progress":
                    ComingSoon(title: "Progress", message: "Money kept, cravings ridden out and your insights arrive in Section 7.", systemImage: "chart.bar")
                default:
                    TodayView(profile: profile)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            DXDock(
                items: [
                    DXDockItem(id: "today", title: "Today", systemImage: "house"),
                    DXDockItem(id: "program", title: "Program", systemImage: "book.closed"),
                    DXDockItem(id: "progress", title: "Progress", systemImage: "chart.bar"),
                ],
                selection: $tab,
                sosAction: { showSOS = true }
            )
            .padding(.bottom, DX.Space.xxs)
        }
        .dxCanvas()
        .sheet(isPresented: $showSOS) {
            ComingSoon(title: "Craving SOS", message: "The 3-minute urge timer, breathing and your reasons arrive in Section 6.", systemImage: "flame")
                .presentationDetents([.medium])
        }
    }
}

/// Stand-in for tabs that later sections fill in.
private struct ComingSoon: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).dxText(.title).padding(.top, DX.Space.xl)
            Spacer()
            DXStateView(.empty, systemImage: systemImage, title: "Coming soon", message: message)
            Spacer()
        }
        .padding(.horizontal, DX.Space.m)
        .dxCanvas()
    }
}

struct TodayView: View {
    let profile: UserProfile
    @Environment(Entitlement.self) private var entitlement
    @Environment(\.modelContext) private var context
    @AppStorage("dx.sosHintSeen") private var sosHintSeen = false
    @State private var openLesson: ProgramDayID?
    @State private var showUpgrade = false
    @State private var showPaywall = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // Re-evaluates each minute so counters tick and the day rolls over on its own.
        TimelineView(.everyMinute) { timeline in
            let snap = HomeSnapshot(profile: profile, isPro: entitlement.isPro, now: timeline.date)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    header(snap, now: timeline.date)
                    hero(snap)
                    if let lesson = snap.lesson { lessonCard(lesson, finished: snap.finishedToday) }
                    if snap.phase == .quitDay, !sosHintSeen { sosHint }
                    tiles(snap)
                    if let next = snap.nextMilestone, !isPrep(snap) { milestone(next: next, daysClear: snap.daysClear) }
                }
                .padding(.horizontal, DX.Space.m)
                .padding(.top, DX.Space.s)
                .padding(.bottom, 120)
            }
        }
        .sheet(item: $openLesson) { day in
            LessonPlaceholder(day: day, profile: profile)
        }
        .sheet(isPresented: $showUpgrade) {
            UpgradeSheet(dayTitle: "Day 2", model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                         showAllPlans: { showUpgrade = false; showPaywall = true },
                         onUnlocked: { showUpgrade = false })
                .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(name: profile.name, quitDay: profile.quitDay,
                        model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                        onClose: { showPaywall = false })
        }
    }

    private func isPrep(_ snap: HomeSnapshot) -> Bool {
        if case .prep = snap.phase { return true }
        return false
    }

    // MARK: Sections

    private func header(_ snap: HomeSnapshot, now: Date) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow(snap, now: now)).dxText(.micro)
                Text(title(snap, now: now)).dxText(.title).font(.custom(DX.Typeface.bold, size: 24, relativeTo: .title))
            }
            Spacer()
            Button {} label: { Image(systemName: "person").accessibilityLabel(Text("Profile and settings")) }
                .buttonStyle(.dxIcon)
        }
        .padding(.bottom, DX.Space.xxs)
    }

    private func eyebrow(_ snap: HomeSnapshot, now: Date) -> String {
        let weekday = now.formatted(.dateTime.weekday(.wide))
        switch snap.phase {
        case .prep: return "\(weekday) · \(String(localized: "Prep day \(snap.prepDayNumber)"))"
        case .quitDay: return "\(weekday) · \(String(localized: "Quit Day"))"
        case let .quitWeek(day): return "\(weekday) · \(String(localized: "Day \(day)"))"
        case let .after(days): return "\(weekday) · \(String(localized: "Week \(days / 7 + 1)"))"
        }
    }

    private func title(_ snap: HomeSnapshot, now: Date) -> String {
        if snap.phase == .quitDay { return String(localized: "Today's the day, \(profile.name)") }
        if snap.finishedToday != nil { return String(localized: "Nice work, \(profile.name)") }
        return "\(HomeSnapshot.greeting(at: now)), \(profile.name)"
    }

    @ViewBuilder
    private func hero(_ snap: HomeSnapshot) -> some View {
        DXGlassCard {
            VStack(alignment: .leading, spacing: 4) {
                switch snap.phase {
                case let .prep(days):
                    Text("Quit Day in").dxText(.micro)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(days, format: .number).dxText(.hero)
                        Text("\(days == 1 ? String(localized: "day") : String(localized: "days")) · \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
                            .dxText(.heroDenominator)
                    }
                    Text(verbatim: prepLine).dxText(.subtitle)
                    DXWeekStrip(days: snap.weekStrip).padding(.top, DX.Space.s)
                case .quitDay:
                    Text("Days clear").dxText(.micro)
                    DXFraction(1, of: ProgramSchedule.quitWeekDays)
                    Text("Your first day. One craving at a time.").dxText(.subtitle)
                    DXProgressBar(value: 1.0 / Double(ProgramSchedule.quitWeekDays), tint: .primary).padding(.top, DX.Space.s)
                    DXWeekStrip(days: snap.weekStrip).padding(.top, DX.Space.s)
                case let .quitWeek(day):
                    Text("Days clear").dxText(.micro)
                    DXFraction(day, of: ProgramSchedule.quitWeekDays)
                    let weekFraction = Double(snap.quitWeekDone) / Double(ProgramSchedule.quitWeekDays)
                    DXMetric("Quit week", value: weekFraction.formatted(.percent.precision(.fractionLength(0))),
                             progress: weekFraction, tint: .primary)
                        .padding(.top, DX.Space.xs)
                    DXWeekStrip(days: snap.weekStrip).padding(.top, DX.Space.s)
                case let .after(days):
                    Text("Days clear").dxText(.micro)
                    DXFraction(days, unit: "days")
                    if let next = snap.nextMilestone {
                        DXMetric(LocalizedStringKey(milestoneLabel(next)), value: "\(days) / \(next)",
                                 progress: snap.milestoneFraction, tint: .accent)
                            .padding(.top, DX.Space.xs)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var prepLine: String {
        let verbs = Product.allCases.filter { p in profile.products.contains { $0.product == p } }.map { product -> String in
            switch product {
            case .cigarettes: String(localized: "smoke")
            case .vape: String(localized: "vape")
            case .pouches: String(localized: "use pouches")
            }
        }
        let joined = ListFormatter.localizedString(byJoining: verbs.reversed())
        return String(localized: "You can still \(joined) while you prepare.")
    }

    @ViewBuilder
    private func lessonCard(_ lesson: HomeSnapshot.Lesson, finished: ProgramDayID?) -> some View {
        DXCard(padding: DX.Space.m) {
            VStack(alignment: .leading, spacing: 4) {
                if let finished {
                    Label {
                        Text("\(LessonCatalog.title(for: finished)) done").font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text2)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(DX.Palette.sage)
                    }
                }
                Text(finished == nil ? "Today · \(lesson.position)" : "Next · \(lesson.position)").dxText(.micro)
                Text(lesson.title).dxText(.cardHeading)
                switch lesson.availability {
                case let .opensOn(date):
                    Label {
                        Text(opensText(date)).dxText(.subtitle)
                    } icon: {
                        Image(systemName: "clock").foregroundStyle(DX.Palette.muted)
                    }
                case .available where lesson.needsUpgrade:
                    Label {
                        Text("Part of the full program").dxText(.micro)
                    } icon: {
                        Image(systemName: "lock").foregroundStyle(DX.Palette.muted)
                    }
                    Button("Unlock \(lesson.title)") { showUpgrade = true }
                        .buttonStyle(.dxPrimary).padding(.top, DX.Space.xs)
                case .available:
                    Button(finished == nil ? "Start" : "Start next") { openLesson = lesson.day }
                        .buttonStyle(.dxPrimary).padding(.top, DX.Space.xs)
                case .completed, .locked:
                    EmptyView()
                }
            }
        }
    }

    private func opensText(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInTomorrow(date) { return String(localized: "Opens tomorrow morning") }
        return String(localized: "Opens \(date.formatted(.dateTime.weekday(.wide)))")
    }

    private var sosHint: some View {
        Button { sosHintSeen = true } label: {
            HStack(spacing: DX.Space.xs) {
                Image(systemName: "flame").foregroundStyle(DX.Palette.accentInk)
                Text("Craving? Tap the green button any time. It takes 3 minutes.")
                    .font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "xmark").font(.system(size: 11, weight: .semibold)).foregroundStyle(DX.Palette.muted)
            }
            .padding(DX.Space.s)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(DX.Palette.faint, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Dismisses this tip"))
    }

    @ViewBuilder
    private func tiles(_ snap: HomeSnapshot) -> some View {
        let columns = typeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: DX.Space.xs), GridItem(.flexible())]
        LazyVGrid(columns: columns, alignment: .leading, spacing: DX.Space.xs) {
            if isPrep(snap) {
                tile("You'll keep", value: snap.moneyPerYear.formatted(.currency(code: snap.currencyCode).precision(.fractionLength(0))),
                     caption: "a year, from Quit Day")
                tile("Prep days done", value: "\(snap.prepDone) / \(snap.prepTotal)", caption: snap.prepDone > 0 ? "on track" : "starts today")
            } else {
                ForEach(snap.counters) { counter in
                    tile(avoidedLabel(counter.product), value: counter.avoided.formatted(),
                         caption: "\(counter.perDayBefore) a day before")
                }
                tile("Money kept", value: snap.moneyKept.formatted(.currency(code: snap.currencyCode)),
                     caption: snap.phase == .quitDay ? "since this morning" : "since \(profile.quitDay.formatted(.dateTime.weekday(.wide)))")
            }
        }
    }

    private func avoidedLabel(_ product: Product) -> LocalizedStringKey {
        switch product {
        case .cigarettes: "Cigarettes not smoked"
        case .vape: "Puffs not taken"
        case .pouches: "Pouches not used"
        }
    }

    private func tile(_ label: LocalizedStringKey, value: String, caption: LocalizedStringKey) -> some View {
        DXCard(padding: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).dxText(.micro).fixedSize(horizontal: false, vertical: true)
                Text(verbatim: value).dxText(.cardHeading).font(.custom(DX.Typeface.bold, size: 20, relativeTo: .title3))
                    .contentTransition(.numericText())
                Text(caption).dxText(.subtitle)
            }
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
        }
        .accessibilityElement(children: .combine)
    }

    private func milestoneLabel(_ next: Int) -> String {
        switch next {
        case 7: String(localized: "To one week")
        case 14: String(localized: "To two weeks")
        case 30: String(localized: "To one month")
        case 365: String(localized: "To one year")
        default: String(localized: "To \(next) days")
        }
    }

    private func milestoneName(_ next: Int) -> String {
        switch next {
        case 1: String(localized: "Your first day clear")
        case 7: String(localized: "One week clear")
        case 14: String(localized: "Two weeks clear")
        case 30: String(localized: "One month clear")
        case 365: String(localized: "One year clear")
        default: String(localized: "\(next) days clear")
        }
    }

    private func milestone(next: Int, daysClear: Int) -> some View {
        let remaining = next - daysClear
        return DXCapsuleCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next milestone").dxText(.micro)
                    Text("\(milestoneName(next)) · \(remaining == 1 ? String(localized: "tomorrow") : String(localized: "in \(remaining) days"))")
                        .dxText(.cardHeading).font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline))
                }
                Spacer()
                Image(systemName: "flag")
                    .foregroundStyle(DX.Palette.accentInk)
                    .frame(width: 40, height: 40)
                    .background(DX.Palette.accentSoft, in: Circle())
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Stand-in for the lesson player (S5.4) so the program can be moved through today.
private struct LessonPlaceholder: View {
    let day: ProgramDayID
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            Text(LessonCatalog.title(for: day)).dxText(.title).padding(.top, DX.Space.xl)
            Text("The lesson player and the program content arrive in Section 5.").dxText(.subtitle)
            Spacer()
            Button("Mark as done") {
                if profile.progress == nil { profile.progress = ProgramProgress() }
                profile.progress?.completions.append(DayCompletion(day: day))
                profile.progress?.lastActiveAt = .now
                try? context.save()
                Analytics.track(.programDayCompleted(day: day.description))
                dismiss()
            }
            .buttonStyle(.dxPrimary)
        }
        .padding(DX.Space.l)
        .dxCanvas()
        .onAppear { Analytics.track(.programDayStarted(day: day.description)) }
    }
}
