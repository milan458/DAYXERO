import Foundation

/// One small thing a day during prep (CLIN-11, 2 Nov 2026). Prep asks people to keep using as normal, which can make
/// the week feel like waiting, and most people who drop out of a quit app do it in the first week. A daily
/// one-minute challenge gives each prep day a win of its own. Separate from the sessions' missions: no lesson needed,
/// nothing to log, done with one tap. Content is a draft for Milan to review.
public struct PrepChallenge: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: LocalizedStringResource
    public let detail: LocalizedStringResource

    public static let all: [PrepChallenge] = [
        PrepChallenge(id: "wallpaper", title: "Put your why on your lock screen",
                      detail: "A photo or a few words. You'll see it every time you reach for your phone."),
        PrepChallenge(id: "water-first", title: "Water before your next one",
                      detail: "Drink a full glass first, then decide. Notice if the urge changed."),
        PrepChallenge(id: "other-hand", title: "Use your other hand once",
                      detail: "Hold it in the hand you don't normally use. Notice how odd it feels: that's the autopilot."),
        PrepChallenge(id: "tell-one", title: "Tell one person your Quit Day",
                      detail: "A text is enough. Saying it out loud makes it real."),
        PrepChallenge(id: "move-spot", title: "Move one trigger",
                      detail: "Put the lighter, the charger or the tin somewhere new, so reaching for it takes a thought."),
        PrepChallenge(id: "habit-or-craving", title: "Ask: craving or habit?",
                      detail: "Before one today, ask yourself which it is. No need to change anything, just notice."),
        PrepChallenge(id: "stock-up", title: "Stock your quit kit",
                      detail: "Gum, mints, something crunchy, a water bottle. Put them where your nicotine used to be."),
        PrepChallenge(id: "note-to-day-three", title: "Write one line to you on Day 3",
                      detail: "What will you want to hear when it's hard? Save it in your notes."),
    ]

    /// The challenge for prep day `n` (from 1). A prep longer than the list goes round again.
    public static func forPrepDay(_ n: Int) -> PrepChallenge {
        all[(max(n, 1) - 1) % all.count]
    }
}
