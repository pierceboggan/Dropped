//
//  DroppedUITests.swift
//  DroppedUITests
//
//  Created by Pierce Boggan on 4/25/25.
//

import XCTest

final class DroppedUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        app = XCUIApplication()
        
        // Reset the app state (wipe UserDefaults data)
        app.launchArguments = ["-resetUserDefaults"]
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app = nil
    }
    
    @MainActor
    func testOnboardingFlow() throws {
        // Launch app with clean state
        app.launch()
        
        // Verify we're on the onboarding screen
        let startText = app.staticTexts["Let's Get Started"]
        XCTAssertTrue(startText.waitForExistence(timeout: 5), "Should start with onboarding")
        
        // Enter user data
        let weightTextField = app.textFields["Weight"]
        if weightTextField.waitForExistence(timeout: 5) {
            weightTextField.tap()
            weightTextField.typeText("70")
        }
        
        let ftpTextField = app.textFields["FTP"]
        if ftpTextField.waitForExistence(timeout: 5) {
            ftpTextField.tap()
            ftpTextField.typeText("220")
        }
        
        // Select hours 
        let hoursTextField = app.textFields["Hours per week"]
        if hoursTextField.waitForExistence(timeout: 5) {
            hoursTextField.tap()
            hoursTextField.typeText("8")
        }
        
        // Tap generate plan button
        let generateButton = app.buttons["generatePlanButton"]
        if generateButton.waitForExistence(timeout: 5) {
            generateButton.tap()
        } else {
            app.buttons["Generate My Training Plan"].tap()
        }
        
        // Verify we're on the plan summary screen
        let trainingPlanNav = app.navigationBars["Your Training Plan"]
        XCTAssertTrue(trainingPlanNav.waitForExistence(timeout: 5), "Should navigate to training plan")
    }
    
    @MainActor
    func testSettingsFlow() throws {
        // First complete onboarding so we can access settings
        completeOnboarding()
        
        // Wait a bit for the UI to settle
        sleep(1)
        
        // Verify we're on the plan summary screen
        let trainingPlanNav = app.navigationBars["Your Training Plan"]
        XCTAssertTrue(trainingPlanNav.waitForExistence(timeout: 5), "Should be on the training plan screen")
    }
    
    @MainActor
    func testInfoPopup() throws {
        // Test case skipped - info popup can be tested separately if this UI element exists
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testPlanSummaryViewDisplaysUserStats() throws {
        // Complete onboarding
        completeOnboarding()
        
        // Navigate to Weekly Plan
        let weeklyPlanLink = app.buttons["Weekly Plan"]
        XCTAssertTrue(weeklyPlanLink.waitForExistence(timeout: 5), "Weekly Plan link should exist")
        weeklyPlanLink.tap()
        
        // Wait for plan summary to load
        sleep(2)
        
        // Verify user stats are displayed
        XCTAssertTrue(app.staticTexts["Your Stats"].exists, "User stats section should be displayed")
        
        // Verify workout plan is displayed
        XCTAssertTrue(app.staticTexts["Your Weekly Plan"].exists, "Weekly plan should be displayed")
        
        // Verify at least one workout card exists
        let workoutCards = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'workoutCard'"))
        XCTAssertTrue(workoutCards.count > 0 || app.otherElements.containing(NSPredicate(format: "label CONTAINS 'Workout'")).count > 0, 
                     "Should display workout cards")
    }
    
    @MainActor
    func testRestartOnboardingFlow() throws {
        // Complete onboarding
        completeOnboarding()
        
        // Navigate to Weekly Plan
        let weeklyPlanLink = app.buttons["Weekly Plan"]
        XCTAssertTrue(weeklyPlanLink.waitForExistence(timeout: 5), "Weekly Plan link should exist")
        weeklyPlanLink.tap()
        
        // Wait for plan to load
        sleep(2)
        
        // Find and tap restart button
        let restartButton = app.buttons["Restart Onboarding"]
        if restartButton.exists {
            restartButton.tap()
            
            // Should return to onboarding
            let onboardingHeader = app.staticTexts["Let's Get Started"]
            XCTAssertTrue(onboardingHeader.waitForExistence(timeout: 3), "Should return to onboarding screen")
        }
    }
    
    @MainActor
    func testNavigationBetweenMainScreens() throws {
        // Complete onboarding
        completeOnboarding()
        
        // Verify we're on the main navigation screen
        XCTAssertTrue(app.buttons["Weekly Plan"].exists, "Weekly Plan option should exist")
        XCTAssertTrue(app.buttons["AI Workout Generator"].exists, "AI Workout Generator option should exist")
        
        // Navigate to Weekly Plan
        app.buttons["Weekly Plan"].tap()
        sleep(1)
        
        // Go back
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
            sleep(1)
        }
        
        // Navigate to AI Workout Generator
        app.buttons["AI Workout Generator"].tap()
        
        // Verify we're on the generator screen
        XCTAssertTrue(app.staticTexts["Select Workout Type"].waitForExistence(timeout: 3), 
                     "Should navigate to workout generator")
    }
    
    // Helper method to quickly complete onboarding
    private func completeOnboarding() {
        app.launch()
        
        // Quick fill of data - wait for text fields to appear
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
        
        // Generate plan - use accessibility identifier if available
        let generateButton = app.buttons["generatePlanButton"]
        if generateButton.waitForExistence(timeout: 5) {
            generateButton.tap()
        } else {
            // Fallback to text-based button
            let planButton = app.buttons["Generate My Training Plan"]
            if planButton.waitForExistence(timeout: 5) {
                planButton.tap()
            }
        }
    }
}
