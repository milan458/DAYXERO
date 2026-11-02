import Foundation

/// Xero's coffee note for Quit Day week (CLIN-02, 2 Nov 2026). Chemicals in tobacco smoke, not nicotine, make the
/// liver clear caffeine about twice as fast. Once the smoke stops, that speed-up fades, so the same coffee hits about
/// twice as hard: jittery, wired, worse sleep, and easy to mistake for a craving. Vapes, pouches and NRT don't do this,
/// so the note is for people who smoke and named coffee as a trigger.
public enum CaffeineAlert {
    /// From Quit Day (0) through the end of its first week.
    public static let days = 0..<7

    public static func applies(products: [Product], triggers: [Trigger], daysSinceQuit: Int) -> Bool {
        products.contains(.cigarettes) && triggers.contains(.coffee) && days.contains(daysSinceQuit)
    }

    public static let title: LocalizedStringResource = "Coffee hits harder this week"
    /// In Xero's voice: first person, calm, no exclamation marks.
    public static let body: LocalizedStringResource = "Smoke made your body clear caffeine about twice as fast. Without it, the same cup hits about twice as hard: jittery, wired, worse sleep, and easy to mistake for a craving. I'd halve your coffee this week."
}
