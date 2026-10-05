import Foundation
import SwiftData

enum ImportService {
    /// Downloads a Cards/*.csv file, creates a FlashCardSet (with its cards and
    /// any per-card images) inside the given class, and records the import.
    /// `onProgress` is called on the main actor with a short status string.
    @MainActor
    static func importCards(
        file: RemoteCardFile,
        into studyClass: StudyClass,
        context: ModelContext,
        onProgress: @escaping (String) -> Void = { _ in }
    ) async throws {
        onProgress("Downloading card list…")
        let csvText = try await GitHubCardsService.downloadCSV(file)
        let rows = CSVParser.parseCards(from: csvText)

        let newSet = FlashCardSet(name: file.displayName, emoji: EmojiLibrary.defaultSetEmoji, studyClass: studyClass)
        context.insert(newSet)

        for (index, row) in rows.enumerated() {
            var imageData: Data?
            if let urlString = row.imageURLString {
                onProgress("Downloading image \(index + 1) of \(rows.count)…")
                imageData = await GitHubCardsService.downloadImageData(from: urlString)
            }
            let card = FlashCard(front: row.front, back: row.back, imageData: imageData, sortIndex: index, set: newSet)
            context.insert(card)
        }

        recordImport(file: file, context: context)
        try context.save()
    }

    private static func recordImport(file: RemoteCardFile, context: ModelContext) {
        let filename = file.name
        let descriptor = FetchDescriptor<ImportedFileRecord>(
            predicate: #Predicate { $0.filename == filename }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.sha = file.sha
            existing.importedAt = .now
        } else {
            context.insert(ImportedFileRecord(filename: file.name, sha: file.sha))
        }
    }
}
