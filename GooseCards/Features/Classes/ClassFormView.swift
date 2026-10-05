import SwiftUI
import SwiftData

struct ClassFormView: View {
    enum Mode {
        case create
        case edit(StudyClass)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var colorHex: String = KidPalette.all[0].hex
    @State private var emoji: String = EmojiLibrary.defaultClassEmoji

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Class Name") {
                    TextField("e.g. History, Math", text: $name)
                        .font(Theme.bodyFont)
                }

                Section("Pick a Color") {
                    ColorSwatchGrid(selectedHex: $colorHex)
                }

                Section("Pick an Emoji") {
                    EmojiPickerGrid(selectedEmoji: $emoji)
                }

                Section {
                    HStack {
                        Spacer()
                        ClassTileView(studyClass: previewClass)
                            .frame(width: 170)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(isEditing ? "Edit Class" : "New Class")
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

    private var previewClass: StudyClass {
        let c = StudyClass(name: name.isEmpty ? "Your Class" : name, colorHex: colorHex, emoji: emoji)
        return c
    }

    private func loadExistingValues() {
        if case .edit(let studyClass) = mode {
            name = studyClass.name
            colorHex = studyClass.colorHex
            emoji = studyClass.emoji
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        switch mode {
        case .create:
            let newClass = StudyClass(name: trimmed, colorHex: colorHex, emoji: emoji)
            modelContext.insert(newClass)
        case .edit(let studyClass):
            studyClass.name = trimmed
            studyClass.colorHex = colorHex
            studyClass.emoji = emoji
        }
        Haptics.success()
        dismiss()
    }
}

struct ColorSwatchGrid: View {
    @Binding var selectedHex: String
    /// Fixed 6 columns so the 12-color palette always renders as exactly
    /// 2 full rows, regardless of screen width (an adaptive grid could fit
    /// an odd number per row and leave a trailing partial row).
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(KidPalette.all) { swatch in
                Circle()
                    .fill(KidPalette.color(forHex: swatch.hex))
                    .frame(width: 40, height: 40)
                    .overlay {
                        if selectedHex == swatch.hex {
                            Image(systemName: "checkmark")
                                .foregroundStyle(KidPalette.color(forHex: swatch.hex).readableForeground())
                                .fontWeight(.bold)
                        }
                    }
                    .onTapGesture {
                        selectedHex = swatch.hex
                        Haptics.tap()
                    }
                    .accessibilityLabel(swatch.name)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmojiPickerGrid: View {
    @Binding var selectedEmoji: String
    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(EmojiLibrary.all, id: \.self) { emoji in
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .onTapGesture {
                        selectedEmoji = emoji
                        Haptics.tap()
                    }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ClassFormView(mode: .create)
        .modelContainer(for: [StudyClass.self], inMemory: true)
}
