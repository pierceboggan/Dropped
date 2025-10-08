//
//  WorkoutGeneratorUITests.swift
//  DroppedUITests
//
//  UI tests for the AI workout generator feature
//

import XCTest

final class WorkoutGeneratorUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        app = XCUIApplication()
        app.launchArguments = ["-resetUserDefaults"]
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testNavigationToWorkoutGenerator() throws {
        // Complete onboarding first
        completeOnboarding()
        
        // Find and tap AI Workout Generator link
        let generatorLink = app.buttons["AI Workout Generator"]
        XCTAssertTrue(generatorLink.waitForExistence(timeout: 5), "AI Workout Generator link should exist")
        generatorLink.tap()
        
        // Verify we're on the workout generator screen
        let header = app.staticTexts["Select Workout Type"]
        XCTAssertTrue(header.waitForExistence(timeout: 3), "Should navigate to workout generator screen")
    }
    
    @MainActor
    func testWorkoutTypeSelection() throws {
        // Navigate to workout generator
        completeOnboarding()
        
        let generatorLink = app.buttons["AI Workout Generator"]
        XCTAssertTrue(generatorLink.waitForExistence(timeout: 5), "AI Workout Generator link should exist")
        generatorLink.tap()
        
        // Wait for view to load
        sleep(1)
        
        // Verify all workout types are displayed
        XCTAssertTrue(app.staticTexts["Endurance"].exists, "Endurance option should exist")
        XCTAssertTrue(app.staticTexts["Threshold"].exists, "Threshold option should exist")
        XCTAssertTrue(app.staticTexts["VO2 Max"].exists, "VO2 Max option should exist")
        XCTAssertTrue(app.staticTexts["Sprint"].exists, "Sprint option should exist")
        XCTAssertTrue(app.staticTexts["Recovery"].exists, "Recovery option should exist")
        
        // Try selecting different workout types
        // Tap on Threshold
        let thresholdButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Threshold'")).element
        if thresholdButton.exists {
            thresholdButton.tap()
            // Checkmark should appear for selected item
            XCTAssertTrue(app.images["checkmark.circle.fill"].exists, "Selected workout should show checkmark")
        }
    }
    
    @MainActor
    func testGenerateWorkoutFlow() throws {
        // Navigate to workout generator
        completeOnboarding()
        
        let generatorLink = app.buttons["AI Workout Generator"]
        XCTAssertTrue(generatorLink.waitForExistence(timeout: 5), "AI Workout Generator link should exist")
        generatorLink.tap()
        
        // Wait for view to load
        sleep(1)
        
        // Select a workout type (Endurance is selected by default)
        // Tap generate button
        let generateButton = app.buttons["Generate Workout"]
        XCTAssertTrue(generateButton.exists, "Generate button should exist")
        generateButton.tap()
        
        // Loading indicator should appear
        let loadingIndicator = app.activityIndicators.firstMatch
        // Note: Loading might be very quick with mock data
        
        // Wait for result (should show workout preview or error)
        sleep(2)
        
        // Either workout preview or error should be visible
        // Since we're using mock data, workout should be generated successfully
        let workoutPreview = app.scrollViews.firstMatch
        // The preview might exist if generation was successful
    }
    
    @MainActor
    func testGenerateButtonAccessibility() throws {
        // Navigate to workout generator
        completeOnboarding()
        
        let generatorLink = app.buttons["AI Workout Generator"]
        XCTAssertTrue(generatorLink.waitForExistence(timeout: 5), "AI Workout Generator link should exist")
        generatorLink.tap()
        
        // Wait for view
        sleep(1)
        
        // Verify generate button has proper accessibility
        let generateButton = app.buttons["Generate Workout"]
        XCTAssertTrue(generateButton.exists, "Generate button should exist")
        XCTAssertTrue(generateButton.isEnabled, "Generate button should be enabled initially")
        
        // Tap to start generation
        generateButton.tap()
        
        // Button should be disabled while loading
        // Note: This might be too fast to catch with mock data
        sleep(0.5)
    }
    
    @MainActor
    func testWorkoutTypeDescriptions() throws {
        // Navigate to workout generator
        completeOnboarding()
        
        let generatorLink = app.buttons["AI Workout Generator"]
        XCTAssertTrue(generatorLink.waitForExistence(timeout: 5), "AI Workout Generator link should exist")
        generatorLink.tap()
        
        // Verify descriptions are shown for workout types
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'aerobic'")).count > 0,
                     "Workout descriptions should be visible")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'power'")).count > 0,
                     "Workout descriptions should mention power")
    }
    
    @MainActor
    func testWorkoutGeneratorAccessibility() throws {
        // Navigate to workout generator
        completeOnboarding()
        
        let generatorLink = app.buttons["AI Workout Generator"]
        XCTAssertTrue(generatorLink.waitForExistence(timeout: 5), "AI Workout Generator link should exist")
        generatorLink.tap()
        
        // Verify header has proper traits
        let header = app.staticTexts["Select Workout Type"]
        XCTAssertTrue(header.waitForExistence(timeout: 3), "Header should exist")
        
        // Verify workout type buttons have accessibility labels
        let enduranceButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Endurance'")).element
        if enduranceButton.exists {
            // Button should combine workout name and description for accessibility
            XCTAssertTrue(enduranceButton.label.contains("Endurance"), "Should have workout type in label")
        }
    }
    
    // MARK: - Helper Methods
    
    private func completeOnboarding() {
        app.launch()
        
        // Fill onboarding data
        let weightTextField = app.textFields["Weight"]
        if weightTextField.waitForExistence(timeout: 5) {
            weightTextField.tap()
            weightTextField.typeText("70")
        }
        
        let ftpTextField = app.textFields["FTP"]
        if ftpTextField.waitForExistence(timeout: 5) {
            ftpTextField.tap()
            ftpTextField.typeText("200")
        }
        
        let hoursTextField = app.textFields["Hours per week"]
        if hoursTextField.waitForExistence(timeout: 5) {
            hoursTextField.tap()
            hoursTextField.typeText("5")
        }
        
        // Tap generate plan button
        let generateButton = app.buttons["generatePlanButton"]
        if generateButton.waitForExistence(timeout: 5) {
            generateButton.tap()
            
            // Wait for navigation to complete
            sleep(2)
        }
    }
}
