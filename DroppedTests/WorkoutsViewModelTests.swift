//
//  WorkoutsViewModelTests.swift
//  DroppedTests
//
//  Unit tests for WorkoutsViewModel functionality including filtering and sorting.
//

import XCTest
@testable import Dropped

final class WorkoutsViewModelTests: XCTestCase {
    
    var viewModel: WorkoutsViewModel!
    var testWorkouts: [Workout]!
    
    override func setUpWithError() throws {
        viewModel = WorkoutsViewModel()
        
        // Create test workouts with different statuses and dates
        let calendar = Calendar.current
        let today = Date()
        
        testWorkouts = [
            Workout(
                title: "Morning Ride",
                date: calendar.date(byAdding: .day, value: -2, to: today)!,
                summary: "Easy recovery ride",
                intervals: [Interval(watts: 150, duration: 1800)],
                status: .completed
            ),
            Workout(
                title: "Interval Training",
                date: calendar.date(byAdding: .day, value: -1, to: today)!,
                summary: "High intensity intervals",
                intervals: [Interval(watts: 250, duration: 3600)],
                status: .completed
            ),
            Workout(
                title: "Tempo Ride",
                date: today,
                summary: "Sustained effort",
                intervals: [Interval(watts: 200, duration: 2700)],
                status: .scheduled
            ),
            Workout(
                title: "Recovery Spin",
                date: calendar.date(byAdding: .day, value: 1, to: today)!,
                summary: "Light spinning",
                intervals: [Interval(watts: 120, duration: 1200)],
                status: .scheduled
            ),
            Workout(
                title: "Weekend Long Ride",
                date: calendar.date(byAdding: .day, value: 2, to: today)!,
                summary: "Endurance building",
                intervals: [Interval(watts: 180, duration: 5400)],
                status: .skipped
            )
        ]
        
        // Save test workouts to WorkoutManager
        for workout in testWorkouts {
            WorkoutManager.shared.saveWorkout(workout)
        }
        
        // Reload workouts in view model
        viewModel.loadWorkouts()
    }
    
    override func tearDownWithError() throws {
        // Clean up test workouts
        for workout in testWorkouts {
            WorkoutManager.shared.deleteWorkout(withID: workout.id)
        }
        viewModel = nil
        testWorkouts = nil
    }
    
    func testLoadWorkouts() throws {
        // Verify that workouts are loaded
        XCTAssertEqual(viewModel.workouts.count, 5, "Should load all test workouts")
    }
    
    func testFilterByStatusCompleted() throws {
        // Set filter to completed
        viewModel.filterStatus = .completed
        
        // Get filtered workouts
        let filtered = viewModel.filteredAndSortedWorkouts
        
        // Verify only completed workouts are shown
        XCTAssertEqual(filtered.count, 2, "Should have 2 completed workouts")
        XCTAssertTrue(filtered.allSatisfy { $0.status == .completed }, "All filtered workouts should be completed")
    }
    
    func testFilterByStatusScheduled() throws {
        // Set filter to scheduled
        viewModel.filterStatus = .scheduled
        
        // Get filtered workouts
        let filtered = viewModel.filteredAndSortedWorkouts
        
        // Verify only scheduled workouts are shown
        XCTAssertEqual(filtered.count, 2, "Should have 2 scheduled workouts")
        XCTAssertTrue(filtered.allSatisfy { $0.status == .scheduled }, "All filtered workouts should be scheduled")
    }
    
    func testFilterByStatusSkipped() throws {
        // Set filter to skipped
        viewModel.filterStatus = .skipped
        
        // Get filtered workouts
        let filtered = viewModel.filteredAndSortedWorkouts
        
        // Verify only skipped workouts are shown
        XCTAssertEqual(filtered.count, 1, "Should have 1 skipped workout")
        XCTAssertTrue(filtered.allSatisfy { $0.status == .skipped }, "All filtered workouts should be skipped")
    }
    
    func testNoFilter() throws {
        // Clear filter
        viewModel.filterStatus = nil
        
        // Get filtered workouts
        let filtered = viewModel.filteredAndSortedWorkouts
        
        // Verify all workouts are shown
        XCTAssertEqual(filtered.count, 5, "Should show all workouts when no filter is applied")
    }
    
    func testSortByDateDescending() throws {
        // Set sort to date descending (newest first)
        viewModel.sortOption = .dateDescending
        viewModel.filterStatus = nil
        
        // Get sorted workouts
        let sorted = viewModel.filteredAndSortedWorkouts
        
        // Verify workouts are sorted by date descending
        XCTAssertEqual(sorted.count, 5, "Should have all workouts")
        
        // Check that dates are in descending order
        for i in 0..<(sorted.count - 1) {
            XCTAssertGreaterThanOrEqual(sorted[i].date, sorted[i + 1].date, "Workouts should be sorted by date descending")
        }
    }
    
    func testSortByDateAscending() throws {
        // Set sort to date ascending (oldest first)
        viewModel.sortOption = .dateAscending
        viewModel.filterStatus = nil
        
        // Get sorted workouts
        let sorted = viewModel.filteredAndSortedWorkouts
        
        // Verify workouts are sorted by date ascending
        XCTAssertEqual(sorted.count, 5, "Should have all workouts")
        
        // Check that dates are in ascending order
        for i in 0..<(sorted.count - 1) {
            XCTAssertLessThanOrEqual(sorted[i].date, sorted[i + 1].date, "Workouts should be sorted by date ascending")
        }
    }
    
    func testSortByTitle() throws {
        // Set sort to title
        viewModel.sortOption = .title
        viewModel.filterStatus = nil
        
        // Get sorted workouts
        let sorted = viewModel.filteredAndSortedWorkouts
        
        // Verify workouts are sorted alphabetically by title
        XCTAssertEqual(sorted.count, 5, "Should have all workouts")
        
        // Check that titles are in alphabetical order
        for i in 0..<(sorted.count - 1) {
            XCTAssertLessThanOrEqual(sorted[i].title, sorted[i + 1].title, "Workouts should be sorted alphabetically by title")
        }
    }
    
    func testFilterAndSort() throws {
        // Test combination of filter and sort
        viewModel.filterStatus = .completed
        viewModel.sortOption = .dateDescending
        
        // Get filtered and sorted workouts
        let result = viewModel.filteredAndSortedWorkouts
        
        // Verify correct number of workouts
        XCTAssertEqual(result.count, 2, "Should have 2 completed workouts")
        
        // Verify all are completed
        XCTAssertTrue(result.allSatisfy { $0.status == .completed }, "All should be completed")
        
        // Verify they are sorted by date descending
        if result.count == 2 {
            XCTAssertGreaterThanOrEqual(result[0].date, result[1].date, "Completed workouts should be sorted by date descending")
        }
    }
}
