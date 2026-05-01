import SwiftUI

/// Review surface for accepting or regenerating an AI-created workout.
struct WorkoutGeneratorReviewView: View {
    @ObservedObject var viewModel: WorkoutGeneratorViewModel
    var onRegenerate: (() -> Void)?
    var onAccept: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if let workout = viewModel.generatedWorkout {
                WorkoutDetailView(workout: workout)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.bottom, 16)
            } else {
                unavailableWorkoutView
            }

            actionButtons
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
        .padding()
        .animation(.spring(), value: viewModel.generatedWorkout?.id)
    }

    /// Fallback content shown when there is no workout to review.
    private var unavailableWorkoutView: some View {
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

    /// Review actions for retrying generation or saving the workout.
    private var actionButtons: some View {
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
                if viewModel.acceptWorkout() {
                    onAccept?()
                }
            }) {
                Label("Accept", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .accessibilityLabel("Accept workout")
            .disabled(viewModel.isLoading || viewModel.generatedWorkout == nil)
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
}
