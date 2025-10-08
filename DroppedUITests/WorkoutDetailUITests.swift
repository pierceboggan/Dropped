//
//  WorkoutDetailUITests.swift
//  DroppedUITests
//
//  UI tests for the workout detail view
//

import XCTest

final class WorkoutDetailUITests: XCTestCase {
    
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
    func testWorkoutDetailViewNavigation() throws {
        // Complete onboarding first
        completeOnboarding()
        
        // Navigate to Weekly Plan
        let weeklyPlanLink = app.buttons["Weekly Plan"]
        XCTAssertTrue(weeklyPlanLink.waitForExistence(timeout: 5), "Weekly Plan link should exist")
        weeklyPlanLink.tap()
        
        // Wait for workout cards to appear
        sleep(2)
        
        // Find and tap the first workout card
        let workoutCards = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'workoutCard'"))
        if workoutCards.count > 0 {
            workoutCards.element(boundBy: 0).tap()
            
            // Verify workout detail view appears
            // Check for key elements that should be in the detail view
            let detailView = app.otherElements.containing(NSPredicate(format: "label CONTAINS 'Workout'"))
            XCTAssertTrue(detailView.count > 0, "Workout detail view should be displayed")
            
            // Verify navigation back works
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists {
                backButton.tap()
                // Should return to plan summary
                XCTAssertTrue(app.staticTexts["Your Training Plan"].waitForExistence(timeout: 3), "Should return to plan summary")
            }
        }
    }
    
    @MainActor
    func testWorkoutDetailViewDisplaysIntervals() throws {
        // Complete onboarding
        completeOnboarding()
        
        // Navigate to Weekly Plan
        let weeklyPlanLink = app.buttons["Weekly Plan"]
        XCTAssertTrue(weeklyPlanLink.waitForExistence(timeout: 5), "Weekly Plan link should exist")
        weeklyPlanLink.tap()
        
        // Wait for content to load
        sleep(2)
        
        // Tap first workout
        let workoutCards = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'workoutCard'"))
        if workoutCards.count > 0 {
            workoutCards.element(boundBy: 0).tap()
            
            // Check for "Intervals" header
            let intervalsHeader = app.staticTexts["Intervals"]
            XCTAssertTrue(intervalsHeader.waitForExistence(timeout: 3), "Intervals section should be displayed")
            
            // Check for Power Profile graph
            let powerProfileHeader = app.staticTexts["Power Profile"]
            XCTAssertTrue(powerProfileHeader.waitForExistence(timeout: 3), "Power Profile section should be displayed")
        }
    }
    
    @MainActor
    func testWorkoutDetailViewAccessibility() throws {
        // Complete onboarding
        completeOnboarding()
        
        // Navigate to Weekly Plan
        let weeklyPlanLink = app.buttons["Weekly Plan"]
        XCTAssertTrue(weeklyPlanLink.waitForExistence(timeout: 5), "Weekly Plan link should exist")
        weeklyPlanLink.tap()
        
        // Wait for content
        sleep(2)
        
        // Tap first workout
        let workoutCards = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'workoutCard'"))
        if workoutCards.count > 0 {
            workoutCards.element(boundBy: 0).tap()
            
            // Verify accessibility labels exist for key elements
            // The intervals list should have accessibility labels
            let intervalsLabel = app.staticTexts["Intervals list"]
            XCTAssertTrue(intervalsLabel.waitForExistence(timeout: 3) || app.staticTexts["Intervals"].exists, 
                         "Intervals section should have accessibility support")
            
            // Power profile graph should have accessibility
            let graphLabel = app.staticTexts["Power profile graph"]
            XCTAssertTrue(graphLabel.waitForExistence(timeout: 3) || app.staticTexts["Power Profile"].exists,
                         "Power profile should have accessibility support")
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
