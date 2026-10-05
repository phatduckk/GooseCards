import SwiftUI
import SwiftData

struct ImportClassPickerView: View {
    let file: RemoteCardFile
    let classes: [StudyClass]
    /// Called when the user wants to quiz on the set they just imported.
    var onStartQuiz: (FlashCardSet) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedClassID: UUID?
    @State private var isImporting = false
    @State private var progressText = ""
    @State private var errorMessage: String?
    @State private var importedSet: FlashCardSet?

    var body: some View {
        NavigationStack {
            Group {
                if let importedSet {
                    successView(for: importedSet)
                } else if classes.isEmpty {
                    ContentUnavailableView(
                        "No Classes Yet",
                        systemImage: "books.vertical",
                        description: Text("Create a class first, then come back to import \(file.displayName).")
                    )
                } else {
                    classPicker
                }
            }
            .navigationTitle(importedSet == nil ? "Choose a Class" : "All Set!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if importedSet == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import") {
                            Task { await runImport() }
                        }
                        .fontWeight(.bold)
                        .disabled(selectedClassID == nil || isImporting)
                    }
                }
            }
            .overlay {
                if isImporting {
                    ZStack {
                        Color.black.opacity(0.15).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text(progressText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .alert("Import Failed", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var classPicker: some View {
        Form {
            Section("Import \"\(file.displayName)\" into:") {
                ForEach(classes) { studyClass in
                    Button {
                        selectedClassID = studyClass.id
                    } label: {
                        HStack {
                            Text(studyClass.emoji)
                            Text(studyClass.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedClassID == studyClass.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
        }
    }

    private func successView(for set: FlashCardSet) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🎉")
                .font(.system(size: 64))

            VStack(spacing: 6) {
                Text("\(set.name) is ready!")
                    .font(Theme.titleFont)
                    .multilineTextAlignment(.center)
                Text("\(set.cards.count) card\(set.cards.count == 1 ? "" : "s") added to \(set.studyClass?.name ?? "your class")")
                    .font(Theme.bodyFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onStartQuiz(set)
            } label: {
                Label("Start Quiz", systemImage: "bolt.fill")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(KidPalette.color(forHex: set.studyClass?.colorHex ?? KidPalette.all[0].hex))
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlCorner, style: .continuous))
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Button("Maybe Later") { dismiss() }
                .font(Theme.bodyFont)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Theme.background)
    }

    private func runImport() async {
        guard let selectedClass = classes.first(where: { $0.id == selectedClassID }) else { return }
        isImporting = true
        defer { isImporting = false }

        do {
            let newSet = try await ImportService.importCards(
                file: file,
                into: selectedClass,
                context: modelContext,
                onProgress: { progressText = $0 }
            )
            Haptics.success()
            importedSet = newSet
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
