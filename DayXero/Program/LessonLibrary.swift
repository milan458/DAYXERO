import DayXeroCore
import Foundation

/// Finds the lesson for a program day: the bundled `program-<product>.json` when it has one,
/// otherwise a clearly tagged placeholder until the Flutter content is ported (S5.1).
@MainActor
enum LessonLibrary {
    private static var cache: [Product: [ProgramDayID: LessonContent]] = [:]

    static func lesson(for day: ProgramDayID, product: Product) -> LessonContent {
        if cache[product] == nil { cache[product] = load(product) }
        return cache[product]?[day] ?? placeholder(for: day, product: product)
    }

    private static func load(_ product: Product) -> [ProgramDayID: LessonContent] {
        guard let url = Bundle.main.url(forResource: "program-\(product.rawValue)", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(LessonFile.self, from: data)
        else { return [:] }
        return Dictionary(file.lessons.map { ($0.day, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Stand-in lessons with the right shape (reading, audio, exercise; weekly check-ins after the quit week).
    /// Wording avoids health claims; every lesson is marked as a placeholder.
    static func placeholder(for day: ProgramDayID, product: Product) -> LessonContent {
        let title = LessonCatalog.title(for: day)
        switch day.phase {
        case .maintenance:
            return LessonContent(day: day, title: title, minutes: 5, placeholder: true, steps: [
                .weekRating,
                .challengeReview(challenge: String(localized: "A short walk after lunch")),
                .nextChallenge(options: [
                    String(localized: "A short walk after lunch"),
                    String(localized: "Drink water when a craving starts"),
                    String(localized: "Text a friend on hard evenings"),
                    String(localized: "Open Craving SOS before deciding"),
                ]),
            ])
        case .prep, .quit:
            return LessonContent(day: day, title: title, minutes: day.phase == .quit ? 7 : 6, placeholder: true, steps: [
                .reading(lead: String(localized: "Lesson text for \(title) goes here."),
                         body: String(localized: "This is placeholder text. The real lesson arrives when the program content is ported."),
                         notes: [Product.cigarettes.rawValue: String(localized: "A short note for people who also smoke goes here.")]),
                .audio(title: String(localized: "Guided practice"), subtitle: String(localized: "Find a comfortable spot. Headphones help."),
                       file: nil, seconds: 180, transcript: String(localized: """
                           This is a placeholder practice until the real lesson audio is ready.                            Sit back and let your shoulders drop.                            Breathe in slowly through your nose.                            And let the breath go, a little longer on the way out.                            Notice where you are right now: the chair, the floor, the sounds around you.                            If a craving shows up, just name it. "There's a craving."                            You don't have to do anything with it.                            Watch it rise, and watch it start to fall.                            One more slow breath in, and out.                            That's it. Let's turn this into a plan.
                           """)),
                .ifThen(title: String(localized: "Make an if-then plan"),
                        subtitle: String(localized: "Pick a moment you know is coming, and what you'll do instead."),
                        actions: [String(localized: "take a short walk"), String(localized: "open Craving SOS"),
                                  String(localized: "drink water"), String(localized: "text a friend")]),
                .reading(lead: String(localized: "Wrap-up for \(title)."),
                         body: String(localized: "Placeholder summary of today's lesson."), notes: [:]),
            ])
        }
    }

    #if DEBUG
    static func resetCache() { cache = [:] }
    #endif
}
