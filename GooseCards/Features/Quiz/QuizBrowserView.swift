import SwiftUI
import SwiftData

struct QuizBrowserView: View {
    @Query(sort: \FlashCardSet.createdAt, order: .reverse) private var allSets: [FlashCardSet]
    @Query(sort: \StudyClass.createdAt) private var classes: [StudyClass]

    @State private var searchText = ""
    @State private var selectedClassID: UUID?
    @State private var configuringSet: FlashCardSet?
    @State private var activeConfig: QuizConfig?

    private var filteredSets: [FlashCardSet] {
        allSets
            .filter { selectedClassID == nil || $0.studyClass?.id == selectedClassID }
            .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { lhs, rhs in
                if lhs.isStarred != rhs.isStarred { return lhs.isStarred }
                return lhs.createdAt > rhs.createdAt
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !classes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: "All", color: .gray, isSelected: selectedClassID == nil, textColorOverride: .white) {
                            selectedClassID = nil
                        }
                        ForEach(classes) { studyClass in
                            FilterChip(
                                title: "\(studyClass.emoji) \(studyClass.name)",
                                color: KidPalette.color(forHex: studyClass.colorHex),
                                isSelected: selectedClassID == studyClass.id
                            ) {
                                selectedClassID = studyClass.id
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
            }

            if filteredSets.isEmpty {
                ContentUnavailableView(
                    "No Flash Quizzes Found",
                    systemImage: "bolt.slash",
                    description: Text("Create a class and add a Flash Quiz to get started.")
                )
                Spacer()
            } else {
                List {
                    ForEach(filteredSets) { set in
                        Button {
                            configuringSet = set
                        } label: {
                            QuizRow(set: set)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .leading) {
                            Button {
                                set.isStarred.toggle()
                                Haptics.tap()
                            } label: {
                                Label(set.isStarred ? "Unstar" : "Star", systemImage: "star.fill")
                            }
                            .tint(.yellow)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                set.isDone.toggle()
                                Haptics.tap()
                            } label: {
                                Label(set.isDone ? "Not Done" : "Done", systemImage: "checkmark.seal.fill")
                            }
                            .tint(.green)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .navigationTitle("Take a Quiz")
        .searchable(text: $searchText, prompt: "Search quizzes")
        .sheet(item: $configuringSet) { set in
            QuizConfigView(set: set) { config in
                configuringSet = nil
                activeConfig = config
            }
        }
        .fullScreenCover(item: $activeConfig) { config in
            QuizPlayView(config: config) {
                activeConfig = nil
            }
        }
    }
}

private struct QuizRow: View {
    let set: FlashCardSet

    var body: some View {
        HStack(spacing: 14) {
            Text(set.emoji)
                .font(.system(size: 32))
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(set.name)
                        .font(Theme.headlineFont)
                        .foregroundStyle(.primary)
                    if set.isStarred {
                        Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                    }
                    if set.isDone {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).font(.caption)
                    }
                }
                if let className = set.studyClass?.name {
                    Text(className)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(set.cards.count)")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}
