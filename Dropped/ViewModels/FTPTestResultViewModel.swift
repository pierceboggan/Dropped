//
//  FTPTestResultViewModel.swift
//  Dropped
//

import Foundation
import SwiftUI

/// Drives the post-test result entry flow: takes the rider's raw input,
/// computes a new FTP, and on confirm persists the updated profile and
/// marks the source workout completed.
@MainActor
final class FTPTestResultViewModel: ObservableObject {
    @Published var inputWatts: String = ""
    @Published var inputError: String? = nil

    let testType: FTPTestType
    let sourceWorkout: Workout?
    let previousFTP: Int

    private let userDataManager: UserDataManager
    private let workoutManager: WorkoutManager

    init(
        testType: FTPTestType,
        sourceWorkout: Workout? = nil,
        userDataManager: UserDataManager = .shared,
        workoutManager: WorkoutManager = .shared
    ) {
        self.testType = testType
        self.sourceWorkout = sourceWorkout
        self.userDataManager = userDataManager
        self.workoutManager = workoutManager
        self.previousFTP = userDataManager.loadUserData().ftp
    }

    /// Parsed watt input, or nil if invalid.
    var parsedWatts: Int? {
        guard let value = Int(inputWatts.trimmingCharacters(in: .whitespaces)),
              value > 0 else { return nil }
        return value
    }

    /// New FTP given the current input, or nil when input is invalid.
    var newFTP: Int? {
        guard let watts = parsedWatts else { return nil }
        return FTPCalculator.ftp(forTest: testType, inputWatts: watts)
    }

    /// FTP delta vs. the previous value (positive = improvement). Nil when no valid input.
    var delta: Int? {
        guard let new = newFTP else { return nil }
        return new - previousFTP
    }

    var canConfirm: Bool { newFTP != nil }

    func validate() {
        if parsedWatts == nil {
            inputError = "Enter a positive whole number of watts."
        } else {
            inputError = nil
        }
    }

    /// Persist the new FTP into the user profile and, if applicable, mark the
    /// source workout completed. Returns the new FTP on success.
    @discardableResult
    func confirm() -> Int? {
        validate()
        guard let new = newFTP else { return nil }

        var current = userDataManager.loadUserData()
        current.ftp = new
        userDataManager.saveUserData(current)

        if let source = sourceWorkout {
            let completed = Workout(
                id: source.id,
                title: source.title,
                date: source.date,
                summary: source.summary,
                intervals: source.intervals,
                status: .completed,
                testKind: source.testKind
            )
            workoutManager.saveWorkout(completed)
        }

        return new
    }
}
