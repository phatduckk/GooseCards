import Foundation
import SwiftData

@Model
final class FlashCardSet {
    var id: UUID
    var name: String
    var emoji: String
    var isStarred: Bool
    var isDone: Bool
    var createdAt: Date

    var studyClass: StudyClass?

    @Relationship(deleteRule: .cascade, inverse: \FlashCard.set)
    var cards: [FlashCard] = []

    @Relationship(deleteRule: .cascade, inverse: \QuizAttempt.set)
    var attempts: [QuizAttempt] = []

    init(name: String, emoji: String, studyClass: StudyClass? = nil, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.isStarred = false
        self.isDone = false
        self.createdAt = createdAt
        self.studyClass = studyClass
    }

    var sortedCards: [FlashCard] {
        cards.sorted { $0.sortIndex < $1.sortIndex }
    }

    var sortedAttempts: [QuizAttempt] {
        attempts.sorted { $0.date < $1.date }
    }
}
