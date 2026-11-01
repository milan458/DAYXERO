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

    /// Lindson N et al. Different doses, durations and modes of delivery of nicotine replacement therapy for smoking
    /// cessation. Cochrane Database Syst Rev 2019;4:CD013308. Combination NRT (a patch plus a fast-acting form)
    /// beat a single form: RR 1.25, high-certainty evidence (S27.6).
    public static let nrtCombinationCochrane2019 = HealthSource(
        label: "Source: Cochrane review of combination NRT, 2019",
        url: URL(string: "https://www.cochranelibrary.com/cdsr/doi/10.1002/14651858.CD013308/full")!
    )

    // NRT label schedules (S9.2). Each preset shows its source: the regulators' label databases (DailyMed for the
    // US, the eMC for the UK, S27.6), not retailer pages. The links open a search, since a single label page
    // changes with each product listing. Check the schedules against the current leaflets before launch.

    /// US 24-hour patch, 10-week label: 21 mg × 6 weeks, 14 mg × 2, 7 mg × 2.
    public static let usPatch10 = HealthSource(
        label: "Source: DailyMed, US Drug Facts label for nicotine patches",
        url: URL(string: "https://dailymed.nlm.nih.gov/dailymed/search.cfm?query=nicotine+patch")!
    )
    /// US 24-hour patch, 8-week label: 21 mg × 4 weeks, 14 mg × 2, 7 mg × 2.
    public static let usPatch8 = HealthSource(
        label: "Source: DailyMed, US Drug Facts label for nicotine patches",
        url: URL(string: "https://dailymed.nlm.nih.gov/dailymed/search.cfm?query=nicotine+patch")!
    )
    /// US gum and lozenge, 12 weeks: a piece every 1–2 hours, then 2–4, then 4–8.
    public static let usGum = HealthSource(
        label: "Source: DailyMed, US Drug Facts label for nicotine gum",
        url: URL(string: "https://dailymed.nlm.nih.gov/dailymed/search.cfm?query=nicotine+gum")!
    )
    /// UK 24-hour patch (NiQuitin): 21 mg × 6 weeks, 14 mg × 2, 7 mg × 2.
    public static let ukPatch24 = HealthSource(
        label: "Source: eMC, UK product information for NiQuitin patches",
        url: URL(string: "https://www.medicines.org.uk/emc/search?q=niquitin+patch")!
    )
    /// UK 16-hour patch (Nicorette Invisi): 25 mg × 8 weeks, 15 mg × 2, 10 mg × 2.
    public static let ukPatch16 = HealthSource(
        label: "Source: eMC, UK product information for Nicorette Invisi patches",
        url: URL(string: "https://www.medicines.org.uk/emc/search?q=nicorette+invisi")!
    )
    /// Australia (Nicabate): 21 mg × 6 weeks, 14 mg × 2, 7 mg × 2–4.
    public static let auPatch = HealthSource(
        label: "Source: Australian product information for Nicabate patches",
        url: URL(string: "https://www.medsinfo.com.au/api/documents/Nicabate_Patch_GC_PI?format=pdf")!
    )
    /// Germany (Nicotinell TTS 30/20/10): 21, 14, 7 mg, 3–4 weeks each.
    public static let dePatch = HealthSource(
        label: "Source: product information for Nicotinell TTS patches",
        url: URL(string: "https://assets.hpra.ie/products/Human/19584/Licence_PA25456-001-002_01092025144505.pdf")!
    )
}
