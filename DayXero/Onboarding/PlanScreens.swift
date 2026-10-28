import DayXeroCore
import SwiftUI
import UserNotifications

// MARK: Screen 10: Quit Day

struct QuitDayScreen: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        OnboardingScaffold(title: model.name.isEmpty ? "Lock in your Quit Day" : "Lock in your Quit Day, \(model.name)",
                           subtitle: "Until then, smoke and vape as normal while doing one short prep a day. On Quit Day, you stop.") {
            QuitDayCalendar(quitDay: $model.quitDay, today: model.today, range: model.quitDayRange, calendar: model.calendar)
            if model.calendar.startOfDay(for: model.quitDay) != model.recommendedQuitDay {
                Button { model.quitDay = model.recommendedQuitDay } label: { recommendation }
                    .buttonStyle(.plain)
            } else {
                recommendation
            }
        } footer: {
            HoldToCommitButton(title: "Hold to commit to \(model.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))") {
                model.next()
            }
            .disabled(!model.canContinue)
            Text("Hold for 1.5 seconds. You can change the date later.")
                .font(.custom(DX.Typeface.regular, size: 12, relativeTo: .caption)).foregroundStyle(DX.Palette.muted)
        }
    }

    private var recommendation: some View {
        Label {
            Text("Recommended: \(model.recommendedQuitDay, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)). It gives you the full 7-day prep window.")
                .multilineTextAlignment(.leading)
        } icon: {
            Image(systemName: "star").font(.system(size: 15, weight: .light)).foregroundStyle(DX.Palette.accentInk)
        }
        .font(DX.TextStyle.subtitle.font)
        .foregroundStyle(DX.Palette.text)
        .padding(.vertical, 12).padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Palette.accentSoft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// Weeks from this one to the last allowed Quit Day. Prep days are tinted as one track that runs into Quit Day.
struct QuitDayCalendar: View {
    @Binding var quitDay: Date
    let today: Date
    let range: ClosedRange<Date>
    let calendar: Calendar

    private var days: [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let endWeek = calendar.dateInterval(of: .weekOfYear, for: range.upperBound)
        let end = endWeek.map { $0.end } ?? range.upperBound
        var all: [Date] = []
        var day = start
        while day < end {
            all.append(day)
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? end
        }
        return all
    }

    private var weekdays: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var header: String {
        let first = today.formatted(.dateTime.month(.abbreviated))
        let last = range.upperBound.formatted(.dateTime.month(.abbreviated).year())
        return calendar.isDate(today, equalTo: range.upperBound, toGranularity: .month) ? last : "\(first) – \(last)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(verbatim: header).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .headline)).foregroundStyle(DX.Palette.text)
                Spacer()
                legend(DX.Palette.moss, "Prep")
                legend(DX.Palette.sage, "Quit Day")
            }
            .accessibilityElement(children: .combine)
            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, symbol in
                    Text(verbatim: symbol).font(.custom(DX.Typeface.semibold, size: 11, relativeTo: .caption2))
                        .foregroundStyle(DX.Palette.muted).frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
            let all = days
            ForEach(0..<(all.count / 7), id: \.self) { week in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { column in
                        cell(all[week * 7 + column], column: column)
                    }
                }
            }
        }
        .padding(DX.Space.m)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: DX.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Radius.card, style: .continuous).strokeBorder(DX.Palette.hairline))
    }

    private func legend(_ color: Color, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title).font(.custom(DX.Typeface.regular, size: 12, relativeTo: .caption)).foregroundStyle(DX.Palette.text2)
        }
        .padding(.leading, DX.Space.s)
    }

    private func isPrep(_ day: Date) -> Bool { day >= today && day < calendar.startOfDay(for: quitDay) }

    @ViewBuilder
    private func cell(_ day: Date, column: Int) -> some View {
        let quit = calendar.isDate(day, inSameDayAs: quitDay)
        let prep = isPrep(day)
        let selectable = range.contains(day)
        let isToday = calendar.isDate(day, inSameDayAs: today)
        let previous = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        let startsRun = column == 0 || !isPrep(previous)
        let endsRun = column == 6 || !isPrep(next)
        Button {
            quitDay = day
        } label: {
            ZStack {
                if prep {
                    UnevenRoundedRectangle(topLeadingRadius: startsRun ? 20 : 0, bottomLeadingRadius: startsRun ? 20 : 0,
                                           bottomTrailingRadius: endsRun ? 20 : 0, topTrailingRadius: endsRun ? 20 : 0, style: .continuous)
                        .fill(DX.Palette.accentSoft)
                }
                if quit {
                    Circle().fill(DX.Palette.sage).frame(width: 40, height: 40)
                        .shadow(color: DX.Palette.sage.opacity(0.6), radius: 10)
                } else if isToday {
                    Circle().strokeBorder(DX.Palette.accentInk, lineWidth: 1.5).frame(width: 34, height: 34)
                }
                Text(day, format: .dateTime.day())
                    .font(.custom(quit || prep || isToday ? DX.Typeface.bold : DX.Typeface.regular, size: 15, relativeTo: .body))
                    .foregroundStyle(quit ? DX.Palette.onAccent : (prep ? DX.Palette.text : (selectable ? DX.Palette.text2 : DX.Palette.faint)))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!selectable)
        .sensoryFeedback(DX.Haptic.select, trigger: quit)
        .accessibilityLabel(Text(day, format: .dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityValue(Text(quit ? "Quit Day" : (prep ? (isToday ? "Today, prep day" : "Prep day") : "")))
        .accessibilityAddTraits(quit ? [.isButton, .isSelected] : .isButton)
    }
}

/// Press and hold to commit (S22): the fill runs left to right over 1.5 s, then a success haptic.
/// Letting go early drains it. VoiceOver commits with a double-tap.
struct HoldToCommitButton: View {
    let title: String
    let action: () -> Void

    @State private var progress: CGFloat = 0
    @State private var committed = false
    @Environment(\.isEnabled) private var isEnabled

    static let duration = 1.5

    var body: some View {
        HStack(spacing: DX.Space.xs) {
            Image(systemName: "hand.tap").font(.system(size: 16, weight: .regular))
            Text(verbatim: title).lineLimit(1).minimumScaleFactor(0.8)
        }
        .font(.custom(DX.Typeface.semibold, size: 16, relativeTo: .callout))
        .foregroundStyle(DX.Palette.onPrimary)
        .frame(maxWidth: .infinity, minHeight: DX.Size.buttonHeight)
        .padding(.horizontal, DX.Space.l)
        .background {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DX.Palette.primary)
                    Rectangle().fill(DX.Palette.sage).frame(width: geo.size.width * progress)
                }
                .clipShape(Capsule())
            }
        }
        .opacity(isEnabled ? 1 : 0.4)
        .scaleEffect(progress > 0 ? DX.Motion.pressedScale : 1)
        .animation(DX.Motion.press, value: progress > 0)
        .onLongPressGesture(minimumDuration: Self.duration, maximumDistance: 40) {
            commit()
        } onPressingChanged: { pressing in
            guard !committed else { return }
            withAnimation(pressing ? .linear(duration: Self.duration) : .easeOut(duration: 0.3)) {
                progress = pressing ? 1 : 0
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: progress > 0)
        .sensoryFeedback(DX.Haptic.commit, trigger: committed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { commit() }
        .accessibilityIdentifier("onboarding.hold")
    }

    private func commit() {
        guard isEnabled, !committed else { return }
        committed = true
        progress = 1
        action()
    }
}

// MARK: Screen 11: building the plan

struct BuildingScreen: View {
    let model: OnboardingModel
    @State private var progress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var duration: Double { reduceMotion ? 1.2 : 4 }

    private var lines: [String] {
        let usage = ListFormatter.localizedString(byJoining: model.orderedProducts.map { product in
            let d = model.baseline(for: product)
            switch product {
            case .cigarettes: return String(localized: "\(Int(d.unitsPerDay)) cigarettes a day")
            case .vape: return d.byPuffs ? String(localized: "\(Int(d.unitsPerDay)) puffs a day")
                                         : String(localized: "\(VapeUsage.format(d.podsPerWeek)) pods a week")
            case .pouches: return String(localized: "\(Int(d.unitsPerDay)) pouches a day")
            }
        })
        let triggers = model.triggers.isEmpty ? String(localized: "your routine")
            : ListFormatter.localizedString(byJoining: Trigger.allCases.filter(model.triggers.contains).prefix(2).map { String(localized: $0.title).lowercased() })
        let money = (model.moneyPerDay * 365).formatted(.currency(code: model.currencyCode).precision(.fractionLength(0)))
        let nrt = model.nrtInterest == .using && !model.nrtFormats.isEmpty
            ? ListFormatter.localizedString(byJoining: NRTType.allCases.filter(model.nrtFormats.contains).map { String(localized: $0.title).lowercased() })
            : nil
        return [
            model.products.count > 1 ? String(localized: "Calibrating your dual-use step-down (\(usage))")
                                     : String(localized: "Calibrating your step-down (\(usage))"),
            String(localized: "Designing \(max(model.prepDays, 1)) prep days around \(triggers)"),
            nrt.map { String(localized: "Setting up \($0) reminders and your \(money) savings tracker") }
                ?? String(localized: "Setting up your \(money) savings tracker"),
            String(localized: "Locking your Quit Day for \(model.quitDay.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))"),
        ]
    }

    var body: some View {
        VStack(spacing: DX.Space.xl) {
            Spacer()
            ZStack {
                Circle().stroke(DX.Palette.track, lineWidth: 10)
                Circle().trim(from: 0, to: progress)
                    .stroke(DX.Palette.sage, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                PercentText(value: progress)
            }
            .frame(width: 120, height: 120)
            .accessibilityElement()
            .accessibilityLabel(Text("Building your plan"))
            .accessibilityValue(Text("\(Int(progress * 100)) percent"))
            VStack(spacing: DX.Space.xs) {
                Text(model.name.isEmpty ? "Building your DayXero plan…" as LocalizedStringKey : "Building your DayXero plan, \(model.name)…")
                    .dxText(.title).multilineTextAlignment(.center)
                Text("Using everything you told us").dxText(.subtitle)
            }
            VStack(alignment: .leading, spacing: DX.Space.m) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    let start = Double(index) / Double(lines.count)
                    let end = Double(index + 1) / Double(lines.count)
                    let state: StepState = progress >= end ? .done : (progress > start ? .now : .todo)
                    HStack(spacing: DX.Space.s) {
                        StepMark(state: state)
                        Text(verbatim: line)
                            .font(.custom(state == .now ? DX.Typeface.semibold : DX.Typeface.regular, size: 14, relativeTo: .subheadline))
                            .foregroundStyle(state == .todo ? DX.Palette.muted : DX.Palette.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(DX.Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(DX.Palette.hairline))
            Spacer()
        }
        .padding(.horizontal, DX.Space.l)
        .dxReadableColumn()
        .task {
            withAnimation(.linear(duration: duration)) { progress = 1 }
            try? await Task.sleep(for: .seconds(duration + 0.4))
            model.next()
        }
    }

    enum StepState { case done, now, todo }

    private struct StepMark: View {
        let state: StepState

        var body: some View {
            ZStack {
                switch state {
                case .done:
                    Circle().fill(DX.Palette.sage)
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(DX.Palette.onAccent)
                case .now:
                    Circle().stroke(DX.Palette.track, lineWidth: 2.5)
                    Circle().trim(from: 0, to: 0.5).stroke(DX.Palette.sage, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                case .todo:
                    Circle().strokeBorder(DX.Palette.faint, lineWidth: 1.5)
                }
            }
            .frame(width: 24, height: 24)
            .accessibilityHidden(true)
        }
    }
}

/// "64%", counting smoothly as the ring fills.
private struct PercentText: View, Animatable {
    var value: Double
    nonisolated var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(verbatim: "\(Int((value * 100).rounded()))%")
            .font(.custom(DX.Typeface.bold, size: 30, relativeTo: .title))
            .tracking(-0.6)
            .monospacedDigit()
            .foregroundStyle(DX.Palette.text)
    }
}

// MARK: Screen 12: the plan

struct PlanRevealScreen: View {
    let model: OnboardingModel
    let onContinue: () -> Void

    private var money: (Decimal) -> String {
        { $0.formatted(.currency(code: model.currencyCode).precision(.fractionLength(0))) }
    }

    var body: some View {
        OnboardingScaffold(title: "Quit Day is \(model.quitDay.formatted(.dateTime.weekday(.wide))), \(model.name)",
                           eyebrow: "Your custom plan") {
            let why = model.why.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !why.isEmpty {
                Label {
                    Text("Anchored to your why: “\(why)”").lineLimit(3)
                } icon: {
                    Image(systemName: "heart").font(.system(size: 14, weight: .light)).foregroundStyle(DX.Palette.accentInk)
                }
                .font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text2)
                .padding(.vertical, 10).padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DX.Palette.surface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(DX.Palette.hairline))
            }
            savings
            LazyVGrid(columns: [GridItem(.flexible(), spacing: DX.Space.s), GridItem(.flexible())], spacing: DX.Space.s) {
                ForEach(model.orderedProducts, id: \.self) { product in reduction(product) }
            }
            runway
            // The one-line health disclaimer, before the paywall (S15.6).
            Text(HealthInfoView.oneLine).dxText(.subtitle).frame(maxWidth: .infinity).multilineTextAlignment(.center)
        } footer: {
            Button("Continue", action: onContinue).buttonStyle(.dxPrimary)
        }
    }

    private var savings: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Money you'll keep in year 1").dxText(.micro)
            Text(verbatim: money(model.stats.moneyPerYear))
                .font(.custom(DX.Typeface.extraBold, size: 40, relativeTo: .largeTitle)).tracking(-1.2)
                .foregroundStyle(DX.Palette.sage)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(verbatim: split).dxText(.subtitle)
        }
        .padding(.vertical, 18).padding(.horizontal, DX.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(hex: 0x2C3816), Color(hex: 0x121212)], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: DX.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Radius.card, style: .continuous).strokeBorder(DX.Palette.hairline))
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .combine)
    }

    /// "₹91,250 from cigarettes + ₹83,200 from vapes", or where the number comes from.
    private var split: String {
        let parts = model.orderedProducts.compactMap { product -> String? in
            guard let yearly = model.baseline(for: product).yearlyCost else { return nil }
            let what = switch product {
            case .cigarettes: String(localized: "cigarettes")
            case .vape: String(localized: "vapes")
            case .pouches: String(localized: "pouches")
            }
            return String(localized: "\(money(yearly)) from \(what)")
        }
        return parts.count > 1 ? parts.joined(separator: " + ") : String(localized: "Based on what you told us you spend")
    }

    private func reduction(_ product: Product) -> some View {
        let d = model.baseline(for: product)
        let mg = Int(NicotineEstimate.mgPerDay(product, unitsPerDay: d.unitsPerDay, strength: d.strengthMg).rounded())
        let label: LocalizedStringKey = switch product {
        case .cigarettes: "Cigarettes / day"
        case .vape: d.byPuffs ? "Puffs / day" : "Vape pods / week"
        case .pouches: "Pouches / day"
        }
        let amount = product == .vape && !d.byPuffs ? VapeUsage.format(d.podsPerWeek) : "\(Int(d.unitsPerDay.rounded()))"
        return VStack(alignment: .leading, spacing: 4) {
            Text(label).dxText(.micro)
            (Text(verbatim: "\(amount) ") + Text(verbatim: "→ 0").foregroundStyle(DX.Palette.accentInk))
                .font(.custom(DX.Typeface.bold, size: 24, relativeTo: .title2))
                .foregroundStyle(DX.Palette.text)
            Text("About \(mg) mg nicotine a day").font(.custom(DX.Typeface.regular, size: 12, relativeTo: .caption))
                .foregroundStyle(DX.Palette.text2)
        }
        .padding(.vertical, 14).padding(.horizontal, DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(DX.Palette.hairline))
        .accessibilityElement(children: .combine)
    }

    private struct Stop: Identifiable {
        let id: String
        let badge: String
        let title: String
        let detail: String
        var tag: (text: LocalizedStringKey, systemImage: String)?
        var isNow = false
        var isQuitDay = false
    }

    /// Prep day 1 today, the middle and the last prep days in groups, then Quit Day.
    private var stops: [Stop] {
        let n = max(model.prepDays, 1)
        let triggers = Trigger.allCases.filter(model.triggers.contains).prefix(2).map { String(localized: $0.title).lowercased() }
        let unlinking = triggers.isEmpty ? String(localized: "Unlinking your daily triggers")
                                         : String(localized: "Unlinking \(ListFormatter.localizedString(byJoining: triggers))")
        let finale = model.nrtInterest == .notInterested || model.nrtInterest == nil
            ? String(localized: "Your craving plan for Quit Day") : String(localized: "NRT set-up and your craving plan")
        var all = [Stop(id: "1", badge: "1", title: String(localized: "Prep day 1 · Today"), detail: String(localized: "Your first lesson · 6 min"),
                        tag: ("Unlocked", "lock.open"), isNow: true)]
        if n >= 5 {
            all.append(Stop(id: "mid", badge: "2–\(n - 3)", title: String(localized: "Prep days 2–\(n - 3)"), detail: unlinking))
            all.append(Stop(id: "end", badge: "\(n - 2)–\(n)", title: String(localized: "Prep days \(n - 2)–\(n)"), detail: finale))
        } else if n >= 2 {
            all.append(Stop(id: "end", badge: n == 2 ? "2" : "2–\(n)", title: n == 2 ? String(localized: "Prep day 2") : String(localized: "Prep days 2–\(n)"),
                            detail: finale))
        }
        all.append(Stop(id: "q", badge: "Q", title: String(localized: "Quit Day · \(model.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))"),
                        detail: String(localized: "Craving SOS and daily support through quit week"), tag: ("Shield", "checkmark.shield"), isQuitDay: true))
        return all
    }

    private var runway: some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            Text("Your runway to Day Xero").dxText(.micro)
            ForEach(stops) { stop in
                HStack(alignment: .top, spacing: DX.Space.s) {
                    Text(verbatim: stop.badge)
                        .font(.custom(DX.Typeface.bold, size: stop.badge.count > 1 ? 11 : 13, relativeTo: .caption))
                        .foregroundStyle(stop.isQuitDay ? DX.Palette.onAccent : (stop.isNow ? DX.Palette.accentInk : DX.Palette.text2))
                        .frame(width: 32, height: 32)
                        .background(stop.isQuitDay ? DX.Palette.sage : (stop.isNow ? DX.Palette.accentSoft : DX.Palette.surface3), in: Circle())
                        .overlay(Circle().strokeBorder(stop.isNow ? DX.Palette.accentInk : .clear, lineWidth: 1.5))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: DX.Space.xs) {
                            Text(verbatim: stop.title).font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline)).foregroundStyle(DX.Palette.text)
                            if let tag = stop.tag {
                                Label(tag.text, systemImage: tag.systemImage)
                                    .font(.custom(DX.Typeface.bold, size: 10, relativeTo: .caption2)).textCase(.uppercase)
                                    .foregroundStyle(DX.Palette.onAccent)
                                    .padding(.vertical, 3).padding(.horizontal, 8)
                                    .background(DX.Palette.sage, in: Capsule())
                            }
                        }
                        Text(verbatim: stop.detail).dxText(.subtitle).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(DX.Palette.hairline))
    }
}

// MARK: Screen 13: the free trial and its reminder

/// Screen 13 (S22): the trial laid out before the paywall (today, the reminder, the first charge), with the reminder
/// on by default. "Remind me & continue" asks for notifications. Without a trial to offer, or once they're Pro,
/// it's the plain reminders screen.
struct TrialScreen: View {
    let name: String
    let quitDay: Date
    let dualUse: Bool
    let onDone: () -> Void

    @Environment(Entitlement.self) private var entitlement
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: PaywallModel?
    @State private var remind = true
    @State private var asking = false

    var body: some View {
        Group {
            if entitlement.isPro {
                RemindersScreen(onDone: onDone)
            } else if let model, model.phase != .loading {
                if let option = model.plans.first(where: { $0.plan == .annual }), let days = option.trialDays {
                    trial(option, days: days)
                } else {
                    RemindersScreen(onDone: onDone)
                }
            } else {
                ProgressView().tint(DX.Palette.accentInk).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            guard model == nil, !entitlement.isPro else { return }
            let loading = PaywallModel(store: entitlement.store, entitlement: entitlement)
            await loading.load(trackView: false)
            model = loading
        }
    }

    private func trial(_ option: PlanOption, days: Int) -> some View {
        let now = Date.now
        let end = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        let lead = TrialReminder.leadDays(trialEndsAt: end, now: now)
        let remindOn = Calendar.current.date(byAdding: .day, value: -lead, to: end) ?? end
        let short = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated)
        let zero = Decimal(0).formatted(.currency(code: option.currencyCode).precision(.fractionLength(0)))
        let leadText = lead == 2 ? String(localized: "2 days") : String(localized: "the day")
        let endsOnQuitDay = Calendar.current.isDate(end, inSameDayAs: quitDay)
        return OnboardingScaffold(title: name.isEmpty ? "We want you to try DayXero for free" : "We want you to try DayXero for free, \(name).",
                                  eyebrow: "A risk-free start") {
            VStack(alignment: .leading, spacing: 0) {
                stop("lock.open", when: String(localized: "Today · \(zero) due"),
                     detail: dualUse ? String(localized: "Full access to every prep day, the dual-use tracker and Craving SOS.")
                                     : String(localized: "Full access to every prep day, your tracker and Craving SOS."), last: false)
                stop("bell", when: String(localized: "\(remindOn.formatted(short)) · Trial reminder"),
                     detail: remind ? String(localized: "We'll notify you \(leadText) before your trial ends, so you're never billed by surprise.")
                                    : String(localized: "Reminder off. You can still cancel any time before it ends."),
                     last: false, dimmed: !remind)
                stop("star", when: endsOnQuitDay ? String(localized: "\(end.formatted(short)) · Quit Day · First billing")
                                                 : String(localized: "\(end.formatted(short)) · First billing"),
                     detail: String(localized: "\(option.priceText) a year unless you cancel. Cancel any time in Settings."), last: true)
            }
            .padding(DX.Space.m)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(DX.Palette.hairline))
            Toggle(isOn: $remind) {
                Label("Remind me \(leadText) before my trial ends", systemImage: "bell")
                    .font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(DX.Palette.text)
            }
            .tint(DX.Palette.sage)
            .padding(.vertical, 12).padding(.horizontal, DX.Space.m)
            .background(DX.Palette.accentSoft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.top, DX.Space.xs)
        } footer: {
            Button(remind ? "Remind me & continue" as LocalizedStringKey : "Continue") {
                UserDefaults.standard.set(remind, forKey: TrialReminder.wantedKey)
                guard remind else { return onDone() }
                asking = true
                Task {
                    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                    onDone()
                }
            }
            .buttonStyle(.dxPrimary)
            .disabled(asking)
        }
        .background(alignment: .bottom) {
            Hills(still: reduceMotion).frame(height: 170).opacity(0.5).ignoresSafeArea().allowsHitTesting(false)
        }
    }

    private func stop(_ systemImage: String, when: String, detail: String, last: Bool, dimmed: Bool = false) -> some View {
        HStack(alignment: .top, spacing: DX.Space.s) {
            Image(systemName: systemImage).font(.system(size: 14, weight: .regular)).foregroundStyle(DX.Palette.accentInk)
                .frame(width: 34, height: 34).background(DX.Palette.accentSoft, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: when).font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline)).foregroundStyle(DX.Palette.text)
                Text(verbatim: detail).dxText(.subtitle).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, last ? 0 : DX.Space.l)
        }
        .opacity(dimmed ? 0.5 : 1)
        .background(alignment: .topLeading) {
            if !last {
                Rectangle().fill(DX.Palette.sage.opacity(0.6)).frame(width: 2).padding(.top, 34).padding(.leading, 16)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: Reminders (when there's no trial to show)

struct RemindersScreen: View {
    let onDone: () -> Void
    @State private var asking = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        OnboardingScaffold(title: "A nudge at the right moments",
                           subtitle: "Your morning pledge, each prep lesson and your Quit Day countdown. You choose the times, and we never guilt you.") {
            VStack(spacing: DX.Space.xs) {
                Text(tomorrow, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline)).foregroundStyle(.white.opacity(0.6))
                Text(pledgeTime, format: .dateTime.hour(.defaultDigits(amPM: .omitted)).minute())
                    .font(.custom(DX.Typeface.bold, size: 60, relativeTo: .largeTitle)).tracking(-2).foregroundStyle(.white)
                    .padding(.bottom, DX.Space.xs)
                preview(NotificationCopy.pledge, time: pledgeTime)
                preview(NotificationCopy.lesson(name: String(localized: "Prep day 2"), minutes: 6), time: lessonTime)
            }
            .padding(.top, 22).padding(.horizontal, DX.Space.s).padding(.bottom, 14)
            .background {
                ZStack(alignment: .bottom) {
                    LinearGradient(colors: [Color(hex: 0x2C3816), Color(hex: 0x0B0B0B)], startPoint: .top, endPoint: .bottom)
                    Hills(still: reduceMotion).frame(height: 180).opacity(0.6)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .environment(\.colorScheme, .dark)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("Example reminders"))
        } footer: {
            Button("Turn on reminders") {
                asking = true
                Task {
                    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                    onDone()
                }
            }
            .buttonStyle(.dxPrimary)
            .disabled(asking)
            Button("Maybe later", action: onDone).buttonStyle(.dxQuiet)
        }
    }

    private var tomorrow: Date { Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now }
    private func at(_ minute: Int) -> Date {
        Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: tomorrow) ?? tomorrow
    }
    private var pledgeTime: Date { at(DailyReminderSettings.pledgeMinute ?? DailyReminderSettings.defaultPledge) }
    private var lessonTime: Date { at(DailyReminderSettings.defaultLesson) }

    private func preview(_ copy: (String, String), time: Date) -> some View {
        HStack(alignment: .top, spacing: DX.Space.s) {
            RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.black)
                .frame(width: 38, height: 38)
                .overlay(Circle().fill(DX.Palette.sage).frame(width: 13, height: 13))
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(.white.opacity(0.1)))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(verbatim: "DayXero").font(.custom(DX.Typeface.semibold, size: 12, relativeTo: .caption)).foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Text(time, format: .dateTime.hour().minute()).font(.custom(DX.Typeface.regular, size: 12, relativeTo: .caption))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Text(verbatim: copy.0).font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline)).foregroundStyle(.white)
                Text(verbatim: copy.1).font(.custom(DX.Typeface.regular, size: 13, relativeTo: .footnote)).foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 12).padding(.horizontal, 14)
        .background(Color(hex: 0x2A2A2A, opacity: 0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
