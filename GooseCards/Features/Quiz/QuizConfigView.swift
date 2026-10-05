import SwiftUI

struct QuizConfig {
    let set: FlashCardSet
    let useTimer: Bool
    let timerMinutes: Int
    let useQuestionLimit: Bool
    let questionLimit: Int
}

struct QuizConfigView: View {
    let set: FlashCardSet
    let onStart: (QuizConfig) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var useTimer = false
    @State private var timerMinutes = 3
    @State private var useQuestionLimit = false
    @State private var questionLimit = 10

    private var cardCount: Int { max(set.cards.count, 1) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(set.emoji).font(.system(size: 36))
                        VStack(alignment: .leading) {
                            Text(set.name).font(Theme.headlineFont)
                            Text("\(set.cards.count) card\(set.cards.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Timer") {
                    Toggle("Use a timer", isOn: $useTimer.animation())
                    if useTimer {
                        Stepper("Time limit: \(timerMinutes) min", value: $timerMinutes, in: 1...30)
                    }
                }

                Section("Number of Questions") {
                    Toggle("Limit questions", isOn: $useQuestionLimit.animation())
                    if useQuestionLimit {
                        Stepper("Questions: \(questionLimit)", value: $questionLimit, in: 1...cardCount)
                    }
                }
            }
            .navigationTitle("Quiz Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    let config = QuizConfig(
                        set: set,
                        useTimer: useTimer,
                        timerMinutes: timerMinutes,
                        useQuestionLimit: useQuestionLimit,
                        questionLimit: min(questionLimit, cardCount)
                    )
                    onStart(config)
                } label: {
                    Label("Start Quiz", systemImage: "bolt.fill")
                        .font(Theme.headlineFont)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
                .disabled(set.cards.isEmpty)
            }
        }
    }
}
