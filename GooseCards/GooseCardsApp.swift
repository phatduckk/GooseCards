import SwiftUI
import SwiftData

@main
struct GooseCardsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [StudyClass.self, FlashCardSet.self, FlashCard.self, QuizAttempt.self])
    }
}
