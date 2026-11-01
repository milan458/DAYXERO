import Foundation

/// Short exercises for stressful moments (S12). Practical, not clinical: descriptions say what you do, not what it treats.
public enum CalmTool: String, CaseIterable, Sendable, Identifiable {
    case boxBreathing, longerOutBreath, grounding, noticeAndName, dropAnchor

    public var id: String { rawValue }

    public var title: LocalizedStringResource {
        switch self {
        case .boxBreathing: "Box breathing"
        case .longerOutBreath: "Longer out-breath"
        case .grounding: "5-4-3-2-1"
        case .noticeAndName: "Notice and name"
        case .dropAnchor: "Drop anchor"
        }
    }

    public var detail: LocalizedStringResource {
        switch self {
        case .boxBreathing: "In, hold, out, hold."
        case .longerOutBreath: "In 4, hold 7, out 8."
        case .grounding: "Use your five senses."
        case .noticeAndName: "Label the thought. Let it be."
        case .dropAnchor: "Feet down. Come back to the room."
        }
    }

    public var minutes: Int {
        switch self {
        case .grounding: 2
        case .boxBreathing, .longerOutBreath, .noticeAndName, .dropAnchor: 1
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
        public let hint: LocalizedStringResource
    }

    public static let steps: [Step] = [
        Step(count: 5, sense: "things you can see", hint: "Look around slowly. Colours, shapes, light."),
        Step(count: 4, sense: "things you can feel", hint: "Your feet on the floor, the chair, your clothes, the air."),
        Step(count: 3, sense: "things you can hear", hint: "Near and far. Traffic, voices, your own breathing."),
        Step(count: 2, sense: "things you can smell", hint: "Or two smells you like, if nothing's around."),
        Step(count: 1, sense: "thing you can taste", hint: "A sip of water, or just what's in your mouth now."),
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
