//
//  DroppedApp.swift
//  Dropped
//
//  Created by Pierce Boggan on 4/25/25.
//

import SwiftUI

/// Observable object that manages the app's theme preference
/// 
/// This class monitors changes to the user's theme preference and updates
/// the app's color scheme accordingly. It observes UserDataManager for theme changes.
class ThemeManager: ObservableObject {
    @Published var selectedTheme: AppTheme = .system
    
    init() {
        // Load the user's theme preference
        let userData = UserDataManager.shared.loadUserData()
        selectedTheme = AppTheme(rawValue: userData.theme) ?? .system
        
        // Listen for theme changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ThemeDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let userData = UserDataManager.shared.loadUserData()
            self?.selectedTheme = AppTheme(rawValue: userData.theme) ?? .system
        }
    }
}

@main
struct DroppedApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    init() {
        // Setup for UI testing
        if CommandLine.arguments.contains("-resetUserDefaults") {
            // Reset UserDefaults for testing
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            print("Reset UserDefaults for UI testing")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.selectedTheme.colorScheme)
        }
    }
}
