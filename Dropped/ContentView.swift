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
            .accessibilityIdentifier("mainNavigationView")
        } else {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .accessibilityIdentifier("onboardingView")
        }
    }
}

#Preview {
    ContentView()
}
