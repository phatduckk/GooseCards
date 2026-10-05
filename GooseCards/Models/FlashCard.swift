import Foundation
import SwiftData

@Model
final class FlashCard {
    var id: UUID
    var front: String
    var back: String
    var imageData: Data?
    var sortIndex: Int

    var set: FlashCardSet?

    init(front: String, back: String, imageData: Data? = nil, sortIndex: Int, set: FlashCardSet? = nil) {
        self.id = UUID()
        self.front = front
        self.back = back
        self.imageData = imageData
        self.sortIndex = sortIndex
        self.set = set
    }
}
