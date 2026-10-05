import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum Theme {
    static let cardCorner: CGFloat = 24
    static let tileCorner: CGFloat = 20
    static let controlCorner: CGFloat = 16

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let bigNumberFont = Font.system(size: 64, weight: .heavy, design: .rounded)

    static let background = Color(.systemGroupedBackground)
}

enum Haptics {
    static func tap() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func warning() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

extension View {
    func kidTileShadow() -> some View {
        self.shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }
}
