//  WorkoutGeneratorView.swift
//  Dropped
//
//  SwiftUI view for the AI-powered workout generator feature.
//
//  - Allows users to select a workout type and generate a workout using AI.
//  - Displays loading state, error messages, and the generated workout preview.
//  - Designed to be accessible and visually consistent with the app.
//
//  Edge Cases: Handles loading and error states, disables generate button when busy.
//  Limitations: Currently displays generated workout as raw JSON; future versions should show a structured review UI.

import SwiftUI

/// Main view for the AI-powered workout generator feature.
/// - Displays workout type options, generate button, and result preview.
struct WorkoutGeneratorView: View {
    @StateObject var viewModel: WorkoutGeneratorViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Select Workout Type")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                // Workout type selection
                VStack(spacing: 12) {
                    ForEach(WorkoutType.allCases) { type in
                        Button(action: {
                            viewModel.selectedWorkoutType = type
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.displayName)
                                        .font(.body)
                                        .bold()
                                    Text(type.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if viewModel.selectedWorkoutType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(type.displayName): \(type.description)")
                            .accessibilityAddTraits(viewModel.selectedWorkoutType == type ? .isSelected : [])
                        }
                    }
                }

                // Generate button
                Button(action: {
                    viewModel.generateWorkout()
                }) {
                    ZStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Generate Workout")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .disabled(viewModel.isLoading)
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Generate Workout")

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .accessibilityLabel("Error: \(error)")
                }

                // Generated workout preview (raw JSON for now)
                if let workout = viewModel.generatedWorkout {
                    ScrollView {
                        Text(workout)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .accessibilityLabel("Generated workout preview")
                    }
                    .frame(maxHeight: 200)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("AI Workout Generator")
        }
    }
}

// MARK: - Preview (not used in production)
// struct WorkoutGeneratorView_Previews: PreviewProvider {
//     static var previews: some View {
//         WorkoutGeneratorView(viewModel: WorkoutGeneratorViewModel(aiGenerator: AIWorkoutGenerator(apiKey: "test"), userData: UserData()))
//     }
// }
