import Foundation

/// What Craving SOS offers while a wave rides (S27.18): the person's own break menu from the program (W2S1 saves
/// `break_menu`, W4S1 adds a way to move as `move_choice`), ordered by what has helped them most after past waves,
/// and a reminder to use fast-acting NRT when they use some.
public enum BreakMenu {
    /// The saved answer keys that make up the menu.
    public static let menuKey = "break_menu"
    public static let moveKey = "move_choice"
    /// The session that builds the menu; its opening day is shown before a menu exists.
    public static let buildingSessionId = "W2S1"

    /// The menu: saved breaks, then the way to move if it isn't already one of them; blanks and repeats dropped.
    public static func items(menu: [String], move: String?) -> [String] {
        var seen = Set<String>()
        return (menu + [move].compactMap { $0 })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }

    /// Most helpful first: by how often each was picked as "What helped?", then in the person's own order.
    public static func ordered(_ items: [String], helped: [String]) -> [String] {
        let counts = Dictionary(helped.map { ($0.lowercased(), 1) }, uniquingKeysWith: +)
        return items.enumerated()
            .sorted { a, b in
                let ca = counts[a.element.lowercased()] ?? 0, cb = counts[b.element.lowercased()] ?? 0
                return ca != cb ? ca > cb : a.offset < b.offset
            }
            .map(\.element)
    }

    /// Gum, lozenges and inhalers act within minutes; a patch is steady background, so it gets no "use it now" row.
    public static func hasFastActingNRT(_ formats: [NRTType]) -> Bool {
        formats.contains { $0 != .patch }
    }
}
