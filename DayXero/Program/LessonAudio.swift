import AVFoundation
import DayXeroCore
import NaturalLanguage
import SwiftUI

/// Plays a lesson's audio and keeps track of which sentence of the transcript is being spoken.
/// With a bundled recording it plays the file; until one exists it reads the transcript with on-device speech.
@MainActor @Observable
final class LessonNarrator: NSObject, AVSpeechSynthesizerDelegate {
    static let speeds: [Double] = [1, 1.25, 0.8]

    let sentences: [String]
    private(set) var index = 0
    private(set) var playing = false
    private(set) var finished = false
    private(set) var speed = 1.0
    /// Seconds of audio, from the file, or estimated from the transcript at normal speed.
    private(set) var total: Double

    @ObservationIgnored private let url: URL?
    @ObservationIgnored private var player: AVPlayer?
    @ObservationIgnored private var observer: Any?
    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private var current: ObjectIdentifier?
    @ObservationIgnored private var sentenceStartedAt: Date?
    /// Where each sentence starts, in seconds and as a share of the transcript's characters.
    @ObservationIgnored private let starts: [Double]
    @ObservationIgnored private let durations: [Double]
    @ObservationIgnored var onFinish: (() -> Void)?

    init(transcript: String, url: URL?, seconds: Int) {
        sentences = Self.split(transcript)
        self.url = url
        // About 2.6 words a second at the coach's speaking rate.
        let estimated = sentences.map { max(Double($0.split(separator: " ").count) / 2.6, 1.2) }
        let estimatedTotal = estimated.reduce(0, +)
        let length = url == nil ? estimatedTotal : Double(max(seconds, 1))
        // With a recording the sentences share its length by their number of characters.
        let weights = url == nil ? estimated : sentences.map { Double(max($0.count, 1)) }
        let weightTotal = max(weights.reduce(0, +), 1)
        durations = weights.map { $0 / weightTotal * length }
        var running = 0.0
        starts = durations.map { d in defer { running += d }; return running }
        total = length
        super.init()
        synthesizer.delegate = self
    }

    static func split(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var out: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let s = text[range].trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty { out.append(s) }
            return true
        }
        return out.isEmpty ? [text] : out
    }

    // MARK: Time

    /// Seconds into the audio, at normal speed.
    func elapsed(at now: Date = .now) -> Double {
        if finished { return total }
        if let player { return min(max(player.currentTime().seconds.isFinite ? player.currentTime().seconds : 0, 0), total) }
        guard starts.indices.contains(index) else { return 0 }
        let into = playing ? (sentenceStartedAt.map { now.timeIntervalSince($0) * speed } ?? 0) : 0
        return starts[index] + min(into, durations[index])
    }

    private func sentence(at seconds: Double) -> Int {
        starts.lastIndex { $0 <= seconds + 0.01 } ?? 0
    }

    // MARK: Controls

    func toggle() {
        if playing { pause() } else { play() }
    }

    func play() {
        if finished { finished = false; index = 0; player?.seek(to: .zero) }
        activate()
        playing = true
        if let url {
            if player == nil { makePlayer(url) }
            player?.playImmediately(atRate: Float(speed))
        } else {
            speak(from: index)
        }
    }

    func pause() {
        playing = false
        player?.pause()
        stopSpeech()
        sentenceStartedAt = nil
    }

    func skip(_ seconds: Double) {
        seek(to: min(max(elapsed() + seconds, 0), total - 0.5))
    }

    func seek(to seconds: Double) {
        finished = false
        if let player {
            player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
            index = sentence(at: seconds)
        } else {
            index = sentence(at: seconds)
            if playing { speak(from: index) }
        }
    }

    func jump(toSentence i: Int) {
        guard starts.indices.contains(i) else { return }
        seek(to: starts[i])
        if !playing { play() }
    }

    func cycleSpeed() {
        let i = Self.speeds.firstIndex(of: speed) ?? 0
        speed = Self.speeds[(i + 1) % Self.speeds.count]
        if playing {
            if player != nil { player?.rate = Float(speed) } else { speak(from: index) }
        }
    }

    func stop() {
        pause()
        if let observer { player?.removeTimeObserver(observer) }
        observer = nil
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: Recording

    private func makePlayer(_ url: URL) {
        let player = AVPlayer(url: url)
        self.player = player
        observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self else { return }
                let t = time.seconds
                if t.isFinite { self.index = self.sentence(at: t) }
                if t >= self.total - 0.3, self.playing { self.reachedEnd() }
            }
        }
    }

    // MARK: On-device voice

    private func speak(from i: Int) {
        stopSpeech()
        guard sentences.indices.contains(i) else { reachedEnd(); return }
        index = i
        let utterance = AVSpeechUtterance(string: sentences[i])
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier == "en" ? nil : "en-US")
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = Float(min(max(0.46 * speed, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate))
        utterance.pitchMultiplier = 0.96
        utterance.postUtteranceDelay = 0.35
        current = ObjectIdentifier(utterance)
        sentenceStartedAt = .now
        synthesizer.speak(utterance)
    }

    private func stopSpeech() {
        current = nil
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.spoke(id) }
    }

    private func spoke(_ id: ObjectIdentifier) {
        guard id == current, playing else { return }
        speak(from: index + 1)
    }

    private func reachedEnd() {
        playing = false
        finished = true
        current = nil
        sentenceStartedAt = nil
        index = max(sentences.count - 1, 0)
        player?.pause()
        onFinish?()
    }

    private func activate() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
    }
}

/// The audio step of a lesson: a synced transcript that follows the voice, a waveform scrubber,
/// ±15 seconds, speed, and play/pause. The lesson moves on to its exercise when the audio ends.
struct LessonAudioStep: View {
    let title: String
    let subtitle: String
    let onFinish: () -> Void

    @State private var narrator: LessonNarrator
    @State private var scrubbing: Double?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(title: String, subtitle: String, file: String?, seconds: Int, transcript: String, onFinish: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.onFinish = onFinish
        let url: URL? = file.flatMap { file in
            let name = (file as NSString).deletingPathExtension, ext = (file as NSString).pathExtension
            return Bundle.main.url(forResource: name, withExtension: ext.isEmpty ? nil : ext)
        }
        _narrator = State(initialValue: LessonNarrator(transcript: transcript, url: url, seconds: seconds))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Audio session", systemImage: "headphones").dxText(.micro)
                Text(title).dxText(.title)
                if !subtitle.isEmpty { Text(subtitle).dxText(.subtitle) }
            }
            transcript
            playerCard
        }
        .onAppear { narrator.onFinish = { finished() } }
        .onDisappear { narrator.stop() }
    }

    private func finished() {
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            onFinish()
        }
    }

    // MARK: Transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.s) {
                    ForEach(Array(narrator.sentences.enumerated()), id: \.offset) { i, sentence in
                        let now = i == narrator.index
                        Button { narrator.jump(toSentence: i) } label: {
                            Text(verbatim: sentence)
                                .font(.custom(now ? DX.Typeface.semibold : DX.Typeface.regular, size: now ? 21 : 18, relativeTo: .body))
                                .foregroundStyle(now ? DX.Palette.text : DX.Palette.faint)
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .id(i)
                        .accessibilityHint(Text("Plays from here"))
                    }
                }
                .padding(.vertical, DX.Space.s)
                .animation(DX.Motion.animation(DX.Motion.glide, reduceMotion: reduceMotion), value: narrator.index)
            }
            .frame(minHeight: 220, maxHeight: 320)
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.08),
                                         .init(color: .black, location: 0.88), .init(color: .clear, location: 1)],
                                 startPoint: .top, endPoint: .bottom))
            .onChange(of: narrator.index) { _, i in
                withAnimation(DX.Motion.animation(DX.Motion.glide, reduceMotion: reduceMotion)) { proxy.scrollTo(i, anchor: .center) }
            }
        }
    }

    // MARK: Player

    private var playerCard: some View {
        VStack(spacing: DX.Space.s) {
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                let elapsed = scrubbing ?? narrator.elapsed(at: context.date)
                let fraction = narrator.total > 0 ? elapsed / narrator.total : 0
                VStack(spacing: 6) {
                    LessonWaveform(progress: fraction)
                        .frame(height: 36)
                        .overlay {
                            GeometryReader { geo in
                                Color.clear.contentShape(Rectangle())
                                    .gesture(DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            scrubbing = narrator.total * min(max(value.location.x / geo.size.width, 0), 1)
                                        }
                                        .onEnded { _ in
                                            if let scrubbing { narrator.seek(to: scrubbing) }
                                            scrubbing = nil
                                        })
                            }
                        }
                        .accessibilityElement()
                        .accessibilityLabel(Text("Position"))
                        .accessibilityValue(Text(Duration.seconds(elapsed), format: .time(pattern: .minuteSecond)))
                        .accessibilityAdjustableAction { direction in
                            narrator.skip(direction == .increment ? 15 : -15)
                        }
                    HStack {
                        Text(Duration.seconds(elapsed), format: .time(pattern: .minuteSecond))
                        Spacer()
                        Text(Duration.seconds(narrator.total), format: .time(pattern: .minuteSecond))
                    }
                    .font(.custom(DX.Typeface.mono, size: 12, relativeTo: .caption))
                    .foregroundStyle(DX.Palette.muted)
                }
            }
            HStack(spacing: 0) {
                Button { narrator.cycleSpeed() } label: {
                    Text(verbatim: narrator.speed.formatted(.number.precision(.fractionLength(1...2))) + "×")
                        .font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
                        .foregroundStyle(DX.Palette.text)
                        .frame(minWidth: 52, minHeight: 34)
                        .background(DX.Palette.surface2, in: Capsule())
                }
                .accessibilityLabel(Text("Speed"))
                .accessibilityValue(Text(verbatim: "\(narrator.speed)×"))
                Spacer()
                Button { narrator.skip(-15) } label: { Image(systemName: "gobackward.15").font(.system(size: 22)) }
                    .accessibilityLabel(Text("Back 15 seconds"))
                    .frame(width: 48, height: 48)
                Button { narrator.toggle() } label: {
                    Image(systemName: narrator.playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(DX.Palette.onPrimary)
                        .frame(width: 56, height: 56)
                        .background(DX.Palette.primary, in: Circle())
                }
                .padding(.horizontal, DX.Space.s)
                .accessibilityLabel(Text(narrator.playing ? "Pause" : "Play"))
                Button { narrator.skip(15) } label: { Image(systemName: "goforward.15").font(.system(size: 22)) }
                    .accessibilityLabel(Text("Forward 15 seconds"))
                    .frame(width: 48, height: 48)
                Spacer()
                Color.clear.frame(width: 52, height: 34)
            }
            .buttonStyle(.plain)
            .foregroundStyle(DX.Palette.text)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            if narrator.finished {
                Label("Nice. On to the exercise.", systemImage: "checkmark")
                    .font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
                    .foregroundStyle(DX.Palette.accentInk)
            }
        }
        .padding(DX.Space.m)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(DX.Palette.hairline))
    }
}

/// A still sage waveform: played bars in sage, the rest as track.
struct LessonWaveform: View {
    let progress: Double

    var body: some View {
        Canvas { context, size in
            let bar: CGFloat = 3, gap: CGFloat = 3
            let count = Int((size.width + gap) / (bar + gap))
            for i in 0..<max(count, 1) {
                // A fixed, speech-like shape so the bars don't jump about.
                let t = Double(i)
                let h = 0.25 + 0.75 * abs(sin(t * 0.55) * 0.6 + sin(t * 1.7 + 1) * 0.3 + sin(t * 0.13) * 0.1)
                let height = max(size.height * h, 4)
                let x = CGFloat(i) * (bar + gap)
                let rect = CGRect(x: x, y: (size.height - height) / 2, width: bar, height: height)
                let played = (x + bar / 2) / size.width <= progress
                context.fill(Path(roundedRect: rect, cornerRadius: bar / 2),
                             with: .color(played ? DX.Palette.sage : DX.Palette.track))
            }
        }
        .accessibilityHidden(true)
    }
}
