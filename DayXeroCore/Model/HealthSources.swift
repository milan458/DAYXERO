import Foundation

/// Citations shown next to health claims. Every claim in the app links to one of these.
public struct HealthSource: Sendable {
    public let label: LocalizedStringResource
    public let url: URL
}

public enum HealthSources {
    /// Hartmann-Boyce J et al. Nicotine replacement therapy versus control for smoking cessation.
    /// Cochrane Database Syst Rev 2018;5:CD000146 (133 trials, 64,640 people; NRT raised quit rates 50–60%).
    public static let nrtCochrane2018 = HealthSource(
        label: "Source: Cochrane review of 133 trials, 2018",
        url: URL(string: "https://www.cochrane.org/evidence/CD000146_can-nicotine-replacement-therapy-nrt-help-people-quit-smoking")!
    )
}
