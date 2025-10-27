//
//  WorkoutsView.swift
//  Dropped
//
//  Created by Copilot on 2025-10-27.
//
//  This file defines the WorkoutsView, a SwiftUI view for displaying all workouts stored in the WorkoutManager.
//  The view allows users to view, filter, and navigate to workout details.
//
//  The view is designed for accessibility, supports both light and dark mode, and is visually consistent with the rest of the app.

import SwiftUI

/// A SwiftUI view that displays all workouts from the WorkoutManager
///
/// This view provides:
/// - A list of all workouts with key information
/// - Filtering by workout status (scheduled, completed, skipped)
/// - Navigation to workout detail view
/// - Visual consistency with the app's design language
struct WorkoutsView: View {
    @State private var workouts: [Workout] = []
    @State private var selectedFilter: WorkoutStatus? = nil
    @State private var userData: UserData = UserData.defaultData
    
    // Filtered workouts based on selected status
    private var filteredWorkouts: [Workout] {
        if let filter = selectedFilter {
            return workouts.filter { $0.status == filter }
        }
        return workouts
    }
    
    // Group workouts by date for better organization
    private var groupedWorkouts: [Date: [Workout]] {
        Dictionary(grouping: filteredWorkouts) { workout in
            Calendar.current.startOfDay(for: workout.date)
        }
    }
    
    private var sortedDates: [Date] {
        groupedWorkouts.keys.sorted(by: >)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterPill(
                            title: "All",
                            isSelected: selectedFilter == nil,
                            action: { selectedFilter = nil }
                        )
                        
                        FilterPill(
                            title: "Scheduled",
                            isSelected: selectedFilter == .scheduled,
                            action: { selectedFilter = .scheduled }
                        )
                        
                        FilterPill(
                            title: "Completed",
                            isSelected: selectedFilter == .completed,
                            action: { selectedFilter = .completed }
                        )
                        
                        FilterPill(
                            title: "Skipped",
                            isSelected: selectedFilter == .skipped,
                            action: { selectedFilter = .skipped }
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
                // Workouts list
                if filteredWorkouts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.indoor.cycle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No workouts found")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("Generate workouts using the AI Workout Generator")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(sortedDates, id: \.self) { date in
                        VStack(alignment: .leading, spacing: 12) {
                            // Date header
                            Text(formatDateHeader(date))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .accessibilityAddTraits(.isHeader)
                            
                            // Workouts for this date, sorted by time
                            ForEach((groupedWorkouts[date] ?? []).sorted(by: { $0.date < $1.date })) { workout in
                                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                    WorkoutListCard(workout: workout, userData: userData)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(.top)
        }
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadWorkouts()
        }
        .accessibilityIdentifier("workoutsView")
    }
    
    // Load workouts from WorkoutManager
    private func loadWorkouts() {
        workouts = WorkoutManager.shared.loadWorkouts()
        userData = UserDataManager.shared.loadUserData()
    }
    
    // Format date for section headers
    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Components

/// Filter pill button for workout status filtering
private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.accentColor : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .accessibilityLabel("\(title) filter")
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to filter by \(title)")
    }
}

/// Card view for displaying workout information in the list
private struct WorkoutListCard: View {
    let workout: Workout
    let userData: UserData
    
    // Status badge color
    private var statusColor: Color {
        switch workout.status {
        case .scheduled:
            return .blue
        case .completed:
            return .green
        case .skipped:
            return .orange
        case .inProgress:
            return .purple
        }
    }
    
    // Intensity color based on average power
    private var intensityColor: Color {
        let avgPower = workout.averagePower
        let ftpPercent = userData.ftp > 0 ?
            Double(avgPower) / Double(userData.ftp) : 0.75
        
        switch ftpPercent {
        case ..<0.65: return .blue
        case 0.65..<0.75: return .green
        case 0.75..<0.85: return .yellow
        case 0.85..<0.95: return .orange
        case 0.95..<1.05: return .red
        default: return .purple
        }
    }
    
    // Format duration in minutes
    private var durationText: String {
        let minutes = Int(workout.totalDuration / 60)
        return "\(minutes) min"
    }
    
    // Format date
    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: workout.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Status badge
                Text(workout.status.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(statusColor.opacity(0.2))
                    )
                    .foregroundColor(statusColor)
                
                Spacer()
                
                // Time and duration
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(dateText)
                        .font(.caption)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(durationText)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            // Workout title
            HStack(spacing: 10) {
                Circle()
                    .fill(intensityColor)
                    .frame(width: 12, height: 12)
                
                Text(workout.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            // Summary
            Text(workout.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Stats
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                    Text("\(workout.averagePower) W")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.caption)
                    Text("\(workout.intervals.count) intervals")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
        .padding(.horizontal)
        .padding(.bottom, 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.status.rawValue) workout: \(workout.title). \(durationText) at \(dateText). \(workout.summary)")
    }
}
