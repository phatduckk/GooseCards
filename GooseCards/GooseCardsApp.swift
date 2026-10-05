import SwiftUI
import SwiftData

@main
struct GooseCardsApp: App {
    private let container: ModelContainer

    init() {
        let schema = Schema([StudyClass.self, FlashCardSet.self, FlashCard.self, QuizAttempt.self])
        do {
            container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        DefaultClassSeeder.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
