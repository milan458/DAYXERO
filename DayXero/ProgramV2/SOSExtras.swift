import DayXeroCore
import SwiftData
import SwiftUI

/// What the program has given the person, under the SOS orb (handoff 6): who they are now, their own lines
/// (one at a time; tap for the next), and what to try instead. Each part is hidden until its answer exists.
struct SOSProgramExtras: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @State private var lineIndex = 0

    var body: some View {
        let store = ProgramStore(context: context, profile: profile)
        let lines = ["no_line", "passenger_reply", "bad_day_line"].compactMap { store.answer($0)?.lines.first }
        let tryInstead = (store.answer("break_menu")?.lines ?? []) + (store.answer("move_choice")?.lines ?? [])
        VStack(spacing: DX.Space.s) {
            if case let .text(identity)? = store.answer("identity_statement"), !identity.isEmpty {
                Text(verbatim: identity + ".").font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body))
                    .foregroundStyle(DX.Palette.accentInk)
            }
            if !lines.isEmpty {
                Button { lineIndex += 1 } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Your line").dxText(.micro).foregroundStyle(DX.Palette.accentInk)
                            Spacer()
                            if lines.count > 1 {
                                HStack(spacing: 4) {
                                    ForEach(lines.indices, id: \.self) { i in
                                        Circle().fill(i == lineIndex % lines.count ? DX.Palette.accentInk : DX.Palette.faint).frame(width: 6, height: 6)
                                    }
                                }
                            }
                        }
                        Text(verbatim: "“\(lines[lineIndex % lines.count])”").font(.custom(DX.Typeface.semibold, size: 17, relativeTo: .body))
                            .foregroundStyle(DX.Palette.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(DX.Space.m)
                    .background(DX.Palette.accentSoft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text(lines.count > 1 ? "Shows your next line" : ""))
            }
            if !tryInstead.isEmpty {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    Text("Try instead").dxText(.micro)
                    DXFlowLayout(spacing: 8) {
                        ForEach(tryInstead, id: \.self) { item in
                            Text(verbatim: item).font(.custom(DX.Typeface.medium, size: 14, relativeTo: .footnote))
                                .foregroundStyle(DX.Palette.text)
                                .padding(.horizontal, 14).frame(minHeight: 36)
                                .background(DX.Palette.surface1, in: Capsule())
                                .overlay(Capsule().strokeBorder(DX.Palette.hairline))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
