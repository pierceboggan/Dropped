//  WorkoutDetailView.swift
//  Dropped
//
//  Created by Copilot on 2025-05-18.
//
//  This file defines the WorkoutDetailView, a SwiftUI view for displaying detailed information about a specific workout, including overview, intervals, and a power graph.
//
//  The view is designed for accessibility, supports both light and dark mode, and is visually consistent with the rest of the app.

import SwiftUI

/// A SwiftUI view that displays detailed information about a workout, including title, date, summary, intervals, and a power graph.
/// - Parameters:
///   - workout: The `Workout` model instance to display details for.
///
/// The view is accessible and visually consistent with the app's design language.
struct WorkoutDetailView: View {
    /// The workout to display
    let workout: Workout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Workout Overview Header
                WorkoutOverviewHeader(workout: workout)
                // TODO: Add intervals list and graph in later steps
            }
            .padding([.horizontal, .bottom])
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview (not included, see instructions)

// MARK: - Components (add at bottom of file as needed)

/// Header view for displaying the workout's title, date, and summary.
/// - Parameter workout: The workout to display.
private struct WorkoutOverviewHeader: View {
    let workout: Workout

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: workout.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workout.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("Workout title: \(workout.title)")

            Text(formattedDate)
                .font(.headline)
                .foregroundColor(.secondary)
                .accessibilityLabel("Date: \(formattedDate)")

            Text(workout.summary)
                .font(.body)
                .foregroundColor(.primary)
                .accessibilityLabel("Summary: \(workout.summary)")
        }
        .padding(.top)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }
}
