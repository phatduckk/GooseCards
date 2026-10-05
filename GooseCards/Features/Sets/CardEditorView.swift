import SwiftUI
import SwiftData
import UIKit

struct CardEditorView: View {
    @Bindable var set: FlashCardSet

    @Environment(\.modelContext) private var modelContext

    @State private var isSelecting = false
    @State private var selection = Set<UUID>()
    @State private var isPresentingNewCard = false
    @State private var cardToEdit: FlashCard?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if set.sortedCards.isEmpty {
                    VStack(spacing: 12) {
                        Text(set.emoji).font(.system(size: 60))
                        Text("No cards yet")
                            .font(Theme.titleFont)
                        Text("Tap + to add your first flash card.")
                            .font(Theme.bodyFont)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 80)
                    .frame(maxWidth: .infinity)
                } else {
                    BulkSelectGrid(
                        items: set.sortedCards,
                        isSelecting: isSelecting,
                        selection: $selection,
                        onTap: { card in
                            cardToEdit = card
                        },
                        tile: { card in
                            CardTileView(card: card)
                        }
                    )
                    .padding()
                }
            }

            if isSelecting {
                BulkDeleteBar(count: selection.count) {
                    deleteSelected()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .navigationTitle(set.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isSelecting ? "Done" : "Select") {
                    isSelecting.toggle()
                    if !isSelecting { selection.removeAll() }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNewCard = true
                } label: {
                    Label("Add Card", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewCard) {
            CardFormView(mode: .create(set: set))
        }
        .sheet(item: $cardToEdit) { card in
            CardFormView(mode: .edit(card))
        }
    }

    private func deleteSelected() {
        let cards = set.sortedCards.filter { selection.contains($0.id) }
        for card in cards {
            modelContext.delete(card)
        }
        Haptics.warning()
        selection.removeAll()
        isSelecting = false
    }
}

struct CardTileView: View {
    let card: FlashCard

    var body: some View {
        VStack(spacing: 8) {
            if let data = card.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Text(card.front)
                .font(Theme.headlineFont)
                .lineLimit(3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCorner, style: .continuous))
        .kidTileShadow()
    }
}

#Preview {
    let container = try! ModelContainer(
        for: StudyClass.self, FlashCardSet.self, FlashCard.self, QuizAttempt.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let set = FlashCardSet(name: "Multiplication", emoji: "🧮")
    container.mainContext.insert(set)
    return NavigationStack { CardEditorView(set: set) }
        .modelContainer(container)
}
