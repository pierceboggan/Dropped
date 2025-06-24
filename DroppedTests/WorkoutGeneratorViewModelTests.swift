//
//  WorkoutGeneratorViewModelTests.swift
//  DroppedTests
//
//  Created on 5/6/25.
//

import XCTest
@testable import Dropped

final class WorkoutGeneratorViewModelTests: XCTestCase {
    
    var viewModel: WorkoutGeneratorViewModel!
    var testUserData: UserData!
    
    override func setUpWithError() throws {
        testUserData = UserData(
            weight: 70.0,
            weightUnit: WeightUnit.kilograms.rawValue,
            ftp: 250,
            trainingHoursPerWeek: 5,
            trainingGoal: TrainingGoal.getFaster.rawValue
        )
        
        // Use a real AIWorkoutGenerator with a mock API key for testing
        let mockAIGenerator = AIWorkoutGenerator(apiKey: "test-key")
        viewModel = WorkoutGeneratorViewModel(
            aiGenerator: mockAIGenerator,
            userData: testUserData
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        testUserData = nil
    }
    
    func testAcceptWorkoutCreatesValidWorkout() throws {
        // Given: A generated workout JSON string (we'll simulate this)
        viewModel.generatedWorkout = "mock workout json"
        
        // Clear any existing workouts for a clean test
        let initialWorkoutCount = WorkoutManager.shared.loadWorkouts().count
        
        // When: Accept workout is called
        viewModel.acceptWorkout()
        
        // Then: A workout should be saved to WorkoutManager
        let savedWorkouts = WorkoutManager.shared.loadWorkouts()
        XCTAssertEqual(savedWorkouts.count, initialWorkoutCount + 1, "A new workout should be saved when acceptWorkout is called")
        
        let lastWorkout = savedWorkouts.last!
        XCTAssertEqual(lastWorkout.title, "Endurance Workout", "Workout title should match the selected type")
        XCTAssertFalse(lastWorkout.intervals.isEmpty, "Workout should have intervals")
        XCTAssertTrue(lastWorkout.summary.contains("250"), "Summary should mention user's FTP")
        XCTAssertEqual(lastWorkout.intervals.count, 3, "Endurance workout should have 3 intervals")
    }
    
    func testAcceptWorkoutWithNilJSONDoesNotCreateWorkout() throws {
        // Given: No generated workout
        viewModel.generatedWorkout = nil
        let initialWorkoutCount = WorkoutManager.shared.loadWorkouts().count
        
        // When: Accept workout is called
        viewModel.acceptWorkout()
        
        // Then: No new workout should be created
        let savedWorkouts = WorkoutManager.shared.loadWorkouts()
        XCTAssertEqual(savedWorkouts.count, initialWorkoutCount, "No workout should be created when generatedWorkout is nil")
    }
    
    func testParseWorkoutCreatesCorrectWorkout() throws {
        // Given: A workout type is selected
        viewModel.selectedWorkoutType = .threshold
        
        // When: parseWorkout is called with any JSON (since we're using demo data)
        let workout = viewModel.parseWorkout(from: "any json")
        
        // Then: A valid workout should be created
        XCTAssertNotNil(workout, "parseWorkout should return a valid workout")
        XCTAssertEqual(workout?.title, "Threshold Workout", "Title should match selected workout type")
        XCTAssertFalse(workout?.intervals.isEmpty ?? true, "Workout should have intervals")
        XCTAssertTrue(workout?.summary.contains("250") ?? false, "Summary should contain FTP value")
    }
    
    func testParseWorkoutCreatesCorrectIntervalsStructure() throws {
        // Given: Threshold workout type (which has a known structure)
        viewModel.selectedWorkoutType = .threshold
        
        // When: parseWorkout is called
        let workout = viewModel.parseWorkout(from: "test json")
        
        // Then: Workout should have expected interval structure for threshold
        XCTAssertNotNil(workout, "Workout should be created")
        XCTAssertEqual(workout?.intervals.count, 5, "Threshold workout should have 5 intervals (warmup, work, recovery, work, cooldown)")
        
        // Verify structure: warmup -> threshold -> recovery -> threshold -> cooldown
        let intervals = workout!.intervals
        XCTAssertEqual(intervals[0].duration, 300, "First interval should be 5-minute warmup")
        XCTAssertEqual(intervals[1].duration, 480, "Second interval should be 8-minute threshold")
        XCTAssertEqual(intervals[2].duration, 180, "Third interval should be 3-minute recovery")
        XCTAssertEqual(intervals[3].duration, 480, "Fourth interval should be 8-minute threshold")
        XCTAssertEqual(intervals[4].duration, 300, "Fifth interval should be 5-minute cooldown")
        
        // Verify power levels relative to FTP (250W)
        XCTAssertEqual(intervals[0].watts, 150, "Warmup should be at 60% FTP (150W)")
        XCTAssertEqual(intervals[1].watts, 237, "Threshold should be at 95% FTP (237W)")
        XCTAssertEqual(intervals[2].watts, 175, "Recovery should be at 70% FTP (175W)")
    }
    
    func testParseWorkoutHandlesValidJSON() throws {
        // Given: Valid JSON workout data
        let validJSON = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "title": "Custom JSON Workout",
            "date": "2025-06-24T12:00:00Z",
            "summary": "A custom workout from JSON",
            "intervals": [
                {
                    "id": "550e8400-e29b-41d4-a716-446655440001",
                    "watts": 200,
                    "duration": 600
                }
            ],
            "status": "scheduled"
        }
        """
        
        // When: parseWorkout is called with valid JSON
        let workout = viewModel.parseWorkout(from: validJSON)
        
        // Then: Should parse the JSON correctly
        XCTAssertNotNil(workout, "Should parse valid JSON")
        XCTAssertEqual(workout?.title, "Custom JSON Workout", "Should use JSON title")
        XCTAssertEqual(workout?.intervals.count, 1, "Should have one interval from JSON")
        XCTAssertEqual(workout?.intervals.first?.watts, 200, "Should use watts from JSON")
        XCTAssertEqual(workout?.intervals.first?.duration, 600, "Should use duration from JSON")
    }
    
    func testParseWorkoutFallsBackToDemoForInvalidJSON() throws {
        // Given: Invalid JSON and endurance workout type
        viewModel.selectedWorkoutType = .endurance
        let invalidJSON = "{ invalid json structure"
        
        // When: parseWorkout is called with invalid JSON
        let workout = viewModel.parseWorkout(from: invalidJSON)
        
        // Then: Should fall back to demo workout
        XCTAssertNotNil(workout, "Should create demo workout for invalid JSON")
        XCTAssertEqual(workout?.title, "Endurance Workout", "Should use demo workout title")
        XCTAssertEqual(workout?.intervals.count, 3, "Endurance demo should have 3 intervals")
    }
    
    func testDefaultWorkoutTypeIsEndurance() throws {
        // Then: Default workout type should be endurance
        XCTAssertEqual(viewModel.selectedWorkoutType, .endurance, "Default workout type should be endurance")
    }
    
    func testInitialStateIsCorrect() throws {
        // Then: Initial state should be properly set
        XCTAssertNil(viewModel.generatedWorkout, "Generated workout should initially be nil")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.errorMessage, "Error message should initially be nil")
    }
}