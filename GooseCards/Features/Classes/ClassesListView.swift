import SwiftUI
import SwiftData

struct ClassesListView: View {
    @Query(sort: \StudyClass.createdAt) private var classes: [StudyClass]
    @Environment(\.modelContext) private var modelContext

    @State private var isPresentingNewClass = false

    private let columns = [GridItem(.adaptive(minimum: 170), spacing: 18)]

    var body: some View {
        ScrollView {
            if classes.isEmpty {
                EmptyClassesView(onAdd: { isPresentingNewClass = true })
                    .padding(.top, 80)
                    .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(classes) { studyClass in
                        NavigationLink(value: studyClass) {
                            ClassTileView(studyClass: studyClass)
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .navigationTitle("My Classes")
        .navigationDestination(for: StudyClass.self) { studyClass in
            ClassDetailView(studyClass: studyClass)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNewClass = true
                } label: {
                    Label("New Class", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewClass) {
            ClassFormView(mode: .create)
        }
    }
}

private struct EmptyClassesView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("🦢")
                .font(.system(size: 80))
            Text("No classes yet!")
                .font(Theme.titleFont)
            Text("Add a class like Math or History to get started.")
                .font(Theme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onAdd) {
                Label("Add a Class", systemImage: "plus.circle.fill")
                    .font(Theme.headlineFont)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct ClassTileView: View {
    let studyClass: StudyClass

    var body: some View {
        VStack(spacing: 10) {
            Text(studyClass.emoji)
                .font(.system(size: 44))
            Text(studyClass.name)
                .font(Theme.headlineFont)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Text("\(studyClass.sets.count) set\(studyClass.sets.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding()
        .background(KidPalette.color(forHex: studyClass.colorHex))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCorner, style: .continuous))
        .kidTileShadow()
    }
}

#Preview {
    NavigationStack { ClassesListView() }
        .modelContainer(for: [StudyClass.self, FlashCardSet.self, FlashCard.self, QuizAttempt.self], inMemory: true)
}
