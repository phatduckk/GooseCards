import SwiftUI
import SwiftData
import UIKit

struct QuizPlayView: View {
    let config: QuizConfig
    var onDone: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var queue: [FlashCard] = []
    @State private var totalCount = 0
    @State private var answeredCount = 0
    @State private var isFlipped = false
    @State private var numRight = 0
    @State private var numWrong = 0
    @State private var everSkippedIDs: Set<UUID> = []
    @State private var secondsRemaining = 0
    @State private var isFinished = false
    @State private var startedAt = Date()
    @State private var savedAttempt: QuizAttempt?

    private var currentCard: FlashCard? { queue.first }

    var body: some View {
        Group {
            if isFinished, let savedAttempt {
                QuizResultView(attempt: savedAttempt, onDone: onDone)
            } else {
                quizBody
            }
        }
        .task {
            setup()
            guard config.useTimer else { return }
            while secondsRemaining > 0 && !isFinished {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled || isFinished { return }
                secondsRemaining -= 1
                if secondsRemaining <= 0 {
                    finish()
                }
            }
        }
    }

    private var quizBody: some View {
        VStack(spacing: 16) {
            header
            Spacer()
            if let card = currentCard {
                if everSkippedIDs.contains(card.id) {
                    Label("You skipped this one — give it another try!", systemImage: "arrow.uturn.forward")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                FlipCardView(card: card, isFlipped: $isFlipped)
                    .padding(.horizontal)
                    .id(card.id)
            }
            Spacer()
            answerButtons
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Quit") { onDone() }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("\(min(answeredCount + 1, totalCount)) / \(totalCount)")
                .font(Theme.headlineFont)
            Spacer()
            if config.useTimer {
                Label(timeString, systemImage: "timer")
                    .font(Theme.headlineFont)
                    .foregroundStyle(secondsRemaining <= 10 ? .red : .primary)
            }
        }
    }

    private var timeString: String {
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    private var answerButtons: some View {
        HStack(spacing: 12) {
            Button {
                skip()
            } label: {
                Label("Skip", systemImage: "arrow.uturn.forward")
                    .font(Theme.headlineFont)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(Color.gray.opacity(0.15))
            .foregroundStyle(.secondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlCorner, style: .continuous))
            .disabled(currentCard == nil || queue.count <= 1)

            Button {
                answer(correct: false)
            } label: {
                Label("Not Yet", systemImage: "xmark")
                    .font(Theme.headlineFont)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(Color.red.opacity(0.15))
            .foregroundStyle(.red)
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlCorner, style: .continuous))

            Button {
                answer(correct: true)
            } label: {
                Label("Got It!", systemImage: "checkmark")
                    .font(Theme.headlineFont)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(Color.green.opacity(0.15))
            .foregroundStyle(.green)
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlCorner, style: .continuous))
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(currentCard == nil)
    }

    private func setup() {
        guard queue.isEmpty, totalCount == 0 else { return }
        let shuffled = config.set.sortedCards.shuffled()
        queue = config.useQuestionLimit ? Array(shuffled.prefix(config.questionLimit)) : shuffled
        totalCount = queue.count
        startedAt = .now
        if config.useTimer {
            secondsRemaining = config.timerMinutes * 60
        }
    }

    private func skip() {
        guard let card = queue.first, queue.count > 1 else { return }
        everSkippedIDs.insert(card.id)
        queue.removeFirst()
        queue.append(card)
        isFlipped = false
        Haptics.tap()
    }

    private func answer(correct: Bool) {
        guard queue.first != nil else { return }
        if correct {
            numRight += 1
            Haptics.success()
        } else {
            numWrong += 1
            Haptics.warning()
        }
        queue.removeFirst()
        answeredCount += 1
        isFlipped = false
        if queue.isEmpty {
            finish()
        }
    }

    private func finish() {
        guard !isFinished else { return }
        // Any cards never reached (e.g. the timer ran out) count as wrong.
        let unanswered = queue.count
        if unanswered > 0 {
            numWrong += unanswered
        }
        let duration = Int(Date.now.timeIntervalSince(startedAt))
        let attempt = QuizAttempt(
            numRight: numRight,
            numWrong: numWrong,
            numSkipped: everSkippedIDs.count,
            durationSeconds: config.useTimer ? duration : nil,
            numQuestionsConfigured: config.useQuestionLimit ? config.questionLimit : nil,
            set: config.set
        )
        modelContext.insert(attempt)
        savedAttempt = attempt
        isFinished = true
    }
}

struct FlipCardView: View {
    let card: FlashCard
    @Binding var isFlipped: Bool

    var body: some View {
        ZStack {
            faceView(text: card.front, imageData: nil)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            faceView(text: card.back, imageData: card.imageData)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .onTapGesture {
            Haptics.tap()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isFlipped.toggle()
            }
        }
    }

    @ViewBuilder
    private func faceView(text: String, imageData: Data?) -> some View {
        ZStack {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipped()
                Color.black.opacity(0.35)
            } else {
                Color.accentColor.opacity(0.15)
            }
            Text(text)
                .font(.system(.title, design: .rounded)).bold()
                .multilineTextAlignment(.center)
                .foregroundStyle(imageData == nil ? Color.primary : Color.white)
                .padding(24)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .kidTileShadow()
    }
}
