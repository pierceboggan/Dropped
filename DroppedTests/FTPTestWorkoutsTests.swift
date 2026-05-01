//
//  FTPTestWorkoutsTests.swift
//  DroppedTests
//

import XCTest
@testable import Dropped

final class FTPTestWorkoutsTests: XCTestCase {
    func testTwentyMinuteWorkoutShape() {
        let workout = FTPTestWorkouts.twentyMinute(ftp: 200)

        XCTAssertEqual(workout.testKind, FTPTestType.twentyMinute.rawValue)
        XCTAssertEqual(workout.intervals.count, 3)
        XCTAssertEqual(workout.totalDuration, TimeInterval((15 + 20 + 10) * 60))

        // Effort interval at ~95% FTP
        let effort = workout.intervals[1]
        XCTAssertEqual(effort.duration, TimeInterval(20 * 60))
        XCTAssertEqual(effort.watts, Int(Double(200) * 0.95))

        // Warmup is the first interval and easier than effort
        XCTAssertLessThan(workout.intervals[0].watts, effort.watts)
        // Cooldown last and easier than warmup or equal
        XCTAssertLessThanOrEqual(workout.intervals[2].watts, workout.intervals[0].watts)
    }

    func testRampWorkoutShape() {
        let workout = FTPTestWorkouts.ramp(ftp: 200)

        XCTAssertEqual(workout.testKind, FTPTestType.ramp.rawValue)
        // 5-min warmup + 20 one-minute steps
        XCTAssertEqual(workout.intervals.count, 21)
        XCTAssertEqual(workout.intervals.first?.duration, TimeInterval(5 * 60))

        // Each step is 1 minute
        for step in workout.intervals.dropFirst() {
            XCTAssertEqual(step.duration, 60)
        }

        // Steps strictly ascending
        let steps = Array(workout.intervals.dropFirst())
        for i in 1..<steps.count {
            XCTAssertGreaterThan(steps[i].watts, steps[i - 1].watts)
        }

        // Step delta is 25 W
        XCTAssertEqual(steps[1].watts - steps[0].watts, 25)
    }

    func testWorkoutFactoryDispatch() {
        let twenty = FTPTestWorkouts.workout(for: .twentyMinute, ftp: 220)
        XCTAssertEqual(twenty.testKind, FTPTestType.twentyMinute.rawValue)

        let ramp = FTPTestWorkouts.workout(for: .ramp, ftp: 220)
        XCTAssertEqual(ramp.testKind, FTPTestType.ramp.rawValue)
    }

    func testWorkoutCodableBackwardCompatWithoutTestKind() throws {
        // Simulate an older persisted workout JSON (no testKind field).
        let legacyJSON = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "title": "Legacy",
            "date": 0,
            "summary": "old",
            "intervals": [],
            "status": "Scheduled"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let workout = try decoder.decode(Workout.self, from: legacyJSON)
        XCTAssertNil(workout.testKind)
        XCTAssertEqual(workout.title, "Legacy")
    }

    func testWorkoutCodableRoundTripWithTestKind() throws {
        let original = FTPTestWorkouts.twentyMinute(ftp: 250)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Workout.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.testKind, FTPTestType.twentyMinute.rawValue)
    }
}
