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
    /// Remembered across quizzes so a kid who likes picture hints doesn't
    /// have to turn them back on every time.
    @AppStorage("showQuizPictures") private var showPictures = false
    @State private var numRight = 0
    @State private var numWrong = 0
    @State private var everSkippedIDs: Set<UUID> = []
    @State private var secondsRemaining = 0
    @State private var isFinished = false
    @State private var isShowingQuitConfirm = false
    @State private var startedAt = Date()
    @State private var savedAttempt: QuizAttempt?

    private var currentCard: FlashCard? { queue.first }

    private var setHasPictures: Bool {
        config.set.cards.contains { $0.imageData != nil }
    }

    private var accentColor: Color {
        KidPalette.color(forHex: config.set.studyClass?.colorHex ?? KidPalette.all[0].hex)
    }

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
            if let card = currentCard, everSkippedIDs.contains(card.id) {
                Label("You skipped this one — give it another try!", systemImage: "arrow.uturn.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.orange.opacity(0.12)))
            }
            if let card = currentCard {
                FlipCardView(
                    card: card,
                    isFlipped: $isFlipped,
                    accentColor: accentColor,
                    showsPicture: showPictures
                )
                .frame(maxHeight: .infinity)
                .id(card.id)
            }
            answerButtons
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .confirmationDialog(
            "Quit this quiz? Your progress won't be saved.",
            isPresented: $isShowingQuitConfirm,
            titleVisibility: .visible
        ) {
            Button("Quit Quiz", role: .destructive) { onDone() }
            Button("Keep Going", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    isShowingQuitConfirm = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                Text("Card \(min(answeredCount + 1, totalCount)) of \(totalCount)")
                    .font(.system(.title3, design: .rounded).weight(.bold))

                Spacer()

                if config.useTimer {
                    Label(timeString, systemImage: "timer")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill((secondsRemaining <= 10 ? Color.red : accentColor).opacity(0.15)))
                        .foregroundStyle(secondsRemaining <= 10 ? .red : accentColor)
                }

                if setHasPictures {
                    Button {
                        Haptics.tap()
                        withAnimation(.easeInOut(duration: 0.25)) { showPictures.toggle() }
                    } label: {
                        Label("Hints", systemImage: showPictures ? "lightbulb.fill" : "lightbulb")
                            .font(.subheadline.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(showPictures ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.15)))
                            .foregroundStyle(showPictures ? Color.orange : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(showPictures ? "On" : "Off")
                }
            }

            ProgressView(value: Double(answeredCount), total: Double(max(totalCount, 1)))
                .tint(accentColor)
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
    let accentColor: Color
    /// When on, cards with a picture show it above the text on both faces.
    let showsPicture: Bool

    private var picture: UIImage? {
        showsPicture ? card.imageData.flatMap(UIImage.init(data:)) : nil
    }

    var body: some View {
        // Hard-resolving the frame via GeometryReader (rather than relying on
        // ambient .frame(maxWidth: .infinity, maxHeight: .infinity) sizing)
        // pins the tap gesture's hit region to the card's actual rendered
        // bounds. Without this, the gesture's hit-testable area can resolve
        // larger than the visible, clipped card — letting taps on sibling
        // controls (the quit button, Skip) register as a card flip instead.
        GeometryReader { geo in
            let picture = picture
            ZStack {
                faceView(text: card.front, picture: picture, badge: ("Question", "questionmark.circle.fill"))
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

                faceView(text: card.back, picture: picture, badge: ("Answer", "checkmark.seal.fill"))
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.tap()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    isFlipped.toggle()
                }
            }
        }
    }

    @ViewBuilder
    private func faceView(text: String, picture: UIImage?, badge: (label: String, icon: String)) -> some View {
        ZStack {
            if let picture {
                // Blurred, filled copy of the picture as the card background.
                // A hard-resolved GeometryReader keeps scaledToFill()'s
                // aspect-ratio negotiation from resolving to an oversized frame
                // that bleeds past the card's clip bounds.
                GeometryReader { geo in
                    Image(uiImage: picture)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .blur(radius: 30, opaque: true)
                        .clipped()
                }
                Color.black.opacity(0.4)
            } else {
                LinedPaperBackground(tint: accentColor)
            }

            VStack {
                HStack {
                    Label(badge.label, systemImage: badge.icon)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .foregroundStyle(picture == nil ? accentColor : .white)
                    Spacer()
                }

                if let picture {
                    PictureAndText(picture: picture, text: text)
                } else {
                    AdaptiveQuizText(text: text, color: Color.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .stroke(accentColor.opacity(0.4), lineWidth: 2)
        )
        .kidTileShadow()
    }
}

/// Picture on top, text underneath, so the text never covers the picture.
/// The split follows the text: it gets the height it needs to stay readable
/// (estimated at `readableSize`), clamped so short text still gets a decent
/// band and long text still leaves the picture at least a third of the card.
/// AdaptiveQuizText then sizes itself to whatever band it gets, so a rough
/// estimate can't cause overflow. Sizes are hard-resolved from a
/// GeometryReader rather than negotiated, which avoids layout circularity
/// between the picture's aspect ratio and AdaptiveQuizText's ViewThatFits.
private struct PictureAndText: View {
    let picture: UIImage
    let text: String

    private static let readableSize: CGFloat = 34
    private static let spacing: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let available = max(geo.size.height - Self.spacing, 0)
            let needed = AdaptiveQuizText.estimatedHeight(text: text, size: Self.readableSize, width: geo.size.width)
            let textHeight = min(max(needed, available * 0.25), available * 0.66)
            let pictureHeight = available - textHeight
            // Never draw the picture larger than its own pixel size, so small
            // pictures stay crisp instead of being stretched.
            let pixelSize = CGSize(width: picture.size.width * picture.scale, height: picture.size.height * picture.scale)

            VStack(spacing: Self.spacing) {
                Image(uiImage: picture)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: min(geo.size.width, pixelSize.width),
                        maxHeight: min(pictureHeight, pixelSize.height)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
                    .frame(width: geo.size.width, height: pictureHeight)

                AdaptiveQuizText(text: text, color: .white)
                    .frame(width: geo.size.width, height: textHeight)
            }
        }
    }
}

/// Renders `text` at the largest size from a descending ladder that still
/// fits the space SwiftUI's own layout system offers — using ViewThatFits
/// (rather than a separate UIKit measurement pass) guarantees the chosen
/// size is correct, since the same engine that measures also renders.
/// Short strings naturally land on a big single line; long ones fall back
/// to wrapping at a smaller size that still fits.
///
/// Lines starting with "*" (e.g. imported from a source using Markdown-style
/// fake bullets) render as real bulleted list rows — a glyph plus
/// hanging-indent wrapped text — instead of a literal asterisk followed by
/// text that can overflow unpredictably.
private struct AdaptiveQuizText: View {
    let text: String
    let color: Color

    private static let sizes: [CGFloat] = [160, 140, 120, 104, 90, 78, 66, 56, 48, 40, 34, 28, 23, 19]

    private struct Line: Identifiable {
        let id = Int.random(in: Int.min...Int.max)
        let content: String
        let isBullet: Bool
    }

    private var lines: [Line] { Self.lines(in: text) }

    /// Splits on "\n" and classifies each line as a bullet ("^\s*\*.*$") or
    /// plain text, stripping the leading "*" marker from bullet lines.
    private static func lines(in text: String) -> [Line] {
        text.components(separatedBy: "\n").compactMap { raw in
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("*") {
                let content = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                return content.isEmpty ? nil : Line(content: content, isBullet: true)
            } else {
                return trimmed.isEmpty ? nil : Line(content: trimmed, isBullet: false)
            }
        }
    }

    private var hasBullets: Bool { lines.contains { $0.isBullet } }

    /// Rough height `text` needs at `size` when wrapped to `width`, using the
    /// same font and bullet spacing as `content(size:)`. Only used to divide
    /// space between a picture and its text; rendering still goes through
    /// ViewThatFits.
    static func estimatedHeight(text: String, size: CGFloat, width: CGFloat) -> CGFloat {
        let base = UIFont.systemFont(ofSize: size, weight: .heavy)
        let font = base.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: size) } ?? base
        let lines = lines(in: text)
        let hasBullets = lines.contains { $0.isBullet }
        let bulletIndent = ("•" as NSString).size(withAttributes: [.font: font]).width + size * 0.22

        func height(_ string: String, width: CGFloat) -> CGFloat {
            ceil((string as NSString).boundingRect(
                with: CGSize(width: max(width, 1), height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            ).height)
        }

        guard hasBullets else { return height(text, width: width) }
        let lineHeights = lines.map { height($0.content, width: $0.isBullet ? width - bulletIndent : width) }
        return lineHeights.reduce(0, +) + CGFloat(max(lines.count - 1, 0)) * size * 0.28
    }

    var body: some View {
        ViewThatFits(in: [.horizontal, .vertical]) {
            ForEach(Self.sizes, id: \.self) { size in
                content(size: size)
            }
            // Guaranteed-to-render fallback for pathologically long text.
            content(size: Self.sizes.last!, minScale: 0.4)
        }
    }

    @ViewBuilder
    private func content(size: CGFloat, minScale: CGFloat? = nil) -> some View {
        if hasBullets {
            VStack(alignment: .leading, spacing: size * 0.28) {
                ForEach(lines) { line in
                    if line.isBullet {
                        HStack(alignment: .top, spacing: size * 0.22) {
                            Text("•")
                            lineText(line.content, size: size, minScale: minScale)
                        }
                    } else {
                        lineText(line.content, size: size, minScale: minScale)
                    }
                }
            }
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
        } else {
            lineText(text, size: size, minScale: minScale)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private func lineText(_ string: String, size: CGFloat, minScale: CGFloat?) -> some View {
        if let minScale {
            Text(string)
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(minScale)
        } else {
            Text(string)
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
        }
    }
}

/// Loose-leaf-style ruled background with a notebook margin line, used
/// behind text-only card faces so they read as an actual flash card.
private struct LinedPaperBackground: View {
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))

            VStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { _ in
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(tint.opacity(0.14))
                        .frame(height: 1)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 30)

            HStack {
                Rectangle()
                    .fill(Color.pink.opacity(0.35))
                    .frame(width: 2)
                Spacer()
            }
            .padding(.leading, 38)
            .padding(.vertical, 22)
        }
    }
}
