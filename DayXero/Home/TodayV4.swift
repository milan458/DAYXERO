import DayXeroCore
import SwiftData
import SwiftUI

// Today's state and clock. The screen itself (Today redesign, 4 Nov 2026) is the sky hero in TodayHero.swift and the
// focus card and timeline in TodayTimeline.swift. State A runs from prep day 1 to Day Xero; State B starts once Day
// Xero's commit is held.

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

    /// From 6 PM until the day starts at 6 AM, the same hours the focus card hands over to Glim (`TodayFocus`). Today
    /// goes fully dark then, even in light mode (Milan, 4 Nov 2026), so the night sky, the cards and the tab bar agree.
    static func isNight(at now: Date) -> Bool {
        let hour = hour(at: now)
        return hour >= TodayFocus.eveningHour || hour < TodayFocus.dayStartHour
    }

    /// Xero's apricot by day, Glim's violet at night.
    static func ground(at now: Date) -> DX.Ground {
        isNight(at: now) ? .violet : .apricot
    }

    /// "Good morning, Milan" until noon, "Good afternoon" until 6 PM, then "Good evening".
    static func greeting(at now: Date, name: String) -> String {
        let hour = hour(at: now)
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        switch hour {
        case TodayFocus.dayStartHour..<12:
            return trimmed.isEmpty ? String(localized: "Good morning") : String(localized: "Good morning, \(trimmed)")
        case 12..<TodayFocus.eveningHour:
            return trimmed.isEmpty ? String(localized: "Good afternoon") : String(localized: "Good afternoon, \(trimmed)")
        default:
            return trimmed.isEmpty ? String(localized: "Good evening") : String(localized: "Good evening, \(trimmed)")
        }
    }
}

// MARK: Focus

/// The recovery card's three lines (wording approved by Milan, 3 Nov 2026).
/// - "Happening now" with the change under way and "Next: … · in 2 days" for the next one;
/// - "Coming up" with the next change and "Starts in 2 days" when nothing is under way, so nothing repeats;
/// - "Many people notice" with that change's own line: those changes (CLIN-01) are never counted down, and the
///   "Next" line skips them;
/// - at the end, "Your body has come a long way" / "Every change on the timeline has started" / "See them all".
struct RecoveryCopy: Equatable {
    let kicker: String
    let title: String
    let line: String
    /// The change the badge shows, if any.
    let featuredID: String?

    @MainActor
    static func make(_ items: [HealthTimeline.Item], elapsedHours elapsed: Double) -> RecoveryCopy {
        let (current, next) = HealthTimeline.nowAndNext(items, elapsedHours: elapsed)
        let nextCounted = items
            .filter { !$0.isFelt && HealthTimeline.state(of: $0, elapsedHours: elapsed) == .ahead }
            .min { $0.fromHours < $1.fromHours }
        guard let featured = current ?? next else {
            return RecoveryCopy(kicker: String(localized: "Your body has come a long way"),
                                title: String(localized: "Every change on the timeline has started"),
                                line: String(localized: "See them all"), featuredID: nil)
        }
        if featured.isFelt {
            return RecoveryCopy(kicker: String(localized: "Many people notice"), title: featured.title,
                                line: featured.line.isEmpty ? featured.when : featured.line, featuredID: featured.id)
        }
        if current == nil {
            return RecoveryCopy(kicker: String(localized: "Coming up"), title: featured.title,
                                line: String(localized: "Starts \(TodayView.relative(hours: featured.fromHours - elapsed))"),
                                featuredID: featured.id)
        }
        let line: String = if let nextCounted {
            String(localized: "Next: \(nextCounted.title) · \(TodayView.relative(hours: nextCounted.fromHours - elapsed))")
        } else {
            String(localized: "See them all")
        }
        return RecoveryCopy(kicker: String(localized: "Happening now"), title: featured.title, line: line, featuredID: featured.id)
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
