import SwiftUI
import SwiftData

enum ImportStatus {
    case new
    case updated
    case upToDate

    var label: String {
        switch self {
        case .new: return "New"
        case .updated: return "Updated"
        case .upToDate: return "Imported"
        }
    }

    var color: Color {
        switch self {
        case .new: return .green
        case .updated: return .orange
        case .upToDate: return .secondary
        }
    }
}

struct ImportBrowserView: View {
    /// Called when the user wants to quiz on a set they just imported.
    var onStartQuiz: (FlashCardSet) -> Void = { _ in }

    @Query private var importedRecords: [ImportedFileRecord]
    @Query(sort: \StudyClass.createdAt) private var classes: [StudyClass]

    @Environment(\.dismiss) private var dismiss

    @State private var remoteFiles: [RemoteCardFile] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var fileToImport: RemoteCardFile?

    var body: some View {
        Group {
            if remoteFiles.isEmpty && isLoading {
                ProgressView("Checking for cards…")
            } else if remoteFiles.isEmpty {
                ContentUnavailableView(
                    "No Card Files Found",
                    systemImage: "tray",
                    description: Text(errorMessage ?? "Nothing in the Cards folder on GitHub yet.")
                )
            } else {
                List {
                    Section {
                        ForEach(remoteFiles) { file in
                            Button {
                                fileToImport = file
                            } label: {
                                ImportRow(file: file, status: status(for: file))
                            }
                        }
                    } footer: {
                        Text("Cards come from github.com/phatduckk/GooseCards. Tap one to import it.")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .navigationTitle("Import Flash Cards")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await load() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .refreshable { await load() }
        .task { await load() }
        .sheet(item: $fileToImport) { file in
            ImportClassPickerView(file: file, classes: classes) { set in
                fileToImport = nil
                onStartQuiz(set)
            }
        }
    }

    private func status(for file: RemoteCardFile) -> ImportStatus {
        guard let record = importedRecords.first(where: { $0.filename == file.name }) else { return .new }
        return record.sha == file.sha ? .upToDate : .updated
    }

    private func load() async {
        isLoading = true
        do {
            remoteFiles = try await GitHubCardsService.listCardFiles()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct ImportRow: View {
    let file: RemoteCardFile
    let status: ImportStatus

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(file.displayName)
                    .font(Theme.headlineFont)
                    .foregroundStyle(.primary)
                Text(status.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(status.color)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
