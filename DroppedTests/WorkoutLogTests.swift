//
//  WorkoutLogTests.swift
//  DroppedTests
//
//  Unit tests covering the `WorkoutLog` model, its derived metrics, and the
//  `WorkoutManager` log persistence APIs.
//

import XCTest
@testable import Dropped

final class WorkoutLogTests: XCTestCase {
    override func setUpWithError() throws {
        UserDataManager.shared.resetUserData()
        WorkoutManager.shared.resetWorkouts()
    }

    override func tearDownWithError() throws {
        UserDataManager.shared.resetUserData()
        WorkoutManager.shared.resetWorkouts()
    }

    // MARK: - Model

    func testRPEIsClampedIntoSupportedRange() {
        let snapshot = UserData.defaultData

        let low = WorkoutLog(workoutID: UUID(), completedAt: Date(),
                             perceivedExertion: -3, userDataSnapshot: snapshot)
        XCTAssertEqual(low.perceivedExertion, WorkoutLog.rpeRange.lowerBound,
                       "RPE values below 1 should clamp to 1")

        let high = WorkoutLog(workoutID: UUID(), completedAt: Date(),
                              perceivedExertion: 42, userDataSnapshot: snapshot)
        XCTAssertEqual(high.perceivedExertion, WorkoutLog.rpeRange.upperBound,
                       "RPE values above 10 should clamp to 10")

        let valid = WorkoutLog(workoutID: UUID(), completedAt: Date(),
                               perceivedExertion: 7, userDataSnapshot: snapshot)
        XCTAssertEqual(valid.perceivedExertion, 7,
                       "Valid RPE values should be preserved")
    }

    func testNotesAreNormalized() {
        let snapshot = UserData.defaultData

        let blank = WorkoutLog(workoutID: UUID(), completedAt: Date(),
                               perceivedExertion: 5, notes: "   \n  ",
                               userDataSnapshot: snapshot)
        XCTAssertNil(blank.notes,
                     "Whitespace-only notes should normalize to nil")

        let trimmed = WorkoutLog(workoutID: UUID(), completedAt: Date(),
                                 perceivedExertion: 5, notes: "  felt great  ",
                                 userDataSnapshot: snapshot)
        XCTAssertEqual(trimmed.notes, "felt great",
                       "Notes should have surrounding whitespace stripped")
    }

    func testEffectiveDurationFallsBackToPlanned() {
        let snapshot = UserData.defaultData
        let planned: TimeInterval = 60 * 60

        let withoutOverride = WorkoutLog(workoutID: UUID(), completedAt: Date(),
                                         perceivedExertion: 5,
                                         userDataSnapshot: snapshot)
        XCTAssertEqual(withoutOverride.effectiveDuration(planned: planned), planned)

        let withOverride = WorkoutLog(workoutID: UUID(), completedAt: Date(),
                                      perceivedExertion: 5,
                                      durationOverride: 30 * 60,
                                      userDataSnapshot: snapshot)
        XCTAssertEqual(withOverride.effectiveDuration(planned: planned), 30 * 60,
                       "Override should win over the planned duration")
    }

    func testIntensityFactorAndEstimatedTSS() {
        let snapshot = UserData(
            weight: 70.0,
            weightUnit: WeightUnit.kilograms.rawValue,
            ftp: 200,
            trainingHoursPerWeek: 6,
            trainingGoal: TrainingGoal.getFaster.rawValue
        )

        // 200 W avg @ 200 W FTP for 1h → IF=1.0, TSS=100
        let log = WorkoutLog(
            workoutID: UUID(),
            completedAt: Date(),
            perceivedExertion: 8,
            averagePower: 200,
            durationOverride: 60 * 60,
            userDataSnapshot: snapshot
        )
        XCTAssertEqual(log.intensityFactor ?? 0, 1.0, accuracy: 0.0001)
        XCTAssertEqual(log.estimatedTSS(planned: 0) ?? 0, 100.0, accuracy: 0.0001)

        // Without average power IF + TSS are unknown.
        let bare = WorkoutLog(workoutID: UUID(), completedAt: Date(),
                              perceivedExertion: 5, userDataSnapshot: snapshot)
        XCTAssertNil(bare.intensityFactor)
        XCTAssertNil(bare.estimatedTSS(planned: 60 * 60))
    }

    func testIntensityFactorIsNilWhenFTPIsZero() {
        let snapshot = UserData(weight: 70, weightUnit: WeightUnit.kilograms.rawValue,
                                ftp: 0, trainingHoursPerWeek: 4,
                                trainingGoal: TrainingGoal.haveFun.rawValue)
        let log = WorkoutLog(workoutID: UUID(), completedAt: Date(),
                             perceivedExertion: 6, averagePower: 180,
                             userDataSnapshot: snapshot)
        XCTAssertNil(log.intensityFactor,
                     "IF must be nil when FTP is zero to avoid divide-by-zero")
    }

    func testCodableRoundTrip() throws {
        let original = WorkoutLog(
            workoutID: UUID(),
            completedAt: Date(timeIntervalSince1970: 1_700_000_000),
            perceivedExertion: 7,
            averagePower: 215,
            averageHeartRate: 152,
            durationOverride: 55 * 60,
            notes: "Tough but good",
            userDataSnapshot: UserData.defaultData
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WorkoutLog.self, from: data)

        XCTAssertEqual(decoded, original,
                       "WorkoutLog should survive a JSON round trip unchanged")
    }

    // MARK: - Persistence

    func testSaveLoadAndLookupByWorkoutID() {
        let workoutID = UUID()
        let log = WorkoutLog(workoutID: workoutID, completedAt: Date(),
                             perceivedExertion: 6,
                             userDataSnapshot: UserData.defaultData)

        WorkoutManager.shared.saveLog(log)

        XCTAssertEqual(WorkoutManager.shared.loadLogs(), [log])
        XCTAssertEqual(WorkoutManager.shared.log(forWorkoutID: workoutID), log)
        XCTAssertNil(WorkoutManager.shared.log(forWorkoutID: UUID()),
                     "Unknown workout IDs should return nil")
    }

    func testSavingTwiceWithSameIDUpdatesInPlace() {
        let logID = UUID()
        let workoutID = UUID()
        let initial = WorkoutLog(id: logID, workoutID: workoutID, completedAt: Date(),
                                 perceivedExertion: 4,
                                 userDataSnapshot: UserData.defaultData)
        WorkoutManager.shared.saveLog(initial)

        let updated = WorkoutLog(id: logID, workoutID: workoutID, completedAt: Date(),
                                 perceivedExertion: 9, notes: "Harder than expected",
                                 userDataSnapshot: UserData.defaultData)
        WorkoutManager.shared.saveLog(updated)

        let logs = WorkoutManager.shared.loadLogs()
        XCTAssertEqual(logs.count, 1, "Re-saving the same log id should not create a duplicate")
        XCTAssertEqual(logs.first?.perceivedExertion, 9)
        XCTAssertEqual(logs.first?.notes, "Harder than expected")
    }

    func testLogLookupReturnsMostRecentWhenMultipleExist() {
        let workoutID = UUID()
        let earlier = WorkoutLog(
            workoutID: workoutID,
            completedAt: Date(timeIntervalSince1970: 1_000_000),
            perceivedExertion: 3,
            userDataSnapshot: UserData.defaultData
        )
        let later = WorkoutLog(
            workoutID: workoutID,
            completedAt: Date(timeIntervalSince1970: 2_000_000),
            perceivedExertion: 8,
            userDataSnapshot: UserData.defaultData
        )
        WorkoutManager.shared.saveLog(earlier)
        WorkoutManager.shared.saveLog(later)

        XCTAssertEqual(WorkoutManager.shared.log(forWorkoutID: workoutID), later,
                       "Lookup should return the most recent log per workout")
    }

    func testDeleteLogRemovesAllLogsForWorkout() {
        let workoutID = UUID()
        let other = UUID()

        WorkoutManager.shared.saveLog(WorkoutLog(workoutID: workoutID, completedAt: Date(),
                                                  perceivedExertion: 5,
                                                  userDataSnapshot: UserData.defaultData))
        WorkoutManager.shared.saveLog(WorkoutLog(workoutID: other, completedAt: Date(),
                                                  perceivedExertion: 6,
                                                  userDataSnapshot: UserData.defaultData))

        WorkoutManager.shared.deleteLog(forWorkoutID: workoutID)

        XCTAssertNil(WorkoutManager.shared.log(forWorkoutID: workoutID))
        XCTAssertNotNil(WorkoutManager.shared.log(forWorkoutID: other),
                        "Unrelated logs should be untouched")
    }

    func testResetClearsLogs() {
        WorkoutManager.shared.saveLog(WorkoutLog(workoutID: UUID(), completedAt: Date(),
                                                  perceivedExertion: 5,
                                                  userDataSnapshot: UserData.defaultData))
        XCTAssertFalse(WorkoutManager.shared.loadLogs().isEmpty)

        WorkoutManager.shared.resetWorkouts()

        XCTAssertTrue(WorkoutManager.shared.loadLogs().isEmpty,
                      "resetWorkouts should also clear persisted logs")
    }
}
