import Foundation

/// ViewModel for the AI-powered workout generator screen.
///
/// It owns generator state, converts API responses into app workouts, and saves
/// accepted workouts through `WorkoutManager`.
final class WorkoutGeneratorViewModel: ObservableObject {
    /// The currently selected workout type.
    @Published var selectedWorkoutType: WorkoutType = .endurance
    /// The generated workout ready for review.
    @Published var generatedWorkout: Workout?
    /// Loading state for API requests.
    @Published var isLoading: Bool = false
    /// Error message for UI display.
    @Published var errorMessage: String?

    private let aiGenerator: AIWorkoutGenerator
    private let userData: UserData
    private let workoutManager: WorkoutManager

    /// Initializes the generator view model.
    /// - Parameters:
    ///   - aiGenerator: Service for AI workout generation.
    ///   - userData: User profile data used for FTP-based generation.
    ///   - workoutManager: Storage manager used when accepting workouts.
    init(aiGenerator: AIWorkoutGenerator, userData: UserData, workoutManager: WorkoutManager = .shared) {
        self.aiGenerator = aiGenerator
        self.userData = userData
        self.workoutManager = workoutManager
    }

    /// Triggers AI workout generation based on the selected type and user FTP.
    func generateWorkout() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        generatedWorkout = nil

        aiGenerator.generateWorkout(ftp: userData.ftp, type: selectedWorkoutType) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let workout):
                    self?.generatedWorkout = workout
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = Self.errorDescription(error)
                }
                self?.isLoading = false
            }
        }
    }

    /// Accepts the generated workout and adds it to the user's schedule.
    /// - Returns: `true` when a workout was saved; otherwise `false` and an error is set.
    @discardableResult
    func acceptWorkout() -> Bool {
        guard let workout = generatedWorkout else {
            errorMessage = "Generate a workout before accepting it."
            return false
        }

        workoutManager.saveWorkout(workout)
        workoutManager.saveWorkoutDay(WorkoutDay(userData: userData, workout: workout))
        errorMessage = nil
        return true
    }

    /// Returns a user-friendly error message.
    private static func errorDescription(_ error: AIWorkoutGeneratorError) -> String {
        switch error {
        case .missingAPIKey:
            return "Add an OpenAI API key before generating workouts."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from AI service."
        case .invalidWorkout:
            return "The AI service returned a workout this app could not read."
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}
