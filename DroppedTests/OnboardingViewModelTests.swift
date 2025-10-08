//
//  OnboardingViewModelTests.swift
//  DroppedTests
//
//  Created on 5/6/25.
//

import XCTest
import Combine
@testable import Dropped

final class OnboardingViewModelTests: XCTestCase {
    
    private var viewModel: OnboardingViewModel!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        // Make sure there's no data in UserDefaults
        UserDefaults.standard.removeObject(forKey: "com.dropped.userdata")
        
        // Create a fresh viewModel for each test
        viewModel = OnboardingViewModel()
        cancellables = []
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        cancellables = nil
        UserDefaults.standard.removeObject(forKey: "com.dropped.userdata")
    }
    
    func testValidInputsValidation() throws {
        // Set valid inputs
        viewModel.weight = "75.0"
        viewModel.ftp = "250"
        viewModel.trainingHoursPerWeek = "10"
        
        // Validate
        XCTAssertTrue(viewModel.validateInputs(), "Valid inputs should pass validation")
        XCTAssertNil(viewModel.weightError, "No weight error should be present")
        XCTAssertNil(viewModel.ftpError, "No FTP error should be present")
        XCTAssertNil(viewModel.hoursError, "No hours error should be present")
    }
    
    func testInvalidWeightValidation() throws {
        // Set invalid weight
        viewModel.weight = "0"
        viewModel.ftp = "250"
        viewModel.trainingHoursPerWeek = "10"
        
        // Validate
        XCTAssertFalse(viewModel.validateInputs(), "Invalid weight should fail validation")
        XCTAssertNotNil(viewModel.weightError, "Weight error should be present")
        XCTAssertNil(viewModel.ftpError, "No FTP error should be present")
        XCTAssertNil(viewModel.hoursError, "No hours error should be present")
        
        // Test non-numeric weight
        viewModel.weight = "abc"
        XCTAssertFalse(viewModel.validateInputs(), "Non-numeric weight should fail validation")
        XCTAssertNotNil(viewModel.weightError, "Weight error should be present")
    }
    
    func testInvalidFTPValidation() throws {
        // Set invalid FTP
        viewModel.weight = "75.0"
        viewModel.ftp = "0"
        viewModel.trainingHoursPerWeek = "10"
        
        // Validate
        XCTAssertFalse(viewModel.validateInputs(), "Invalid FTP should fail validation")
        XCTAssertNil(viewModel.weightError, "No weight error should be present")
        XCTAssertNotNil(viewModel.ftpError, "FTP error should be present")
        XCTAssertNil(viewModel.hoursError, "No hours error should be present")
        
        // Test non-numeric FTP
        viewModel.ftp = "abc"
        XCTAssertFalse(viewModel.validateInputs(), "Non-numeric FTP should fail validation")
        XCTAssertNotNil(viewModel.ftpError, "FTP error should be present")
    }
    
    func testInvalidHoursValidation() throws {
        // Set invalid hours (too many)
        viewModel.weight = "75.0"
        viewModel.ftp = "250"
        viewModel.trainingHoursPerWeek = "50"
        
        // Validate
        XCTAssertFalse(viewModel.validateInputs(), "Too many hours should fail validation")
        XCTAssertNil(viewModel.weightError, "No weight error should be present")
        XCTAssertNil(viewModel.ftpError, "No FTP error should be present")
        XCTAssertNotNil(viewModel.hoursError, "Hours error should be present")
        
        // Test non-numeric hours
        viewModel.trainingHoursPerWeek = "abc"
        XCTAssertFalse(viewModel.validateInputs(), "Non-numeric hours should fail validation")
        XCTAssertNotNil(viewModel.hoursError, "Hours error should be present")
        
        // Test negative hours
        viewModel.trainingHoursPerWeek = "-5"
        XCTAssertFalse(viewModel.validateInputs(), "Negative hours should fail validation")
        XCTAssertNotNil(viewModel.hoursError, "Hours error should be present")
    }
    
    func testToggleUnitSystem() throws {
        // Start with imperial (default)
        XCTAssertFalse(viewModel.isMetric, "Default should be imperial")
        XCTAssertEqual(viewModel.selectedWeightUnit, .pounds, "Default unit should be pounds")
        
        // Set a starting weight
        viewModel.weight = "150.0" // in pounds
        
        // Toggle to metric
        viewModel.toggleUnitSystem()
        
        // Check state after toggle
        XCTAssertTrue(viewModel.isMetric, "Should be metric after toggle")
        XCTAssertEqual(viewModel.selectedWeightUnit, .kilograms, "Unit should be kilograms")
        
        // Check if weight was converted (150 lb ≈ 68.04 kg)
        let convertedWeight = Double(viewModel.weight) ?? 0
        XCTAssertEqual(convertedWeight, 68.0, accuracy: 0.1, "Weight should be converted from lb to kg")
        
        // Toggle back to imperial
        viewModel.toggleUnitSystem()
        
        // Check state after toggle back
        XCTAssertFalse(viewModel.isMetric, "Should be imperial after second toggle")
        XCTAssertEqual(viewModel.selectedWeightUnit, .pounds, "Unit should be pounds")
        
        // Check if weight was converted back (68.04 kg ≈ 150 lb)
        let convertedBackWeight = Double(viewModel.weight) ?? 0
        XCTAssertEqual(convertedBackWeight, 150.0, accuracy: 0.1, "Weight should be converted from kg back to lb")
    }
    
    func testSelectWeightUnit() throws {
        // Start with pounds
        XCTAssertEqual(viewModel.selectedWeightUnit, .pounds, "Default unit should be pounds")
        viewModel.weight = "154.0" // in pounds
        
        // Switch to kilograms
        viewModel.selectWeightUnit(.kilograms)
        
        // Check state
        XCTAssertEqual(viewModel.selectedWeightUnit, .kilograms, "Unit should be kilograms")
        XCTAssertTrue(viewModel.isMetric, "Should be metric")
        
        // Check weight conversion (154 lb ≈ 69.85 kg)
        let convertedToKgWeight = Double(viewModel.weight) ?? 0
        XCTAssertEqual(convertedToKgWeight, 69.9, accuracy: 0.1, "Weight should be converted from lb to kg")
        
        // Switch back to pounds
        viewModel.selectWeightUnit(.pounds)
        
        // Check state
        XCTAssertEqual(viewModel.selectedWeightUnit, .pounds, "Unit should be pounds")
        XCTAssertFalse(viewModel.isMetric, "Should be imperial")
        
        // Check weight conversion (69.9 kg ≈ 154 lb)
        let convertedBackToLbWeight = Double(viewModel.weight) ?? 0
        XCTAssertEqual(convertedBackToLbWeight, 154.0, accuracy: 0.1, "Weight should be converted from kg back to lb")
    }
    
    func testSaveUserData() throws {
        // Set valid data
        viewModel.weight = "75.0"
        viewModel.ftp = "250"
        viewModel.trainingHoursPerWeek = "10"
        viewModel.selectedGoal = .getFaster
        viewModel.selectedWeightUnit = .kilograms
        viewModel.isMetric = true
        
        // Save data
        XCTAssertTrue(viewModel.saveUserData(), "Saving valid data should succeed")
        
        // Load the data back using UserDataManager
        let loadedData = UserDataManager.shared.loadUserData()
        
        // Verify saved data
        XCTAssertEqual(loadedData.weight, 75.0, "Saved weight should match input")
        XCTAssertEqual(loadedData.weightUnit, WeightUnit.kilograms.rawValue, "Saved unit should match selection")
        XCTAssertEqual(loadedData.ftp, 250, "Saved FTP should match input")
        XCTAssertEqual(loadedData.trainingHoursPerWeek, 10, "Saved training hours should match input")
        XCTAssertEqual(loadedData.trainingGoal, TrainingGoal.getFaster.rawValue, "Saved goal should match selection")
    }
}
