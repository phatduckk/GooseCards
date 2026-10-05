import SwiftUI
import SwiftData

/// Landing screen for a Flash Quiz: leads with "Start Quiz" and keeps card
/// management one tap away behind Edit.
struct SetOverviewView: View {
    @Bindable var set: FlashCardSet

    @State private var isConfiguringQuiz = false
    @State private var activeConfig: QuizConfig?

    private var accentHex: String {
        self.set.studyClass?.colorHex ?? KidPalette.all[0].hex
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(set.emoji)
                .font(.system(size: 80))

            VStack(spacing: 6) {
                Text(set.name)
                    .font(Theme.titleFont)
                    .multilineTextAlignment(.center)
                Text("\(set.cards.count) card\(set.cards.count == 1 ? "" : "s")")
                    .font(Theme.bodyFont)
                    .foregroundStyle(.secondary)
            }

            Button {
                isConfiguringQuiz = true
            } label: {
                Label("Start Quiz", systemImage: "bolt.fill")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
            .buttonStyle(.borderedProminent)
            .tint(KidPalette.color(forHex: accentHex))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
            .disabled(set.cards.isEmpty)
            .padding(.horizontal, 40)
            .padding(.top, 8)

            if set.cards.isEmpty {
                Text("Add some cards first, then you can take a quiz.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .navigationTitle(set.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    CardEditorView(set: set)
                } label: {
                    Label("Edit", systemImage: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $isConfiguringQuiz) {
            QuizConfigView(set: set) { config in
                isConfiguringQuiz = false
                activeConfig = config
            }
        }
        .fullScreenCover(item: $activeConfig) { config in
            QuizPlayView(config: config) { activeConfig = nil }
        }
    }
}
