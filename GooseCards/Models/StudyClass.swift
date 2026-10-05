import Foundation
import SwiftData

@Model
final class StudyClass {
    var id: UUID
    var name: String
    var colorHex: String
    var emoji: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \FlashCardSet.studyClass)
    var sets: [FlashCardSet] = []

    init(name: String, colorHex: String, emoji: String, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.emoji = emoji
        self.createdAt = createdAt
    }
}
