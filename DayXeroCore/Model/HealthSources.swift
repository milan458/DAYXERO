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

    /// Theodoulou A, Chepkin SC, Ye W, et al. Different doses, durations and modes of delivery of nicotine replacement
    /// therapy for smoking cessation. Cochrane Database Syst Rev 2023;6:CD013308.pub2. Combination NRT (a patch plus
    /// a fast-acting form) beat a single form: RR 1.27, 16 studies, 12,169 people, high-certainty evidence.
    public static let nrtCombinationCochrane2023 = HealthSource(
        label: "Source: Cochrane review of combination NRT, 2023",
        url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/37335995/")!
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

extension HealthSources {
    /// Benowitz NL, Hall SM, Modin G. Persistent increase in caffeine concentrations in people who stop smoking.
    /// BMJ 1989;298:1075–6. Smoke (not nicotine) speeds up how fast the liver clears caffeine; after quitting, the
    /// same intake leaves caffeine levels much higher (CLIN-02, Xero's coffee note).
    public static let caffeineAfterQuitting = HealthSource(
        label: "Source: BMJ, caffeine levels in people who stop smoking, 1989",
        url: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC1836474")!
    )
}

// The onboarding evidence story (18 Nov 2026). Each figure was read at its source; none is a result of using DayXero.
extension HealthSources {
    /// VanFrank B et al. Adult Smoking Cessation, United States, 2022. MMWR 2024;73(29). 67.7% of adults who smoked
    /// wanted to quit.
    public static let wantToQuitCDC2022 = HealthSource(
        label: "Source: CDC, 2022 survey of US adults",
        url: URL(string: "https://www.cdc.gov/mmwr/volumes/73/wr/mm7329a1.htm")!
    )
    /// Rosen RL, Steinberg ML. Drug Alcohol Depend 2021;227:108973. PATH Study Wave 4 (2017 to 2018): 60% of adult
    /// e-cigarette users intended to quit completely.
    public static let vapeQuitIntentPATH = HealthSource(
        label: "Source: US PATH Study, 2017 to 2018",
        url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/34482034/")!
    )
    /// Stead LF et al. Combined pharmacotherapy and behavioural interventions for smoking cessation. Cochrane
    /// Database Syst Rev 2016;3:CD008286.pub3. RR 1.83, 52 studies, 19,488 people, against usual care, brief advice
    /// or less intensive behavioural support.
    public static let medicinePlusSupportCochrane2016 = HealthSource(
        label: "Source: Cochrane review of 52 trials, 2016",
        url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/27009521/")!
    )
    /// "If you can make it to 28 days smoke-free, you're 5 times more likely to quit for good." The NHS cites no study.
    public static let nhs28Days = HealthSource(
        label: "Source: NHS Better Health",
        url: URL(string: "https://www.nhs.uk/better-health/quit-smoking/")!
    )
    /// Lindson-Hawley N et al. Gradual versus abrupt smoking cessation. Ann Intern Med 2016;164:585. Six-month
    /// abstinence 22.0% abrupt, 15.5% gradual (n = 697). A 2019 Cochrane review of 22 trials found no difference.
    public static let abruptVsGradual2016 = HealthSource(
        label: "Source: Lindson-Hawley et al., 2016",
        url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/26975007/")!
    )
    /// Hughes JR. Effects of abstinence from tobacco: valid symptoms and time course. Nicotine Tob Res 2007;9:315.
    /// Symptoms peak in the first week and last two to four weeks. Covers irritability, sleep, restlessness and
    /// concentration, not craving or hunger.
    public static let withdrawalHughes2007 = HealthSource(
        label: "Source: Hughes, Nicotine and Tobacco Research, 2007",
        url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/17365764/")!
    )
}
