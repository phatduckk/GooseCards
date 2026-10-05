import SwiftUI
import SwiftData
import Charts

struct ProgressDashboardView: View {
    @Query(sort: \StudyClass.createdAt) private var classes: [StudyClass]
    @Query(sort: \FlashCardSet.createdAt) private var allSets: [FlashCardSet]

    @State private var selectedClassID: UUID?
    @State private var selectedSetID: UUID?

    private var availableSets: [FlashCardSet] {
        allSets.filter { selectedClassID == nil || $0.studyClass?.id == selectedClassID }
    }

    private var attempts: [QuizAttempt] {
        if let selectedSetID, let set = availableSets.first(where: { $0.id == selectedSetID }) {
            return set.sortedAttempts
        }
        return availableSets.flatMap(\.attempts).sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                filters

                if attempts.isEmpty {
                    ContentUnavailableView(
                        "No Quiz History Yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Take a quiz to start tracking progress.")
                    )
                    .padding(.top, 40)
                } else {
                    trendCard
                    chart
                    historyList
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .navigationTitle("Progress")
        .onChange(of: selectedClassID) { selectedSetID = nil }
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(title: "All Classes", color: .gray, isSelected: selectedClassID == nil, textColorOverride: .white) {
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
            .padding(.vertical, 2)
        }
    }

    private var quizPicker: some View {
        Picker("Quiz", selection: $selectedSetID) {
            Text("All Quizzes").tag(UUID?.none)
            ForEach(availableSets) { set in
                Text("\(set.emoji) \(set.name)").tag(Optional(set.id))
            }
        }
        .pickerStyle(.menu)
    }

    private var trendCard: some View {
        HStack(spacing: 14) {
            Image(systemName: trend.symbol)
                .font(.largeTitle)
                .foregroundStyle(trend.color)
            VStack(alignment: .leading) {
                Text(trend.title).font(Theme.headlineFont)
                Text(trend.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.controlCorner, style: .continuous))
    }

    private var chart: some View {
        Chart(attempts) { attempt in
            LineMark(
                x: .value("Date", attempt.date),
                y: .value("Score", attempt.percent)
            )
            .interpolationMethod(.catmullRom)
            .symbol(.circle)
            PointMark(
                x: .value("Date", attempt.date),
                y: .value("Score", attempt.percent)
            )
        }
        .chartYScale(domain: 0.0...100.0)
        .frame(height: 220)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.controlCorner, style: .continuous))
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("History").font(Theme.headlineFont)
                Spacer()
                quizPicker
            }
            ForEach(attempts.reversed()) { attempt in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(attempt.set?.name ?? "Quiz")
                            .font(.headline)
                            .lineLimit(1)
                        Text(attempt.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(attempt.numRight)/\(attempt.numRight + attempt.numWrong)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text(attempt.letterGrade)
                        .font(.title2.bold())
                        .foregroundStyle(Color(hex: Grading.color(forGrade: attempt.letterGrade)) ?? .primary)
                        .frame(width: 48)
                }
                .padding(.vertical, 8)
                Divider()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.controlCorner, style: .continuous))
    }

    private struct Trend {
        let symbol: String
        let color: Color
        let title: String
        let subtitle: String
    }

    private enum TrendDirection {
        case up, steady, down
    }

    /// Reacts to both how well the kid is doing overall (their average
    /// letter-grade tier, reusing the app's existing A–F grading) and
    /// whether they're improving (direction) — so a struggling tier gets
    /// encouragement, a strong tier gets applause, and an upward trend
    /// gets called out regardless of tier. Each (tier, direction) pairing
    /// has several message variants, chosen at random, so the card doesn't
    /// say the exact same thing every visit.
    private var trend: Trend {
        guard attempts.count >= 2 else {
            return firstAttemptTrend
        }

        let latest = attempts.last!.percent
        let previous = attempts.dropLast()
        let previousAverage = previous.map(\.percent).reduce(0, +) / Double(previous.count)
        let delta = latest - previousAverage

        let direction: TrendDirection
        if delta > 2 {
            direction = .up
        } else if delta < -2 {
            direction = .down
        } else {
            direction = .steady
        }

        let overallAverage = attempts.map(\.percent).reduce(0, +) / Double(attempts.count)
        let tierGrade = Grading.letterGrade(forPercent: overallAverage)
        let tierColor = Color(hex: Grading.color(forGrade: tierGrade)) ?? .secondary

        let symbol: String
        switch direction {
        case .up: symbol = "arrow.up.right.circle.fill"
        case .steady: symbol = "equal.circle.fill"
        case .down: symbol = "arrow.down.right.circle.fill"
        }

        let (title, subtitle) = Self.messages(forTier: tierGrade.first ?? "C", direction: direction).randomElement()!
        return Trend(symbol: symbol, color: tierColor, title: title, subtitle: subtitle)
    }

    /// Only one attempt recorded yet — no direction to report, but still
    /// react to how that first score went rather than a flat "keep going."
    private var firstAttemptTrend: Trend {
        guard let only = attempts.first else {
            return Trend(symbol: "flag.checkered", color: .secondary, title: "Ready, Set, Go!", subtitle: "Take a quiz to start tracking progress.")
        }
        let color = Color(hex: Grading.color(forGrade: only.letterGrade)) ?? .secondary
        let pool: [(String, String)]
        switch only.letterGrade.first {
        case "A":
            pool = [
                ("🎉 Great Start!", "You aced your very first quiz!"),
                ("🌟 Flying Start!", "What a first score — keep it up!"),
            ]
        case "B":
            pool = [
                ("👍 Nice First Try!", "Solid start — take another to see your trend!"),
                ("😊 Good Beginning!", "Take a few more quizzes to see yourself improve!"),
            ]
        case "C":
            pool = [
                ("🙂 You're On the Board!", "Take a few more quizzes and watch yourself improve!"),
                ("📘 First One Down!", "Practice makes progress — try another!"),
            ]
        default:
            pool = [
                ("🤗 Everyone Starts Somewhere!", "Take a few more quizzes — you'll get the hang of it!"),
                ("💪 You Tried, That's What Counts!", "Keep practicing, you've got this!"),
            ]
        }
        let (title, subtitle) = pool.randomElement()!
        return Trend(symbol: "flag.checkered", color: color, title: title, subtitle: subtitle)
    }

    private static func messages(forTier tier: Character, direction: TrendDirection) -> [(String, String)] {
        switch (tier, direction) {
        case ("A", .up):
            return [
                ("🚀 Blasting Off!", "Amazing scores and still climbing!"),
                ("🌟 Superstar Status!", "Top marks AND improving — wow!"),
                ("🔥 On Fire!", "You're acing it and getting even better!"),
            ]
        case ("A", .steady):
            return [
                ("🏆 Champion Mode!", "Staying strong at the top — incredible work!"),
                ("✨ Excellence, As Usual!", "You're consistently amazing!"),
                ("🎯 Nailing It Every Time!", "Your scores are rock solid up here!"),
            ]
        case ("A", .down):
            return [
                ("👍 Still Awesome!", "A tiny dip, but you're still acing it!"),
                ("💪 Shake It Off!", "Even superstars have an off day — you've got this!"),
            ]
        case ("B", .up):
            return [
                ("📈 Leveling Up!", "Great scores and climbing higher!"),
                ("💫 Getting Even Better!", "Solid grades, and you're on the rise!"),
            ]
        case ("B", .steady):
            return [
                ("👏 Nice and Steady!", "Consistently solid work!"),
                ("✅ Dependable As Always!", "You're holding a strong average!"),
            ]
        case ("B", .down):
            return [
                ("🙂 Still Solid!", "A small dip, but you're doing well overall!"),
                ("🌤️ Minor Bump in the Road", "Still a good average — keep it up!"),
            ]
        case ("C", .up):
            return [
                ("📈 Climbing Up!", "You're improving — keep that momentum!"),
                ("🌱 Growing Stronger!", "Nice upward trend, keep pushing!"),
            ]
        case ("C", .steady):
            return [
                ("🙂 Making Progress", "You're doing okay — a little more practice will help!"),
                ("📚 Keep At It!", "Steady scores — try a few more rounds to level up!"),
            ]
        case ("C", .down):
            return [
                ("💡 Time for a Quick Review", "A little practice goes a long way!"),
                ("🔄 Let's Bounce Back", "Everyone has a tough stretch — you can turn this around!"),
            ]
        case ("D", .up):
            return [
                ("🌈 Things Are Looking Up!", "You're improving — keep going, you've got this!"),
                ("💪 Fighting Back!", "Nice climb! A little more practice and you'll be golden!"),
            ]
        case ("D", .steady):
            return [
                ("📖 Let's Practice Together", "These are tricky — a bit more review should help a lot!"),
                ("🧭 Finding Your Footing", "Keep at it — practice makes progress!"),
            ]
        case ("D", .down):
            return [
                ("🤗 Don't Give Up!", "Tough scores lately — but every try makes you stronger!"),
                ("🌱 Every Expert Was Once a Beginner", "Keep practicing, you'll turn this around!"),
            ]
        case ("F", .up):
            return [
                ("🌈 Great Improvement!", "Still tough, but you're moving the right direction!"),
                ("💪 Keep Climbing!", "Hard quizzes, but you're starting to turn it around!"),
            ]
        default: // F, steady or down
            return [
                ("🤗 You've Got This!", "These are tough ones — let's practice together and it'll click!"),
                ("🌟 Don't Give Up!", "Mistakes help your brain grow — try again!"),
                ("📚 Time to Team Up", "Maybe review these with a grown-up — you'll get there!"),
            ]
        }
    }
}
