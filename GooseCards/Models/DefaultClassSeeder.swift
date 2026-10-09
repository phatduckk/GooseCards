import Foundation
import SwiftData

enum DefaultClassSeeder {
    private static let seededKey = "didSeedDefaultClasses"

    private static let multiplicationSetName = "Multiplication Facts"
    private static let divisionSetName = "Division Facts"

    /// Cards/*.csv files that duplicate sets seeded on first launch. They
    /// never count as "new" in the import browser or the import button's dot.
    static let builtInCardFilenames: Set<String> = [
        "\(multiplicationSetName).csv",
        "\(divisionSetName).csv",
    ]

    private static let defaults: [(name: String, emoji: String)] = [
        ("English", "📖"),
        ("Math", "➗"),
        ("Science", "🔬"),
        ("Social Studies", "🌍"),
        ("Art", "🎨"),
        ("Music", "🎵"),
        ("History", "🏛️"),
    ]

    /// "a x b" -> a*b, for a and b in 1...12.
    private static var multiplicationCards: [(front: String, back: String)] {
        (1...12).flatMap { a in
            (1...12).map { b in ("\(a) x \(b)", "\(a * b)") }
        }
    }

    /// "(d*q) / d" -> q, for quotient q and divisor d in 1...12 (always divides evenly).
    private static var divisionCards: [(front: String, back: String)] {
        (1...12).flatMap { q in
            (1...12).map { d in ("\(d * q) / \(d)", "\(q)") }
        }
    }

    static func seedIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }

        var colorPool = KidPalette.funForKids.shuffled()
        var mathClass: StudyClass?

        for item in defaults {
            let hex = colorPool.popLast()?.hex ?? KidPalette.funForKids.randomElement()!.hex
            let studyClass = StudyClass(name: item.name, colorHex: hex, emoji: item.emoji)
            context.insert(studyClass)
            if item.name == "Math" { mathClass = studyClass }
        }

        if let mathClass {
            insertSet(named: multiplicationSetName, emoji: "✖️", cards: multiplicationCards, into: mathClass, context: context)
            insertSet(named: divisionSetName, emoji: "➗", cards: divisionCards, into: mathClass, context: context)
        }

        if (try? context.save()) != nil {
            UserDefaults.standard.set(true, forKey: seededKey)
        }
    }

    private static func insertSet(
        named name: String,
        emoji: String,
        cards: [(front: String, back: String)],
        into studyClass: StudyClass,
        context: ModelContext
    ) {
        let set = FlashCardSet(name: name, emoji: emoji, studyClass: studyClass)
        context.insert(set)
        for (index, card) in cards.enumerated() {
            context.insert(FlashCard(front: card.front, back: card.back, sortIndex: index, set: set))
        }
    }
}
