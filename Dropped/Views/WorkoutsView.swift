//
//  WorkoutsView.swift
//  Dropped
//
//  This file defines the WorkoutsView, a SwiftUI view for displaying a list of all workouts.
//  The view provides filtering by workout status and sorting options for better workout management.
//  
//  Features:
//  - Display all workouts in a scrollable list
//  - Filter workouts by status (all, scheduled, completed, skipped)
//  - Sort workouts by date or title
//  - Navigate to individual workout details
//  - Accessible and consistent with app design language

import SwiftUI

/// ViewModel for managing workouts list state, filtering, and sorting
class WorkoutsViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var filterStatus: WorkoutStatus?
    @Published var sortOption: SortOption = .dateDescending
    
    enum SortOption: String, CaseIterable, Identifiable {
        case dateAscending = "Date (Oldest First)"
        case dateDescending = "Date (Newest First)"
        case title = "Title (A-Z)"
        
        var id: String { self.rawValue }
    }
    
    init() {
        loadWorkouts()
    }
    
    /// Load all workouts from WorkoutManager
    func loadWorkouts() {
        workouts = WorkoutManager.shared.loadWorkouts()
    }
    
    /// Get filtered and sorted workouts based on current settings
    var filteredAndSortedWorkouts: [Workout] {
        var result = workouts
        
        // Apply status filter if set
        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }
        
        // Apply sorting
        switch sortOption {
        case .dateAscending:
            result.sort { $0.date < $1.date }
        case .dateDescending:
            result.sort { $0.date > $1.date }
        case .title:
            result.sort { $0.title < $1.title }
        }
        
        return result
    }
}

/// A SwiftUI view that displays a list of all workouts with filtering and sorting options
struct WorkoutsView: View {
    @StateObject private var viewModel = WorkoutsViewModel()
    @State private var showingFilterOptions = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter and Sort Controls
                filterSortBar
                
                // Workouts List
                if viewModel.filteredAndSortedWorkouts.isEmpty {
                    emptyStateView
                } else {
                    workoutsList
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        sortMenu
                        Divider()
                        filterMenu
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .accessibilityLabel("Filter and sort options")
                    }
                }
            }
            .onAppear {
                viewModel.loadWorkouts()
            }
        }
        .accessibilityIdentifier("workoutsView")
    }
    
    // MARK: - View Components
    
    /// Filter and sort status bar
    private var filterSortBar: some View {
        HStack {
            if let status = viewModel.filterStatus {
                HStack(spacing: 4) {
                    Text("Showing:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        viewModel.filterStatus = nil
                    }) {
                        HStack(spacing: 4) {
                            Text(status.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("Clear filter: \(status.rawValue)")
                }
            }
            
            Spacer()
            
            Text("\(viewModel.filteredAndSortedWorkouts.count) workout\(viewModel.filteredAndSortedWorkouts.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    /// Sort menu items
    private var sortMenu: some View {
        ForEach(WorkoutsViewModel.SortOption.allCases) { option in
            Button {
                viewModel.sortOption = option
            } label: {
                HStack {
                    Text(option.rawValue)
                    if viewModel.sortOption == option {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
    
    /// Filter menu items
    private var filterMenu: some View {
        Group {
            Button {
                viewModel.filterStatus = nil
            } label: {
                HStack {
                    Text("All Workouts")
                    if viewModel.filterStatus == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button {
                viewModel.filterStatus = .scheduled
            } label: {
                HStack {
                    Text(WorkoutStatus.scheduled.rawValue)
                    if viewModel.filterStatus == .scheduled {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button {
                viewModel.filterStatus = .completed
            } label: {
                HStack {
                    Text(WorkoutStatus.completed.rawValue)
                    if viewModel.filterStatus == .completed {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button {
                viewModel.filterStatus = .skipped
            } label: {
                HStack {
                    Text(WorkoutStatus.skipped.rawValue)
                    if viewModel.filterStatus == .skipped {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
    
    /// List of workouts
    private var workoutsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredAndSortedWorkouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        WorkoutListCard(workout: workout)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    /// Empty state view when no workouts match filter
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.indoor.cycle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Workouts Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            if viewModel.filterStatus != nil {
                Text("Try changing your filter or add new workouts to your plan.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text("Create your first workout using the AI Workout Generator.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No workouts found. Try changing your filter or add new workouts.")
    }
}

/// Card view for displaying a workout in the list
struct WorkoutListCard: View {
    let workout: Workout
    
    /// Format date to display day and full date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter.string(from: workout.date)
    }
    
    /// Calculate intensity level based on average power
    var intensityInfo: (color: Color, text: String) {
        let userData = UserDataManager.shared.loadUserData()
        let avgPower = workout.averagePower
        let ftpPercent = userData.ftp > 0 ? Double(avgPower) / Double(userData.ftp) : 0.75
        
        switch ftpPercent {
        case ..<0.65:
            return (.blue, "Low")
        case 0.65..<0.75:
            return (.green, "Medium-Low")
        case 0.75..<0.85:
            return (.yellow, "Medium")
        case 0.85..<0.95:
            return (.orange, "Medium-High")
        case 0.95..<1.05:
            return (.red, "High")
        default:
            return (.purple, "Very High")
        }
    }
    
    /// Format duration in hours and minutes
    var durationText: String {
        let totalMinutes = Int(workout.totalDuration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Status badge color
    var statusColor: Color {
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and status
            HStack {
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Status badge
                Text(workout.status.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }
            
            // Workout title
            Text(workout.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Workout summary
            Text(workout.summary)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Metrics row
            HStack(spacing: 20) {
                // Duration
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(durationText)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                // Average power
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                    Text("\(workout.averagePower) W")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                // Intensity
                HStack(spacing: 4) {
                    Circle()
                        .fill(intensityInfo.color)
                        .frame(width: 8, height: 8)
                    Text(intensityInfo.text)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.title), \(formattedDate), \(workout.status.rawValue), \(durationText), \(workout.averagePower) watts, \(intensityInfo.text) intensity")
    }
}
