import Foundation
import SwiftData

enum DefaultClassSeeder {
    private static let seededKey = "didSeedDefaultClasses"

    private static let defaults: [(name: String, emoji: String)] = [
        ("English", "📖"),
        ("Math", "➗"),
        ("Science", "🔬"),
        ("Social Studies", "🌍"),
        ("Art", "🎨"),
        ("Music", "🎵"),
        ("History", "🏛️"),
    ]

    static func seedIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }

        var colorPool = KidPalette.funForKids.shuffled()

        for item in defaults {
            let hex = colorPool.popLast()?.hex ?? KidPalette.funForKids.randomElement()!.hex
            let studyClass = StudyClass(name: item.name, colorHex: hex, emoji: item.emoji)
            context.insert(studyClass)
        }

        if (try? context.save()) != nil {
            UserDefaults.standard.set(true, forKey: seededKey)
        }
    }
}
