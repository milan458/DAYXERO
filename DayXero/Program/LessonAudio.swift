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
    /// Loudness of the recording, 30 readings a second, 0…1.
    @ObservationIgnored private var loudness: [Float] = []
    /// When the on-device voice last started a word, and how long that word is.
    @ObservationIgnored private var wordAt: Date?
    @ObservationIgnored private var wordLength = 0

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
        if let url {
            Task.detached(priority: .utility) {
                let values = Self.loudness(of: url)
                await MainActor.run { self.loudness = values }
            }
        }
    }

    /// Reads the recording once and keeps how loud each thirtieth of a second is, scaled so normal speech reaches 1.
    nonisolated static func loudness(of url: URL) -> [Float] {
        guard let file = try? AVAudioFile(forReading: url) else { return [] }
        let window = AVAudioFrameCount(max(file.processingFormat.sampleRate / 30, 1))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: window) else { return [] }
        var values: [Float] = []
        while file.framePosition < file.length {
            do { try file.read(into: buffer, frameCount: window) } catch { break }
            let count = Int(buffer.frameLength)
            guard count > 0, let samples = buffer.floatChannelData?[0] else { break }
            var sum: Float = 0
            for i in 0..<count { sum += samples[i] * samples[i] }
            values.append((sum / Float(count)).squareRoot())
        }
        guard !values.isEmpty else { return [] }
        let peak = max(values.sorted()[Int(Double(values.count - 1) * 0.95)], 0.0001)
        return values.map { min($0 / peak, 1) }
    }

    /// How loud the voice is right now, 0…1, for the wave.
    func level(at now: Date = .now) -> Double {
        guard playing else { return 0.1 }
        if player != nil {
            guard !loudness.isEmpty else { return 0.55 }
            let i = min(max(Int(elapsed(at: now) * 30), 0), loudness.count - 1)
            return 0.15 + 0.85 * Double(loudness[i])
        }
        // The on-device voice gives no samples, so the wave pulses on each word and settles between sentences.
        guard let wordAt else { return 0.2 }
        let since = now.timeIntervalSince(wordAt) * speed
        let weight = 0.6 + 0.4 * min(Double(wordLength) / 8, 1)
        return 0.18 + 0.82 * weight * exp(-since / 0.32)
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
        utterance.rate = min(max(Float(0.46 * speed), AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
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

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange,
                                       utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance), length = characterRange.length
        Task { @MainActor in
            guard id == self.current else { return }
            self.wordAt = .now
            self.wordLength = length
        }
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

/// The audio step of a lesson. The top half holds the cloud wave, which swells with the voice, and the controls under it.
/// The bottom half holds captions that rise from below and fade out at the top, the current line in the middle.
/// The lesson moves on to its exercise when the audio ends.
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
        VStack(spacing: DX.Space.s) {
            VStack(spacing: 4) {
                Label("Audio session", systemImage: "headphones").dxText(.micro)
                Text(title).dxText(.title).multilineTextAlignment(.center)
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            CloudWave(level: { narrator.level(at: $0) }, playing: narrator.playing)
                .frame(height: 190)
            scrubber
            controls
            captions
                .frame(maxHeight: .infinity)
            if narrator.finished {
                Label("Nice. On to the exercise.", systemImage: "checkmark")
                    .font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
                    .foregroundStyle(DX.Palette.accentInk)
            }
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

    // MARK: Captions

    private var captions: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DX.Space.m) {
                        ForEach(Array(narrator.sentences.enumerated()), id: \.offset) { i, sentence in
                            let distance = abs(i - narrator.index)
                            Button { narrator.jump(toSentence: i) } label: {
                                Text(verbatim: sentence)
                                    .font(.custom(distance == 0 ? DX.Typeface.bold : DX.Typeface.medium, size: 22, relativeTo: .title3))
                                    .tracking(-0.3)
                                    .lineSpacing(3)
                                    .foregroundStyle(DX.Palette.text)
                                    .opacity(distance == 0 ? 1 : distance == 1 ? 0.45 : distance == 2 ? 0.2 : 0.08)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .id(i)
                            .accessibilityHint(Text("Plays from here"))
                        }
                    }
                    // Room above and below, so the first and last lines can sit in the middle too.
                    .padding(.vertical, max(geo.size.height / 2 - 30, 0))
                    .animation(DX.Motion.animation(DX.Motion.glide, reduceMotion: reduceMotion), value: narrator.index)
                }
                .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.24),
                                             .init(color: .black, location: 0.76), .init(color: .clear, location: 1)],
                                     startPoint: .top, endPoint: .bottom))
                .onAppear { proxy.scrollTo(narrator.index, anchor: .center) }
                .onChange(of: narrator.index) { _, i in
                    withAnimation(DX.Motion.animation(DX.Motion.glide, reduceMotion: reduceMotion)) { proxy.scrollTo(i, anchor: .center) }
                }
            }
        }
        .frame(minHeight: 180)
    }

    // MARK: Player

    private var scrubber: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let elapsed = scrubbing ?? narrator.elapsed(at: context.date)
            let fraction = narrator.total > 0 ? min(max(elapsed / narrator.total, 0), 1) : 0
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(DX.Palette.track).frame(height: 4)
                        Capsule().fill(DX.Palette.primary).frame(width: geo.size.width * fraction, height: 4)
                        Circle().fill(DX.Palette.primary).frame(width: 14, height: 14)
                            .offset(x: geo.size.width * fraction - 7)
                    }
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            scrubbing = narrator.total * min(max(value.location.x / geo.size.width, 0), 1)
                        }
                        .onEnded { _ in
                            if let scrubbing { narrator.seek(to: scrubbing) }
                            scrubbing = nil
                        })
                }
                .frame(height: 24)
                .accessibilityElement()
                .accessibilityLabel(Text("Position"))
                .accessibilityValue(Text(Duration.seconds(elapsed), format: .time(pattern: .minuteSecond)))
                .accessibilityAdjustableAction { direction in
                    narrator.skip(direction == .increment ? 15 : -15)
                }
                HStack {
                    Text(Duration.seconds(elapsed), format: .time(pattern: .minuteSecond))
                    Spacer()
                    Text(Duration.seconds(max(narrator.total - elapsed, 0)), format: .time(pattern: .minuteSecond))
                }
                .font(.custom(DX.Typeface.mono, size: 12, relativeTo: .caption))
                .foregroundStyle(DX.Palette.muted)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
        }
    }

    private var controls: some View {
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
                    .frame(width: 60, height: 60)
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
    }
}
