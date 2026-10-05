import Foundation
import SwiftData

/// Tracks which GitHub Cards/*.csv files have been imported and at what
/// commit SHA, so the Import tab can tell New vs Updated vs already-imported.
@Model
final class ImportedFileRecord {
    var filename: String
    var sha: String
    var importedAt: Date

    init(filename: String, sha: String, importedAt: Date = .now) {
        self.filename = filename
        self.sha = sha
        self.importedAt = importedAt
    }
}
