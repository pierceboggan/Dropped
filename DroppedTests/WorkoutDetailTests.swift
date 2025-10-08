//
//  WorkoutDetailTests.swift
//  DroppedTests
//
//  Unit tests for workout detail functionality
//

import XCTest
@testable import Dropped

final class WorkoutDetailTests: XCTestCase {
    
    func testWorkoutCumulativeDurations() throws {
        // Create a workout with multiple intervals
        let intervals = [
            Interval(watts: 150, duration: 300),  // 5 minutes
            Interval(watts: 200, duration: 180),  // 3 minutes
            Interval(watts: 250, duration: 120)   // 2 minutes
        ]
        
        let workout = Workout(
            title: "Test Workout",
            date: Date(),
            summary: "Test summary",
            intervals: intervals
        )
        
        // Test cumulative durations calculation
        let cumulative = workout.cumulativeDurations
        XCTAssertEqual(cumulative.count, 3, "Should have 3 cumulative duration values")
        XCTAssertEqual(cumulative[0], 300, "First cumulative should be 300 seconds")
        XCTAssertEqual(cumulative[1], 480, "Second cumulative should be 480 seconds (300 + 180)")
        XCTAssertEqual(cumulative[2], 600, "Third cumulative should be 600 seconds (300 + 180 + 120)")
    }
    
    func testWorkoutTotalDuration() throws {
        let intervals = [
            Interval(watts: 150, duration: 300),
            Interval(watts: 200, duration: 180),
            Interval(watts: 250, duration: 120)
        ]
        
        let workout = Workout(
            title: "Test Workout",
            date: Date(),
            summary: "Test summary",
            intervals: intervals
        )
        
        // Test total duration
        XCTAssertEqual(workout.totalDuration, 600, "Total duration should be 600 seconds")
    }
    
    func testWorkoutAveragePower() throws {
        // Create intervals with known power values
        let intervals = [
            Interval(watts: 100, duration: 300),  // 100W for 5 min
            Interval(watts: 200, duration: 300)   // 200W for 5 min
        ]
        
        let workout = Workout(
            title: "Test Workout",
            date: Date(),
            summary: "Test summary",
            intervals: intervals
        )
        
        // Average should be 150W (weighted by duration)
        XCTAssertEqual(workout.averagePower, 150, "Average power should be 150W")
    }
    
    func testWorkoutAveragePowerWeighted() throws {
        // Create intervals with different durations
        let intervals = [
            Interval(watts: 100, duration: 100),  // 100W for 100 seconds
            Interval(watts: 200, duration: 400)   // 200W for 400 seconds
        ]
        
        let workout = Workout(
            title: "Test Workout",
            date: Date(),
            summary: "Test summary",
            intervals: intervals
        )
        
        // Weighted average: (100*100 + 200*400) / 500 = 180
        XCTAssertEqual(workout.averagePower, 180, "Weighted average power should be 180W")
    }
    
    func testWorkoutAveragePowerEmptyIntervals() throws {
        let workout = Workout(
            title: "Empty Workout",
            date: Date(),
            summary: "No intervals",
            intervals: []
        )
        
        // Should handle empty intervals gracefully
        XCTAssertEqual(workout.averagePower, 0, "Average power should be 0 for empty intervals")
        XCTAssertEqual(workout.totalDuration, 0, "Total duration should be 0 for empty intervals")
    }
    
    func testWorkoutStatus() throws {
        // Test default status
        let workout1 = Workout(
            title: "Test Workout",
            date: Date(),
            summary: "Test",
            intervals: []
        )
        XCTAssertEqual(workout1.status, .scheduled, "Default status should be scheduled")
        
        // Test with explicit status
        let workout2 = Workout(
            title: "Completed Workout",
            date: Date(),
            summary: "Test",
            intervals: [],
            status: .completed
        )
        XCTAssertEqual(workout2.status, .completed, "Status should be completed")
        
        // Test skipped status
        let workout3 = Workout(
            title: "Skipped Workout",
            date: Date(),
            summary: "Test",
            intervals: [],
            status: .skipped
        )
        XCTAssertEqual(workout3.status, .skipped, "Status should be skipped")
    }
    
    func testIntervalEquality() throws {
        let interval1 = Interval(watts: 200, duration: 300)
        let interval2 = Interval(watts: 200, duration: 300)
        let interval3 = Interval(watts: 250, duration: 300)
        
        // Different IDs but same values should not be equal
        XCTAssertNotEqual(interval1, interval2, "Intervals with different IDs should not be equal")
        XCTAssertNotEqual(interval1, interval3, "Intervals with different watts should not be equal")
        
        // Same interval should be equal to itself
        XCTAssertEqual(interval1, interval1, "Interval should be equal to itself")
    }
    
    func testWorkoutEquality() throws {
        let intervals = [Interval(watts: 200, duration: 300)]
        let date = Date()
        
        let workout1 = Workout(
            title: "Test",
            date: date,
            summary: "Summary",
            intervals: intervals
        )
        
        let workout2 = Workout(
            title: "Test",
            date: date,
            summary: "Summary",
            intervals: intervals
        )
        
        // Different IDs means not equal
        XCTAssertNotEqual(workout1, workout2, "Workouts with different IDs should not be equal")
        
        // Same workout should be equal to itself
        XCTAssertEqual(workout1, workout1, "Workout should be equal to itself")
    }
}
