import SwiftUI

/// Rounded pill used for horizontal-scrolling filter bars (class/quiz
/// selection). Selected state fills with `color`; unselected shows a tinted
/// wash of the same color so the whole row stays colorful. Text uses the
/// same `readableForeground()` darkened hue in both states — matches the
/// text treatment on class tiles, and stays legible against both the solid
/// pastel fill and its much lighter wash.
struct FilterChip: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    private var textColor: Color { color.readableForeground() }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.15))
                .foregroundStyle(textColor)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
