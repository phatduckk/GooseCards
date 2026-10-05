import SwiftUI

struct KidColor: Identifiable, Hashable {
    let name: String
    let hex: String
    var id: String { hex }
}

enum KidPalette {
    static let all: [KidColor] = [
        KidColor(name: "Tomato", hex: "#FF6B6B"),
        KidColor(name: "Tangerine", hex: "#FF9F43"),
        KidColor(name: "Sunshine", hex: "#FFD93D"),
        KidColor(name: "Lime", hex: "#8BC34A"),
        KidColor(name: "Mint", hex: "#2EC4B6"),
        KidColor(name: "Sky", hex: "#4D96FF"),
        KidColor(name: "Cornflower", hex: "#5B6EF5"),
        KidColor(name: "Grape", hex: "#9D65C9"),
        KidColor(name: "Bubblegum", hex: "#FF6FB5"),
        KidColor(name: "Watermelon", hex: "#FF4D6D"),
        KidColor(name: "Teal", hex: "#20C997"),
        KidColor(name: "Slate", hex: "#6C7A89"),
    ]

    /// The vivid, kid-friendly subset used for auto-assigned colors (no muted/drab tones).
    static let funForKids: [KidColor] = all.filter { $0.name != "Slate" }

    static func color(forHex hex: String) -> Color {
        Color(hex: hex) ?? .gray
    }
}

extension Color {
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
