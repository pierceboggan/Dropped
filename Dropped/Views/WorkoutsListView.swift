//  WorkoutsListView.swift
//  Dropped
//
//  SwiftUI view for displaying a list of all workouts.
//
//  - Displays all saved workouts from WorkoutManager.
//  - Allows navigation to workout details.
//  - Supports filtering by workout status.
//  - Designed to be accessible and visually consistent with the app.
//
//  Edge Cases: Handles empty workout list with informative message.
//  Limitations: Currently shows all workouts; future versions may add date-based filtering.

import SwiftUI

/// Main view for displaying a list of all workouts.
/// - Displays workouts from WorkoutManager with navigation to details.
struct WorkoutsListView: View {
    @State private var workouts: [Workout] = []
    @State private var selectedFilter: WorkoutStatusFilter = .all
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(WorkoutStatusFilter.allCases) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .accessibilityLabel("Filter workouts by status")
            
            // Workouts list
            if filteredWorkouts.isEmpty {
                EmptyWorkoutsView(filter: selectedFilter)
            } else {
                List(filteredWorkouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        WorkoutListRow(workout: workout)
                    }
                    .accessibilityLabel("View details for \(workout.title) workout")
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("My Workouts")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadWorkouts()
        }
    }
    
    /// Filter workouts based on selected status filter
    private var filteredWorkouts: [Workout] {
        switch selectedFilter {
        case .all:
            return workouts
        case .scheduled:
            return workouts.filter { $0.status == .scheduled }
        case .completed:
            return workouts.filter { $0.status == .completed }
        case .skipped:
            return workouts.filter { $0.status == .skipped }
        }
    }
    
    /// Load workouts from WorkoutManager
    private func loadWorkouts() {
        workouts = WorkoutManager.shared.loadWorkouts()
    }
}

/// Filter options for workout status
enum WorkoutStatusFilter: String, CaseIterable, Identifiable {
    case all
    case scheduled
    case completed
    case skipped
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .scheduled: return "Scheduled"
        case .completed: return "Completed"
        case .skipped: return "Skipped"
        }
    }
}

/// Row view for displaying a single workout in the list
private struct WorkoutListRow: View {
    let workout: Workout
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: workout.date)
    }
    
    var durationText: String {
        let minutes = Int(workout.totalDuration / 60)
        return "\(minutes) min"
    }
    
    var statusColor: Color {
        switch workout.status {
        case .scheduled: return .blue
        case .completed: return .green
        case .skipped: return .orange
        case .inProgress: return .purple
        }
    }
    
    var statusIcon: String {
        switch workout.status {
        case .scheduled: return "calendar"
        case .completed: return "checkmark.circle.fill"
        case .skipped: return "xmark.circle"
        case .inProgress: return "play.circle"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.title3)
                .frame(width: 30)
                .accessibilityLabel("\(workout.status.rawValue)")
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(durationText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Average power indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(workout.averagePower) W")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("avg")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.title), \(formattedDate), \(durationText), average power \(workout.averagePower) watts, status \(workout.status.rawValue)")
    }
}

/// View displayed when no workouts match the current filter
private struct EmptyWorkoutsView: View {
    let filter: WorkoutStatusFilter
    
    var message: String {
        switch filter {
        case .all:
            return "No workouts yet. Start by generating a training plan!"
        case .scheduled:
            return "No scheduled workouts."
        case .completed:
            return "No completed workouts yet."
        case .skipped:
            return "No skipped workouts."
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.cycling")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}
