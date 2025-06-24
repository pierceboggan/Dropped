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
        // Given: Default endurance workout type
        viewModel.selectedWorkoutType = .endurance
        
        // When: parseWorkout is called
        let workout = viewModel.parseWorkout(from: "test json")
        
        // Then: Workout should have expected interval structure
        XCTAssertNotNil(workout, "Workout should be created")
        XCTAssertEqual(workout?.intervals.count, 7, "Workout should have 7 intervals (warmup, 3 work intervals, 2 recovery, cooldown)")
        
        // Verify structure: warmup -> work -> recovery -> work -> recovery -> work -> cooldown
        let intervals = workout!.intervals
        XCTAssertEqual(intervals[0].watts, 150, "First interval should be warmup at 150W")
        XCTAssertEqual(intervals[0].duration, 300, "First interval should be 5 minutes")
        XCTAssertEqual(intervals[6].watts, 150, "Last interval should be cooldown at 150W")
        XCTAssertEqual(intervals[6].duration, 300, "Last interval should be 5 minutes")
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