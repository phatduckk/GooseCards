import SwiftUI
import SwiftData

struct SetFormView: View {
    enum Mode {
        case create(studyClass: StudyClass)
        case edit(FlashCardSet)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var emoji: String = EmojiLibrary.defaultSetEmoji

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Quiz Name") {
                    TextField("e.g. Multiplication, State Capitals", text: $name)
                        .font(Theme.bodyFont)
                }
                Section("Pick an Emoji") {
                    EmojiPickerGrid(selectedEmoji: $emoji)
                }
            }
            .navigationTitle(isEditing ? "Edit Flash Quiz" : "New Flash Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.bold)
                }
            }
            .onAppear(perform: loadExistingValues)
        }
    }

    private func loadExistingValues() {
        if case .edit(let set) = mode {
            name = set.name
            emoji = set.emoji
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        switch mode {
        case .create(let studyClass):
            let newSet = FlashCardSet(name: trimmed, emoji: emoji, studyClass: studyClass)
            modelContext.insert(newSet)
        case .edit(let set):
            set.name = trimmed
            set.emoji = emoji
        }
        Haptics.success()
        dismiss()
    }
}
