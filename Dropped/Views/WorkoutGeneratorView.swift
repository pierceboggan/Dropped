import SwiftUI

/// Main view for selecting an AI workout type, generating a workout, and reviewing the result.
struct WorkoutGeneratorView: View {
    @StateObject var viewModel: WorkoutGeneratorViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Select Workout Type")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                workoutTypeSelection
                generateButton

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .accessibilityLabel("Error: \(error)")
                }

                if viewModel.generatedWorkout != nil {
                    WorkoutGeneratorReviewView(
                        viewModel: viewModel,
                        onRegenerate: viewModel.generateWorkout
                    )
                }
            }
            .padding()
        }
        .navigationTitle("AI Workout Generator")
    }

    /// Selection controls for available workout types.
    private var workoutTypeSelection: some View {
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
                .buttonStyle(.plain)
            }
        }
    }

    /// Button that starts workout generation and reflects loading state.
    private var generateButton: some View {
        Button(action: viewModel.generateWorkout) {
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
    }
}
