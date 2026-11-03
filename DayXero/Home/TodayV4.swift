import DayXeroCore
import SwiftData
import SwiftUI

// Today as one screen with no scrolling (UX-07, UX-09; 2 Nov 2026): a kicker line, a hero card, one focus card and
// a two-cell bento row. State A runs from prep day 1 to Day Xero; State B starts once Day Xero's commit is held.

/// Which of Today's two layouts shows.
enum TodayState: Equatable {
    /// Prep day 1 to Quit Day, until Day Xero's commit is held.
    case prep
    /// After Day Xero: time free, money kept, recovery and urges surfed.
    case postQuit

    /// After Day Xero's commit; for anyone without one (an older program, or Day Xero left for later), once the
    /// calendar is past Quit Day itself.
    init(snap: HomeSnapshot, quitTimestamp: Date?) {
        if quitTimestamp != nil {
            self = .postQuit
            return
        }
        switch snap.phase {
        case .prep, .quitDay: self = .prep
        case .quitWeek, .after: self = .postQuit
        }
    }
}

/// Today's time of day. DEBUG builds can force it for screenshots with `-dx.todaySlot morning|afternoon|evening|night`.
enum TodayClock {
    static func slot(at now: Date) -> TodaySlot {
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "dx.todaySlot"), let forced = TodaySlot(rawValue: raw) { return forced }
        #endif
        return TodaySlot(now)
    }

    /// The hour the focus card follows; a forced slot stands in with an hour inside it.
    static func hour(at now: Date) -> Int {
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "dx.todaySlot"), let forced = TodaySlot(rawValue: raw) {
            return switch forced {
            case .morning: 9
            case .afternoon: 14
            case .evening: 19
            case .night: 23
            }
        }
        #endif
        return Calendar.current.component(.hour, from: now)
    }

    /// Xero's apricot by day, Glim's violet in the evening and at night.
    static func ground(at now: Date) -> DX.Ground {
        switch slot(at: now) {
        case .morning, .afternoon: .apricot
        case .evening, .night: .violet
        }
    }
}

// MARK: Kicker

/// The one all-caps line on Today: "PREP DAY 1 OF 7 · HI, MILAN", with the profile button beside it.
struct TodayKicker: View {
    let text: String
    let name: String
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: DX.Space.s) {
            Text(verbatim: text)
                .dxType(.caption).textCase(.uppercase)
                .foregroundStyle(DX.Ground.reading.muted)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            Button(action: onSettings) {
                Text(verbatim: String(name.prefix(1)).uppercased())
                    .dxType(.headline)
                    .foregroundStyle(DX.Fill.cream)
                    .frame(width: 44, height: 44)
                    .background(DX.Fill.navy, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Profile and settings"))
        }
    }
}

// MARK: Hero

/// The onboarding "Why", in quotes (UX-06). Shown on both heroes.
struct WhyQuote: View {
    let text: String
    let ground: DX.Ground

    var body: some View {
        Text(verbatim: "“\(text)”")
            .dxFont(16, weight: 600, style: .body)
            .italic()
            .foregroundStyle(ground.ink)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(Text("Your why: \(text)"))
    }
}

/// State A's hero: the countdown to Quit Day, a dot per prep day, and their "Why".
struct TodayPrepHero: View {
    let snap: HomeSnapshot
    let quitDay: Date
    let why: String?
    let ground: DX.Ground
    let crewStage: Int

    @Environment(\.dynamicTypeSize) private var typeSize

    private var daysToGo: Int {
        if case let .prep(days) = snap.phase { return days }
        return 0
    }

    /// "9 days to Quit Day", "1 day to Quit Day", or "Quit Day is today".
    private var countdown: String {
        switch daysToGo {
        case 0: String(localized: "Quit Day is today")
        case 1: String(localized: "1 day to Quit Day")
        default: String(localized: "\(daysToGo) days to Quit Day")
        }
    }

    var body: some View {
        let date = quitDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        let strong = DX.Typeface4.scaledFont(22, weight: 800, style: .title2, dynamicTypeSize: typeSize)
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: DX.Space.s) {
                // "9 days to Quit Day · Thu, 5 Nov" on one line where it fits.
                Text("\(Text(verbatim: countdown).font(strong).foregroundStyle(ground.ink)) · \(Text(verbatim: date))")
                    .dxFont(16, weight: 600, style: .body)
                    .foregroundStyle(ground.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                CrewAvatar(ground: ground, stage: crewStage)
            }
            PrepDots(done: snap.prepDone, total: snap.prepTotal, today: snap.prepDayNumber - 1, ground: ground)
            if let why { WhyQuote(text: why, ground: ground) }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ground.background, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
    }
}

/// A dot per prep day: done ones filled, today's ringed, the rest waiting. A bar for a prep longer than two weeks.
struct PrepDots: View {
    let done: Int
    let total: Int
    /// Today's index on the calendar, from 0.
    let today: Int
    let ground: DX.Ground

    var body: some View {
        let track = ground.ink.opacity(0.16)
        HStack(spacing: DX.Space.s) {
            if total <= 14 {
                HStack(spacing: 8) {
                    ForEach(0..<max(total, 1), id: \.self) { index in
                        Circle()
                            .fill(index < done ? DX.Fill.green : track)
                            .overlay {
                                if index >= done, index == today {
                                    Circle().strokeBorder(DX.Fill.green, lineWidth: 2.5)
                                }
                            }
                            .frame(width: 12, height: 12)
                    }
                }
            } else {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(track)
                        Capsule().fill(DX.Fill.green)
                            .frame(width: geo.size.width * min(1, Double(done) / Double(max(total, 1))))
                    }
                }
                .frame(height: 8)
            }
            Text("\(done) of \(total) done")
                .dxType(.footnote).foregroundStyle(ground.muted)
                .lineLimit(1)
                .fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Prep: \(done) of \(total) sessions done"))
    }
}

/// State B's hero: time free, cumulative resilience, money kept, and their "Why". Resilience never resets to zero
/// (CLIN-07): "45 of 46 days smoke-free · 98%".
struct TodayQuitHero: View {
    /// "3d 14h".
    let timeFree: String
    let resilience: Resilience.Days
    let product: Product
    let moneyKept: Decimal
    let currencyCode: String
    let why: String?
    let ground: DX.Ground
    let crewStage: Int

    /// "45 of 46 days smoke-free · 98%", with "vape-free" or "pouch-free" for the other products.
    private var resilienceLine: String {
        let clear = resilience.clear, total = resilience.total, pct = resilience.percent
        return switch product {
        case .cigarettes: String(localized: "\(clear) of \(total) days smoke-free · \(pct)%")
        case .vape: String(localized: "\(clear) of \(total) days vape-free · \(pct)%")
        case .pouches: String(localized: "\(clear) of \(total) days pouch-free · \(pct)%")
        }
    }

    var body: some View {
        let money = Decimal(floor(NSDecimalNumber(decimal: moneyKept).doubleValue))
            .formatted(.currency(code: currencyCode).precision(.fractionLength(0)))
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: DX.Space.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: timeFree)
                        .dxType(.display)
                        .foregroundStyle(ground.ink)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(verbatim: resilienceLine)
                        .dxFont(16, weight: 700, style: .body)
                        .foregroundStyle(ground.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(money) kept so far")
                        .dxType(.body).foregroundStyle(ground.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(timeFree) free. \(resilienceLine). \(money) kept so far."))
                .accessibilityAddTraits(.isHeader)
                CrewAvatar(ground: ground, stage: crewStage)
            }
            if let why { WhyQuote(text: why, ground: ground) }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ground.background, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
    }
}

/// Xero by day, Glim in the evening, small in the hero's corner.
private struct CrewAvatar: View {
    let ground: DX.Ground
    let stage: Int

    var body: some View {
        Group {
            if ground == .apricot {
                XeroView(mood: .hello, stage: stage, points: 52, animate: false)
            } else {
                GlimView(mood: .calm, stage: stage, points: 52, animate: false)
            }
        }
        .frame(width: 52, height: 52)
        .accessibilityHidden(true)
    }
}

// MARK: Focus

/// State B's focus card (UX-09): what's changing in the body now, and what's next. Opens the health timeline.
/// Wording pending Milan's approval; it reuses the body-change row's lines for now.
struct RecoveryCard: View {
    let product: Product
    let quitDay: Date
    let clock: DayClock
    let now: Date
    let action: () -> Void

    var body: some View {
        let items = HealthTimeline.bundled?.items(for: product) ?? []
        let elapsed = HealthTimeline.elapsedHours(quitDay: quitDay, now: now, clock: clock)
        let (current, next) = HealthTimeline.nowAndNext(items, elapsedHours: elapsed)
        let featured = current ?? next
        // What many people notice (CLIN-01) gets its rough window, never a countdown.
        let line: String = if let next, next.isFelt {
            String(localized: "Next: \(next.title), \(next.when.lowercased())")
        } else if let next {
            String(localized: "Next: \(next.title), \(TodayView.relative(hours: next.fromHours - elapsed))")
        } else {
            String(localized: "Every change on the timeline is under way")
        }
        return Button(action: action) {
            HStack(spacing: 12) {
                HealthBadge(id: featured?.id ?? "",
                            state: current.map { HealthTimeline.state(of: $0, elapsedHours: elapsed) } ?? .underWay(0),
                            size: 48, showsRing: current != nil)
                    .padding(4)
                    .background(DX.Fill.cream, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your body is recovering").dxType(.footnote)
                    Text(verbatim: featured?.title ?? String(localized: "Your body is recovering"))
                        .dxType(.headline).fixedSize(horizontal: false, vertical: true)
                    Text(verbatim: line).dxType(.footnote).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .heavy))
                    .frame(width: 44, height: 44)
                    .background(DX.Fill.cream.opacity(0.2), in: Circle())
                    .accessibilityHidden(true)
            }
            .foregroundStyle(DX.Fill.cream)
            .multilineTextAlignment(.leading)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous)
                    .fill(ColourCard.lesson)
                    .shadow(color: .black.opacity(0.14), radius: 0, x: 0, y: 5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Opens what changes in your body"))
    }
}

// MARK: Bento

/// A bento cell's frame: white card, label row on top, number, then the action at the bottom.
struct BentoCell<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { content }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(DX.Fill.raised, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous).strokeBorder(DX.Fill.hairline))
    }
}

/// The small label at the top of a bento cell, with its icon. Sentence case: the kicker is Today's only caps line.
struct BentoLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage).font(.system(size: 12, weight: .semibold)).accessibilityHidden(true)
            Text(verbatim: title).dxFont(14, weight: 600, style: .footnote).lineLimit(1).minimumScaleFactor(0.85)
        }
        .foregroundStyle(DX.Ground.reading.muted)
    }
}

/// A pill button for a bento cell: "+1 glass", "+5", "+10".
struct BentoPill: View {
    let title: String
    var accent = false

    var body: some View {
        Text(verbatim: title).dxFont(15, weight: 700, style: .footnote)
            .foregroundStyle(accent ? DX.Ground.reading.background : DX.Ground.reading.ink)
            .lineLimit(1).minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(accent ? DX.Ground.reading.ink : DX.Fill.surface, in: Capsule())
    }
}

/// "12 / 9" in the cell's big type, then a quiet unit.
struct BentoNumber: View {
    let value: String
    let unit: String
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let big = DX.Typeface4.scaledFont(30, weight: 800, style: .title1, dynamicTypeSize: typeSize)
        Text("\(Text(verbatim: value).font(big).foregroundStyle(DX.Ground.reading.ink)) \(Text(verbatim: unit))")
            .dxType(.footnote)
            .foregroundStyle(DX.Ground.reading.muted)
            .contentTransition(.numericText())
            .lineLimit(1).minimumScaleFactor(0.7)
    }
}

/// Water (left cell): "7 / 9 glasses" and +1, which logs the usual drink (S27.12).
struct WaterBentoCell: View {
    let profile: UserProfile
    let now: Date

    @Environment(\.modelContext) private var context
    @Query(sort: \WaterEntry.timestamp) private var entries: [WaterEntry]
    @Query private var waterProfiles: [WaterProfile]
    @State private var logged = 0

    var body: some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let todays = WaterDay.entries(entries, on: clock.day(containing: now), clock: clock)
        let total = todays.reduce(0) { $0 + $1.countedMl }
        let goal = waterProfiles.first?.effectiveGoalMl ?? WaterGoal.skippedMl
        let drink = waterProfiles.first?.selectedDrink ?? .glass
        let glasses = WaterFormat.glasses(total)
        let goalGlasses = max(goal / WaterGoal.glassMl, 1)
        let units = waterProfiles.first?.units ?? WaterUnits.default()
        BentoCell {
            // UX-12: "0 / 9 glasses" and "2.25 L daily goal", said once each; the cell's drop says it's water.
            BentoLabel(title: String(localized: "Water"), systemImage: "drop.fill")
                .accessibilityHidden(true)
            BentoNumber(value: "\(glasses)", unit: String(localized: "/ \(goalGlasses) glasses"))
                // UI tests read "3 of 8 glasses" from here.
                .accessibilityLabel(Text("Water · \(glasses) of \(goalGlasses) glasses"))
                .accessibilityIdentifier("today.water.count")
            Text("\(WaterFormat.amount(goal, units: units)) \(WaterFormat.unit(units)) daily goal")
                .dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            Button {
                WaterLog.log(drink, source: .app, in: context)
                logged += 1
                Analytics.track(.waterLogged(source: WaterSource.app.rawValue, drink: drink.rawValue))
            } label: { BentoPill(title: String(localized: "+1")) }
                .buttonStyle(.plain)
                // "Add", not "Log": UI tests find the use log by a button containing "Log".
                .accessibilityLabel(Text("Add \(Text(drink.name))"))
                .accessibilityIdentifier("today.water.add")
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: logged)
    }
}

// MARK: Clinical notes (CLIN-02, CLIN-05, CLIN-11)

/// A short note from Xero on Today, on apricot, with "Got it" and an optional source: Xero's coffee note (CLIN-02) and
/// the swap trap (CLIN-05). Shown only while it applies, and gone once dismissed.
struct XeroNoteCard: View {
    let kicker: String
    let title: String
    let message: String
    var source: HealthSource?
    let onDismiss: () -> Void

    private let ground = DX.Ground.apricot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: DX.Space.s) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: kicker).dxFont(14, weight: 600, style: .footnote).foregroundStyle(ground.muted)
                    Text(verbatim: title).dxType(.headline).foregroundStyle(ground.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                XeroView(mood: .hello, stage: 1, points: 44, animate: false)
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
            Text(verbatim: message).dxType(.footnote).foregroundStyle(ground.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: DX.Space.s) {
                if let source {
                    Link(destination: source.url) {
                        Text("Why?").dxFont(14, weight: 600, style: .footnote).underline().foregroundStyle(ground.ink)
                    }
                    .frame(minHeight: DX.Layout.touchTarget)
                    .accessibilityHint(Text(source.label))
                }
                Spacer(minLength: 0)
                Button(action: onDismiss) {
                    Text("Got it").dxFont(15, weight: 700, style: .footnote)
                        .foregroundStyle(ground.background)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 44)
                        .background(ground.ink, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ground.background, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

/// Today's prep challenge (CLIN-11): one small thing, ticked with one tap.
struct PrepChallengeRow: View {
    let challenge: PrepChallenge
    let done: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: done ? "checkmark" : "bolt.fill").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(done ? DX.Fill.cream : DX.Ground.reading.ink)
                    .frame(width: 32, height: 32)
                    .background(done ? DX.Fill.green : DX.Fill.surface, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's challenge · 1 min").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                    Text(challenge.title).dxType(.body).foregroundStyle(DX.Ground.reading.ink)
                        .strikethrough(done, color: DX.Ground.reading.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if !done {
                        Text(challenge.detail).dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            }
            .padding(14)
            .background(DX.Fill.raised, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(DX.Haptic.commit, trigger: done)
        .accessibilityAddTraits(done ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(Text(done ? "Marks it not done" : "Marks it done"))
    }
}
