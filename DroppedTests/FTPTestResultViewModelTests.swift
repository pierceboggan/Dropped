//
//  FTPTestResultViewModelTests.swift
//  DroppedTests
//

import XCTest
@testable import Dropped

@MainActor
final class FTPTestResultViewModelTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var userManager: UserDataManager!
    private var workoutManager: WorkoutManager!

    override func setUpWithError() throws {
        suiteName = "FTPTestResultVMTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        userManager = UserDataManager(defaults: defaults)
        workoutManager = WorkoutManager(defaults: defaults)

        // Seed a known starting profile.
        userManager.saveUserData(UserData(
            weight: 70,
            weightUnit: WeightUnit.kilograms.rawValue,
            ftp: 200,
            trainingHoursPerWeek: 5,
            trainingGoal: TrainingGoal.haveFun.rawValue
        ))
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        userManager = nil
        workoutManager = nil
    }

    func testInitialStateUsesPersistedFTP() {
        let vm = FTPTestResultViewModel(
            testType: .twentyMinute,
            userDataManager: userManager,
            workoutManager: workoutManager
        )
        XCTAssertEqual(vm.previousFTP, 200)
        XCTAssertNil(vm.newFTP)
        XCTAssertFalse(vm.canConfirm)
    }

    func testTwentyMinuteConfirmUpdatesProfile() {
        let vm = FTPTestResultViewModel(
            testType: .twentyMinute,
            userDataManager: userManager,
            workoutManager: workoutManager
        )
        vm.inputWatts = "250"
        XCTAssertEqual(vm.newFTP, 238)
        XCTAssertEqual(vm.delta, 38)
        XCTAssertTrue(vm.canConfirm)

        let result = vm.confirm()
        XCTAssertEqual(result, 238)
        XCTAssertEqual(userManager.loadUserData().ftp, 238)
    }

    func testRampConfirmUpdatesProfile() {
        let vm = FTPTestResultViewModel(
            testType: .ramp,
            userDataManager: userManager,
            workoutManager: workoutManager
        )
        vm.inputWatts = "300"
        XCTAssertEqual(vm.newFTP, 225)
        XCTAssertEqual(vm.delta, 25)

        XCTAssertEqual(vm.confirm(), 225)
        XCTAssertEqual(userManager.loadUserData().ftp, 225)
    }

    func testInvalidInputBlocksConfirm() {
        let vm = FTPTestResultViewModel(
            testType: .twentyMinute,
            userDataManager: userManager,
            workoutManager: workoutManager
        )
        vm.inputWatts = "not a number"
        XCTAssertNil(vm.newFTP)
        XCTAssertFalse(vm.canConfirm)
        XCTAssertNil(vm.confirm())
        XCTAssertNotNil(vm.inputError)
        // FTP must remain unchanged.
        XCTAssertEqual(userManager.loadUserData().ftp, 200)
    }

    func testZeroInputIsRejected() {
        let vm = FTPTestResultViewModel(
            testType: .twentyMinute,
            userDataManager: userManager,
            workoutManager: workoutManager
        )
        vm.inputWatts = "0"
        XCTAssertNil(vm.newFTP)
        XCTAssertNil(vm.confirm())
        XCTAssertEqual(userManager.loadUserData().ftp, 200)
    }

    func testConfirmMarksSourceWorkoutCompleted() {
        let workout = FTPTestWorkouts.twentyMinute(ftp: 200)
        workoutManager.saveWorkout(workout)

        let vm = FTPTestResultViewModel(
            testType: .twentyMinute,
            sourceWorkout: workout,
            userDataManager: userManager,
            workoutManager: workoutManager
        )
        vm.inputWatts = "250"
        _ = vm.confirm()

        let stored = workoutManager.loadWorkouts().first { $0.id == workout.id }
        XCTAssertNotNil(stored)
        XCTAssertEqual(stored?.status, .completed)
        XCTAssertEqual(stored?.testKind, FTPTestType.twentyMinute.rawValue)
    }

    func testConfirmDoesNotChangeOtherProfileFields() {
        let original = userManager.loadUserData()
        let vm = FTPTestResultViewModel(
            testType: .twentyMinute,
            userDataManager: userManager,
            workoutManager: workoutManager
        )
        vm.inputWatts = "250"
        _ = vm.confirm()

        let updated = userManager.loadUserData()
        XCTAssertEqual(updated.weight, original.weight)
        XCTAssertEqual(updated.weightUnit, original.weightUnit)
        XCTAssertEqual(updated.trainingHoursPerWeek, original.trainingHoursPerWeek)
        XCTAssertEqual(updated.trainingGoal, original.trainingGoal)
        XCTAssertNotEqual(updated.ftp, original.ftp)
    }
}
