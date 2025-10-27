//
//  WorkoutsListUITests.swift
//  DroppedUITests
//
//  UI tests for the WorkoutsListView.
//

import XCTest

final class WorkoutsListUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    func testNavigateToWorkoutsList() throws {
        // Skip onboarding if it appears
        if app.buttons["Get Started"].exists {
            // Complete onboarding quickly
            let getStartedButton = app.buttons["Get Started"]
            if getStartedButton.waitForExistence(timeout: 2) {
                getStartedButton.tap()
                
                // Fill in minimal onboarding data
                if app.textFields.firstMatch.waitForExistence(timeout: 2) {
                    // FTP field
                    let ftpField = app.textFields.element(boundBy: 0)
                    ftpField.tap()
                    ftpField.typeText("200")
                    
                    // Tap Next or Done to proceed through onboarding
                    if app.buttons["Next"].exists {
                        app.buttons["Next"].tap()
                    }
                    
                    // Continue through remaining onboarding steps
                    var attempts = 0
                    while app.buttons["Next"].exists && attempts < 5 {
                        app.buttons["Next"].tap()
                        attempts += 1
                        sleep(1)
                    }
                    
                    // Tap Done if it exists
                    if app.buttons["Done"].exists {
                        app.buttons["Done"].tap()
                    }
                }
            }
        }
        
        // Wait for main navigation view
        let mainNav = app.otherElements["mainNavigationView"]
        XCTAssertTrue(mainNav.waitForExistence(timeout: 5), "Main navigation should appear after onboarding")
        
        // Look for "My Workouts" navigation link
        let myWorkoutsLink = app.buttons["My Workouts"]
        XCTAssertTrue(myWorkoutsLink.waitForExistence(timeout: 2), "My Workouts link should be visible")
        
        // Tap to navigate to workouts list
        myWorkoutsLink.tap()
        
        // Verify we're on the workouts list screen
        let workoutsTitle = app.navigationBars["My Workouts"]
        XCTAssertTrue(workoutsTitle.waitForExistence(timeout: 2), "Workouts list navigation bar should appear")
    }
    
    func testWorkoutFilterSegmentedControl() throws {
        // Navigate to workouts list
        try testNavigateToWorkoutsList()
        
        // Check for filter segmented control
        let filterControl = app.segmentedControls.firstMatch
        XCTAssertTrue(filterControl.exists, "Filter segmented control should exist")
        
        // Verify filter options exist
        XCTAssertTrue(filterControl.buttons["All"].exists, "All filter should exist")
        XCTAssertTrue(filterControl.buttons["Scheduled"].exists, "Scheduled filter should exist")
        XCTAssertTrue(filterControl.buttons["Completed"].exists, "Completed filter should exist")
        XCTAssertTrue(filterControl.buttons["Skipped"].exists, "Skipped filter should exist")
    }
}
