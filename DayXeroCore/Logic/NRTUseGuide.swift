import Foundation

/// How to use NRT well (CLIN-03, 2 Nov 2026): the "chew and park" technique for gum, and the 16- or 24-hour choice for
/// patches. Technique, not dosing: the dose always comes from the person's own pack.
public enum NRTUseGuide {
    public struct Step: Sendable, Equatable {
        public let title: LocalizedStringResource
        public let detail: LocalizedStringResource
    }

    /// Nicotine gum isn't chewed like ordinary gum. Chewed fast, the nicotine is swallowed, which wastes it and can
    /// cause hiccups, heartburn or nausea. Parked against the cheek, it's absorbed through the lining of the mouth.
    public static let chewAndPark: [Step] = [
        Step(title: "Chew slowly", detail: "A few slow chews, until you taste a peppery or tingly flavour."),
        Step(title: "Park it", detail: "Tuck it between your cheek and gum, and leave it there until the tingle fades. About a minute."),
        Step(title: "Chew again", detail: "A few more slow chews, then park it in a different spot."),
        Step(title: "Keep going", detail: "Chew and park for about 30 minutes, then throw it away."),
    ]

    /// The tip under the steps.
    public static let chewAndParkTip: LocalizedStringResource =
        "Skip coffee, juice and fizzy drinks for 15 minutes before and while you use it: they stop the nicotine getting in."

    /// A 16-hour patch comes off this long after the fresh-patch time.
    public static let patchOffMinutes = 16 * 60

    /// Why someone might pick each. Many 24-hour patch labels say to take it off at bedtime if sleep is disturbed.
    public static let overnightDetail: LocalizedStringResource =
        "Covers the first-thing-in-the-morning cravings. Best if you usually reach for nicotine soon after waking."
    public static let bedtimeDetail: LocalizedStringResource =
        "Vivid dreams or broken sleep? Taking it off at bedtime often helps. Check your pack's label says you can."
}
