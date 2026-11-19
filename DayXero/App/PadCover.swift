import DayXeroCore
import SwiftUI

/// Full-screen covers that keep their content in the iPad column (`dxPadColumn`). Use these in place of
/// `fullScreenCover`: a cover is a new hierarchy and doesn't inherit the root's column.
extension View {
    func dxCover<Content: View>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil,
                                @ViewBuilder content: @escaping () -> Content) -> some View {
        fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) { content().dxPadColumn() }
    }

    func dxCover<Item: Identifiable, Content: View>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil,
                                                    @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        fullScreenCover(item: item, onDismiss: onDismiss) { content($0).dxPadColumn() }
    }
}
