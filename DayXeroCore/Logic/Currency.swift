import Foundation

/// The currency money is shown in (S18.17). It starts from the phone's region and can be changed in Settings;
/// changing it relabels amounts, it doesn't convert them.
public enum CurrencyChoice {
    /// The currency of the phone's region: India → INR, the UK → GBP, Germany → EUR. US dollars if the region
    /// has none.
    public static func defaultCode(for locale: Locale = .current) -> String {
        // A locale's currency is its region's, so English set to India gives rupees.
        locale.currency?.identifier ?? "USD"
    }

    /// Every currency someone might pick, the region's first and the rest by name.
    public static func codes(for locale: Locale = .current) -> [String] {
        let all = Set(Locale.commonISOCurrencyCodes)
        let first = defaultCode(for: locale)
        return [first] + all.subtracting([first]).sorted { name($0, locale: locale).localizedCompare(name($1, locale: locale)) == .orderedAscending }
    }

    /// "Indian Rupee".
    public static func name(_ code: String, locale: Locale = .current) -> String {
        locale.localizedString(forCurrencyCode: code) ?? code
    }

    /// "₹", or the code where the locale has no symbol for it.
    public static func symbol(_ code: String, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = code
        return formatter.currencySymbol ?? code
    }
}
