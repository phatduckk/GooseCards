import SwiftUI
import SwiftData

struct ClassesListView: View {
    @Query(sort: \StudyClass.createdAt) private var classes: [StudyClass]
    @Environment(\.modelContext) private var modelContext

    @AppStorage("showEmptyClasses") private var showEmptyClasses = false

    @State private var isPresentingNewClass = false
    @State private var isPresentingImport = false
    /// Set aside when the import sheet asks to start a quiz; consumed in its
    /// onDismiss so we don't present a new sheet while one is still closing.
    @State private var pendingQuizSet: FlashCardSet?
    @State private var quizConfigSet: FlashCardSet?
    @State private var activeConfig: QuizConfig?

    private let columns = [GridItem(.adaptive(minimum: 170), spacing: 18)]

    private var visibleClasses: [StudyClass] {
        showEmptyClasses ? classes : classes.filter { !$0.sets.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if !classes.isEmpty {
                    header
                }

                if classes.isEmpty {
                    EmptyClassesView(onAdd: { isPresentingNewClass = true })
                        .padding(.top, 80)
                        .frame(maxWidth: .infinity)
                } else if visibleClasses.isEmpty {
                    AllEmptyClassesView(onShowEmpty: { showEmptyClasses = true })
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity)
                } else {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(visibleClasses) { studyClass in
                            NavigationLink(value: studyClass) {
                                ClassTileView(studyClass: studyClass)
                            }
                            .buttonStyle(BouncyButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("My Classes")
        .navigationDestination(for: StudyClass.self) { studyClass in
            ClassDetailView(studyClass: studyClass)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingImport = true
                } label: {
                    Label("Import Flash Cards", systemImage: "bolt.circle.fill")
                }
            }
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
        .sheet(isPresented: $isPresentingImport, onDismiss: {
            if let pendingQuizSet {
                quizConfigSet = pendingQuizSet
                self.pendingQuizSet = nil
            }
        }) {
            NavigationStack {
                ImportBrowserView { set in
                    pendingQuizSet = set
                    isPresentingImport = false
                }
            }
        }
        .sheet(item: $quizConfigSet) { set in
            QuizConfigView(set: set) { config in
                quizConfigSet = nil
                activeConfig = config
            }
        }
        .fullScreenCover(item: $activeConfig) { config in
            QuizPlayView(config: config) { activeConfig = nil }
        }
    }

    private var header: some View {
        HStack {
            Text("My Classes")
                .font(.largeTitle.bold())
            Spacer()
            Toggle("Show Empty", isOn: $showEmptyClasses)
                .toggleStyle(.switch)
                .font(.subheadline.weight(.semibold))
                .fixedSize()
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

private struct EmptyClassesView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image("GooseMascot")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
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

private struct AllEmptyClassesView: View {
    let onShowEmpty: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("🙈")
                .font(.system(size: 60))
            Text("All Your Classes Are Empty")
                .font(Theme.titleFont)
            Text("None of your classes have any Flash Quizzes yet.")
                .font(Theme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onShowEmpty) {
                Label("Show Empty Classes", systemImage: "eye.fill")
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

    private var bgColor: Color { KidPalette.color(forHex: studyClass.colorHex) }
    private var textColor: Color { bgColor.readableForeground() }

    var body: some View {
        VStack(spacing: 10) {
            Text(studyClass.emoji)
                .font(.system(size: 44))
            Text(studyClass.name)
                .font(Theme.headlineFont)
                .foregroundStyle(textColor)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Text("\(studyClass.sets.count) set\(studyClass.sets.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(textColor.opacity(0.8))
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding()
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCorner, style: .continuous))
        .kidTileShadow()
    }
}

#Preview {
    NavigationStack { ClassesListView() }
        .modelContainer(for: [StudyClass.self, FlashCardSet.self, FlashCard.self, QuizAttempt.self], inMemory: true)
}
