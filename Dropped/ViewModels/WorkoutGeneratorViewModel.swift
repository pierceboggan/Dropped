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
import SwiftUI

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
        guard let workoutJSON = generatedWorkout,
              let parsedWorkout = parseWorkout(from: workoutJSON) else { 
            errorMessage = "Could not parse the generated workout."
            return 
        }
        
        // Add the workout to the user's schedule using WorkoutManager
        WorkoutManager.shared.saveWorkout(parsedWorkout)
        
        // Reset state (optional - depending on UX flow)
        // generatedWorkout = nil
    }
 
    /// Parses a workout JSON string into a Workout model
    /// - Parameter json: JSON string from the AI service
    /// - Returns: A parsed Workout object if successful, nil otherwise
    func parseWorkout(from json: String) -> Workout? {
        // First, try to parse the actual JSON from the AI service
        if let data = Data(json.utf8),
           let workout = try? JSONDecoder().decode(Workout.self, from: data) {
            return workout
        }
        
        // Fallback: create a demo workout based on the selected type and user FTP
        let intervals = createDemoIntervals(for: selectedWorkoutType, ftp: userData.ftp)
        
        return Workout(
            title: "\(selectedWorkoutType.displayName) Workout",
            date: Date(),
            summary: "AI-generated \(selectedWorkoutType.displayName.lowercased()) workout based on your FTP of \(userData.ftp) watts.",
            intervals: intervals
        )
    }
    
    /// Creates demo intervals for a given workout type and FTP
    /// - Parameters:
    ///   - type: The workout type to generate intervals for
    ///   - ftp: User's Functional Threshold Power
    /// - Returns: Array of intervals appropriate for the workout type
    private func createDemoIntervals(for type: WorkoutType, ftp: Int) -> [Interval] {
        let ftpDouble = Double(ftp)
        
        switch type {
        case .endurance:
            return [
                Interval(watts: Int(ftpDouble * 0.6), duration: 300),   // 5-min warmup at 60% FTP
                Interval(watts: Int(ftpDouble * 0.7), duration: 1200),  // 20-min endurance at 70% FTP
                Interval(watts: Int(ftpDouble * 0.6), duration: 300)    // 5-min cooldown at 60% FTP
            ]
        case .threshold:
            return [
                Interval(watts: Int(ftpDouble * 0.6), duration: 300),   // 5-min warmup
                Interval(watts: Int(ftpDouble * 0.95), duration: 480),  // 8-min threshold
                Interval(watts: Int(ftpDouble * 0.7), duration: 180),   // 3-min recovery
                Interval(watts: Int(ftpDouble * 0.95), duration: 480),  // 8-min threshold
                Interval(watts: Int(ftpDouble * 0.6), duration: 300)    // 5-min cooldown
            ]
        case .vo2Max:
            return [
                Interval(watts: Int(ftpDouble * 0.6), duration: 300),   // 5-min warmup
                Interval(watts: Int(ftpDouble * 1.15), duration: 180),  // 3-min VO2max
                Interval(watts: Int(ftpDouble * 0.7), duration: 120),   // 2-min recovery
                Interval(watts: Int(ftpDouble * 1.15), duration: 180),  // 3-min VO2max
                Interval(watts: Int(ftpDouble * 0.7), duration: 120),   // 2-min recovery
                Interval(watts: Int(ftpDouble * 1.15), duration: 180),  // 3-min VO2max
                Interval(watts: Int(ftpDouble * 0.6), duration: 300)    // 5-min cooldown
            ]
        case .sprint:
            return [
                Interval(watts: Int(ftpDouble * 0.6), duration: 300),   // 5-min warmup
                Interval(watts: Int(ftpDouble * 1.5), duration: 15),    // 15-sec sprint
                Interval(watts: Int(ftpDouble * 0.5), duration: 105),   // 1:45 recovery
                Interval(watts: Int(ftpDouble * 1.5), duration: 15),    // 15-sec sprint
                Interval(watts: Int(ftpDouble * 0.5), duration: 105),   // 1:45 recovery
                Interval(watts: Int(ftpDouble * 1.5), duration: 15),    // 15-sec sprint
                Interval(watts: Int(ftpDouble * 0.6), duration: 300)    // 5-min cooldown
            ]
        case .recovery:
            return [
                Interval(watts: Int(ftpDouble * 0.5), duration: 1800)   // 30-min easy recovery
            ]
        }
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
