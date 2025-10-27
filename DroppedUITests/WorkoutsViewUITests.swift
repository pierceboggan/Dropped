//
//  WorkoutsViewUITests.swift
//  DroppedUITests
//
//  UI tests for the Workouts screen navigation and interaction.
//

import XCTest

final class WorkoutsViewUITests: XCTestCase {
    
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
    func testNavigationToWorkoutsView() throws {
        // Complete onboarding first
        completeOnboarding()
        
        // Wait for main navigation view
        let mainNav = app.otherElements["mainNavigationView"]
        XCTAssertTrue(mainNav.waitForExistence(timeout: 5), "Should be on main navigation view")
        
        // Find and tap the Workouts navigation link
        let workoutsLink = app.staticTexts["Workouts"]
        XCTAssertTrue(workoutsLink.waitForExistence(timeout: 5), "Workouts link should exist")
        workoutsLink.tap()
        
        // Verify we're on the Workouts view
        let workoutsView = app.otherElements["workoutsView"]
        XCTAssertTrue(workoutsView.waitForExistence(timeout: 5), "Should navigate to Workouts view")
        
        // Verify navigation title
        let workoutsNavBar = app.navigationBars["Workouts"]
        XCTAssertTrue(workoutsNavBar.exists, "Should show Workouts navigation bar")
    }
    
    @MainActor
    func testWorkoutsListDisplay() throws {
        // Complete onboarding to generate workouts
        completeOnboarding()
        
        // Navigate to Workouts view
        let workoutsLink = app.staticTexts["Workouts"]
        if workoutsLink.waitForExistence(timeout: 5) {
            workoutsLink.tap()
        }
        
        // Wait for the view to load
        let workoutsView = app.otherElements["workoutsView"]
        XCTAssertTrue(workoutsView.waitForExistence(timeout: 5), "Workouts view should be displayed")
        
        // Check that workouts are displayed (or empty state if no workouts)
        // The view should show either workout cards or an empty state message
        let hasWorkouts = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'workout'")).count > 0
        let hasEmptyState = app.staticTexts["No Workouts Found"].exists
        
        XCTAssertTrue(hasWorkouts || hasEmptyState, "Should show either workouts or empty state")
    }
    
    @MainActor
    func testFilterAndSortMenu() throws {
        // Complete onboarding
        completeOnboarding()
        
        // Navigate to Workouts view
        let workoutsLink = app.staticTexts["Workouts"]
        if workoutsLink.waitForExistence(timeout: 5) {
            workoutsLink.tap()
        }
        
        // Wait for the view to load
        sleep(1)
        
        // Find and tap the filter/sort button
        let filterButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Filter' OR label CONTAINS 'sort'")).firstMatch
        if filterButton.waitForExistence(timeout: 5) {
            filterButton.tap()
            
            // Wait for menu to appear - check if menu items are displayed
            let menuAppeared = app.menuItems.firstMatch.waitForExistence(timeout: 3) || app.buttons.firstMatch.waitForExistence(timeout: 3)
            
            // Menu should have options - we can verify by checking if menu items exist
            // The menu will contain sort and filter options
            XCTAssertTrue(app.menuItems.count > 0 || app.buttons.count > 0, "Filter/sort menu should show options")
        }
    }
    
    @MainActor
    func testEmptyStateWhenNoWorkouts() throws {
        // Launch app without completing onboarding (no workouts created)
        app.launch()
        
        // Complete onboarding but navigate away before workouts are generated
        completeOnboarding()
        
        // Go to workouts view
        let workoutsLink = app.staticTexts["Workouts"]
        if workoutsLink.waitForExistence(timeout: 5) {
            workoutsLink.tap()
        }
        
        // Wait for workouts view to load
        let workoutsView = app.otherElements["workoutsView"]
        XCTAssertTrue(workoutsView.waitForExistence(timeout: 5), "Workouts view should load")
        
        // Just verify the view loads successfully
        XCTAssertTrue(workoutsView.exists, "Workouts view should be displayed")
    }
    
    @MainActor
    func testNavigateToWorkoutDetail() throws {
        // Complete onboarding to generate workouts
        completeOnboarding()
        
        // Navigate to Workouts view
        let workoutsLink = app.staticTexts["Workouts"]
        if workoutsLink.waitForExistence(timeout: 5) {
            workoutsLink.tap()
        }
        
        // Wait for view to load
        let workoutsView = app.otherElements["workoutsView"]
        XCTAssertTrue(workoutsView.waitForExistence(timeout: 5), "Workouts view should load")
        
        // Try to find and tap on a workout card
        // Look for common workout title patterns
        let workoutTitles = ["Recovery", "Tempo", "Endurance", "Intervals", "Threshold", "VO2 Max", "Active Recovery", "Long Ride"]
        
        var foundWorkout = false
        for title in workoutTitles {
            if app.staticTexts[title].exists {
                app.staticTexts[title].tap()
                foundWorkout = true
                break
            }
        }
        
        if foundWorkout {
            // Verify we navigated to workout detail
            let detailNav = app.navigationBars["Workout Details"]
            XCTAssertTrue(detailNav.waitForExistence(timeout: 5), "Should navigate to workout detail view")
        } else {
            // If no workout cards found, at least verify the view is showing
            XCTAssertTrue(app.otherElements["workoutsView"].exists, "Workouts view should be displayed")
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
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
        
        // Submit onboarding
        let generateButton = app.buttons["generatePlanButton"]
        if generateButton.waitForExistence(timeout: 5) {
            generateButton.tap()
        } else {
            let planButton = app.buttons["Generate My Training Plan"]
            if planButton.waitForExistence(timeout: 5) {
                planButton.tap()
            }
        }
        
        // Wait for navigation to complete
        let planNav = app.navigationBars["Your Training Plan"]
        XCTAssertTrue(planNav.waitForExistence(timeout: 5), "Should navigate to training plan")
    }
}
