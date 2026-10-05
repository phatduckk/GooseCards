import SwiftUI

/// Rounded pill used for horizontal-scrolling filter bars (class/quiz
/// selection). Background is always the solid `color` — matching the solid
/// pastel fill used on class tiles exactly, rather than a lighter wash that
/// reads as a different color. Selection is shown with a border ring
/// instead of a background/opacity change. Text uses the same
/// `readableForeground()` darkened hue as everywhere else `color` is used
/// as a fill, unless `textColorOverride` is supplied (for non-hue colors
/// like the neutral "All" pill, which wants plain white text, not a
/// computed dark-gray fallback).
struct FilterChip: View {
    let title: String
    let color: Color
    let isSelected: Bool
    var textColorOverride: Color? = nil
    let action: () -> Void

    private var textColor: Color { textColorOverride ?? color.readableForeground() }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .bold : .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(color)
                .foregroundStyle(textColor)
                .clipShape(Capsule())
                .overlay {
                    if isSelected {
                        Capsule().stroke(textColor, lineWidth: 2.5)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
