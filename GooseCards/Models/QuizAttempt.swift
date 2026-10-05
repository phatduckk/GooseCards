import Foundation
import SwiftData

@Model
final class QuizAttempt {
    var id: UUID
    var date: Date
    var numRight: Int
    var numWrong: Int
    var percent: Double
    var letterGrade: String
    var durationSeconds: Int?
    var numQuestionsConfigured: Int?

    var set: FlashCardSet?

    init(
        date: Date = .now,
        numRight: Int,
        numWrong: Int,
        durationSeconds: Int? = nil,
        numQuestionsConfigured: Int? = nil,
        set: FlashCardSet? = nil
    ) {
        let total = numRight + numWrong
        let computedPercent = total > 0 ? (Double(numRight) / Double(total)) * 100.0 : 0
        let computedGrade = Grading.letterGrade(forPercent: computedPercent)

        self.id = UUID()
        self.date = date
        self.numRight = numRight
        self.numWrong = numWrong
        self.percent = computedPercent
        self.letterGrade = computedGrade
        self.durationSeconds = durationSeconds
        self.numQuestionsConfigured = numQuestionsConfigured
        self.set = set
    }
}
