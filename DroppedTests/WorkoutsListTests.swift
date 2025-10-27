//
//  WorkoutsListTests.swift
//  DroppedTests
//
//  Created for testing WorkoutsListView functionality.
//

import XCTest
@testable import Dropped

final class WorkoutsListTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear any existing workouts before each test
        clearAllWorkouts()
    }
    
    override func tearDown() {
        // Clean up after each test
        clearAllWorkouts()
        super.tearDown()
    }
    
    /// Clear all workouts from the WorkoutManager
    private func clearAllWorkouts() {
        let workouts = WorkoutManager.shared.loadWorkouts()
        for workout in workouts {
            WorkoutManager.shared.deleteWorkout(withID: workout.id)
        }
    }
    
    func testWorkoutManagerSaveAndLoad() throws {
        // Create a test workout
        let testWorkout = Workout(
            title: "Test Workout",
            date: Date(),
            summary: "This is a test workout",
            intervals: [
                Interval(watts: 200, duration: 300),
                Interval(watts: 250, duration: 600)
            ],
            status: .scheduled
        )
        
        // Save the workout
        WorkoutManager.shared.saveWorkout(testWorkout)
        
        // Load all workouts
        let loadedWorkouts = WorkoutManager.shared.loadWorkouts()
        
        // Verify the workout was saved
        XCTAssertEqual(loadedWorkouts.count, 1, "Should have exactly 1 workout")
        XCTAssertEqual(loadedWorkouts.first?.title, testWorkout.title, "Workout title should match")
        XCTAssertEqual(loadedWorkouts.first?.summary, testWorkout.summary, "Workout summary should match")
        XCTAssertEqual(loadedWorkouts.first?.intervals.count, 2, "Should have 2 intervals")
        XCTAssertEqual(loadedWorkouts.first?.status, .scheduled, "Status should be scheduled")
    }
    
    func testWorkoutManagerDeleteWorkout() throws {
        // Create and save multiple test workouts
        let workout1 = Workout(
            title: "Workout 1",
            date: Date(),
            summary: "First workout",
            intervals: [Interval(watts: 200, duration: 300)],
            status: .scheduled
        )
        
        let workout2 = Workout(
            title: "Workout 2",
            date: Date(),
            summary: "Second workout",
            intervals: [Interval(watts: 250, duration: 600)],
            status: .completed
        )
        
        WorkoutManager.shared.saveWorkout(workout1)
        WorkoutManager.shared.saveWorkout(workout2)
        
        // Verify both workouts are saved
        var loadedWorkouts = WorkoutManager.shared.loadWorkouts()
        XCTAssertEqual(loadedWorkouts.count, 2, "Should have 2 workouts")
        
        // Delete the first workout
        WorkoutManager.shared.deleteWorkout(withID: workout1.id)
        
        // Verify only one workout remains
        loadedWorkouts = WorkoutManager.shared.loadWorkouts()
        XCTAssertEqual(loadedWorkouts.count, 1, "Should have 1 workout after deletion")
        XCTAssertEqual(loadedWorkouts.first?.title, "Workout 2", "Remaining workout should be Workout 2")
    }
    
    func testWorkoutStatusFilter() throws {
        // Create workouts with different statuses
        let scheduledWorkout = Workout(
            title: "Scheduled Workout",
            date: Date(),
            summary: "To be done",
            intervals: [Interval(watts: 200, duration: 300)],
            status: .scheduled
        )
        
        let completedWorkout = Workout(
            title: "Completed Workout",
            date: Date(),
            summary: "Already done",
            intervals: [Interval(watts: 250, duration: 600)],
            status: .completed
        )
        
        let skippedWorkout = Workout(
            title: "Skipped Workout",
            date: Date(),
            summary: "Skipped this one",
            intervals: [Interval(watts: 180, duration: 400)],
            status: .skipped
        )
        
        // Save all workouts
        WorkoutManager.shared.saveWorkout(scheduledWorkout)
        WorkoutManager.shared.saveWorkout(completedWorkout)
        WorkoutManager.shared.saveWorkout(skippedWorkout)
        
        // Load all workouts
        let allWorkouts = WorkoutManager.shared.loadWorkouts()
        XCTAssertEqual(allWorkouts.count, 3, "Should have 3 workouts total")
        
        // Filter by scheduled status
        let scheduledOnly = allWorkouts.filter { $0.status == .scheduled }
        XCTAssertEqual(scheduledOnly.count, 1, "Should have 1 scheduled workout")
        XCTAssertEqual(scheduledOnly.first?.title, "Scheduled Workout")
        
        // Filter by completed status
        let completedOnly = allWorkouts.filter { $0.status == .completed }
        XCTAssertEqual(completedOnly.count, 1, "Should have 1 completed workout")
        XCTAssertEqual(completedOnly.first?.title, "Completed Workout")
        
        // Filter by skipped status
        let skippedOnly = allWorkouts.filter { $0.status == .skipped }
        XCTAssertEqual(skippedOnly.count, 1, "Should have 1 skipped workout")
        XCTAssertEqual(skippedOnly.first?.title, "Skipped Workout")
    }
    
    func testWorkoutTotalDuration() throws {
        // Create a workout with multiple intervals
        let workout = Workout(
            title: "Duration Test",
            date: Date(),
            summary: "Testing duration calculation",
            intervals: [
                Interval(watts: 200, duration: 300),  // 5 minutes
                Interval(watts: 250, duration: 600),  // 10 minutes
                Interval(watts: 180, duration: 900)   // 15 minutes
            ],
            status: .scheduled
        )
        
        // Total should be 30 minutes (1800 seconds)
        XCTAssertEqual(workout.totalDuration, 1800, "Total duration should be 1800 seconds (30 minutes)")
    }
    
    func testWorkoutAveragePower() throws {
        // Create a workout with intervals of different powers
        let workout = Workout(
            title: "Power Test",
            date: Date(),
            summary: "Testing average power calculation",
            intervals: [
                Interval(watts: 200, duration: 600),  // 10 minutes at 200W
                Interval(watts: 300, duration: 600)   // 10 minutes at 300W
            ],
            status: .scheduled
        )
        
        // Average should be 250W (weighted by duration)
        XCTAssertEqual(workout.averagePower, 250, "Average power should be 250W")
    }
    
    func testWorkoutStatusFilterEnum() throws {
        // Test that all filter cases have proper display names
        XCTAssertEqual(WorkoutStatusFilter.all.displayName, "All")
        XCTAssertEqual(WorkoutStatusFilter.scheduled.displayName, "Scheduled")
        XCTAssertEqual(WorkoutStatusFilter.completed.displayName, "Completed")
        XCTAssertEqual(WorkoutStatusFilter.skipped.displayName, "Skipped")
        
        // Test that all cases are covered
        XCTAssertEqual(WorkoutStatusFilter.allCases.count, 4, "Should have 4 filter options")
    }
}
