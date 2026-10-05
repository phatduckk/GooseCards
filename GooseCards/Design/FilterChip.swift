import SwiftUI

/// Rounded pill used for horizontal-scrolling filter bars (class/quiz
/// selection). Selected state fills with `color`; unselected shows a tinted
/// outline-less wash of the same color so the whole row stays colorful.
struct FilterChip: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.15))
                .foregroundStyle(isSelected ? .white : color)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
