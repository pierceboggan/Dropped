//  WorkoutGeneratorReviewView.swift
//  Dropped
//
//  SwiftUI view for reviewing and accepting a generated workout.
//
//  - Wraps the existing WorkoutDetailView for a consistent, rich display.
//  - Provides accessible Accept and Regenerate buttons with clear feedback.
//  - Designed for a smooth, visually appealing user experience.
//
//  Edge Cases: Handles missing/invalid workout data, disables actions when busy.
//  Limitations: Assumes generated workout can be parsed into a Workout model.

import SwiftUI

/// View for reviewing and accepting a generated workout.
/// - Displays the workout details and provides accept/regenerate actions.
struct WorkoutGeneratorReviewView: View {
    @ObservedObject var viewModel: WorkoutGeneratorViewModel
    var onRegenerate: (() -> Void)?
    var onAccept: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if let workout = viewModel.generatedWorkout, let parsed = parseWorkoutSafely(json: workout, viewModel: viewModel) {
                // Show the detailed workout view
                WorkoutDetailView(workout: parsed)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.bottom, 16)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                    Text("Could not display workout details.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            HStack(spacing: 16) {
                Button(action: {
                    onRegenerate?()
                }) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Regenerate workout")
                .disabled(viewModel.isLoading)

                Button(action: {
                    viewModel.acceptWorkout()
                    onAccept?()
                }) {
                    Label("Accept", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .accessibilityLabel("Accept workout")
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
        .padding()
        .animation(.spring(), value: viewModel.generatedWorkout)
    }

    /// Safely parses a workout JSON string, falling back to ViewModel's parsing logic
    /// - Parameters:
    ///   - json: JSON string from the AI service
    ///   - viewModel: The view model to use for fallback parsing
    /// - Returns: A parsed Workout object if successful, nil otherwise
    private func parseWorkoutSafely(json: String, viewModel: WorkoutGeneratorViewModel) -> Workout? {
        // First, try the original JSON parsing approach
        if let data = Data(json.utf8),
           let workout = try? JSONDecoder().decode(Workout.self, from: data) {
            return workout
        }
        
        // Fall back to the view model's parsing logic (which includes demo workouts)
        return viewModel.parseWorkout(from: json)
    }

    /// Parses a JSON string into a Workout model
    /// - Throws: DecodingError if the JSON is invalid
    static func parseWorkout(json: String) throws -> Workout {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(Workout.self, from: data)
    }
}
