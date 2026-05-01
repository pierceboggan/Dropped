import SwiftUI

/// Displays detailed information about a workout, including overview, intervals, and a power graph.
struct WorkoutDetailView: View {
    /// The workout to display.
    let workout: Workout

    /// The persisted completion log for this workout, if one exists.
    @State private var log: WorkoutLog?
    /// Drives presentation of the `WorkoutLogSheet`.
    @State private var isShowingLogSheet = false
    /// Drives presentation of the FTP-test result entry sheet (test workouts only).
    @State private var showingResultEntry = false
    /// Controls presentation of the full-screen interval player.
    @State private var isPlayerPresented: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                WorkoutOverviewHeader(workout: workout)
                if let testTypeRaw = workout.testKind,
                   let testType = FTPTestType(rawValue: testTypeRaw) {
                    logResultButton(testType: testType)
                }
                if let log {
                    WorkoutLogSummaryCard(log: log, plannedDuration: workout.totalDuration)
                }
                startWorkoutButton
                intervalsSection
                powerProfileSection
                completionCTA
            }
            .padding([.horizontal, .bottom])
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refreshLog)
        .sheet(isPresented: $isShowingLogSheet) {
            WorkoutLogSheet(workout: workout, existingLog: log) {
                refreshLog()
            }
        }
        .sheet(isPresented: $showingResultEntry) {
            if let testTypeRaw = workout.testKind,
               let testType = FTPTestType(rawValue: testTypeRaw) {
                FTPTestResultEntryView(testType: testType, sourceWorkout: workout)
            }
        }
        .fullScreenCover(isPresented: $isPlayerPresented) {
            IntervalPlayerView(
                workout: workout,
                ftp: UserDataManager.shared.loadUserData().ftp
            )
        }
    }

    /// CTA toggles between marking complete and editing an existing log.
    private var completionCTA: some View {
        Button {
            isShowingLogSheet = true
        } label: {
            HStack {
                Image(systemName: log == nil ? "checkmark.circle" : "square.and.pencil")
                Text(log == nil ? "Mark Complete" : "Edit Log")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(.white)
            .background((log == nil ? Color.green : Color.blue).gradient)
            .cornerRadius(12)
        }
        .accessibilityLabel(log == nil ? "Mark workout complete" : "Edit completion log")
        .padding(.top, 8)
    }

    private func refreshLog() {
        log = WorkoutManager.shared.log(forWorkoutID: workout.id)
    }

    /// CTA shown on FTP-test workouts to open the result-entry sheet.
    private func logResultButton(testType: FTPTestType) -> some View {
        Button(action: { showingResultEntry = true }) {
            HStack {
                Image(systemName: "square.and.pencil")
                Text("Log \(testType.shortName) result")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(.white)
            .background(Color.accentColor.gradient)
            .cornerRadius(12)
        }
        .accessibilityIdentifier("logFTPTestResultButton")
    }

    /// Primary CTA that launches the guided interval player. Disabled when the
    /// workout has no intervals to play.
    private var startWorkoutButton: some View {
        Button {
            isPlayerPresented = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("Start workout")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(workout.intervals.isEmpty ? Color.gray.opacity(0.4) : Color.accentColor)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .disabled(workout.intervals.isEmpty)
        .accessibilityLabel("Start workout")
        .accessibilityHint(workout.intervals.isEmpty
            ? "This workout has no intervals to play"
            : "Begins a guided interval session")
    }

    /// List of workout intervals, or an empty state if the workout has none.
    private var intervalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intervals")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("Intervals list")

            if workout.intervals.isEmpty {
                Text("No intervals available.")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(workout.intervals.enumerated()), id: \.offset) { index, interval in
                        IntervalRow(interval: interval, index: index + 1)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    /// Power graph section shown only when interval data is available.
    @ViewBuilder
    private var powerProfileSection: some View {
        if !workout.intervals.isEmpty {
            Text("Power Profile")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("Power profile graph")

            WorkoutDetailGraph(intervals: workout.intervals)
                .frame(height: 180)
                .padding(.vertical, 4)
        }
    }
}

/// Header view for displaying the workout's title, date, and summary.
private struct WorkoutOverviewHeader: View {
    let workout: Workout

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: workout.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workout.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("Workout title: \(workout.title)")

            Text(formattedDate)
                .font(.headline)
                .foregroundColor(.secondary)
                .accessibilityLabel("Date: \(formattedDate)")

            Text(workout.summary)
                .font(.body)
                .foregroundColor(.primary)
                .accessibilityLabel("Summary: \(workout.summary)")
        }
        .padding(.top)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }
}

/// Row view for displaying a single interval's details.
private struct IntervalRow: View {
    let interval: Interval
    let index: Int

    var formattedDuration: String {
        let minutes = Int(interval.duration) / 60
        let seconds = Int(interval.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack(spacing: 16) {
            Text("#\(index)")
                .font(.headline)
                .frame(width: 32, alignment: .leading)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Power: \(interval.watts) W")
                    .font(.body)
                    .accessibilityLabel("Power \(interval.watts) watts")
                Text("Duration: \(formattedDuration)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Duration \(formattedDuration)")
            }
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Interval \(index), Power \(interval.watts) watts, Duration \(formattedDuration)")
    }
}

/// Summary card shown at the top of the detail view when a log exists.
private struct WorkoutLogSummaryCard: View {
    let log: WorkoutLog
    let plannedDuration: TimeInterval

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: log.completedAt)
    }

    private var formattedDuration: String {
        let minutes = Int(log.effectiveDuration(planned: plannedDuration) / 60)
        return "\(minutes) min"
    }

    private var accessibilitySummary: String {
        var parts: [String] = ["Completed \(formattedDate)", "RPE \(log.perceivedExertion) of 10"]
        if let avgPower = log.averagePower { parts.append("Average power \(avgPower) watts") }
        if let avgHR = log.averageHeartRate { parts.append("Average heart rate \(avgHR) bpm") }
        parts.append("Duration \(formattedDuration)")
        if let notes = log.notes { parts.append("Notes: \(notes)") }
        return parts.joined(separator: ". ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text("Completed")
                    .font(.headline)
                Spacer()
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                LogMetric(label: "RPE", value: "\(log.perceivedExertion)/10")
                LogMetric(label: "Duration", value: formattedDuration)
                if let avgPower = log.averagePower {
                    LogMetric(label: "Avg Power", value: "\(avgPower) W")
                }
                if let avgHR = log.averageHeartRate {
                    LogMetric(label: "Avg HR", value: "\(avgHR) bpm")
                }
            }

            if let notes = log.notes {
                Text(notes)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.4), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }
}

/// Compact metric chip used inside `WorkoutLogSummaryCard`.
private struct LogMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .accessibilityHidden(true)
    }
}

/// Visualizes workout intervals as a power/time bar graph.
private struct WorkoutDetailGraph: View {
    let intervals: [Interval]

    private var totalDuration: TimeInterval {
        intervals.reduce(0) { $0 + $1.duration }
    }

    private func color(for watts: Int) -> Color {
        switch watts {
        case ..<120: return .blue
        case 120..<180: return .green
        case 180..<240: return .yellow
        case 240..<300: return .orange
        case 300..<400: return .red
        default: return .purple
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let maxWatts = intervals.map { $0.watts }.max() ?? 1

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(intervals.enumerated()), id: \.offset) { index, interval in
                    let barWidth = totalDuration > 0 ? CGFloat(interval.duration / totalDuration) * width : 0
                    let barHeight = CGFloat(interval.watts) / CGFloat(maxWatts) * (height - 24)

                    Rectangle()
                        .fill(color(for: interval.watts))
                        .frame(width: barWidth, height: max(barHeight, 2))
                        .accessibilityLabel("Interval \(index + 1), \(interval.watts) watts, \(Int(interval.duration)) seconds")
                }
            }
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Power profile graph for workout intervals")
    }
}
