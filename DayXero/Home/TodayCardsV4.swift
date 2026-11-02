import DayXeroCore
import SwiftUI

/// A coloured action card on Today (F08): kicker, 19 pt title, 14 pt line, and a chevron in a 44 pt circle.
/// The kicker is in sentence case: Today's own kicker line is the screen's only all-caps label (UX-07).
/// Cream text on every fill: ocean 6.0:1, lesson green 6.4:1, Glim violet 13:1, night 16:1.
struct ColourCard: View {
    let kicker: String
    let title: String
    let detail: String?
    let fill: Color
    var chevron = true
    /// "Start", "Continue": a pill in place of the chevron (UX-12), so the card says what a tap does.
    var actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        let content = HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: kicker).dxFont(14, weight: 600, style: .footnote)
                Text(verbatim: title).dxType(.headline).fixedSize(horizontal: false, vertical: true)
                if let detail { Text(verbatim: detail).dxType(.footnote).fixedSize(horizontal: false, vertical: true) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let actionTitle, action != nil {
                Text(verbatim: actionTitle)
                    .dxFont(15, weight: 700, style: .subheadline)
                    .foregroundStyle(fill)
                    .lineLimit(1)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .background(DX.Fill.cream, in: Capsule())
                    .fixedSize()
            } else if chevron, action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .heavy))
                    .frame(width: 44, height: 44)
                    .background(DX.Fill.cream.opacity(0.2), in: Circle())
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(DX.Fill.cream)
        .padding(16)
        .background {
            // The lip shadow sits on the card shape only, so text is never doubled.
            RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous)
                .fill(fill)
                .shadow(color: .black.opacity(0.14), radius: 0, x: 0, y: 5)
        }
        if let action {
            Button(action: action) { content }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
        } else {
            content.accessibilityElement(children: .combine)
        }
    }

    static let ocean = Color(hex: 0x2A52DB)
    static let lesson = Color(hex: 0x0F6E43)
    static let glim = Color(hex: 0x2A1C6E)
    static let night = Color(hex: 0x0E0B2B)
}
