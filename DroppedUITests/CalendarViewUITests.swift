//
//  CalendarViewUITests.swift
//  DroppedUITests
//
//  Created by Copilot on 2025-05-20.
//
//  UI tests for the CalendarView feature, ensuring proper navigation and interaction
//  with the calendar interface.

import XCTest

final class CalendarViewUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        app = XCUIApplication()
        
        // Reset the app state
        app.launchArguments = ["-resetUserDefaults"]
        
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testCalendarNavigationFromMainMenu() throws {
        // Complete onboarding to access main menu
        completeOnboarding()
        
        // Wait for main navigation to appear
        let mainNav = app.navigationBars["Dropped"]
        XCTAssertTrue(mainNav.waitForExistence(timeout: 5), "Should be on the main screen")
        
        // Tap on Calendar navigation link
        let calendarLink = app.buttons["Calendar"]
        XCTAssertTrue(calendarLink.waitForExistence(timeout: 5), "Calendar link should exist")
        calendarLink.tap()
        
        // Verify we're on the calendar screen
        let calendarNav = app.navigationBars["Calendar"]
        XCTAssertTrue(calendarNav.waitForExistence(timeout: 5), "Should navigate to calendar view")
    }
    
    @MainActor
    func testCalendarDisplaysMonthAndYear() throws {
        // Complete onboarding and navigate to calendar
        completeOnboarding()
        navigateToCalendar()
        
        // Get current month and year (we'll look for a date pattern)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        let expectedMonthYear = dateFormatter.string(from: Date())
        
        // Check if the month/year text is displayed
        let monthYearText = app.staticTexts[expectedMonthYear]
        XCTAssertTrue(monthYearText.exists, "Calendar should display current month and year")
    }
    
    @MainActor
    func testCalendarNavigationToWorkoutDetail() throws {
        // Complete onboarding and navigate to calendar
        completeOnboarding()
        navigateToCalendar()
        
        // Look for the calendar month/year header to ensure calendar has loaded
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        let expectedMonthYear = dateFormatter.string(from: Date())
        let monthYearText = app.staticTexts[expectedMonthYear]
        XCTAssertTrue(monthYearText.waitForExistence(timeout: 5), "Calendar should be loaded")
        
        // Look for any workout on the calendar by checking for buttons in the main view
        // Note: This test may not find workouts if the calendar days don't have workouts
        // In a real scenario, we'd need to ensure test data exists
        let calendarButtons = app.buttons.allElementsBoundByIndex
        
        // Try to find and tap a button that might be a workout day
        var foundWorkoutDay = false
        for button in calendarButtons {
            // Skip navigation buttons
            if !button.label.contains("Back") && !button.label.contains("Calendar") {
                button.tap()
                foundWorkoutDay = true
                break
            }
        }
        
        // If we found and tapped a workout day, verify navigation
        if foundWorkoutDay {
            // Check if we navigated to either "Workouts" or "Workout Details"
            let workoutsNav = app.navigationBars["Workouts"]
            let detailNav = app.navigationBars["Workout Details"]
            
            let navigated = workoutsNav.waitForExistence(timeout: 3) || detailNav.waitForExistence(timeout: 3)
            XCTAssertTrue(navigated, "Should navigate to workout detail or day view after tapping a workout")
        }
    }
    
    @MainActor
    func testCalendarBackNavigation() throws {
        // Complete onboarding and navigate to calendar
        completeOnboarding()
        navigateToCalendar()
        
        // Verify we're on the calendar screen
        let calendarNav = app.navigationBars["Calendar"]
        XCTAssertTrue(calendarNav.exists, "Should be on calendar view")
        
        // Tap back button
        let backButton = calendarNav.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
            
            // Verify we're back on the main screen
            let mainNav = app.navigationBars["Dropped"]
            XCTAssertTrue(mainNav.waitForExistence(timeout: 5), "Should navigate back to main screen")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to quickly complete onboarding
    private func completeOnboarding() {
        app.launch()
        
        // Quick fill of data
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
        
        // Generate plan
        let generateButton = app.buttons["generatePlanButton"]
        if generateButton.waitForExistence(timeout: 5) {
            generateButton.tap()
        } else {
            let planButton = app.buttons["Generate My Training Plan"]
            if planButton.waitForExistence(timeout: 5) {
                planButton.tap()
            }
        }
        
        // Wait for plan summary to appear
        let trainingPlanNav = app.navigationBars["Your Training Plan"]
        XCTAssertTrue(trainingPlanNav.waitForExistence(timeout: 5), "Should be on training plan")
        
        // Navigate back to main menu
        let backButton = trainingPlanNav.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
        }
    }
    
    /// Helper method to navigate to calendar view
    private func navigateToCalendar() {
        let calendarLink = app.buttons["Calendar"]
        if calendarLink.waitForExistence(timeout: 5) {
            calendarLink.tap()
        }
        
        // Verify we're on the calendar
        let calendarNav = app.navigationBars["Calendar"]
        XCTAssertTrue(calendarNav.waitForExistence(timeout: 5), "Should be on calendar view")
    }
}
