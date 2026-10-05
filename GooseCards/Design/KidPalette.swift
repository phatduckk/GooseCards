import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct KidColor: Identifiable, Hashable {
    let name: String
    let hex: String
    var id: String { hex }
}

enum KidPalette {
    /// Soft pastel rainbow — 12 hues evenly spaced around the color wheel at
    /// HSL(_, 60%, 80%), so they stay easy to tell apart while reading as
    /// gentle rather than eye-jarring.
    static let all: [KidColor] = [
        KidColor(name: "Coral", hex: "#EBADAD"),
        KidColor(name: "Peach", hex: "#EBCCAD"),
        KidColor(name: "Lemon", hex: "#EBEBAD"),
        KidColor(name: "Lime", hex: "#CCEBAD"),
        KidColor(name: "Mint", hex: "#ADEBAD"),
        KidColor(name: "Seafoam", hex: "#ADEBCC"),
        KidColor(name: "Aqua", hex: "#ADEBEB"),
        KidColor(name: "Sky", hex: "#ADCCEB"),
        KidColor(name: "Periwinkle", hex: "#ADADEB"),
        KidColor(name: "Lavender", hex: "#CCADEB"),
        KidColor(name: "Orchid", hex: "#EBADEB"),
        KidColor(name: "Bubblegum", hex: "#EBADCC"),
    ]

    /// Full palette — every entry is already a soft, kid-friendly pastel.
    static let funForKids: [KidColor] = all

    static func color(forHex hex: String) -> Color {
        Color(hex: hex) ?? .gray
    }
}

extension Color {
    /// A darker, more saturated version of this color's own hue — legible
    /// as text/foreground sitting on top of this same color used as a
    /// light pastel background or wash. Same formula everywhere (tile
    /// text, pill text in both its selected and unselected states) so
    /// "a class's color" reads as one consistent color across the app,
    /// just lighter for fills and darker for text on top of them. Falls
    /// back to a plain dark gray for colors with no real hue (e.g. the
    /// neutral "All" filter chip), since a hue can't be preserved there.
    func readableForeground() -> Color {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a), s > 0.08 else {
            return Color(white: 0.32)
        }
        return Color(hue: h, saturation: 0.65, brightness: 0.42)
        #else
        return self
        #endif
    }

    init?(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "#", with: "")
        guard sanitized.count == 6, let value = UInt64(sanitized, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
