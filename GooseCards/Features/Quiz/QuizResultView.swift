import SwiftUI

struct QuizResultView: View {
    let attempt: QuizAttempt
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(celebration)
                .font(.system(size: 56))

            ZStack {
                Circle()
                    .stroke(gradeColor.opacity(0.2), lineWidth: 18)
                Circle()
                    .trim(from: 0, to: attempt.percent / 100)
                    .stroke(gradeColor, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text(attempt.letterGrade)
                        .font(Theme.bigNumberFont)
                        .foregroundStyle(gradeColor)
                    Text("\(Int(attempt.percent.rounded()))%")
                        .font(Theme.headlineFont)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, height: 220)
            .padding()

            HStack(spacing: 32) {
                ScoreStat(label: "Right", value: attempt.numRight, color: .green)
                ScoreStat(label: "Wrong", value: attempt.numWrong, color: .red)
                if attempt.numSkipped > 0 {
                    ScoreStat(label: "Skipped", value: attempt.numSkipped, color: .orange)
                }
            }

            Spacer()

            Button(action: onDone) {
                Text("Done")
                    .font(Theme.headlineFont)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .onAppear {
            if attempt.percent >= 90 { Haptics.success() }
        }
    }

    private var gradeColor: Color {
        Color(hex: Grading.color(forGrade: attempt.letterGrade)) ?? .accentColor
    }

    private var celebration: String {
        switch attempt.letterGrade.first {
        case "A": return "🎉"
        case "B": return "👏"
        case "C": return "🙂"
        case "D": return "💪"
        default: return "📚"
        }
    }
}

private struct ScoreStat: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack {
            Text("\(value)")
                .font(.system(.title, design: .rounded)).bold()
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
