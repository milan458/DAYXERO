import Foundation

/// Short exercises for stressful moments (S12). Practical, not clinical: descriptions say what you do, not what it treats.
public enum CalmTool: String, CaseIterable, Sendable, Identifiable {
    case boxBreathing, longerOutBreath, grounding, noticeAndName, dropAnchor

    public var id: String { rawValue }

    public var title: LocalizedStringResource {
        switch self {
        case .boxBreathing: "Box breathing"
        case .longerOutBreath: "Wind down"
        case .grounding: "Grounding"
        case .noticeAndName: "Notice the urge"
        case .dropAnchor: "Drop anchor"
        }
    }

    public var detail: LocalizedStringResource {
        switch self {
        case .boxBreathing: "In, hold, out"
        case .longerOutBreath: "Before sleep"
        case .grounding: "Five senses"
        case .noticeAndName: "Just watch"
        case .dropAnchor: "Feet down. Come back to the room."
        }
    }

    public var minutes: Int {
        switch self {
        case .grounding: 3
        case .longerOutBreath: 5
        case .boxBreathing, .noticeAndName, .dropAnchor: 1
        }
    }

    public var systemImage: String {
        switch self {
        case .boxBreathing: "square"
        case .longerOutBreath: "wind"
        case .grounding: "eye"
        case .noticeAndName: "tag"
        case .dropAnchor: "figure.stand"
        }
    }

    /// Breathing tools run on the Bio-Orb with this pattern from breathing_orb_data.json (S12.4).
    /// They end after the pattern's recommended cycles; the other tools are as long as you take.
    public var orbPattern: String? {
        switch self {
        case .boxBreathing: "box"
        case .longerOutBreath: "478"
        case .grounding, .noticeAndName, .dropAnchor: nil
        }
    }

    /// The four tools on the Calm tab (v5, 056), in their grid order. Drop anchor stays in the evening wind-down.
    public static let shelf: [CalmTool] = [.boxBreathing, .grounding, .noticeAndName, .longerOutBreath]

    /// Wind down runs the 4-7-8 breath for about five minutes (16 rounds of 19 s).
    public var cycles: Int? { self == .longerOutBreath ? 16 : nil }

    /// Minutes of calm in `uses` (finished tools only), as on the Calm tab and its done screen.
    public static func minutes(in uses: [ToolUse]) -> Int {
        uses.filter(\.finished).reduce(0) { $0 + (CalmTool(rawValue: $1.toolRaw)?.minutes ?? 0) }
    }
}

/// Box breathing: four equal sides of four seconds (S12.1).
public enum BoxBreath {
    public static let sideSeconds: TimeInterval = 4

    public enum Side: Int, CaseIterable, Sendable {
        case breatheIn, holdIn, breatheOut, holdOut
    }

    public struct Moment: Sendable, Equatable {
        public let side: Side
        /// 0…1 along the current side.
        public let progress: Double
        /// 4, 3, 2, 1 counting down on each side.
        public let count: Int
        /// 0…1 around the whole square.
        public let around: Double
    }

    public static func moment(at elapsed: TimeInterval) -> Moment {
        let t = max(elapsed, 0).truncatingRemainder(dividingBy: sideSeconds * 4)
        let index = min(Int(t / sideSeconds), 3)
        let into = t - Double(index) * sideSeconds
        return Moment(side: Side(rawValue: index) ?? .breatheIn, progress: into / sideSeconds,
                      count: max(Int(sideSeconds - into.rounded(.down)), 1), around: t / (sideSeconds * 4))
    }
}

/// 5-4-3-2-1 grounding: one sense per step.
public enum Grounding {
    public struct Step: Sendable, Equatable {
        public let count: Int
        public let sense: LocalizedStringResource
        /// The one-line instruction under the count (v5, 058).
        public let line: LocalizedStringResource
        public let hint: LocalizedStringResource
    }

    public static let steps: [Step] = [
        Step(count: 5, sense: "things you can see", line: "Let your eyes move slowly.", hint: "Colours, shapes, light, something you hadn't noticed."),
        Step(count: 4, sense: "things you can feel", line: "Touch them, or just notice them.", hint: "Your feet on the floor, the chair, your clothes, the air on your skin."),
        Step(count: 3, sense: "things you can hear", line: "Listen near, then far.", hint: "Traffic, voices, the hum of a room, your own breathing."),
        Step(count: 2, sense: "things you can smell", line: "Breathe in through your nose.", hint: "Or two smells you like, if nothing's around."),
        Step(count: 1, sense: "thing you can taste", line: "Notice what's there now.", hint: "A sip of water, or just what's in your mouth."),
    ]
}

/// Notice and name, a brief ACT-style exercise.
public enum NoticeAndName {
    public static let thoughts: [LocalizedStringResource] = [
        "I need one", "I can't cope", "Just one won't hurt", "I deserve it", "This will never get easier",
    ]
    public static let breaths = 3
}

/// Drop anchor, a brief ACT-style exercise in three steps.
public enum DropAnchor {
    public static let steps: [(title: LocalizedStringResource, body: LocalizedStringResource)] = [
        ("Notice what's here", "Notice the thoughts and feelings that are here right now. You don't have to change them."),
        ("Feel your body", "Push your feet into the floor. Straighten your back. Feel your hands, your shoulders, your breath."),
        ("Come back to the room", "Look around. Notice where you are and what you're doing. Then carry on with it."),
    ]
}

/// "Don't I deserve a reward?" (CLIN-04, 2 Nov 2026): a defusion card for the moment after finishing a task or chore,
/// when nicotine shows up dressed as a reward. Three steps: notice the thought, see what it's offering, pick a real
/// reward. ACT-style, like Notice and name. Logged as a calm tool use with `toolID`.
public enum RewardDefusion {
    public static let toolID = "rewardDefusion"

    public static let thought: LocalizedStringResource = "Don't I deserve a reward?"

    public static let steps: [(title: LocalizedStringResource, body: LocalizedStringResource)] = [
        ("Notice the thought",
         "Say it this way: \u{201C}I'm noticing the thought that I deserve a reward.\u{201D} It's a thought, not an order."),
        ("You do deserve one",
         "The thought is right about that. It's just offering the old reward. Most of the lift nicotine gave was relief from the craving it caused in the first place."),
        ("Pick a real one",
         "Choose something that's a reward on its own, and give it to yourself now."),
    ]

    /// Rewards to pick from on the last step.
    public static let rewards: [LocalizedStringResource] = [
        "A proper tea or coffee", "Five minutes outside", "A song, loud", "A snack I love",
        "Tell someone what I finished", "A stretch", "Ten minutes of something fun",
    ]
}
