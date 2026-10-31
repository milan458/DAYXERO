#if DEBUG
import DayXeroCore
import SwiftUI

/// The v4 foundation on one scrolling page: grounds, type steps and the crew in every
/// mood and stage, for side-by-side checks against the Design canvas
/// (`-dx.v4Gallery YES`). Debug builds only.
struct V4Gallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("v4 foundation").dxType(.large)
                grounds
                type
                crew(name: "Xero", ground: .apricot) { mood, stage, size in XeroView(mood: mood, stage: stage, size: size) }
                crew(name: "Jelli", ground: .ocean) { mood, stage, size in JelliView(mood: mood, stage: stage, size: size) }
                crew(name: "Glim", ground: .violet) { mood, stage, size in GlimView(mood: mood, stage: stage, size: size) }
            }
            .padding(DX.Layout.gutter)
        }
        .foregroundStyle(DX.Ground.reading.ink)
        .background(DX.Ground.reading.background.ignoresSafeArea())
    }

    private var grounds: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grounds").dxType(.headline)
            ForEach(DX.Ground.allCases, id: \.self) { ground in
                HStack {
                    Text(ground.rawValue.capitalized).dxType(.headline).foregroundStyle(ground.ink)
                    Spacer()
                    Text("Muted text").dxType(.footnote).foregroundStyle(ground.muted)
                }
                .padding(16)
                .background(ground.background, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius))
            }
        }
    }

    private var type: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type steps").dxType(.headline)
            ForEach(DX.TypeStep.allCases, id: \.self) { step in
                Text("\(step.rawValue.capitalized) \(Int(step.size))").dxType(step)
            }
        }
    }

    private func crew<Art: View>(name: String, ground: DX.Ground,
                                       @ViewBuilder make: @escaping (CrewMood, Int, DX.CharacterSize) -> Art) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name).dxType(.title).foregroundStyle(ground.ink)
            Text("Moods").dxType(.caption).foregroundStyle(ground.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CrewMood.allCases, id: \.self) { mood in
                        VStack(spacing: 4) {
                            make(mood, 2, .card)
                            Text(mood.rawValue).dxType(.caption).foregroundStyle(ground.muted)
                        }
                    }
                }
            }
            Text("Stages 1 to 4").dxType(.caption).foregroundStyle(ground.muted)
            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { stage in make(.hello, stage, .avatar) }
            }
            Text("Hero").dxType(.caption).foregroundStyle(ground.muted)
            make(.hello, 1, .hero).frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(ground.background, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius))
    }
}

#Preview { V4Gallery() }
#endif
