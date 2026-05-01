//
//  DroppedApp.swift
//  Dropped
//
//  Created by Pierce Boggan on 4/25/25.
//

import SwiftUI

@main
struct DroppedApp: App {
    init() {
        // Setup for UI testing
        if CommandLine.arguments.contains("-resetUserDefaults") {
            UserDataManager.shared.resetUserData()
            WorkoutManager.shared.resetWorkouts()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
