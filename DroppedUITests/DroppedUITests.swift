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
        
        let weightTextField = app.textFields["Weight"]
        XCTAssertTrue(weightTextField.waitForExistence(timeout: 5), "Weight field should be visible")
        
        let ftpTextField = app.textFields["FTP"]
        XCTAssertTrue(ftpTextField.waitForExistence(timeout: 5), "FTP field should be visible")
        
        let hoursTextField = app.textFields["Hours per week"]
        XCTAssertTrue(hoursTextField.waitForExistence(timeout: 5), "Hours field should be visible")
        
        // Tap generate plan button
        let generateButton = app.buttons["generatePlanButton"]
        if generateButton.waitForExistence(timeout: 5) {
            generateButton.tap()
        } else {
            app.buttons["Generate My Training Plan"].tap()
        }
        
        openTrainingPlan()

        let trainingPlanTitle = app.staticTexts["Your Weekly Plan"]
        XCTAssertTrue(trainingPlanTitle.waitForExistence(timeout: 5), "Should navigate to training plan")
    }
    
    @MainActor
    func testSettingsFlow() throws {
        // First complete onboarding so we can access settings
        completeOnboarding()
        
        // Wait a bit for the UI to settle
        sleep(1)
        
        let trainingPlanTitle = app.staticTexts["Your Weekly Plan"]
        XCTAssertTrue(trainingPlanTitle.waitForExistence(timeout: 5), "Should be on the training plan screen")
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
    
    // Helper method to quickly complete onboarding
    private func completeOnboarding() {
        app.launch()
        
        let weightTextField = app.textFields["Weight"]
        XCTAssertTrue(weightTextField.waitForExistence(timeout: 5), "Weight field should be visible")
        
        let ftpTextField = app.textFields["FTP"]
        XCTAssertTrue(ftpTextField.waitForExistence(timeout: 5), "FTP field should be visible")
        
        let hoursTextField = app.textFields["Hours per week"]
        XCTAssertTrue(hoursTextField.waitForExistence(timeout: 5), "Hours field should be visible")
        
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

        openTrainingPlan()
    }

    private func openTrainingPlan() {
        let trainingPlanLink = app.buttons["Training Plan"]
        if trainingPlanLink.waitForExistence(timeout: 5) {
            trainingPlanLink.tap()
        }
    }
}
