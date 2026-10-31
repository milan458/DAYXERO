import SwiftUI

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
