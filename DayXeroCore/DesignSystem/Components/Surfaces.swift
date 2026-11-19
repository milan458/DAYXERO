import SwiftUI
import UIKit

public extension View {

    /// Keeps a column of content at a readable width and centres it in wider windows (S18.13). When iPhone Duo is
    /// half open like a book, the column moves to the leading side of the fold instead of straddling it (S18.14);
    /// a screen that splits itself around the fold passes `avoidingFold: false`.
    func dxReadableColumn(avoidingFold: Bool = true) -> some View {
        frame(maxWidth: DX.Size.readableWidth).frame(maxWidth: .infinity).modifier(AvoidFold(enabled: avoidingFold))
    }
}

/// Pads a full-width view's trailing side so its content stays clear of a fold running top to bottom.
/// The fold APIs only exist in the iOS 27.1 SDK; older builds lay out as before.
private struct AvoidFold: ViewModifier {
    let enabled: Bool
    @State private var trailing: CGFloat = 0

    func body(content: Content) -> some View {
        #if compiler(>=6.4)
        if enabled {
            if #available(iOS 27.1, *) {
                content
                    .padding(.trailing, trailing)
                    .background {
                        // Measured outside the padding, so the frame is the whole width either way.
                        GeometryReader { proxy in
                            Color.clear.onChange(of: Self.trailingInset(proxy), initial: true) { _, inset in trailing = inset }
                        }
                    }
            } else {
                content
            }
        } else {
            content
        }
        #else
        content
        #endif
    }

    #if compiler(>=6.4)
    @available(iOS 27.1, *)
    private static func trailingInset(_ proxy: GeometryProxy) -> CGFloat {
        guard let fold = proxy.reservedRegions(kind: .division).first(where: { $0.frame.height > $0.frame.width }) else { return 0 }
        return max(proxy.size.width - fold.frame.minX, 0)
    }
    #endif
}

// MARK: iPad

public extension DX.Size {
    /// The widest the app's content runs on iPad: the iPhone Duo's inner display, the widest screen every layout
    /// has been checked on.
    static let padColumnWidth: CGFloat = 670
}

public extension View {
    /// On iPad (19 Nov 2026, portrait and full screen only), keeps a screen's content in a centred column of
    /// `DX.Size.padColumnWidth` by widening the horizontal safe area. Anything that ignores the safe area (grounds,
    /// skies, dimming layers) still runs to the screen's edges. On iPhone this does nothing.
    ///
    /// A presentation starts a new hierarchy, so the app's root and every full-screen cover apply it (`dxCover`).
    func dxPadColumn() -> some View {
        modifier(PadColumn())
    }
}

private struct PadColumn: ViewModifier {
    @State private var width: CGFloat = 0

    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .safeAreaPadding(.horizontal, max(0, (width - DX.Size.padColumnWidth) / 2))
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        } else {
            content
        }
    }
}
