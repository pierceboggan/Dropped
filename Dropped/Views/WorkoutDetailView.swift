import SwiftUI

/// Displays detailed information about a workout, including overview, intervals, and a power graph.
struct WorkoutDetailView: View {
    /// The workout to display.
    let workout: Workout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                WorkoutOverviewHeader(workout: workout)
                intervalsSection
                powerProfileSection
            }
            .padding([.horizontal, .bottom])
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
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
