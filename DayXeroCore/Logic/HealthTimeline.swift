import Foundation

/// What changes in the body after stopping (S10). Content lives in `health-timeline.json` so wording and sources
/// can be corrected without code changes (S10.3). Every health item names a source the person can open (S10.2);
/// the sources are listed once, under the timeline.
public struct HealthTimeline: Sendable {
    public struct Source: Codable, Sendable, Equatable {
        public let label: String
        public let title: String
        public let url: URL
    }

    public struct Item: Codable, Sendable, Equatable, Identifiable {
        public let id: String
        /// The change starts this many hours after Quit Day begins…
        public let fromHours: Double
        /// …and is complete by this many. Equal for a single point in time.
        public let toHours: Double
        public let when: String
        public let title: String
        public let line: String
        public let detail: String
        /// The source behind a health claim. Looks changes (lips, skin, hair…) are general wellness notes and have none.
        public let source: String?
        /// "looks" for the appearance changes; nil for health.
        public let kind: String?
        /// The longer, warmer read on the detail sheet, one string per paragraph. Falls back to `detail`.
        public let story: [String]?
        /// "What you might notice".
        public let notice: [String]?
        /// "Help it along".
        public let helps: String?

        public init(id: String, fromHours: Double, toHours: Double, when: String, title: String, line: String,
                    detail: String, source: String?, kind: String? = nil, story: [String]? = nil, notice: [String]? = nil,
                    helps: String? = nil) {
            self.id = id
            self.fromHours = fromHours
            self.toHours = toHours
            self.when = when
            self.title = title
            self.line = line
            self.detail = detail
            self.source = source
            self.kind = kind
            self.story = story
            self.notice = notice
            self.helps = helps
        }

        public var isLooks: Bool { kind == "looks" }

        /// The paragraphs for the detail sheet.
        public var paragraphs: [String] { story ?? [detail] }

        func with(source: String) -> Item {
            Item(id: id, fromHours: fromHours, toHours: toHours, when: when, title: title, line: line, detail: detail,
                 source: source, kind: kind, story: story, notice: notice, helps: helps)
        }
    }

    struct ProductEntry: Codable, Sendable {
        let groups: [String]
        var sourceOverride: [String: String]?
        var note: String?
    }

    struct File: Codable, Sendable {
        let version: Int
        let sources: [String: Source]
        let groups: [String: [Item]]
        let products: [String: ProductEntry]
    }

    public enum State: Sendable, Equatable {
        case done
        /// Under way, with how far through its window (0…1).
        case underWay(Double)
        case ahead
    }

    let file: File

    public init(data: Data) throws {
        file = try JSONDecoder().decode(File.self, from: data)
    }

    /// The bundled timeline.
    public static let bundled: HealthTimeline? = {
        guard let url = Bundle(for: TimelineBundleToken.self).url(forResource: "health-timeline", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? HealthTimeline(data: data)
    }()

    /// Items for a product, in time order, with any per-product source swaps applied.
    public func items(for product: Product) -> [Item] {
        guard let entry = file.products[product.rawValue] else { return [] }
        return entry.groups.flatMap { file.groups[$0] ?? [] }
            .map { item in
                guard let swap = entry.sourceOverride?[item.id] else { return item }
                return item.with(source: swap)
            }
            .sorted { ($0.toHours, $0.fromHours) < ($1.toHours, $1.fromHours) }
    }

    /// The plain note shown under a product's timeline where evidence is thin, if any.
    public func note(for product: Product) -> String? {
        file.products[product.rawValue]?.note
    }

    public func source(_ id: String?) -> Source? {
        id.flatMap { file.sources[$0] }
    }

    /// Every source a product's timeline cites, once each, in the order they first appear.
    public func sources(for product: Product) -> [Source] {
        var seen = Set<String>()
        return items(for: product).compactMap { item in
            guard let id = item.source, seen.insert(id).inserted else { return nil }
            return file.sources[id]
        }
    }

    /// Hours since the start of Quit Day. Negative before it. Slips don't reset it, like days clear.
    public static func elapsedHours(quitDay: Date, now: Date, clock: DayClock) -> Double {
        now.timeIntervalSince(clock.startOfDate(quitDay)) / 3600
    }

    /// What Home and Progress feature: the change under way now (the latest to start, if several overlap) and the
    /// next one still ahead. Before Quit Day nothing is under way and `next` is the first item.
    public static func nowAndNext(_ items: [Item], elapsedHours: Double) -> (now: Item?, next: Item?) {
        let underWay = items.filter { if case .underWay = state(of: $0, elapsedHours: elapsedHours) { true } else { false } }
        let ahead = items.filter { state(of: $0, elapsedHours: elapsedHours) == .ahead }
        return (underWay.max { $0.fromHours < $1.fromHours }, ahead.min { $0.fromHours < $1.fromHours })
    }

    public static func state(of item: Item, elapsedHours: Double) -> State {
        if elapsedHours < 0 || elapsedHours < item.fromHours { return .ahead }
        if elapsedHours >= item.toHours { return .done }
        let span = max(item.toHours - item.fromHours, 1)
        return .underWay(min(max((elapsedHours - item.fromHours) / span, 0), 1))
    }
}

private final class TimelineBundleToken {}
