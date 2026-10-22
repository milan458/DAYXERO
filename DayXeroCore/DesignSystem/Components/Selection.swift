import SwiftUI

/// Wraps children onto new lines, left-aligned. Used for chip groups.
public struct DXFlowLayout: Layout {
    var spacing: CGFloat

    public init(spacing: CGFloat = DX.Space.xs) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
            rows[rows.count - 1] = row
        }
        return rows.filter { !$0.indices.isEmpty }
    }
}

/// Large selectable card: optional icon, title, detail, and a check. Works for single and multi select.
public struct DXOptionCard: View {
    let title: LocalizedStringResource
    let detail: LocalizedStringResource?
    let systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    public init(_ title: LocalizedStringResource, detail: LocalizedStringResource? = nil, systemImage: String? = nil,
                isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: DX.Space.s) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17))
                        .foregroundStyle(isSelected ? DX.Palette.accentInk : DX.Palette.text)
                        .frame(width: 40, height: 40)
                        .background(isSelected ? DX.Palette.accentSoft : DX.Palette.surface2, in: Circle())
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                    if let detail {
                        Text(detail).dxText(.subtitle)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    Circle().strokeBorder(isSelected ? .clear : DX.Palette.faint, lineWidth: 1.5)
                    if isSelected {
                        Circle().fill(DX.Palette.sage)
                        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(DX.Palette.onAccent)
                    }
                }
                .frame(width: 24, height: 24)
            }
            .padding(.vertical, DX.Space.s)
            .padding(.horizontal, 14)
            .frame(minHeight: 56)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(isSelected ? DX.Palette.accentInk : DX.Palette.hairline, lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(DX.Haptic.select, trigger: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// A chip bound to set membership, for multi-select groups.
public struct DXSetChip<Value: Hashable>: View {
    let title: LocalizedStringResource
    let value: Value
    @Binding var selection: Set<Value>

    public init(_ title: LocalizedStringResource, value: Value, selection: Binding<Set<Value>>) {
        self.title = title
        self.value = value
        self._selection = selection
    }

    public var body: some View {
        DXChip(LocalizedStringKey(String(localized: title)), isOn: Binding(
            get: { selection.contains(value) },
            set: { on in
                if on { selection.insert(value) } else { selection.remove(value) }
            }
        ))
    }
}
