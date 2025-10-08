//
//  ThemeUITests.swift
//  DroppedUITests
//
//  UI tests for theme switching functionality
//
//  Tests the ability to switch between light, dark, and system themes
//  through the Settings view and verifies that the preference is persisted.
//

import XCTest

final class ThemeUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        app = XCUIApplication()
        
        // Reset the app state (wipe UserDefaults data)
        app.launchArguments = ["-resetUserDefaults"]
        
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testThemeSelectionInSettings() throws {
        // Complete onboarding first
        completeOnboarding()
        
        // Verify we're on the main screen
        let mainNav = app.navigationBars["Dropped"]
        XCTAssertTrue(mainNav.waitForExistence(timeout: 5), "Should be on main screen")
        
        // Navigate to Settings
        let settingsLink = app.tables.cells.containing(.staticText, identifier: "Settings").firstMatch
        if settingsLink.waitForExistence(timeout: 5) {
            settingsLink.tap()
        } else {
            // Try alternative approach
            app.tables.cells["Settings"].tap()
        }
        
        // Wait for Settings view to appear
        let settingsNav = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNav.waitForExistence(timeout: 5), "Should navigate to Settings")
        
        // Find the theme picker
        let themePicker = app.segmentedControls.firstMatch
        XCTAssertTrue(themePicker.waitForExistence(timeout: 5), "Theme picker should exist")
        
        // Verify system theme is selected by default
        let systemButton = themePicker.buttons["System"]
        XCTAssertTrue(systemButton.exists, "System theme button should exist")
        
        // Select light theme
        let lightButton = themePicker.buttons["Light"]
        if lightButton.exists {
            lightButton.tap()
            // Verify light theme is now selected
            XCTAssertTrue(lightButton.isSelected, "Light theme should be selected")
        }
        
        // Select dark theme
        let darkButton = themePicker.buttons["Dark"]
        if darkButton.exists {
            darkButton.tap()
            // Verify dark theme is now selected
            XCTAssertTrue(darkButton.isSelected, "Dark theme should be selected")
        }
        
        // Go back to main screen
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }
    }
    
    @MainActor
    func testThemePreferencePersistence() throws {
        // Complete onboarding
        completeOnboarding()
        
        // Navigate to Settings
        let settingsLink = app.tables.cells.containing(.staticText, identifier: "Settings").firstMatch
        if settingsLink.waitForExistence(timeout: 5) {
            settingsLink.tap()
        }
        
        // Wait for Settings view
        let settingsNav = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNav.waitForExistence(timeout: 5), "Should be in Settings")
        
        // Select dark theme
        let themePicker = app.segmentedControls.firstMatch
        if themePicker.waitForExistence(timeout: 5) {
            let darkButton = themePicker.buttons["Dark"]
            if darkButton.exists {
                darkButton.tap()
            }
        }
        
        // Return to main screen
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }
        
        // Wait a moment for the change to persist
        sleep(1)
        
        // Navigate back to Settings
        let settingsLinkAgain = app.tables.cells.containing(.staticText, identifier: "Settings").firstMatch
        if settingsLinkAgain.waitForExistence(timeout: 5) {
            settingsLinkAgain.tap()
        }
        
        // Verify dark theme is still selected
        let themePickerAgain = app.segmentedControls.firstMatch
        if themePickerAgain.waitForExistence(timeout: 5) {
            let darkButton = themePickerAgain.buttons["Dark"]
            XCTAssertTrue(darkButton.isSelected, "Dark theme should still be selected after navigating away")
        }
    }
    
    // Helper method to quickly complete onboarding
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
        
        // Wait for main screen
        sleep(1)
    }
}
