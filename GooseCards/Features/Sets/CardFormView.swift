import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct CardFormView: View {
    enum Mode {
        case create(set: FlashCardSet)
        case edit(FlashCard)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var front: String = ""
    @State private var back: String = ""
    @State private var imageData: Data?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var isShowingImageSearch = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Question (Front)") {
                    TextField("What is an island?", text: $front, axis: .vertical)
                        .lineLimit(1...4)
                        .font(Theme.bodyFont)
                }
                Section("Answer (Back)") {
                    TextField("Land surrounded by water", text: $back, axis: .vertical)
                        .lineLimit(1...4)
                        .font(Theme.bodyFont)
                }
                Section("Picture (optional)") {
                    if let imageData, let uiImage = UIImage(data: imageData) {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            Button(role: .destructive) {
                                self.imageData = nil
                                photosPickerItem = nil
                            } label: {
                                Label("Remove Picture", systemImage: "xmark.circle")
                            }
                        }
                    } else {
                        Button {
                            isShowingImageSearch = true
                        } label: {
                            Label("Search the Web for a Picture", systemImage: "magnifyingglass")
                        }
                        PhotosPicker(selection: $photosPickerItem, matching: .images) {
                            Label("Choose from Photos", systemImage: "photo.on.rectangle")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Card" : "New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(front.trimmingCharacters(in: .whitespaces).isEmpty
                                  || back.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadExistingValues)
            .task(id: photosPickerItem) {
                guard let photosPickerItem else { return }
                if let data = try? await photosPickerItem.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
            .sheet(isPresented: $isShowingImageSearch) {
                ImageSearchView { data in
                    imageData = data
                }
            }
        }
    }

    private func loadExistingValues() {
        if case .edit(let card) = mode {
            front = card.front
            back = card.back
            imageData = card.imageData
        }
    }

    private func save() {
        let trimmedFront = front.trimmingCharacters(in: .whitespaces)
        let trimmedBack = back.trimmingCharacters(in: .whitespaces)
        guard !trimmedFront.isEmpty, !trimmedBack.isEmpty else { return }

        switch mode {
        case .create(let set):
            let newCard = FlashCard(
                front: trimmedFront,
                back: trimmedBack,
                imageData: imageData,
                sortIndex: set.cards.count,
                set: set
            )
            modelContext.insert(newCard)
        case .edit(let card):
            card.front = trimmedFront
            card.back = trimmedBack
            card.imageData = imageData
        }
        Haptics.success()
        dismiss()
    }
}
