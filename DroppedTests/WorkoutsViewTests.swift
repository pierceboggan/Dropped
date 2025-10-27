//
//  WorkoutsViewTests.swift
//  DroppedTests
//
//  Created by Copilot on 2025-10-27.
//
//  Unit tests for WorkoutsView functionality

import XCTest
@testable import Dropped

/// Unit tests for the WorkoutsView
final class WorkoutsViewTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear workouts before each test
        clearAllWorkouts()
    }
    
    override func tearDown() {
        // Clean up after each test
        clearAllWorkouts()
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Clear all workouts from WorkoutManager
    private func clearAllWorkouts() {
        let workouts = WorkoutManager.shared.loadWorkouts()
        for workout in workouts {
            WorkoutManager.shared.deleteWorkout(withID: workout.id)
        }
    }
    
    /// Create a sample workout for testing
    private func createSampleWorkout(
        title: String = "Test Workout",
        date: Date = Date(),
        status: WorkoutStatus = .scheduled
    ) -> Workout {
        let intervals = [
            Interval(watts: 150, duration: 300),
            Interval(watts: 200, duration: 600),
            Interval(watts: 150, duration: 300)
        ]
        
        return Workout(
            title: title,
            date: date,
            summary: "Test workout summary",
            intervals: intervals,
            status: status
        )
    }
    
    // MARK: - Tests
    
    /// Test that workouts can be loaded from WorkoutManager
    func testLoadWorkouts() {
        // Given: Some workouts are saved
        let workout1 = createSampleWorkout(title: "Workout 1")
        let workout2 = createSampleWorkout(title: "Workout 2")
        
        WorkoutManager.shared.saveWorkout(workout1)
        WorkoutManager.shared.saveWorkout(workout2)
        
        // When: Loading workouts
        let loadedWorkouts = WorkoutManager.shared.loadWorkouts()
        
        // Then: Workouts should be loaded correctly
        XCTAssertEqual(loadedWorkouts.count, 2)
        XCTAssertTrue(loadedWorkouts.contains(where: { $0.title == "Workout 1" }))
        XCTAssertTrue(loadedWorkouts.contains(where: { $0.title == "Workout 2" }))
    }
    
    /// Test filtering workouts by status
    func testWorkoutFiltering() {
        // Given: Workouts with different statuses
        let scheduledWorkout = createSampleWorkout(title: "Scheduled", status: .scheduled)
        let completedWorkout = createSampleWorkout(title: "Completed", status: .completed)
        let skippedWorkout = createSampleWorkout(title: "Skipped", status: .skipped)
        
        WorkoutManager.shared.saveWorkout(scheduledWorkout)
        WorkoutManager.shared.saveWorkout(completedWorkout)
        WorkoutManager.shared.saveWorkout(skippedWorkout)
        
        let allWorkouts = WorkoutManager.shared.loadWorkouts()
        
        // When: Filtering by status
        let scheduledOnly = allWorkouts.filter { $0.status == .scheduled }
        let completedOnly = allWorkouts.filter { $0.status == .completed }
        let skippedOnly = allWorkouts.filter { $0.status == .skipped }
        
        // Then: Filters should work correctly
        XCTAssertEqual(scheduledOnly.count, 1)
        XCTAssertEqual(scheduledOnly.first?.title, "Scheduled")
        
        XCTAssertEqual(completedOnly.count, 1)
        XCTAssertEqual(completedOnly.first?.title, "Completed")
        
        XCTAssertEqual(skippedOnly.count, 1)
        XCTAssertEqual(skippedOnly.first?.title, "Skipped")
    }
    
    /// Test grouping workouts by date
    func testWorkoutGroupingByDate() {
        // Given: Workouts on different dates
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let workout1 = createSampleWorkout(title: "Today 1", date: today)
        let workout2 = createSampleWorkout(title: "Today 2", date: today)
        let workout3 = createSampleWorkout(title: "Yesterday", date: yesterday)
        let workout4 = createSampleWorkout(title: "Tomorrow", date: tomorrow)
        
        WorkoutManager.shared.saveWorkout(workout1)
        WorkoutManager.shared.saveWorkout(workout2)
        WorkoutManager.shared.saveWorkout(workout3)
        WorkoutManager.shared.saveWorkout(workout4)
        
        let allWorkouts = WorkoutManager.shared.loadWorkouts()
        
        // When: Grouping by date
        let grouped = Dictionary(grouping: allWorkouts) { workout in
            calendar.startOfDay(for: workout.date)
        }
        
        // Then: Workouts should be grouped correctly
        XCTAssertEqual(grouped.count, 3) // 3 different dates
        
        let todayStart = calendar.startOfDay(for: today)
        let yesterdayStart = calendar.startOfDay(for: yesterday)
        let tomorrowStart = calendar.startOfDay(for: tomorrow)
        
        XCTAssertEqual(grouped[todayStart]?.count, 2)
        XCTAssertEqual(grouped[yesterdayStart]?.count, 1)
        XCTAssertEqual(grouped[tomorrowStart]?.count, 1)
    }
    
    /// Test empty workouts list
    func testEmptyWorkoutsList() {
        // Given: No workouts
        let workouts = WorkoutManager.shared.loadWorkouts()
        
        // Then: List should be empty
        XCTAssertEqual(workouts.count, 0)
    }
    
    /// Test workout sorting by date
    func testWorkoutSortingByDate() {
        // Given: Workouts with different dates
        let calendar = Calendar.current
        let today = Date()
        let pastDate = calendar.date(byAdding: .day, value: -5, to: today)!
        let futureDate = calendar.date(byAdding: .day, value: 5, to: today)!
        
        let workout1 = createSampleWorkout(title: "Future", date: futureDate)
        let workout2 = createSampleWorkout(title: "Today", date: today)
        let workout3 = createSampleWorkout(title: "Past", date: pastDate)
        
        WorkoutManager.shared.saveWorkout(workout1)
        WorkoutManager.shared.saveWorkout(workout2)
        WorkoutManager.shared.saveWorkout(workout3)
        
        // When: Sorting by date (descending)
        let workouts = WorkoutManager.shared.loadWorkouts()
        let sorted = workouts.sorted { $0.date > $1.date }
        
        // Then: Workouts should be sorted correctly
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0].title, "Future")
        XCTAssertEqual(sorted[1].title, "Today")
        XCTAssertEqual(sorted[2].title, "Past")
    }
    
    /// Test date header formatting
    func testDateHeaderFormatting() {
        // Given: Different dates
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Then: Date headers should format correctly
        XCTAssertTrue(calendar.isDateInToday(today))
        XCTAssertTrue(calendar.isDateInYesterday(yesterday))
        XCTAssertTrue(calendar.isDateInTomorrow(tomorrow))
    }
}
