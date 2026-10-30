import Foundation
import Observation

/// The Bio-Orb's data, session clock and per-frame motion (S6.7), from DAYXERO_BIO_ORB_SPEC.md.
/// Every value comes from `breathing_orb_data.json`; the view only draws.
public struct OrbData: Decodable, Sendable {
    public struct GradientStop: Decodable, Sendable {
        public let stop: Double
        public let hex: String
        public let alpha: Double
    }

    public struct Tokens: Decodable, Sendable {
        public let canvasBlack, sage, moss, porcelain: String
        public let lensGradient, haloGradient: [GradientStop]
    }

    public struct Geometry: Decodable, Sendable {
        public let sizeFull, sizeMini, ringBaseFactor, haloInner, haloOuter, lensFactor, lensFeather: Double
        public let vertices: Int
    }

    public struct Motion: Decodable, Sendable {
        public let orbTimeStepPerFrame, breathDampingPerFrame, speechDampingPerFrame: Double
        public let holdShimmerAmp, holdShimmerFreq, phaseRippleSeconds: Double
        public let finishedScale, initialBreathScale, initialSpeechEnergy: Double
    }

    public struct PlasmaLayer: Decodable, Sendable {
        public let id, hex, glowHex: String
        public let opacity, widthFull, widthMini, glowFull, glowMini, amp, speed, radiusMult: Double
        public let freq1, freq2: Double
    }

    public struct ReadoutSize: Decodable, Sendable {
        public let labelSize, rowHeight, gap, heroSize, heroSizeSOS, cycleSize, cycleTracking: Double
        public let barWidth, barMaxHeight, barGap, cycleToBars: Double
    }

    public struct Readout: Decodable, Sendable {
        public let full, mini: ReadoutSize
        public let labelOpacity, cycleOpacity: Double
    }

    public struct SOS: Decodable, Sendable {
        public let sessionSeconds: Int
        public let defaultPattern: String
        public let coachingTriggers: [String: Int]
    }

    public struct PhaseHaptic: Decodable, Sendable {
        public let intensityStart, intensityEnd, sharpness: Double
    }

    public struct Pattern: Decodable, Sendable, Identifiable {
        public let id, name, counts, subtitle: String
        public let recommendedCycles: Int
        let phases: [String: Int]
        let scaleTargets: [String: Double]
        let haptics: [String: PhaseHaptic]

        public func seconds(_ phase: BreathPhase) -> Int { phases[phase.rawValue] ?? 0 }
        public func scale(_ phase: BreathPhase) -> Double { scaleTargets[phase.rawValue] ?? 1 }
        public func haptic(_ phase: BreathPhase) -> PhaseHaptic? { haptics[phase.rawValue] }
    }

    public struct Labels: Decodable, Sendable {
        public let badgeSpeaking, badgeIdle, coachButton, pause, resume, start: String
        public let breathingDoneLabel, breathingDoneTranscript, sosDoneLabel, sosDoneTranscript: String
    }

    public struct CoachingLine: Decodable, Sendable, Equatable {
        public let id, trigger, text: String
        public let durationSeconds: Double
    }

    public let version: String
    public let tokens: Tokens
    public let geometry: Geometry
    public let motion: Motion
    public let plasmaLayers: [PlasmaLayer]
    public let readout: Readout
    public let sos: SOS
    public let breathingPatterns: [Pattern]
    public let labels: Labels
    let phaseScripts: [String: [String]]
    public let coachingLines: [CoachingLine]

    public init(data: Data) throws {
        self = try JSONDecoder().decode(OrbData.self, from: data)
    }

    /// The bundled data file. Missing or broken data is a build error, caught by the tests.
    public static let bundled: OrbData = {
        guard let url = Bundle(for: OrbBundleToken.self).url(forResource: "breathing_orb_data", withExtension: "json"),
              let data = try? Data(contentsOf: url), let orb = try? OrbData(data: data)
        else { fatalError("breathing_orb_data.json is missing or invalid") }
        return orb
    }()

    public func pattern(_ id: String) -> Pattern {
        breathingPatterns.first { $0.id == id } ?? breathingPatterns[0]
    }

    public func scripts(_ phase: BreathPhase) -> [String] { phaseScripts[phase.rawValue] ?? [] }

    public func coachingLine(trigger: String) -> CoachingLine? { coachingLines.first { $0.trigger == trigger } }
}

private final class OrbBundleToken {}

public enum BreathPhase: String, CaseIterable, Sendable {
    /// In order. A pattern skips any phase it gives no seconds, so the sigh runs Inhale, TopUp, Exhale, Rest
    /// and the others never meet TopUp.
    case inhale = "Inhale", hold = "Hold", topUp = "TopUp", exhale = "Exhale", rest = "Rest"

    /// Lowercase, for the label: "4 seconds · inhale", "1 second · sip in".
    public var word: String { self == .topUp ? "sip in" : rawValue.lowercased() }
}

/// The one-second session clock: phases, cycles, the SOS countdown and its coaching cues (spec §5).
public struct BreathSession: Sendable, Equatable {
    public enum Mode: Sendable, Equatable {
        /// Section 12: ends after the pattern's recommended cycles.
        case breathing
        /// Section 6: a countdown of this many seconds.
        case sos(seconds: Int)
    }

    public enum Event: Sendable, Equatable {
        case phaseChanged(BreathPhase)
        /// A coaching trigger from the data file, e.g. "mid_session".
        case coach(String)
        case finished
    }

    public let mode: Mode
    public private(set) var pattern: OrbData.Pattern.ID
    public private(set) var phase = BreathPhase.inhale
    /// Seconds left in the phase.
    public private(set) var remaining: Int
    public private(set) var cycle = 1
    /// SOS only: seconds left in the session.
    public private(set) var sosRemaining: Int
    public private(set) var finished = false
    private let triggers: [String: Int]

    public init(mode: Mode, pattern: String, data: OrbData = .bundled) {
        self.mode = mode
        self.pattern = pattern
        remaining = data.pattern(pattern).seconds(.inhale)
        if case let .sos(seconds) = mode { sosRemaining = seconds } else { sosRemaining = 0 }
        triggers = data.sos.coachingTriggers
    }

    public var isSOS: Bool { if case .sos = mode { true } else { false } }

    /// The coaching cue that opens an SOS session (at 180s left).
    public var startTrigger: String? {
        guard isSOS else { return nil }
        return triggers.first { $0.value == sosRemaining }?.key
    }

    /// Switching pattern restarts the breath at Inhale, cycle 1; an SOS countdown carries on.
    public mutating func switchPattern(to id: String, data: OrbData = .bundled) {
        pattern = id
        phase = .inhale
        cycle = 1
        remaining = data.pattern(id).seconds(.inhale)
    }

    /// One second passes.
    public mutating func tick(data: OrbData = .bundled) -> [Event] {
        guard !finished else { return [] }
        var events: [Event] = []
        let pattern = data.pattern(self.pattern)
        remaining -= 1
        if isSOS {
            sosRemaining -= 1
            if let trigger = triggers.first(where: { $0.value == sosRemaining && $0.value > 0 })?.key {
                events.append(.coach(trigger))
            }
            if sosRemaining <= 0 {
                sosRemaining = 0
                finished = true
                return events + [.finished]
            }
        }
        if remaining <= 0 {
            let (next, wrapped) = nextPhase(after: phase, in: pattern)
            if wrapped {
                if mode == .breathing, cycle >= pattern.recommendedCycles {
                    finished = true
                    remaining = 0
                    return events + [.finished]
                }
                cycle = cycle % pattern.recommendedCycles + 1
            }
            phase = next
            remaining = pattern.seconds(next)
            events.append(.phaseChanged(next))
        }
        return events
    }

    /// The next phase with any seconds, and whether it wrapped back to Inhale.
    func nextPhase(after phase: BreathPhase, in pattern: OrbData.Pattern) -> (BreathPhase, Bool) {
        let order = BreathPhase.allCases
        let i = order.firstIndex(of: phase) ?? 0
        for k in 1...order.count {
            let n = order[(i + k) % order.count]
            if pattern.seconds(n) > 0 { return (n, i + k >= order.count) }
        }
        return (phase, false)
    }
}

/// Everything the orb animates (spec §4), advanced once per display frame.
/// The per-frame values aren't observed, so drawing them never invalidates SwiftUI; the readout and pill
/// read the observed values, which only change once a second or when a coaching line starts or ends.
@Observable @MainActor
public final class OrbEngine {
    public let data: OrbData
    public private(set) var session: BreathSession
    public private(set) var running = false
    /// The pill's text: a phase script, a coaching line, or the done line.
    public private(set) var transcript: String
    /// True only while a coaching line plays: drives the badge and the dot.
    public private(set) var coachSpeaking = false
    public private(set) var currentLine: OrbData.CoachingLine?
    /// Which sentence of a coaching line the caption shows (S18.11).
    public private(set) var captionIndex = 0
    /// Whether the transcript is a coaching line, shown a sentence at a time, rather than a short script.
    public private(set) var captionFromLine = false

    @ObservationIgnored public private(set) var orbTime = 0.0
    @ObservationIgnored public private(set) var breathScale: Double
    @ObservationIgnored public private(set) var speechEnergy: Double
    @ObservationIgnored public var reduceMotion = false
    @ObservationIgnored private var last: TimeInterval?
    @ObservationIgnored private var tickAccumulator = 0.0
    @ObservationIgnored private var rippleUntil: TimeInterval = 0
    @ObservationIgnored private var lineEndsAt: TimeInterval?
    @ObservationIgnored private var now: TimeInterval = 0
    @ObservationIgnored private var lineIndex = 0
    @ObservationIgnored private var lineStartedAt: TimeInterval?
    @ObservationIgnored private var lineVoiced = false
    @ObservationIgnored private var lineFragments: [OrbCaptionText.Fragment] = []

    /// Phase changes, coaching cues and the finish, for haptics, speech and the screen around the orb.
    @ObservationIgnored public var onEvent: ((BreathSession.Event) -> Void)?

    public init(mode: BreathSession.Mode, pattern: String? = nil, data: OrbData = .bundled) {
        self.data = data
        let id = pattern ?? data.sos.defaultPattern
        session = BreathSession(mode: mode, pattern: id, data: data)
        breathScale = data.motion.initialBreathScale
        speechEnergy = data.motion.initialSpeechEnergy
        transcript = data.scripts(.inhale).first ?? ""
    }

    public var pattern: OrbData.Pattern { data.pattern(session.pattern) }

    /// Motion counts as "speaking" during a coaching line and for a moment after each phase change.
    public var motionSpeaking: Bool { coachSpeaking || now < rippleUntil }

    // MARK: Control

    public func start() {
        guard !running, !session.finished else { return }
        running = true
        if session.isSOS, session.sosRemaining == sosLength, let trigger = session.startTrigger {
            onEvent?(.coach(trigger))
        }
    }

    public func pause() { running = false; tickAccumulator = 0 }

    /// Fast-forwards the clock without events, for screenshots (`-dx.sosElapsed`).
    public func skip(seconds: Int) {
        for _ in 0..<max(seconds, 0) where !session.finished {
            if session.tick(data: data).contains(.finished) { finish() }
        }
    }

    public func switchPattern(to id: String) {
        session.switchPattern(to: id, data: data)
        if !coachSpeaking { showScript(data.scripts(.inhale).first ?? transcript) }
        rippleUntil = now + data.motion.phaseRippleSeconds
    }

    /// Starts a coaching line. `speaking` is false when voice guidance is off: the line then shows as a caption
    /// for its set duration. Call `lineEnded()` when speech finishes.
    public func beginLine(_ line: OrbData.CoachingLine, voiced: Bool) {
        currentLine = line
        coachSpeaking = true
        transcript = line.text
        captionFromLine = true
        captionIndex = 0
        lineFragments = OrbCaptionText.fragments(line.text)
        lineStartedAt = now
        lineVoiced = voiced
        lineEndsAt = now + (voiced ? line.durationSeconds + 8 : line.durationSeconds)
    }

    /// The speech synthesiser is about to speak from this UTF-16 offset of the current line.
    public func spoke(upTo location: Int) {
        guard coachSpeaking, lineVoiced else { return }
        let index = OrbCaptionText.fragment(containing: location, in: lineFragments)
        if index != captionIndex { captionIndex = index }
    }

    /// The caption text: the sentence of the coaching line being said, or the whole phase script.
    public var caption: String {
        guard captionFromLine else { return transcript }
        let parts = OrbCaptionText.fragments(transcript)
        guard !parts.isEmpty else { return transcript }
        return parts[min(captionIndex, parts.count - 1)].text
    }

    /// Ends the line; the caption keeps its last sentence until the next script replaces it.
    public func lineEnded() {
        coachSpeaking = false
        currentLine = nil
        lineEndsAt = nil
        lineStartedAt = nil
    }

    private func showScript(_ text: String) {
        transcript = text
        captionFromLine = false
        captionIndex = 0
    }

    /// The next line in rotation, for a tap on the orb or the coach button.
    public func nextLine() -> OrbData.CoachingLine {
        defer { lineIndex += 1 }
        return data.coachingLines[lineIndex % data.coachingLines.count]
    }

    // MARK: Frames

    /// Advances one display frame. `time` is a monotonic clock in seconds.
    public func advance(to time: TimeInterval) {
        let dt = min(max(time - (last ?? time), 0), 0.050)
        last = time
        now = time
        let k = dt / (1.0 / 60)

        if running {
            tickAccumulator += dt
            while tickAccumulator >= 1, running {
                tickAccumulator -= 1
                tick()
            }
        }
        // Without voice, the caption moves through the line's sentences over its set duration.
        if coachSpeaking, !lineVoiced, let start = lineStartedAt, let line = currentLine {
            let index = OrbCaptionText.fragment(at: now - start, duration: line.durationSeconds, in: lineFragments)
            if index != captionIndex { captionIndex = index }
        }
        if let end = lineEndsAt, now >= end { lineEnded() }

        orbTime += data.motion.orbTimeStepPerFrame * k
        var target = pattern.scale(session.phase)
        if session.phase == .hold { target += sin(orbTime * data.motion.holdShimmerFreq) * data.motion.holdShimmerAmp }
        if session.finished { target = data.motion.finishedScale }
        breathScale += (target - breathScale) * (1 - pow(1 - data.motion.breathDampingPerFrame, k))

        let syllable = motionSpeaking
            ? 0.45 + abs(sin(orbTime * 4.8) * cos(orbTime * 2.3)) * 0.65
            : 0.22 + sin(orbTime * 1.5) * 0.08
        speechEnergy += (syllable - speechEnergy) * (1 - pow(1 - data.motion.speechDampingPerFrame, k))
    }

    /// The energy the rings and bars use: fixed low under Reduce Motion.
    public var drawEnergy: Double { reduceMotion ? 0.1 : speechEnergy }

    private var sosLength: Int {
        if case let .sos(seconds) = session.mode { seconds } else { 0 }
    }

    private func tick() {
        for event in session.tick(data: data) {
            switch event {
            case let .phaseChanged(phase):
                rippleUntil = now + data.motion.phaseRippleSeconds
                if !coachSpeaking {
                    let pool = data.scripts(phase)
                    if !pool.isEmpty { showScript(pool[session.cycle % pool.count]) }
                }
            case .finished:
                finish()
            case .coach:
                break
            }
            onEvent?(event)
        }
    }

    private func finish() {
        running = false
        lineEnded()
        showScript(session.isSOS
            ? data.labels.sosDoneTranscript
            : data.labels.breathingDoneTranscript.replacingOccurrences(of: "{N}", with: "\(pattern.recommendedCycles)"))
    }
}

/// The SOS caption shows a coaching line one sentence at a time, in step with the voice (S18.11).
public enum OrbCaptionText {
    public struct Fragment: Equatable, Sendable {
        public let text: String
        /// UTF-16 offset in the full line where this sentence starts, as the speech synthesiser counts.
        public let start: Int
    }

    /// The line's sentences, split after `.`, `!`, `?` or an ellipsis that's followed by a space.
    /// A line with one sentence comes back whole.
    public static func fragments(_ text: String) -> [Fragment] {
        var result: [Fragment] = []
        var current = ""
        var start = 0
        var offset = 0
        var lastWasEnd = false
        for character in text {
            let width = String(character).utf16.count
            if lastWasEnd, character.isWhitespace {
                let trimmed = current.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { result.append(Fragment(text: trimmed, start: start)) }
                current = ""
                start = offset + width
                lastWasEnd = false
            } else {
                if current.isEmpty, character.isWhitespace {
                    start = offset + width
                } else {
                    current.append(character)
                }
                lastWasEnd = ".!?…".contains(character)
            }
            offset += width
        }
        let trimmed = current.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { result.append(Fragment(text: trimmed, start: start)) }
        return result
    }

    /// The sentence holding UTF-16 offset `location`.
    public static func fragment(containing location: Int, in fragments: [Fragment]) -> Int {
        fragments.lastIndex { $0.start <= location } ?? 0
    }

    /// The sentence showing `elapsed` seconds into a line that lasts `duration`, giving each sentence time in
    /// proportion to its length.
    public static func fragment(at elapsed: Double, duration: Double, in fragments: [Fragment]) -> Int {
        guard fragments.count > 1, duration > 0 else { return 0 }
        let total = Double(fragments.reduce(0) { $0 + $1.text.count })
        var end = 0.0
        for (index, fragment) in fragments.enumerated() {
            end += duration * Double(fragment.text.count) / total
            if elapsed < end { return index }
        }
        return fragments.count - 1
    }
}
