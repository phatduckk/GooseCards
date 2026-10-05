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
        VStack(alignment: .leading, spacing: 10) {
            Picker("Class", selection: $selectedClassID) {
                Text("All Classes").tag(UUID?.none)
                ForEach(classes) { studyClass in
                    Text("\(studyClass.emoji) \(studyClass.name)").tag(Optional(studyClass.id))
                }
            }
            .pickerStyle(.menu)

            Picker("Quiz", selection: $selectedSetID) {
                Text("All Quizzes").tag(UUID?.none)
                ForEach(availableSets) { set in
                    Text("\(set.emoji) \(set.name)").tag(Optional(set.id))
                }
            }
            .pickerStyle(.menu)
        }
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
            Text("History").font(Theme.headlineFont)
            ForEach(attempts.reversed()) { attempt in
                HStack {
                    Text(attempt.date, style: .date)
                        .font(.subheadline)
                    Spacer()
                    Text("\(attempt.numRight)/\(attempt.numRight + attempt.numWrong)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(attempt.letterGrade)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: Grading.color(forGrade: attempt.letterGrade)) ?? .primary)
                        .frame(width: 36)
                }
                .padding(.vertical, 4)
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

    private var trend: Trend {
        guard attempts.count >= 2 else {
            return Trend(symbol: "minus.circle", color: .secondary, title: "Keep going!", subtitle: "Take a couple more quizzes to see a trend.")
        }
        let latest = attempts.last!.percent
        let previous = attempts.dropLast()
        let previousAverage = previous.map(\.percent).reduce(0, +) / Double(previous.count)
        let delta = latest - previousAverage

        if delta > 2 {
            return Trend(symbol: "arrow.up.right.circle.fill", color: .green, title: "Trending up!", subtitle: "Latest score is \(Int(delta.rounded()))pts above your average.")
        } else if delta < -2 {
            return Trend(symbol: "arrow.down.right.circle.fill", color: .orange, title: "Needs practice", subtitle: "Latest score is \(Int(abs(delta).rounded()))pts below your average.")
        } else {
            return Trend(symbol: "equal.circle.fill", color: .blue, title: "Holding steady", subtitle: "About the same as your average.")
        }
    }
}
