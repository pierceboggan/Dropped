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
                    NavigationLink(destination: {
                        // Inject dependencies for the generator
                        let userData = UserDataManager.shared.loadUserData()
                        let aiGenerator = AIWorkoutGenerator(apiKey: "YOUR_OPENAI_API_KEY")
                        let viewModel = WorkoutGeneratorViewModel(aiGenerator: aiGenerator, userData: userData)
                        WorkoutGeneratorView(viewModel: viewModel)
                    }) {
                        Label("AI Workout Generator", systemImage: "bolt.circle")
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
