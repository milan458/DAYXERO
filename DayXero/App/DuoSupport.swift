import DayXeroCore
import SwiftUI

// iPhone Duo (S18.13, S18.14). Its APIs exist only in the iOS 27.1 SDK. Builds with older Xcode (the iOS 18 test
// leg still uses Xcode 26) compile the plain fallbacks here, so nothing else needs an SDK check.

extension View {
    /// Reports the edge where the system puts vertical bars (iPhone Duo's cover, or its inner display in landscape),
    /// or nil where it doesn't use them.
    func readVerticalBarEdge(_ edge: Binding<HorizontalEdge?>) -> some View {
        modifier(VerticalBarEdgeReader(edge: edge))
    }
}

private struct VerticalBarEdgeReader: ViewModifier {
    @Binding var edge: HorizontalEdge?

    func body(content: Content) -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            content.background { BarEdgeProbe(edge: $edge) }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

#if compiler(>=6.4)
@available(iOS 27.1, *)
private struct BarEdgeProbe: View {
    @Environment(\.toolbarVerticalEdge) private var systemEdge
    @Binding var edge: HorizontalEdge?

    var body: some View {
        Color.clear.onChange(of: systemEdge, initial: true) { _, new in edge = new }
    }
}
#endif

/// A screen in two parts that sit on either side of iPhone Duo's fold while it's half open. Open flat, closed,
/// or on any other iPhone, it shows `flat`: the screen as it always is.
struct FoldAware<Primary: View, Secondary: View, Flat: View>: View {
    @ViewBuilder var primary: () -> Primary
    @ViewBuilder var secondary: () -> Secondary
    @ViewBuilder var flat: () -> Flat

    var body: some View {
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            GeometryReader { proxy in
                if proxy.reservedRegions(kind: .division).isEmpty {
                    flat()
                } else {
                    ArrangementView {
                        primary()
                    } secondary: {
                        secondary()
                    }
                    .arrangementViewStyle(.split)
                }
            }
        } else {
            flat()
        }
        #else
        flat()
        #endif
    }
}
