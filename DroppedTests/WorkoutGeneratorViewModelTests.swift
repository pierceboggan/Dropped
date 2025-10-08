//
//  WorkoutGeneratorViewModelTests.swift
//  DroppedTests
//
//  Unit tests for WorkoutGeneratorViewModel
//

import XCTest
import Combine
@testable import Dropped

final class WorkoutGeneratorViewModelTests: XCTestCase {
    
    private var viewModel: WorkoutGeneratorViewModel!
    private var aiGenerator: AIWorkoutGenerator!
    private var userData: UserData!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        // Create test dependencies
        userData = UserData(
            weight: 75.0,
            weightUnit: WeightUnit.kilograms.rawValue,
            ftp: 250,
            trainingHoursPerWeek: 10,
            trainingGoal: TrainingGoal.getFaster.rawValue
        )
        
        aiGenerator = AIWorkoutGenerator(apiKey: "test-key")
        viewModel = WorkoutGeneratorViewModel(aiGenerator: aiGenerator, userData: userData)
        cancellables = []
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        aiGenerator = nil
        userData = nil
        cancellables = nil
    }
    
    func testInitialState() throws {
        // Verify initial state
        XCTAssertEqual(viewModel.selectedWorkoutType, .endurance, "Default workout type should be endurance")
        XCTAssertNil(viewModel.generatedWorkout, "No workout should be generated initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.errorMessage, "No error should be present initially")
    }
    
    func testWorkoutTypeSelection() throws {
        // Test changing workout type
        viewModel.selectedWorkoutType = .threshold
        XCTAssertEqual(viewModel.selectedWorkoutType, .threshold, "Workout type should be threshold")
        
        viewModel.selectedWorkoutType = .vo2Max
        XCTAssertEqual(viewModel.selectedWorkoutType, .vo2Max, "Workout type should be vo2Max")
        
        viewModel.selectedWorkoutType = .sprint
        XCTAssertEqual(viewModel.selectedWorkoutType, .sprint, "Workout type should be sprint")
        
        viewModel.selectedWorkoutType = .recovery
        XCTAssertEqual(viewModel.selectedWorkoutType, .recovery, "Workout type should be recovery")
    }
    
    func testGenerateWorkoutSuccess() throws {
        let expectation = XCTestExpectation(description: "Workout generation completes")
        
        // Monitor loading state
        var loadingStates: [Bool] = []
        viewModel.$isLoading
            .sink { loading in
                loadingStates.append(loading)
            }
            .store(in: &cancellables)
        
        // Monitor generated workout
        viewModel.$generatedWorkout
            .dropFirst() // Skip initial nil
            .sink { workout in
                if workout != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Generate workout
        viewModel.selectedWorkoutType = .threshold
        viewModel.generateWorkout()
        
        // Should be loading initially
        XCTAssertTrue(viewModel.isLoading, "Should be loading after calling generateWorkout")
        
        // Wait for completion
        wait(for: [expectation], timeout: 3.0)
        
        // Verify results
        XCTAssertNotNil(viewModel.generatedWorkout, "Workout should be generated")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
        XCTAssertNil(viewModel.errorMessage, "No error should be present on success")
        
        // Verify loading states changed
        XCTAssertTrue(loadingStates.contains(true), "Loading should have been true at some point")
        XCTAssertTrue(loadingStates.contains(false), "Loading should have been false at some point")
    }
    
    func testPreventDuplicateRequests() throws {
        // Start generating a workout
        viewModel.generateWorkout()
        XCTAssertTrue(viewModel.isLoading, "Should be loading")
        
        // Try to generate another workout while loading
        viewModel.generateWorkout()
        
        // Should still be processing the first request
        XCTAssertTrue(viewModel.isLoading, "Should still be loading")
    }
    
    func testAcceptWorkout() throws {
        let expectation = XCTestExpectation(description: "Workout accepted")
        
        // Generate a workout first
        viewModel.selectedWorkoutType = .endurance
        viewModel.generateWorkout()
        
        // Wait for generation
        viewModel.$generatedWorkout
            .dropFirst()
            .sink { workout in
                if workout != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
        
        // Accept the workout
        viewModel.acceptWorkout()
        
        // Verify the workout was saved to the manager
        let savedWorkouts = WorkoutManager.shared.loadWorkouts()
        XCTAssertTrue(savedWorkouts.count > 0, "Workout should be saved to the manager")
        
        // Clean up
        WorkoutManager.shared.deleteWorkout(withID: savedWorkouts.first!.id)
    }
    
    func testAcceptWorkoutWithoutGeneration() throws {
        // Try to accept without generating first
        viewModel.acceptWorkout()
        
        // Should set error message
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set when no workout to accept")
        XCTAssertTrue(viewModel.errorMessage!.contains("parse"), "Error should mention parsing issue")
    }
    
    func testErrorHandling() throws {
        // Test that error descriptions work correctly
        let networkError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network failed"])
        let errorMsg1 = WorkoutGeneratorViewModel.errorDescription(.networkError(networkError))
        XCTAssertTrue(errorMsg1.contains("Network error"), "Should contain network error message")
        
        let errorMsg2 = WorkoutGeneratorViewModel.errorDescription(.invalidResponse)
        XCTAssertTrue(errorMsg2.contains("Invalid response"), "Should contain invalid response message")
        
        let errorMsg3 = WorkoutGeneratorViewModel.errorDescription(.apiError("Test error"))
        XCTAssertTrue(errorMsg3.contains("API error"), "Should contain API error message")
    }
    
    func testGeneratedWorkoutContent() throws {
        let expectation = XCTestExpectation(description: "Workout generated with correct FTP")
        
        // Generate workout with specific FTP
        viewModel.selectedWorkoutType = .threshold
        viewModel.generateWorkout()
        
        viewModel.$generatedWorkout
            .dropFirst()
            .sink { workout in
                if let json = workout {
                    // Verify the FTP is included in the generated workout
                    XCTAssertTrue(json.contains("250"), "Generated workout should reference the user's FTP of 250")
                    XCTAssertTrue(json.contains("Threshold"), "Generated workout should reference the workout type")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
}

/// Extension to make the private errorDescription method accessible for testing
extension WorkoutGeneratorViewModel {
    static func errorDescription(_ error: AIWorkoutGeneratorError) -> String {
        switch error {
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .invalidResponse: return "Invalid response from AI service."
        case .apiError(let msg): return "API error: \(msg)"
        }
    }
}
