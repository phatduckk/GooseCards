import SwiftUI
import UIKit

struct QuizPlayView: View {
    let config: QuizConfig
    var onDone: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var cards: [FlashCard] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var numRight = 0
    @State private var numWrong = 0
    @State private var secondsRemaining = 0
    @State private var isFinished = false
    @State private var startedAt = Date()
    @State private var savedAttempt: QuizAttempt?
    @State private var isTimerRunning = false

    private var currentCard: FlashCard? {
        cards.indices.contains(currentIndex) ? cards[currentIndex] : nil
    }

    var body: some View {
        Group {
            if isFinished, let savedAttempt {
                QuizResultView(attempt: savedAttempt, onDone: onDone)
            } else {
                quizBody
            }
        }
        .onAppear(perform: setup)
        .task(id: isTimerRunning) {
            guard isTimerRunning, config.useTimer else { return }
            while isTimerRunning && secondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard isTimerRunning else { return }
                secondsRemaining -= 1
                if secondsRemaining <= 0 {
                    finish()
                }
            }
        }
    }

    private var quizBody: some View {
        VStack(spacing: 20) {
            header
            Spacer()
            if let card = currentCard {
                FlipCardView(card: card, isFlipped: $isFlipped)
                    .padding(.horizontal)
                    .id(card.id)
            }
            Spacer()
            answerButtons
        }
        .padding()
        .background(Theme.background)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Quit") { onDone() }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("\(currentIndex + 1) / \(cards.count)")
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
        HStack(spacing: 16) {
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
        guard cards.isEmpty else { return }
        let shuffled = config.set.sortedCards.shuffled()
        cards = config.useQuestionLimit ? Array(shuffled.prefix(config.questionLimit)) : shuffled
        startedAt = .now
        if config.useTimer {
            secondsRemaining = config.timerMinutes * 60
            isTimerRunning = true
        }
    }

    private func answer(correct: Bool) {
        if correct {
            numRight += 1
            Haptics.success()
        } else {
            numWrong += 1
            Haptics.warning()
        }
        isFlipped = false
        if currentIndex + 1 < cards.count {
            withAnimation { currentIndex += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        guard !isFinished else { return }
        isTimerRunning = false
        // Any cards never reached while the timer ran out count as wrong.
        let unanswered = cards.count - (numRight + numWrong)
        if unanswered > 0 {
            numWrong += unanswered
        }
        let duration = Int(Date.now.timeIntervalSince(startedAt))
        let attempt = QuizAttempt(
            numRight: numRight,
            numWrong: numWrong,
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
