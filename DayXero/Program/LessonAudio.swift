import AVFoundation
import DayXeroCore
import MediaPlayer
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
    /// Where a seek is heading until the player gets there, so the position reads right in between.
    @ObservationIgnored private var seekTarget: Double?
    /// The lesson's name on the lock screen and in Control Centre.
    @ObservationIgnored var nowPlayingTitle = "DayXero"
    /// The lock screen's play, pause and skip buttons, kept so they can be taken away again.
    @ObservationIgnored private var remotes: [(command: MPRemoteCommand, target: Any)] = []
    @ObservationIgnored private var interruption: NSObjectProtocol?
    /// True while a call or another app has taken the sound from a lesson that was playing.
    @ObservationIgnored private var interrupted = false
    /// True while the lesson waits because the screen is being recorded or shared (`CaptureWatch`): the shield keeps
    /// the session's picture out of a recording, and this keeps its voice out too. It plays on when that stops.
    private(set) var heldForCapture = false
    @ObservationIgnored private var captureObserver: NSObjectProtocol?

    init(transcript: String, url: URL?, seconds: Int) {
        sentences = Self.split(transcript)
        self.url = url
        // About 2.6 words a second at the coach's speaking rate.
        let estimated = sentences.map { max(Double($0.split(separator: " ").count) / 2.6, 1.2) }
        let estimatedTotal = estimated.reduce(0, +)
        // A recording runs for as long as its file does; `seconds` is the planned length, used only if the file can't be read.
        let length: Double
        if let url {
            length = LessonNarrator.duration(of: url) ?? Double(max(seconds, 1))
        } else {
            length = estimatedTotal
        }
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

    /// A recording with its transcript already timed (program v2's `tx_<session>_<variant>.json`).
    init(segments: [(start: Double, text: String)], url: URL, seconds: Double) {
        let ordered = segments.sorted { $0.start < $1.start }
        sentences = ordered.map(\.text)
        self.url = url
        let length = max(LessonNarrator.duration(of: url) ?? seconds, (ordered.last?.start ?? 0) + 1)
        starts = ordered.map(\.start)
        durations = ordered.indices.map { i in (i + 1 < ordered.count ? ordered[i + 1].start : length) - ordered[i].start }
        total = length
        super.init()
        synthesizer.delegate = self
        Task.detached(priority: .utility) {
            let values = Self.loudness(of: url)
            await MainActor.run { self.loudness = values }
        }
    }

    /// How long the recording really is, in seconds. The planned minutes in program.json are only an estimate, and
    /// a track that ends early must still reach its end (the Continue gate and the finish both depend on it).
    nonisolated static func duration(of url: URL) -> Double? {
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let rate = file.processingFormat.sampleRate
        guard rate > 0, file.length > 0 else { return nil }
        return Double(file.length) / rate
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
        if let seekTarget, player != nil { return min(max(seekTarget, 0), total) }
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
        watchCapture()
        if CaptureShield.isOn, CaptureWatch.shared.capturing {
            heldForCapture = true
            return
        }
        if finished { finished = false; index = 0; player?.seek(to: .zero) }
        activate()
        playing = true
        if let url {
            if player == nil { makePlayer(url) }
            player?.playImmediately(atRate: Float(speed))
        } else {
            speak(from: index)
        }
        publish()
    }

    func pause() {
        heldForCapture = false
        playing = false
        player?.pause()
        stopSpeech()
        sentenceStartedAt = nil
        publish()
    }

    func skip(_ seconds: Double) {
        seek(to: min(max(elapsed() + seconds, 0), total - 0.5))
    }

    func seek(to seconds: Double) {
        finished = false
        // A recording's player is made on first play. Make it now, or a place saved earlier would be dropped and
        // the audio would start again from the top.
        if player == nil, let url { makePlayer(url) }
        if let player {
            seekTarget = seconds
            player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600)) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, self.seekTarget == seconds else { return }
                    self.seekTarget = nil
                }
            }
            index = sentence(at: seconds)
        } else {
            index = sentence(at: seconds)
            if playing { speak(from: index) }
        }
        publish(at: seconds)
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
        publish()
    }

    /// A recording or screen share started (true) or stopped (false). A lesson that was playing waits, and goes on
    /// from where it was when the recording stops; one paused by hand stays paused.
    func captureChanged(_ capturing: Bool) {
        if capturing {
            guard playing else { return }
            pause()
            heldForCapture = true
        } else if heldForCapture {
            heldForCapture = false
            play()
        }
    }

    private func watchCapture() {
        guard CaptureShield.isOn, captureObserver == nil else { return }
        captureObserver = NotificationCenter.default.addObserver(forName: .dxCaptureChanged, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.captureChanged(CaptureWatch.shared.capturing) }
        }
    }

    func stop() {
        pause()
        if let captureObserver { NotificationCenter.default.removeObserver(captureObserver) }
        captureObserver = nil
        if let observer { player?.removeTimeObserver(observer) }
        observer = nil
        player = nil
        seekTarget = nil
        for remote in remotes { remote.command.removeTarget(remote.target) }
        remotes = []
        if let interruption { NotificationCenter.default.removeObserver(interruption) }
        interruption = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: Recording

    private func makePlayer(_ url: URL) {
        let player = AVPlayer(url: url)
        self.player = player
        observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self, self.seekTarget == nil else { return }
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
        publish()
        onFinish?()
    }

    private func activate() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
        connectLockScreen()
    }

    // MARK: Locked phone

    /// The lesson keeps playing with the phone locked (the app's `audio` background mode). This puts its name and
    /// position on the lock screen, answers the play, pause and skip buttons there and on headphones, and picks up
    /// again after a phone call.
    private func connectLockScreen() {
        guard remotes.isEmpty else { return }
        let centre = MPRemoteCommandCenter.shared()
        func add(_ command: MPRemoteCommand, _ action: @escaping @MainActor (LessonNarrator) -> Void) {
            command.isEnabled = true
            let target = command.addTarget { [weak self] _ in
                Task { @MainActor in
                    if let self { action(self) }
                }
                return .success
            }
            remotes.append((command, target))
        }
        add(centre.playCommand) { if !$0.playing { $0.play() } }
        add(centre.pauseCommand) { if $0.playing { $0.pause() } }
        add(centre.togglePlayPauseCommand) { $0.toggle() }
        centre.skipForwardCommand.preferredIntervals = [15]
        centre.skipBackwardCommand.preferredIntervals = [15]
        add(centre.skipForwardCommand) { $0.skip(15) }
        add(centre.skipBackwardCommand) { $0.skip(-15) }

        interruption = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil,
                                                              queue: .main) { [weak self] note in
            let kind = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt).flatMap { AVAudioSession.InterruptionType(rawValue: $0) }
            let options = AVAudioSession.InterruptionOptions(rawValue: note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0)
            MainActor.assumeIsolated {
                guard let self else { return }
                if kind == .began {
                    self.interrupted = self.playing
                    if self.playing { self.pause() }
                } else if kind == .ended {
                    if self.interrupted, options.contains(.shouldResume) { self.play() }
                    self.interrupted = false
                }
            }
        }
    }

    /// Tells the lock screen what is playing and where it has got to.
    private func publish(at seconds: Double? = nil) {
        guard !remotes.isEmpty else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: nowPlayingTitle,
            MPMediaItemPropertyArtist: "DayXero",
            MPMediaItemPropertyPlaybackDuration: total,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: seconds ?? elapsed(),
            MPNowPlayingInfoPropertyPlaybackRate: playing ? speed : 0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
        ]
    }
}

/// The audio step of a lesson (v5, 035): Xero in his headphones on a paper-cut hill at dawn, the title, a scrubber with
/// the times, the controls, the speed and transcript pills, and the line being read now. "Done listening" waits
/// outlined at the foot and turns solid once 80% has played.
///
/// Motion (035): the art fades up and Xero settles, then bobs; three thin arcs each side pulse outward for as long as
/// he is reading. Play starts by itself after 1.2 s. Each new spoken line cross-fades in (300 ms). At 80% the outlined
/// button cross-fades into the solid one (300 ms, light haptic).
struct LessonAudioStep: View {
    let title: String
    let subtitle: String
    let onFinish: () -> Void

    @State private var narrator: LessonNarrator
    @State private var scrubbing: Double?
    @Environment(\.scenePhase) private var scenePhase
    /// The saved place is restored once, not every time the step comes back on screen.
    @State private var restored = false
    @State private var reading = false
    @State private var ended = false
    /// Where to start, for a session resumed mid-audio.
    private var startAt: Double = 0
    /// Called every few seconds and on pause with the position, so a closed session resumes there.
    private var onPosition: ((Double) -> Void)?
    /// "Done listening". Without it the step has no button and moves on by itself when the audio ends.
    private var onDone: (() -> Void)?
    @Environment(\.dxGround) private var ground
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()

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

    /// For a program v2 session: a narrator built from a timed transcript, resuming at `startAt`.
    init(title: String, subtitle: String = "", narrator: LessonNarrator, startAt: Double, onPosition: @escaping (Double) -> Void,
         onFinish: @escaping () -> Void, onDone: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.onFinish = onFinish
        self.startAt = startAt
        self.onPosition = onPosition
        self.onDone = onDone
        _narrator = State(initialValue: narrator)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { reader in
                ScrollView {
                    VStack(spacing: 0) {
                        LessonAudioArt(playing: narrator.playing, dark: scheme == .dark)
                            .dxArrive(0)
                        VStack(spacing: 4) {
                            Text(verbatim: title).dxType(.title).foregroundStyle(ground.ink)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                            if !subtitle.isEmpty {
                                Text(verbatim: subtitle).dxType(.footnote).foregroundStyle(ground.muted)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 18)
                        .dxArrive(1)
                        scrubber.padding(.top, 14).dxArrive(2)
                        controls.padding(.top, 10).dxArrive(3)
                        if narrator.heldForCapture {
                            Text("Paused while your screen is recorded or shared. It plays on when that stops.")
                                .dxType(.footnote).foregroundStyle(ground.muted)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8).padding(.horizontal, 24)
                        }
                        pills.padding(.top, 16).dxArrive(4)
                        live.padding(.top, 22).dxArrive(5)
                        if reading {
                            transcript.padding(.top, 18)
                                .transition(.opacity)
                        }
                    }
                    .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
                // The open transcript follows the voice.
                .onChange(of: narrator.index) { _, i in
                    guard reading else { return }
                    withAnimation(motion.reduce ? nil : .easeInOut(duration: 0.4)) { reader.scrollTo("line-\(i)", anchor: .center) }
                }
            }
            if let onDone {
                gate(onDone).padding(.top, 8).dxArrive(6)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .onAppear {
            narrator.onFinish = { finished() }
            narrator.nowPlayingTitle = title
            guard !restored else { return }
            restored = true
            // A place saved at the very end means it was heard through: start from the top, not on the last second.
            if startAt > 0, startAt < narrator.total - 1 { narrator.seek(to: startAt) }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.2))
            if !Task.isCancelled, !narrator.playing, !narrator.finished { narrator.play() }
        }
        .onChange(of: narrator.playing) { _, playing in if !playing { onPosition?(narrator.elapsed()) } }
        .onChange(of: scenePhase) { _, phase in
            // The audio keeps playing with the phone locked or the app in the background (17 Nov 2026). The place is
            // still saved on the way out, so a session closed from there carries on from the same point.
            guard phase == .background else { return }
            onPosition?(narrator.elapsed())
        }
        .task(id: narrator.playing) {
            // Every few seconds while playing, so a force-quit loses at most a moment.
            while narrator.playing, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4))
                onPosition?(narrator.elapsed())
            }
        }
        .onDisappear {
            onPosition?(narrator.elapsed())
            narrator.stop()
        }
    }

    private func finished() {
        ended = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            onFinish()
        }
    }

    // MARK: Done

    /// Outlined while it plays; solid from 80% or once it has played through.
    private func gate(_ onDone: @escaping () -> Void) -> some View {
        let played = narrator.total > 0 ? narrator.elapsed() / narrator.total : 0
        let open = ended || narrator.finished || played >= 0.8
        return ZStack {
            Button(String(localized: "Done listening"), action: onDone)
                .buttonStyle(.dx(.ghost, on: ground))
                .opacity(open ? 0 : 1)
                .allowsHitTesting(!open)
                .accessibilityHidden(open)
            Button(String(localized: "Done listening"), action: onDone)
                .buttonStyle(.dx(.primary, on: ground))
                .opacity(open ? 1 : 0)
                .allowsHitTesting(open)
                .accessibilityHidden(!open)
        }
        .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.3), value: open)
        .sensoryFeedback(.impact(weight: .light), trigger: open) { _, now in now }
    }

    // MARK: The line being read

    private var currentLine: String {
        narrator.sentences.indices.contains(narrator.index) ? narrator.sentences[narrator.index] : ""
    }

    private var live: some View {
        HStack(spacing: 10) {
            LessonLevelBars(playing: narrator.playing, color: ground.mark)
            Text(verbatim: "\u{201C}\(currentLine)\u{201D}")
                .dxType(.footnote).foregroundStyle(ground.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .id("live-\(narrator.index)")
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity)
        .animation(motion.reduce ? nil : .easeInOut(duration: 0.3), value: narrator.index)
        .accessibilityElement(children: .combine)
    }

    /// Every line, the one being read at full strength. A tap plays from that line.
    private var transcript: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(narrator.sentences.enumerated()), id: \.offset) { i, sentence in
                Button { narrator.jump(toSentence: i) } label: {
                    Text(verbatim: sentence).dxFace(.body, 17, weight: i == narrator.index ? 600 : 450)
                        .foregroundStyle(ground.ink)
                        .opacity(i == narrator.index ? 1 : 0.5)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(.plain)
                .id("line-\(i)")
                .accessibilityHint(Text("Plays from here"))
            }
        }
        .animation(motion.reduce ? nil : .easeInOut(duration: 0.3), value: narrator.index)
    }

    // MARK: Player

    private var scrubber: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let elapsed = scrubbing ?? narrator.elapsed(at: context.date)
            let fraction = narrator.total > 0 ? min(max(elapsed / narrator.total, 0), 1) : 0
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(ground.track).frame(height: 6)
                        Capsule().fill(ground.ink).frame(width: max(geo.size.width * fraction, 6), height: 6)
                        Circle().fill(ground.ink).frame(width: 18, height: 18)
                            .offset(x: min(max(geo.size.width * fraction - 9, 0), geo.size.width - 18))
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
                    Text(Duration.seconds(narrator.total), format: .time(pattern: .minuteSecond))
                }
                .dxType(.caption).monospacedDigit()
                .foregroundStyle(ground.ink)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 30) {
            SkipButton(forward: false, ink: ground.ink) { narrator.skip(-15) }
            Button { narrator.toggle() } label: {
                DXIcon(narrator.playing ? .pause : .play, size: 30, weight: 2.4, filled: !narrator.playing)
                    .foregroundStyle(ground.btnFg)
                    .offset(x: narrator.playing ? 0 : 2)
                    .frame(width: 76, height: 76)
                    .background(ground.btn, in: Circle())
                    .shadow(color: .black.opacity(0.18), radius: 0, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(narrator.playing ? "Pause" : "Play"))
            SkipButton(forward: true, ink: ground.ink) { narrator.skip(15) }
        }
        .frame(maxWidth: .infinity)
    }

    /// Speed and Transcript share one pill shape.
    private var pills: some View {
        HStack(spacing: 8) {
            Button { narrator.cycleSpeed() } label: {
                pill {
                    Text(verbatim: narrator.speed.formatted(.number.precision(.fractionLength(0...2))) + "×")
                }
            }
            .accessibilityLabel(Text("Speed"))
            .accessibilityValue(Text(verbatim: "\(narrator.speed)×"))
            Button {
                withAnimation(motion.reduce ? nil : .easeInOut(duration: 0.3)) { reading.toggle() }
            } label: {
                pill {
                    DXIcon(.text, size: 18)
                    Text("Transcript")
                    DXIcon(.down, size: 16).foregroundStyle(ground.muted)
                        .rotationEffect(.degrees(reading ? 180 : 0))
                }
            }
            .accessibilityValue(Text(reading ? "Transcript shown" : ""))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func pill<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 7) { content() }
            .dxFace(.body, 15, weight: 600)
            .foregroundStyle(ground.ink)
            .padding(.horizontal, 15)
            .frame(height: 44)
            .background(ground.card2, in: Capsule())
    }
}

/// Three small level bars beside the line being read; they move while the audio plays.
private struct LessonLevelBars: View {
    let playing: Bool
    let color: Color
    private let motion = MotionPolicy()
    private static let heights: [CGFloat] = [8, 14, 10]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !playing || motion.reduce)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    // Typed step by step: Xcode 26 (the iOS 18 CI leg) can't type-check this body in time otherwise.
                    let phase: Double = (t / 1.8 + Double(i) * 0.2) * 2 * Double.pi
                    let wave: Double = 0.675 + 0.325 * cos(phase)
                    let k: CGFloat = playing && !motion.reduce ? CGFloat(wave) : 1
                    Capsule().fill(color).frame(width: 3, height: Self.heights[i] * k)
                }
            }
            .frame(height: 14, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }
}

/// The scene of the lesson audio step (035). Light: a paper-cut dawn, the sun low behind Xero between lifted hills.
/// Dark: the same hills before dawn with a warm glow. Xero stands on the nearest hill in his headphones, and three
/// thin arcs each side pulse while he reads.
private struct LessonAudioArt: View {
    let playing: Bool
    let dark: Bool
    private let motion = MotionPolicy()

    var body: some View {
        ZStack {
            sky
            Circle().fill(dark ? Color(hex: 0xFFB25E).opacity(0.3) : Color(hex: 0xFFD86E))
                .frame(width: 144, height: 144)
                .blur(radius: dark ? 24 : 0)
                .offset(y: 28)
            LessonHill(left: 0.66, crest: 0.62, right: 0.61).fill(dark ? Color(hex: 0x22305A) : Color(hex: 0xFFA06C))
            LessonHill(left: 0.76, crest: 0.74, right: 0.74).fill(dark ? Color(hex: 0x1D2A50) : Color(hex: 0xFF8558))
            LessonHill(left: 0.90, crest: 0.81, right: 0.88).fill(dark ? Color(hex: 0x1A2847) : Color(hex: 0xE85A3E))
            LessonHill(left: 0.96, crest: 0.94, right: 0.945).fill(dark ? Color(hex: 0x111C34) : Color(hex: 0xC2402A))
            arcs
            XeroView(mood: .calm, stage: 0, points: 120, animate: playing, pose: .headphones)
                .dxBob()
                .offset(y: 24)
                .dxSettle(1)
        }
        .frame(height: 264)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .accessibilityHidden(true)
    }

    @ViewBuilder private var sky: some View {
        if dark {
            LinearGradient(colors: [Color(hex: 0x27325C), Color(hex: 0x19223F)], startPoint: .top, endPoint: .bottom)
        } else {
            LinearGradient(stops: [.init(color: Color(hex: 0xFF7E5A), location: 0), .init(color: Color(hex: 0xFFB27A), location: 0.6),
                                   .init(color: Color(hex: 0xFFDDB0), location: 1)], startPoint: .top, endPoint: .bottom)
        }
    }

    private var arcs: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !playing || motion.reduce)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    let pulse: Double = playing && !motion.reduce ? 0.675 + 0.325 * cos((t / 2.4 - Double(i) * 0.09) * 2 * .pi) : 1
                    LessonSoundArcs(radius: 80 + CGFloat(i) * 18, spread: 28 - Double(i) * 4)
                        .stroke(Color(hex: 0xFFF8EE), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .opacity(0.7 * pulse)
                }
            }
            .offset(y: 24)
        }
    }
}

/// A paper hill: a soft rise across the scene, filled to the bottom. Heights are shares of the box, from the top.
private struct LessonHill: Shape {
    let left: CGFloat
    let crest: CGFloat
    let right: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.height * left))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.height * right),
                          control: CGPoint(x: rect.midX, y: rect.height * (2 * crest - (left + right) / 2)))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// One sound arc on each side of the centre.
private struct LessonSoundArcs: Shape {
    let radius: CGFloat
    /// Half the arc's sweep, in degrees.
    let spread: Double

    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(center: centre, radius: radius, startAngle: .degrees(-spread), endAngle: .degrees(spread), clockwise: false)
        var left = Path()
        left.addArc(center: centre, radius: radius, startAngle: .degrees(180 - spread), endAngle: .degrees(180 + spread), clockwise: false)
        path.addPath(left)
        return path
    }
}
