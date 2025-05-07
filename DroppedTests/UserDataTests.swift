//
//  UserDataTests.swift
//  DroppedTests
//
//  Created on 5/6/25.
//

import XCTest
@testable import Dropped

final class UserDataTests: XCTestCase {
    
    func testWeightUnitConversion() throws {
        // Test pounds to kilograms
        let poundsToKgResult = WeightUnit.pounds.convert(from: 154.0, to: .kilograms)
        XCTAssertEqual(poundsToKgResult, 69.85317, accuracy: 0.001, "Converting 154 lb to kg should be about 69.85 kg")
        
        // Test kilograms to pounds
        let kgToPoundsResult = WeightUnit.kilograms.convert(from: 70.0, to: .pounds)
        XCTAssertEqual(kgToPoundsResult, 154.324, accuracy: 0.001, "Converting 70 kg to lb should be about 154.32 lb")
        
        // Test stones to kilograms
        let stonesToKgResult = WeightUnit.stones.convert(from: 11.0, to: .kilograms)
        XCTAssertEqual(stonesToKgResult, 69.85319, accuracy: 0.001, "Converting 11 st to kg should be about 69.85 kg")
        
        // Test circular conversion (should get back to original value)
        let originalValue = 75.0
        let intermediate = WeightUnit.kilograms.convert(from: originalValue, to: .pounds)
        let finalValue = WeightUnit.pounds.convert(from: intermediate, to: .kilograms)
        XCTAssertEqual(finalValue, originalValue, accuracy: 0.001, "Converting kg → lb → kg should return the original value")
    }
    
    func testUserDataManagerSaveAndLoad() throws {
        // Create test data
        let testData = UserData(
            weight: 65.0,
            weightUnit: WeightUnit.kilograms.rawValue,
            ftp: 250,
            trainingHoursPerWeek: 8,
            trainingGoal: TrainingGoal.getFaster.rawValue
        )
        
        // Save test data
        UserDataManager.shared.saveUserData(testData)
        
        // Load the data back
        let loadedData = UserDataManager.shared.loadUserData()
        
        // Verify all properties match
        XCTAssertEqual(loadedData.weight, testData.weight, "Loaded weight should match saved weight")
        XCTAssertEqual(loadedData.weightUnit, testData.weightUnit, "Loaded weight unit should match saved weight unit")
        XCTAssertEqual(loadedData.ftp, testData.ftp, "Loaded FTP should match saved FTP")
        XCTAssertEqual(loadedData.trainingHoursPerWeek, testData.trainingHoursPerWeek, "Loaded training hours should match saved hours")
        XCTAssertEqual(loadedData.trainingGoal, testData.trainingGoal, "Loaded training goal should match saved goal")
        
        // Clean up by resetting to default data
        UserDataManager.shared.saveUserData(UserData.defaultData)
    }
    
    func testUserDataDisplayWeight() throws {
        // Test display weight conversion for different units
        
        // Create test data with weight in kg but display unit set to pounds
        let poundsDisplayData = UserData(
            weight: 70.0,  // Weight in kg
            weightUnit: WeightUnit.pounds.rawValue,
            ftp: 200,
            trainingHoursPerWeek: 5,
            trainingGoal: TrainingGoal.haveFun.rawValue
        )
        
        // Weight should be converted to pounds for display
        XCTAssertEqual(poundsDisplayData.displayWeight(), 154.324, accuracy: 0.001, "70kg should display as approximately 154.32 pounds")
        
        // Create test data with weight in kg and display unit set to stones
        let stonesDisplayData = UserData(
            weight: 70.0,  // Weight in kg
            weightUnit: WeightUnit.stones.rawValue,
            ftp: 200,
            trainingHoursPerWeek: 5,
            trainingGoal: TrainingGoal.haveFun.rawValue
        )
        
        // Weight should be converted to stones for display
        XCTAssertEqual(stonesDisplayData.displayWeight(), 11.023, accuracy: 0.001, "70kg should display as approximately 11.02 stones")
    }
    
    func testHasCompletedOnboarding() throws {
        // Remove any existing user data
        UserDefaults.standard.removeObject(forKey: "com.dropped.userdata")
        
        // Initially should indicate onboarding not completed
        XCTAssertFalse(UserDataManager.shared.hasCompletedOnboarding(), "Onboarding should not be completed after clearing data")
        
        // Save some user data
        UserDataManager.shared.saveUserData(UserData.defaultData)
        
        // Should now indicate onboarding is completed
        XCTAssertTrue(UserDataManager.shared.hasCompletedOnboarding(), "Onboarding should be completed after saving data")
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "com.dropped.userdata")
    }
}
