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
            NavigationView {
                List {
                    NavigationLink(destination: PlanSummaryView(hasCompletedOnboarding: $hasCompletedOnboarding)) {
                        Label("Weekly Plan", systemImage: "calendar")
                    }
                }
                .navigationTitle("Dropped")
            }
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
