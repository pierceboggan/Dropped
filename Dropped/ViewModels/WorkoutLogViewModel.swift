//
//  WorkoutLogViewModel.swift
//  Dropped
//
//  Form-state owner for the "Mark workout complete" sheet. The view model
//  exposes editable fields backed by the optional metrics on `WorkoutLog`,
//  validates RPE, and bridges Save / Delete actions back to the
//  `WorkoutManager` persistence layer.
//

import Foundation
import SwiftUI

/// Drives the workout-completion sheet.
///
/// The view model is initialized with the `Workout` being completed and an
/// optional existing `WorkoutLog`. When an existing log is provided the form
/// pre-populates with its values and `isEditing` becomes `true` so the UI can
/// surface "Update" + "Remove Log" affordances instead of plain "Save".
@MainActor
final class WorkoutLogViewModel: ObservableObject {
    /// The workout the rider is logging a completion for.
    let workout: Workout

    /// Existing log id when editing an entry, otherwise `nil` (new log).
    private let existingLogID: UUID?

    /// `true` when the rider opened the sheet to edit an existing log.
    var isEditing: Bool { existingLogID != nil }

    // MARK: - Form fields

    @Published var completedAt: Date
    @Published var perceivedExertion: Int
    @Published var includeAveragePower: Bool
    @Published var averagePowerText: String
    @Published var includeAverageHeartRate: Bool
    @Published var averageHeartRateText: String
    @Published var includeDurationOverride: Bool
    /// Duration override expressed in **minutes** for rider-friendly entry.
    @Published var durationOverrideMinutesText: String
    @Published var notes: String

    // MARK: - Init

    init(workout: Workout, existingLog: WorkoutLog? = nil) {
        self.workout = workout
        self.existingLogID = existingLog?.id

        if let log = existingLog {
            self.completedAt = log.completedAt
            self.perceivedExertion = log.perceivedExertion
            self.includeAveragePower = log.averagePower != nil
            self.averagePowerText = log.averagePower.map(String.init) ?? ""
            self.includeAverageHeartRate = log.averageHeartRate != nil
            self.averageHeartRateText = log.averageHeartRate.map(String.init) ?? ""
            self.includeDurationOverride = log.durationOverride != nil
            self.durationOverrideMinutesText = log.durationOverride.map { String(Int(($0 / 60).rounded())) } ?? ""
            self.notes = log.notes ?? ""
        } else {
            self.completedAt = Date()
            self.perceivedExertion = 5
            self.includeAveragePower = false
            self.averagePowerText = ""
            self.includeAverageHeartRate = false
            self.averageHeartRateText = ""
            self.includeDurationOverride = false
            self.durationOverrideMinutesText = String(Int((workout.totalDuration / 60).rounded()))
            self.notes = ""
        }
    }

    /// RPE bounds exposed to the view layer.
    var rpeRange: ClosedRange<Int> { WorkoutLog.rpeRange }

    /// Save button label changes copy when editing vs. creating.
    var saveButtonTitle: String { isEditing ? "Update Log" : "Save Log" }

    /// Builds a `WorkoutLog` from the current form state and persists it.
    /// Returns the saved log so the caller can refresh local UI state.
    @discardableResult
    func save(manager: WorkoutManager = .shared,
              userDataManager: UserDataManager = .shared) -> WorkoutLog {
        let log = WorkoutLog(
            id: existingLogID ?? UUID(),
            workoutID: workout.id,
            completedAt: completedAt,
            perceivedExertion: perceivedExertion,
            averagePower: includeAveragePower ? Int(averagePowerText.trimmingCharacters(in: .whitespaces)) : nil,
            averageHeartRate: includeAverageHeartRate ? Int(averageHeartRateText.trimmingCharacters(in: .whitespaces)) : nil,
            durationOverride: includeDurationOverride ? parsedDurationSeconds() : nil,
            notes: notes,
            userDataSnapshot: userDataManager.loadUserData()
        )
        manager.saveLog(log)
        return log
    }

    /// Removes any logs associated with this workout. Used by "Remove Log".
    func deleteLog(manager: WorkoutManager = .shared) {
        manager.deleteLog(forWorkoutID: workout.id)
    }

    // MARK: - Helpers

    private func parsedDurationSeconds() -> TimeInterval? {
        let trimmed = durationOverrideMinutesText.trimmingCharacters(in: .whitespaces)
        guard let minutes = Double(trimmed), minutes > 0 else { return nil }
        return minutes * 60.0
    }
}
