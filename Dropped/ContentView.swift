//
//  ContentView.swift
//  Dropped
//
//  Created by Pierce Boggan on 4/25/25.
//

import SwiftUI

struct ContentView: View {
    @State private var hasCompletedOnboarding = UserDataManager.shared.hasCompletedOnboarding()
    
    var body: some View {
        if hasCompletedOnboarding {
            PlanSummaryView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
}

#Preview {
    ContentView()
}
