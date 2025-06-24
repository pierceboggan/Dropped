//
//  WorkoutGeneratorIntegrationTests.swift
//  DroppedTests
//
//  Created on 5/6/25.
//

import XCTest
@testable import Dropped

final class WorkoutGeneratorIntegrationTests: XCTestCase {
    
    var viewModel: WorkoutGeneratorViewModel!
    var testUserData: UserData!
    
    override func setUpWithError() throws {
        testUserData = UserData(
            weight: 70.0,
            weightUnit: WeightUnit.kilograms.rawValue,
            ftp: 200,
            trainingHoursPerWeek: 5,
            trainingGoal: TrainingGoal.getFaster.rawValue
        )
        
        let aiGenerator = AIWorkoutGenerator(apiKey: "test-key")
        viewModel = WorkoutGeneratorViewModel(
            aiGenerator: aiGenerator,
            userData: testUserData
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        testUserData = nil
    }
    
    func testCompleteWorkflowFromGenerationToAcceptance() throws {
        // Given: A view model with no generated workout
        XCTAssertNil(viewModel.generatedWorkout, "Should start with no generated workout")
        
        // When: We simulate a generated workout (since we can't call the real API in tests)
        viewModel.generatedWorkout = "simulated AI response"
        
        // And: We accept the workout
        let initialWorkoutCount = WorkoutManager.shared.loadWorkouts().count
        viewModel.acceptWorkout()
        
        // Then: A workout should be created and saved
        let savedWorkouts = WorkoutManager.shared.loadWorkouts()
        XCTAssertEqual(savedWorkouts.count, initialWorkoutCount + 1, "Should save one new workout")
        
        let newWorkout = savedWorkouts.last!
        XCTAssertEqual(newWorkout.title, "Endurance Workout", "Should use correct title for default workout type")
        XCTAssertFalse(newWorkout.intervals.isEmpty, "Should have intervals")
        XCTAssertEqual(newWorkout.status, .scheduled, "Should be scheduled status")
    }
    
    func testWorkoutGeneratorReviewViewIntegration() throws {
        // Given: A generated workout
        viewModel.generatedWorkout = "test workout data"
        
        // When: We try to parse it using the review view's safe parsing
        let reviewView = WorkoutGeneratorReviewView(
            viewModel: viewModel,
            onRegenerate: {},
            onAccept: {}
        )
        
        // Then: The parsing should work (we can't directly test private methods, but we can verify the workflow)
        XCTAssertNotNil(viewModel.generatedWorkout, "Generated workout should exist for review")
        XCTAssertNotNil(viewModel.parseWorkout(from: viewModel.generatedWorkout!), "Should be able to parse the workout")
    }
    
    func testDifferentWorkoutTypesCreateDifferentStructures() throws {
        let workoutTypes: [WorkoutType] = [.endurance, .threshold, .vo2Max, .sprint, .recovery]
        
        for workoutType in workoutTypes {
            // Given: A specific workout type
            viewModel.selectedWorkoutType = workoutType
            
            // When: We parse a workout
            let workout = viewModel.parseWorkout(from: "test json")
            
            // Then: The workout should be created with appropriate characteristics
            XCTAssertNotNil(workout, "Should create workout for \(workoutType)")
            XCTAssertEqual(workout?.title, "\(workoutType.displayName) Workout", "Should have correct title for \(workoutType)")
            XCTAssertTrue(workout!.summary.contains("200"), "Should mention FTP in summary for \(workoutType)")
            
            // Verify that different workout types have different structures
            let intervalCount = workout?.intervals.count ?? 0
            XCTAssertGreaterThan(intervalCount, 0, "\(workoutType) should have at least one interval")
            
            // Check specific characteristics for some workout types
            switch workoutType {
            case .recovery:
                XCTAssertEqual(intervalCount, 1, "Recovery should have 1 interval")
            case .endurance:
                XCTAssertEqual(intervalCount, 3, "Endurance should have 3 intervals")
            case .threshold:
                XCTAssertEqual(intervalCount, 5, "Threshold should have 5 intervals")
            case .vo2Max:
                XCTAssertEqual(intervalCount, 7, "VO2 Max should have 7 intervals")
            case .sprint:
                XCTAssertEqual(intervalCount, 7, "Sprint should have 7 intervals")
            }
        }
    }
}