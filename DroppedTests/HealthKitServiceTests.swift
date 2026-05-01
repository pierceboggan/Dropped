//
//  HealthKitServiceTests.swift
//  DroppedTests
//
//  Tests for HealthKit integration plumbing using a stub service.
//

import XCTest
@testable import Dropped

final class MockHealthKitService: HealthKitServicing {
    var isAvailable: Bool = true
    var authorizationCalls: Int = 0
    var authorizationError: Error?
    var bodyMass: (mass: Double, date: Date)?
    var restingHR: Double?
    var vo2: Double?
    var ftp: Int?
    var savedSummaries: [CompletedWorkoutSummary] = []
    var saveError: Error?

    func requestAuthorization() async throws {
        authorizationCalls += 1
        if let authorizationError { throw authorizationError }
    }
    func latestBodyMassKg() async throws -> (mass: Double, date: Date)? { bodyMass }
    func latestRestingHeartRate() async throws -> Double? { restingHR }
    func latestVO2Max() async throws -> Double? { vo2 }
    func latestCyclingFTP() async throws -> Int? { ftp }
    func saveCyclingWorkout(_ summary: CompletedWorkoutSummary) async throws {
        if let saveError { throw saveError }
        savedSummaries.append(summary)
    }
}

final class HealthKitServiceTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUpWithError() throws {
        suiteName = "HealthKitServiceTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        UserDataManager.shared.resetUserData()
        WorkoutManager.shared.resetWorkouts()
        defaults.removeObject(forKey: WorkoutManager.healthSyncEnabledKey)
    }

    override func tearDownWithError() throws {
        UserDataManager.shared.resetUserData()
        WorkoutManager.shared.resetWorkouts()
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
    }

    // MARK: - Energy estimation

    func test_estimateKilocalories_convertsPowerAndDuration() {
        // 200 W mechanical for 3600 s, at ~23% efficiency:
        //   metabolicJ = 200*3600 / 0.23 ≈ 3,130,434
        //   kcal       = / 4184           ≈ 748.2
        let kcal = CompletedWorkoutSummary.estimateKilocalories(
            averagePowerWatts: 200, duration: 3600
        )
        XCTAssertEqual(kcal, 748.2, accuracy: 1.0)
    }

    func test_estimateKilocalories_zeroForBadInputs() {
        XCTAssertEqual(CompletedWorkoutSummary.estimateKilocalories(averagePowerWatts: 0, duration: 3600), 0)
        XCTAssertEqual(CompletedWorkoutSummary.estimateKilocalories(averagePowerWatts: 200, duration: 0), 0)
    }

    // MARK: - Body mass sync

    func test_syncBodyMass_updatesProfile_whenSampleNewer() async {
        let service = MockHealthKitService()
        service.bodyMass = (mass: 72.5, date: Date())
        UserDataManager.shared.saveUserData(UserData.defaultData)

        let updated = await service.syncBodyMassToProfile()
        XCTAssertTrue(updated)
        let stored = UserDataManager.shared.loadUserData()
        XCTAssertEqual(stored.weight, 72.5, accuracy: 0.0001)
        XCTAssertNotNil(stored.weightUpdatedAt)
    }

    func test_syncBodyMass_skips_whenSampleOlder() async {
        let service = MockHealthKitService()
        let now = Date()
        UserDataManager.shared.saveUserData(UserData(
            weight: 80.0,
            weightUnit: WeightUnit.kilograms.rawValue,
            ftp: 250,
            trainingHoursPerWeek: 6,
            trainingGoal: TrainingGoal.getFaster.rawValue,
            weightUpdatedAt: now
        ))
        service.bodyMass = (mass: 60.0, date: now.addingTimeInterval(-3600))

        let updated = await service.syncBodyMassToProfile()
        XCTAssertFalse(updated)
        XCTAssertEqual(UserDataManager.shared.loadUserData().weight, 80.0, accuracy: 0.0001)
    }

    func test_syncBodyMass_noop_whenServiceUnavailable() async {
        let service = MockHealthKitService()
        service.isAvailable = false
        service.bodyMass = (mass: 50.0, date: Date())
        UserDataManager.shared.saveUserData(UserData.defaultData)

        let updated = await service.syncBodyMassToProfile()
        XCTAssertFalse(updated)
        XCTAssertEqual(UserDataManager.shared.loadUserData().weight, 70.0, accuracy: 0.0001)
    }

    func test_updateWeightFromHealth_skipsStaleSample_whenNoPriorHealthSync() {
        // Profile has no weightUpdatedAt (manual entry). Old HK sample shouldn't clobber it.
        UserDataManager.shared.saveUserData(UserData.defaultData)
        let now = Date()
        let stale = now.addingTimeInterval(-60 * 24 * 60 * 60) // 60 days ago

        let updated = UserDataManager.shared.updateWeightFromHealth(
            kg: 99.0, sampleDate: stale, now: now
        )
        XCTAssertFalse(updated)
        XCTAssertEqual(UserDataManager.shared.loadUserData().weight, 70.0, accuracy: 0.0001)
    }

    func test_updateWeightFromHealth_acceptsRecentSample_whenNoPriorHealthSync() {
        UserDataManager.shared.saveUserData(UserData.defaultData)
        let now = Date()
        let recent = now.addingTimeInterval(-3600)

        let updated = UserDataManager.shared.updateWeightFromHealth(
            kg: 75.0, sampleDate: recent, now: now
        )
        XCTAssertTrue(updated)
        XCTAssertEqual(UserDataManager.shared.loadUserData().weight, 75.0, accuracy: 0.0001)
    }

    // MARK: - Codable backward compatibility

    func test_userData_decodes_legacyJSONWithoutWeightUpdatedAt() throws {
        let json = """
        {
          "weight": 68.5,
          "weightUnit": "kg",
          "ftp": 240,
          "trainingHoursPerWeek": 7,
          "trainingGoal": "Get Faster"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(UserData.self, from: json)
        XCTAssertEqual(decoded.weight, 68.5)
        XCTAssertEqual(decoded.ftp, 240)
        XCTAssertNil(decoded.weightUpdatedAt)
    }

    // MARK: - Workout completion → HealthKit write-through

    func test_markCompleted_writesToHealthKit_whenToggleOn() async {
        let service = MockHealthKitService()
        let manager = WorkoutManager(defaults: defaults, healthKitService: service)
        defaults.set(true, forKey: WorkoutManager.healthSyncEnabledKey)

        let workout = makeWorkout()
        let summary = CompletedWorkoutSummary(
            start: Date(timeIntervalSince1970: 1_000_000),
            end: Date(timeIntervalSince1970: 1_003_600),
            averageHeartRate: 150,
            averagePowerWatts: 220
        )
        let completed = await manager.markWorkoutCompleted(workout, summary: summary)

        XCTAssertEqual(completed.status, .completed)
        XCTAssertEqual(service.savedSummaries.count, 1)
        XCTAssertEqual(service.savedSummaries.first?.averagePowerWatts, 220)
        // Persisted status is updated.
        XCTAssertEqual(manager.loadWorkouts().first?.status, .completed)
    }

    func test_markCompleted_skipsHealthKit_whenToggleOff() async {
        let service = MockHealthKitService()
        let manager = WorkoutManager(defaults: defaults, healthKitService: service)
        defaults.set(false, forKey: WorkoutManager.healthSyncEnabledKey)

        let workout = makeWorkout()
        let summary = CompletedWorkoutSummary(start: Date(), end: Date().addingTimeInterval(60))
        _ = await manager.markWorkoutCompleted(workout, summary: summary)

        XCTAssertTrue(service.savedSummaries.isEmpty)
        XCTAssertEqual(manager.loadWorkouts().first?.status, .completed)
    }

    func test_markCompleted_persistsStatus_evenWhenHealthKitFails() async {
        let service = MockHealthKitService()
        service.saveError = HealthKitServiceError.notAuthorized
        let manager = WorkoutManager(defaults: defaults, healthKitService: service)
        defaults.set(true, forKey: WorkoutManager.healthSyncEnabledKey)

        let workout = makeWorkout()
        let summary = CompletedWorkoutSummary(start: Date(), end: Date().addingTimeInterval(60))
        _ = await manager.markWorkoutCompleted(workout, summary: summary)

        XCTAssertEqual(manager.loadWorkouts().first?.status, .completed)
    }

    // MARK: - Helpers

    private func makeWorkout() -> Workout {
        Workout(
            title: "Test Ride",
            date: Date(),
            summary: "Easy spin",
            intervals: [Interval(watts: 180, duration: 60)]
        )
    }
}
