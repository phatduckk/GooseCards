import SwiftUI
import SwiftData

struct ImportClassPickerView: View {
    let file: RemoteCardFile
    let classes: [StudyClass]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedClassID: UUID?
    @State private var isImporting = false
    @State private var progressText = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if classes.isEmpty {
                    ContentUnavailableView(
                        "No Classes Yet",
                        systemImage: "books.vertical",
                        description: Text("Create a class first, then come back to import \(file.displayName).")
                    )
                } else {
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
            }
            .navigationTitle("Choose a Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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

    private func runImport() async {
        guard let selectedClass = classes.first(where: { $0.id == selectedClassID }) else { return }
        isImporting = true
        defer { isImporting = false }

        do {
            try await ImportService.importCards(
                file: file,
                into: selectedClass,
                context: modelContext,
                onProgress: { progressText = $0 }
            )
            Haptics.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
