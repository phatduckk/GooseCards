import Foundation

enum Grading {
    /// percent is 0...100
    static func letterGrade(forPercent percent: Double) -> String {
        switch percent {
        case 97...: return "A+"
        case 93..<97: return "A"
        case 90..<93: return "A-"
        case 87..<90: return "B+"
        case 83..<87: return "B"
        case 80..<83: return "B-"
        case 77..<80: return "C+"
        case 73..<77: return "C"
        case 70..<73: return "C-"
        case 67..<70: return "D+"
        case 65..<67: return "D"
        case 60..<65: return "D-"
        default: return "F"
        }
    }

    static func color(forGrade grade: String) -> String {
        switch grade.first {
        case "A": return "#34C759" // green
        case "B": return "#30B0C7" // teal
        case "C": return "#FFC107" // amber
        case "D": return "#FF9500" // orange
        default: return "#FF3B30" // red (F)
        }
    }
}
