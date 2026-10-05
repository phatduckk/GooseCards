import SwiftUI

/// Photos-app-style selectable grid: reused for both the Flash Card Sets grid
/// and the Cards grid. The parent screen owns the "Select" toggle and the
/// bottom "Delete (n)" bar; this view just renders tiles with selection
/// overlays and routes taps.
struct BulkSelectGrid<Item: Identifiable, Tile: View>: View {
    let items: [Item]
    let isSelecting: Bool
    @Binding var selection: Set<Item.ID>
    var columns: [GridItem] = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    let onTap: (Item) -> Void
    @ViewBuilder let tile: (Item) -> Tile

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(items) { item in
                ZStack(alignment: .topTrailing) {
                    tile(item)
                        .opacity(isSelecting && !selection.contains(item.id) ? 0.55 : 1.0)

                    if isSelecting {
                        SelectionBadge(isSelected: selection.contains(item.id))
                            .padding(10)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isSelecting {
                        toggle(item.id)
                    } else {
                        onTap(item)
                    }
                }
            }
        }
    }

    private func toggle(_ id: Item.ID) {
        Haptics.tap()
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }
}

struct SelectionBadge: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title2)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, isSelected ? Color.accentColor : Color.black.opacity(0.35))
            .background(Circle().fill(.white).padding(2))
            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
    }
}

/// Bottom action bar shown while in selection mode.
struct BulkDeleteBar: View {
    let count: Int
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Label("Delete (\(count))", systemImage: "trash.fill")
                    .font(Theme.headlineFont)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(count == 0)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
