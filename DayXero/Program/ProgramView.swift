import DayXeroCore
import SwiftUI

/// The Program tab (S5.8): prep, the quit week and the weeks after, with each day's state.
struct ProgramView: View {
    let profile: UserProfile
    @Environment(Entitlement.self) private var entitlement
    @State private var showPrep = false
    @State private var open: LessonOpen?
    @State private var upgradeFor: ProgramDayID?
    @State private var showPaywall = false
    @State private var showCalm = UserDefaults.standard.bool(forKey: "dx.openCalmList") || UserDefaults.standard.string(forKey: "dx.openCalm") != nil
    @Environment(SOSRouter.self) private var sos

    struct LessonOpen: Identifiable {
        let day: ProgramDayID
        let isReplay: Bool
        var id: String { day.description + (isReplay ? "-replay" : "") }
    }

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            let state = ProgramState(profile: profile, isPro: entitlement.isPro, now: timeline.date)
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    Text("Your program").dxText(.micro)
                    Text("Program").dxText(.title).accessibilityAddTraits(.isHeader)
                    variantLine.padding(.vertical, DX.Space.xs)
                    // Calm tools, always here and free for everyone (S12.2).
                    NRTInviteRow(title: "Calm tools", detail: "5 short exercises for stressful moments", systemImage: "wind") { showCalm = true }
                    if let replay = state.replayDay {
                        ReplayCard(title: state.lesson(replay).title, minutes: state.lesson(replay).minutes) {
                            open = LessonOpen(day: replay, isReplay: true)
                        }
                    }
                    prepSection(state)
                    section("Quit week", detail: "\(state.completed.filter { $0.phase == .quit }.count) of \(ProgramSchedule.quitWeekDays)",
                            rows: state.rows(.quit), state: state)
                    section("The four weeks after", detail: String(localized: "Weekly"), rows: state.rows(.maintenance), state: state)
                }
                .padding(.horizontal, DX.Space.m)
                .padding(.top, DX.Space.xl)
                .padding(.bottom, 120)
            }
        }
        .fullScreenCover(isPresented: $showCalm) {
            CalmToolsView(onClose: { showCalm = false }, startSOS: { sos.open(source: "calm") })
        }
        .fullScreenCover(item: $open) { item in
            LessonPlayer(day: item.day, profile: profile, isReplay: item.isReplay)
        }
        .sheet(item: $upgradeFor) { day in
            UpgradeSheet(dayTitle: LessonLibrary.lesson(for: day, product: profile.primaryProduct?.product ?? .cigarettes).title,
                         model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                         showAllPlans: { upgradeFor = nil; showPaywall = true },
                         onUnlocked: { upgradeFor = nil })
                .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(name: profile.name, quitDay: profile.quitDay,
                        model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                        onClose: { showPaywall = false })
        }
    }

    private var variantLine: some View {
        let primary = profile.primaryProduct?.product ?? .cigarettes
        let others = profile.products.map(\.product).filter { $0 != primary }
        return HStack(spacing: DX.Space.xs) {
            Image(systemName: "book.closed").foregroundStyle(DX.Palette.accentInk)
            Text(variantText(primary: primary, others: others)).font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text2)
            Spacer(minLength: 0)
        }
        .padding(DX.Space.s)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DX.Palette.hairline))
    }

    private func variantText(primary: Product, others: [Product]) -> AttributedString {
        let name: String = switch primary {
        case .cigarettes: String(localized: "Smoking program")
        case .vape: String(localized: "Vaping program")
        case .pouches: String(localized: "Pouches program")
        }
        var text = AttributedString(name)
        text.font = .custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote)
        text.foregroundColor = DX.Palette.text
        if !others.isEmpty {
            let list = ListFormatter.localizedString(byJoining: others.map { String(localized: $0.title).lowercased() })
            text += AttributedString(String(localized: ", with notes for \(list)"))
        }
        return text
    }

    @ViewBuilder
    private func prepSection(_ state: ProgramState) -> some View {
        let rows = state.rows(.prep)
        let done = rows.filter { $0.availability == .completed }.count
        if !rows.isEmpty {
            header(done == rows.count ? "Prep · done" : "Prep", detail: "\(done) of \(rows.count)")
            if done == rows.count && !showPrep {
                Button { showPrep = true } label: {
                    HStack(spacing: DX.Space.xs) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(DX.Palette.sage)
                        Text("\(rows.count) prep days done · show").font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text2)
                        Spacer()
                    }
                    .padding(DX.Space.s)
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(DX.Palette.faint, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
                }
                .buttonStyle(.plain)
            } else {
                ForEach(rows) { row in dayRow(row, state: state) }
            }
        }
    }

    @ViewBuilder
    private func section(_ title: LocalizedStringKey, detail: String, rows: [ProgramState.Row], state: ProgramState) -> some View {
        header(title, detail: detail)
        ForEach(rows) { row in dayRow(row, state: state) }
    }

    private func header(_ title: LocalizedStringKey, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).dxText(.micro)
            Spacer()
            Text(verbatim: detail).font(.custom(DX.Typeface.regular, size: 11, relativeTo: .caption2)).foregroundStyle(DX.Palette.muted)
        }
        .padding(.top, DX.Space.m)
        .accessibilityAddTraits(.isHeader)
    }

    private func dayRow(_ row: ProgramState.Row, state: ProgramState) -> some View {
        let isNow = row.availability == .available
        let canTap = row.availability == .completed || (isNow && !row.needsUpgrade) || (isNow && row.needsUpgrade)
        return Button {
            if row.availability == .completed || (isNow && !row.needsUpgrade) {
                open = LessonOpen(day: row.day, isReplay: false)
            } else if isNow && row.needsUpgrade {
                upgradeFor = row.day
            }
        } label: {
            HStack(spacing: DX.Space.s) {
                badge(row)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(row.lesson.title).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                        if row.lesson.placeholder { PlaceholderTag() }
                    }
                    Text(subtitle(row)).dxText(.subtitle)
                }
                Spacer(minLength: DX.Space.xs)
                trailing(row)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, DX.Space.s)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(isNow ? DX.Palette.accentInk : DX.Palette.hairline, lineWidth: isNow ? 1.5 : 1))
            .opacity(row.availability == .locked || isOpensLater(row) ? 0.62 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!canTap)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(accessibilityState(row)))
    }

    private func isOpensLater(_ row: ProgramState.Row) -> Bool {
        if case .opensOn = row.availability { return true }
        return false
    }

    @ViewBuilder
    private func badge(_ row: ProgramState.Row) -> some View {
        let label = row.day.phase == .maintenance ? "W\(row.day.index + 1)" : "\(row.day.index)"
        switch row.availability {
        case .completed:
            Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(DX.Palette.onAccent)
                .frame(width: 30, height: 30).background(DX.Palette.sage, in: Circle())
        case .available:
            Text(verbatim: label).font(.custom(DX.Typeface.bold, size: 12, relativeTo: .caption)).foregroundStyle(DX.Palette.onPrimary)
                .frame(width: 30, height: 30).background(DX.Palette.primary, in: Circle())
        case .opensOn, .locked:
            Text(verbatim: label).font(.custom(DX.Typeface.bold, size: 12, relativeTo: .caption)).foregroundStyle(DX.Palette.muted)
                .frame(width: 30, height: 30).background(DX.Palette.track, in: Circle())
        }
    }

    @ViewBuilder
    private func trailing(_ row: ProgramState.Row) -> some View {
        Group {
            switch row.availability {
            case .completed: Text("Review")
            case .available where row.needsUpgrade: Label("Unlock", systemImage: "lock")
            case .available: Label("Start", systemImage: "chevron.right").labelStyle(TrailingIconLabelStyle())
            case let .opensOn(date): Label(date.formatted(.dateTime.weekday(.abbreviated)), systemImage: "clock")
            case .locked: row.needsUpgrade ? AnyView(Image(systemName: "lock")) : AnyView(EmptyView())
            }
        }
        .font(.custom(DX.Typeface.medium, size: 12, relativeTo: .caption))
        .foregroundStyle(DX.Palette.muted)
    }

    /// When and how long, e.g. "Today · 6 min". The badge and section header already say which day it is (S18.10).
    private func subtitle(_ row: ProgramState.Row) -> String {
        var parts: [String] = []
        if let date = row.date {
            parts.append(Calendar.current.isDateInToday(date) ? String(localized: "Today") : date.formatted(.dateTime.weekday(.abbreviated)))
        }
        parts.append(String(localized: "\(row.lesson.minutes) min"))
        return parts.joined(separator: " · ")
    }

    private func accessibilityState(_ row: ProgramState.Row) -> String {
        switch row.availability {
        case .completed: String(localized: "Done")
        case .available: row.needsUpgrade ? String(localized: "Part of the full program") : String(localized: "Ready")
        case let .opensOn(date): String(localized: "Opens \(date.formatted(.dateTime.weekday(.wide)))")
        case .locked: row.needsUpgrade ? String(localized: "Part of the full program") : String(localized: "Locked")
        }
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) { configuration.title; configuration.icon }
    }
}

/// "Welcome back" card shown on Home and Program while a replay is due (S5.7).
struct ReplayCard: View {
    let title: String
    let minutes: Int
    let action: () -> Void

    var body: some View {
        DXGlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Pick up where you left off").dxText(.micro)
                Text("Let's replay \(title), then carry on").dxText(.cardHeading)
                    .font(.custom(DX.Typeface.bold, size: 18, relativeTo: .headline))
                Text("A quick refresher of your last lesson. Your days clear and progress haven't changed.").dxText(.subtitle)
                Button("Replay · \(minutes) min", action: action).buttonStyle(.dxPrimary).padding(.top, DX.Space.xs)
            }
        }
    }
}
