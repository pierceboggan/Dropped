//  WorkoutGeneratorViewModel.swift
//  Dropped
//
//  ViewModel for the AI-powered workout generator feature.
//
//  - Manages state for workout type selection, workout generation, loading, and error handling.
//  - Coordinates with AIWorkoutGenerator to fetch structured workouts from OpenAI.
//  - Handles user acceptance of generated workouts.
//
//  Edge Cases: Handles API/network errors, prevents duplicate requests, and ensures valid state transitions.
//  Limitations: Assumes UserData and AIWorkoutGenerator are correctly initialized and available.

import Foundation

/// ViewModel for the AI-powered workout generator screen.
/// - Publishes state for UI binding.
/// - Handles workout generation and acceptance logic.
final class WorkoutGeneratorViewModel: ObservableObject {
    /// The currently selected workout type
    @Published var selectedWorkoutType: WorkoutType = .endurance
    /// The generated workout (as JSON string for now)
    @Published var generatedWorkout: String?
    /// Loading state for API requests
    @Published var isLoading: Bool = false
    /// Error message for UI display
    @Published var errorMessage: String?

    private let aiGenerator: AIWorkoutGenerator
    private let userData: UserData

    /// Initialize with dependencies
    /// - Parameters:
    ///   - aiGenerator: Service for AI workout generation
    ///   - userData: User data model (must provide FTP)
    init(aiGenerator: AIWorkoutGenerator, userData: UserData) {
        self.aiGenerator = aiGenerator
        self.userData = userData
    }

    /// Triggers AI workout generation based on selected type and user FTP
    func generateWorkout() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        generatedWorkout = nil
        aiGenerator.generateWorkout(ftp: userData.ftp, type: selectedWorkoutType) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let workout):
                    self?.generatedWorkout = workout
                case .failure(let error):
                    self?.errorMessage = Self.errorDescription(error)
                }
            }
        }
    }

    /// Accepts the generated workout and adds it to the user's schedule
    func acceptWorkout() {
        guard let workoutJSON = generatedWorkout else { return }
        // TODO: Parse JSON and add to userData (requires Workout model integration)
        // userData.addWorkoutToSchedule(parsedWorkout)
    }

    /// Returns a user-friendly error message
    private static func errorDescription(_ error: AIWorkoutGeneratorError) -> String {
        switch error {
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .invalidResponse: return "Invalid response from AI service."
        case .apiError(let msg): return "API error: \(msg)"
        }
    }
}
