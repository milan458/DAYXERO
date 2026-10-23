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

    // NRT label schedules (S9.2). Each preset shows its source. Check against the current official leaflets
    // (FDA/DailyMed, MHRA/eMC, TGA, BfArM) before launch.

    /// US 24-hour patch, 10-week label: 21 mg × 6 weeks, 14 mg × 2, 7 mg × 2.
    public static let usPatch10 = HealthSource(
        label: "Source: US Drug Facts label for nicotine patches",
        url: URL(string: "https://hellopharmacist.com/ndc/11673-0194-01")!
    )
    /// US 24-hour patch, 8-week label: 21 mg × 4 weeks, 14 mg × 2, 7 mg × 2.
    public static let usPatch8 = HealthSource(
        label: "Source: US Drug Facts label for nicotine patches",
        url: URL(string: "https://otclabels.com/lib/otc/otc-meds/nicotine-32/")!
    )
    /// US gum and lozenge, 12 weeks: a piece every 1–2 hours, then 2–4, then 4–8.
    public static let usGum = HealthSource(
        label: "Source: US Drug Facts label for nicotine gum",
        url: URL(string: "https://otclabels.com/lib/otc/otc-meds/nicotine-gum-1/")!
    )
    /// UK 24-hour patch (NiQuitin): 21 mg × 6 weeks, 14 mg × 2, 7 mg × 2.
    public static let ukPatch24 = HealthSource(
        label: "Source: UK pack information for 24-hour patches",
        url: URL(string: "https://shop.rowlandspharmacy.co.uk/products/niquitin-clear-patch-step-1-21mg-14-patches")!
    )
    /// UK 16-hour patch (Nicorette Invisi): 25 mg × 8 weeks, 15 mg × 2, 10 mg × 2.
    public static let ukPatch16 = HealthSource(
        label: "Source: UK pack information for 16-hour patches",
        url: URL(string: "https://www.theindependentpharmacy.co.uk/stop-smoking/nicorette-invisipatch")!
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
