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
        }
    }
}
