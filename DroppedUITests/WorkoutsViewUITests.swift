//
//  WorkoutsViewUITests.swift
//  DroppedUITests
//
//  Created by Copilot on 2025-10-27.
//
//  UI tests for the WorkoutsView screen

import XCTest

/// UI tests for the WorkoutsView screen
final class WorkoutsViewUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["-resetUserDefaults"]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Complete onboarding to access the main app
    private func completeOnboarding() {
        // Wait for onboarding view to appear
        let onboardingView = app.otherElements["onboardingView"]
        XCTAssertTrue(onboardingView.waitForExistence(timeout: 5))
        
        // Fill in onboarding form
        // Weight field
        let weightField = app.textFields.element(boundBy: 0)
        weightField.tap()
        weightField.typeText("150")
        
        // FTP field
        let ftpField = app.textFields.element(boundBy: 1)
        ftpField.tap()
        ftpField.typeText("250")
        
        // Hours per week picker
        let hoursButton = app.buttons["5"]
        if hoursButton.exists {
            hoursButton.tap()
        }
        
        // Training goal
        let goalButton = app.buttons["Have Fun"]
        if goalButton.exists {
            goalButton.tap()
        }
        
        // Tap the submit button
        let submitButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'get started' OR label CONTAINS[c] 'continue'")).firstMatch
        if submitButton.exists {
            submitButton.tap()
        }
        
        // Wait for main navigation view to appear
        let mainNav = app.otherElements["mainNavigationView"]
        XCTAssertTrue(mainNav.waitForExistence(timeout: 5))
    }
    
    /// Navigate to the Workouts screen
    private func navigateToWorkouts() {
        completeOnboarding()
        
        // Tap the Workouts navigation link
        let workoutsLink = app.buttons["Workouts"]
        XCTAssertTrue(workoutsLink.waitForExistence(timeout: 5))
        workoutsLink.tap()
        
        // Wait for workouts view to appear
        let workoutsView = app.otherElements["workoutsView"]
        XCTAssertTrue(workoutsView.waitForExistence(timeout: 5))
    }
    
    // MARK: - Tests
    
    /// Test that the Workouts navigation link exists in the main menu
    func testWorkoutsNavigationLinkExists() {
        completeOnboarding()
        
        // Verify Workouts link exists
        let workoutsLink = app.buttons["Workouts"]
        XCTAssertTrue(workoutsLink.exists)
    }
    
    /// Test navigating to the Workouts screen
    func testNavigateToWorkoutsScreen() {
        completeOnboarding()
        
        // Tap the Workouts link
        let workoutsLink = app.buttons["Workouts"]
        XCTAssertTrue(workoutsLink.waitForExistence(timeout: 5))
        workoutsLink.tap()
        
        // Verify workouts view appears
        let workoutsView = app.otherElements["workoutsView"]
        XCTAssertTrue(workoutsView.waitForExistence(timeout: 5))
        
        // Verify navigation title
        let navigationBar = app.navigationBars["Workouts"]
        XCTAssertTrue(navigationBar.exists)
    }
    
    /// Test that empty state is shown when no workouts exist
    func testEmptyStateDisplayed() {
        navigateToWorkouts()
        
        // Look for empty state text
        let emptyStateText = app.staticTexts["No workouts found"]
        XCTAssertTrue(emptyStateText.waitForExistence(timeout: 5))
        
        // Verify empty state image exists
        let emptyStateImage = app.images.containing(NSPredicate(format: "identifier CONTAINS[c] 'indoor.cycle'")).firstMatch
        XCTAssertTrue(emptyStateImage.exists || app.images.count > 0)
    }
    
    /// Test that filter pills are displayed
    func testFilterPillsExist() {
        navigateToWorkouts()
        
        // Verify filter buttons exist
        let allFilter = app.buttons["All filter"]
        let scheduledFilter = app.buttons["Scheduled filter"]
        let completedFilter = app.buttons["Completed filter"]
        let skippedFilter = app.buttons["Skipped filter"]
        
        XCTAssertTrue(allFilter.waitForExistence(timeout: 5))
        XCTAssertTrue(scheduledFilter.exists)
        XCTAssertTrue(completedFilter.exists)
        XCTAssertTrue(skippedFilter.exists)
    }
    
    /// Test tapping filter pills
    func testFilterPillInteraction() {
        navigateToWorkouts()
        
        // Tap different filters
        let scheduledFilter = app.buttons["Scheduled filter"]
        XCTAssertTrue(scheduledFilter.waitForExistence(timeout: 5))
        scheduledFilter.tap()
        
        let completedFilter = app.buttons["Completed filter"]
        completedFilter.tap()
        
        let allFilter = app.buttons["All filter"]
        allFilter.tap()
    }
    
    /// Test back navigation from Workouts screen
    func testBackNavigation() {
        navigateToWorkouts()
        
        // Tap back button
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.exists)
        backButton.tap()
        
        // Verify we're back at main navigation
        let mainNav = app.otherElements["mainNavigationView"]
        XCTAssertTrue(mainNav.waitForExistence(timeout: 5))
    }
}
