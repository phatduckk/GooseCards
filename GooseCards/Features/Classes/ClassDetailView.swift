import SwiftUI
import SwiftData

struct ClassDetailView: View {
    @Bindable var studyClass: StudyClass

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isSelecting = false
    @State private var selection = Set<UUID>()
    @State private var isPresentingNewSet = false
    @State private var isPresentingEditClass = false
    @State private var setToRename: FlashCardSet?
    @State private var isShowingDeleteClassConfirm = false
    @State private var setToOpen: FlashCardSet?

    private var orderedSets: [FlashCardSet] {
        studyClass.sets.sorted { lhs, rhs in
            if lhs.isStarred != rhs.isStarred { return lhs.isStarred && !rhs.isStarred }
            return lhs.createdAt > rhs.createdAt
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if orderedSets.isEmpty {
                    VStack(spacing: 12) {
                        Text(studyClass.emoji).font(.system(size: 60))
                        Text("No quiz sets yet")
                            .font(Theme.titleFont)
                        Text("Tap + to create your first Flash Quiz for \(studyClass.name).")
                            .font(Theme.bodyFont)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 80)
                    .frame(maxWidth: .infinity)
                } else {
                    BulkSelectGrid(
                        items: orderedSets,
                        isSelecting: isSelecting,
                        selection: $selection,
                        onTap: { set in
                            setToOpen = set
                        },
                        tile: { set in
                            SetTileView(set: set, accentHex: studyClass.colorHex)
                                .contextMenu {
                                    Button { setToRename = set } label: {
                                        Label("Rename / Emoji", systemImage: "pencil")
                                    }
                                    Button { toggleStar(set) } label: {
                                        Label(set.isStarred ? "Unstar" : "Star", systemImage: set.isStarred ? "star.slash" : "star.fill")
                                    }
                                    Button { toggleDone(set) } label: {
                                        Label(set.isDone ? "Mark Not Done" : "Mark Done", systemImage: "checkmark.circle")
                                    }
                                    Button(role: .destructive) { delete(sets: [set]) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
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
        .navigationTitle(studyClass.name)
        .navigationDestination(item: $setToOpen) { set in
            CardEditorView(set: set)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isSelecting ? "Done" : "Select") {
                    isSelecting.toggle()
                    if !isSelecting { selection.removeAll() }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { isPresentingNewSet = true } label: {
                        Label("New Flash Quiz", systemImage: "plus.circle.fill")
                    }
                    Button { isPresentingEditClass = true } label: {
                        Label("Edit Class", systemImage: "pencil")
                    }
                    Button(role: .destructive) { isShowingDeleteClassConfirm = true } label: {
                        Label("Delete Class", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewSet) {
            SetFormView(mode: .create(studyClass: studyClass))
        }
        .sheet(isPresented: $isPresentingEditClass) {
            ClassFormView(mode: .edit(studyClass))
        }
        .sheet(item: $setToRename) { set in
            SetFormView(mode: .edit(set))
        }
        .confirmationDialog(
            "Delete \(studyClass.name)? This removes all its quiz sets and history.",
            isPresented: $isShowingDeleteClassConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Class", role: .destructive) {
                modelContext.delete(studyClass)
                dismiss()
            }
        }
    }

    private func toggleStar(_ set: FlashCardSet) {
        set.isStarred.toggle()
        Haptics.tap()
    }

    private func toggleDone(_ set: FlashCardSet) {
        set.isDone.toggle()
        Haptics.tap()
    }

    private func deleteSelected() {
        let sets = orderedSets.filter { selection.contains($0.id) }
        delete(sets: sets)
        selection.removeAll()
        isSelecting = false
    }

    private func delete(sets: [FlashCardSet]) {
        for set in sets {
            modelContext.delete(set)
        }
        Haptics.warning()
    }
}

struct SetTileView: View {
    let set: FlashCardSet
    let accentHex: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                if set.isStarred {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
                Spacer()
                if set.isDone {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }
            Text(set.emoji)
                .font(.system(size: 40))
            Text(set.name)
                .font(Theme.headlineFont)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Text("\(set.cards.count) card\(set.cards.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding()
        .background(KidPalette.color(forHex: accentHex).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.tileCorner, style: .continuous)
                .stroke(KidPalette.color(forHex: accentHex), lineWidth: 2)
        )
    }
}

#Preview {
    let container = try! ModelContainer(
        for: StudyClass.self, FlashCardSet.self, FlashCard.self, QuizAttempt.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let sample = StudyClass(name: "History", colorHex: KidPalette.all[0].hex, emoji: "🏛️")
    container.mainContext.insert(sample)
    return NavigationStack { ClassDetailView(studyClass: sample) }
        .modelContainer(container)
}
