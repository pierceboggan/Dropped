//
//  CalendarView.swift
//  Dropped
//
//  Created by Copilot on 2025-05-20.
//
//  This file defines the CalendarView, a SwiftUI view for displaying a monthly calendar
//  of workouts. Users can see all workouts for the current month and tap on them to
//  navigate to the workout detail view.
//
//  The view is designed for accessibility, supports both light and dark mode, and is
//  visually consistent with the rest of the app.
//
//  Edge Cases: Handles months with different numbers of days, displays workouts on
//  correct dates, handles multiple workouts on the same day.
//  Limitations: Currently shows one month at a time; future versions could add
//  month navigation.

import SwiftUI

/// A SwiftUI view that displays a calendar grid showing all workouts for the current month.
/// Users can tap on workouts to navigate to the detail view.
struct CalendarView: View {
    @State private var currentDate = Date()
    @State private var workouts: [Workout] = []
    
    // Calendar instance for date calculations
    private let calendar = Calendar.current
    
    // Get the first day of the current month
    private var startOfMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) ?? currentDate
    }
    
    // Get the last day of the current month
    private var endOfMonth: Date {
        calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? currentDate
    }
    
    // Get number of days in the month
    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30
    }
    
    // Get the weekday of the first day (1 = Sunday, 7 = Saturday)
    private var firstWeekday: Int {
        calendar.component(.weekday, from: startOfMonth)
    }
    
    // Format current month and year for display
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }
    
    // Days of the week headers
    private let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Month and year header
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel("Calendar for \(monthYearString)")
                
                // Weekday headers
                HStack(spacing: 0) {
                    ForEach(weekdaySymbols, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal)
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    // Empty cells for days before the month starts
                    ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                        CalendarDayCell(day: nil, workouts: [])
                    }
                    
                    // Cells for each day in the month
                    ForEach(1...daysInMonth, id: \.self) { day in
                        let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) ?? currentDate
                        let dayWorkouts = workoutsForDate(date)
                        
                        if dayWorkouts.isEmpty {
                            CalendarDayCell(day: day, workouts: [])
                        } else {
                            NavigationLink(destination: WorkoutDayDetailView(date: date, workouts: dayWorkouts)) {
                                CalendarDayCell(day: day, workouts: dayWorkouts)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadWorkouts()
        }
    }
    
    /// Load workouts for the current month
    private func loadWorkouts() {
        workouts = WorkoutManager.shared.getWorkouts(from: startOfMonth, to: endOfMonth)
    }
    
    /// Get workouts for a specific date
    /// - Parameter date: The date to get workouts for
    /// - Returns: Array of workouts on that date
    private func workoutsForDate(_ date: Date) -> [Workout] {
        workouts.filter { workout in
            calendar.isDate(workout.date, inSameDayAs: date)
        }
    }
}

// MARK: - Components (add at bottom of file as needed)

/// Cell view for a single day in the calendar grid
/// - Parameters:
///   - day: The day number (1-31), or nil for empty cells
///   - workouts: Array of workouts on this day
private struct CalendarDayCell: View {
    let day: Int?
    let workouts: [Workout]
    
    var hasWorkouts: Bool {
        !workouts.isEmpty
    }
    
    var intensityColor: Color {
        guard let firstWorkout = workouts.first else { return .clear }
        let avgPower = firstWorkout.averagePower
        let ftp = UserDataManager.shared.loadUserData().ftp
        let ftpPercent = ftp > 0 ? Double(avgPower) / Double(ftp) : 0.75
        
        switch ftpPercent {
        case ..<0.65: return .blue
        case 0.65..<0.75: return .green
        case 0.75..<0.85: return .yellow
        case 0.85..<0.95: return .orange
        case 0.95..<1.05: return .red
        default: return .purple
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            if let day = day {
                Text("\(day)")
                    .font(.system(size: 16))
                    .fontWeight(hasWorkouts ? .bold : .regular)
                    .foregroundColor(hasWorkouts ? .primary : .secondary)
                
                if hasWorkouts {
                    Circle()
                        .fill(intensityColor)
                        .frame(width: 6, height: 6)
                } else {
                    Spacer()
                        .frame(height: 6)
                }
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hasWorkouts ? Color(.systemGray6) : Color.clear)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(day != nil ? "Day \(day!)\(hasWorkouts ? ", \(workouts.count) workout\(workouts.count > 1 ? "s" : "")" : "")" : "")
    }
}

/// Detail view for a specific day showing all workouts on that date
/// - Parameters:
///   - date: The date to display workouts for
///   - workouts: Array of workouts on this date
private struct WorkoutDayDetailView: View {
    let date: Date
    let workouts: [Workout]
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(formattedDate)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)
                    .accessibilityAddTraits(.isHeader)
                
                ForEach(workouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        WorkoutCard(workout: workout)
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
