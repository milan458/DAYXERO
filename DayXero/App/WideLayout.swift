import DayXeroCore
import SwiftUI

// Wide screens (1.1, 27 Nov 2026): iPad in either orientation, iPhone Duo open flat, and a wide iPad window. In 1.0 the
// iPad got the iPhone layout in a centred column and the open Duo got the iPhone layout stretched; now each tab puts
// what it shows in two columns side by side, each its own scroll.

/// Two columns side by side when there's room (`DX.Size.splitMinWidth`); anywhere narrower, `narrow`: the screen as
/// it is on iPhone. Each column is usually a scroll view of its own. `leadingShare` is the leading column's part of
/// the width.
struct WideSplit<Leading: View, Trailing: View, Narrow: View>: View {
    var leadingShare: CGFloat = 0.5
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder var narrow: () -> Narrow

    var body: some View {
        GeometryReader { proxy in
            if WideLayout.isWide(proxy.size.width) {
                HStack(alignment: .top, spacing: 0) {
                    leading()
                        .frame(width: (proxy.size.width * leadingShare).rounded())
                        .frame(maxHeight: .infinity, alignment: .top)
                    trailing()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .environment(\.dxWide, true)
            } else {
                narrow()
            }
        }
    }
}

enum WideLayout {
    /// Whether a screen this wide gets two columns.
    static func isWide(_ width: CGFloat) -> Bool {
        width >= DX.Size.splitMinWidth
    }
}

private struct WideKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True inside one of `WideSplit`'s columns: a card can lay out for the column it sits in.
    var dxWide: Bool {
        get { self[WideKey.self] }
        set { self[WideKey.self] = newValue }
    }
}
