//
//  FTPCalculatorTests.swift
//  DroppedTests
//

import XCTest
@testable import Dropped

final class FTPCalculatorTests: XCTestCase {
    func testTwentyMinuteFormula() {
        // 250 W avg → 250 * 0.95 = 237.5 → rounds to 238
        XCTAssertEqual(FTPCalculator.ftp(fromTwentyMinuteAvgWatts: 250), 238)
        // 300 W avg → 285
        XCTAssertEqual(FTPCalculator.ftp(fromTwentyMinuteAvgWatts: 300), 285)
        // 200 W avg → 190
        XCTAssertEqual(FTPCalculator.ftp(fromTwentyMinuteAvgWatts: 200), 190)
    }

    func testTwentyMinuteRoundingBoundary() {
        // 211 * 0.95 = 200.45 → 200
        XCTAssertEqual(FTPCalculator.ftp(fromTwentyMinuteAvgWatts: 211), 200)
        // 212 * 0.95 = 201.4 → 201
        XCTAssertEqual(FTPCalculator.ftp(fromTwentyMinuteAvgWatts: 212), 201)
    }

    func testRampFormula() {
        // 300 W final → 225
        XCTAssertEqual(FTPCalculator.ftp(fromRampFinalMinuteWatts: 300), 225)
        // 400 W final → 300
        XCTAssertEqual(FTPCalculator.ftp(fromRampFinalMinuteWatts: 400), 300)
    }

    func testRampRoundingBoundary() {
        // 267 * 0.75 = 200.25 → 200
        XCTAssertEqual(FTPCalculator.ftp(fromRampFinalMinuteWatts: 267), 200)
        // 268 * 0.75 = 201 → 201
        XCTAssertEqual(FTPCalculator.ftp(fromRampFinalMinuteWatts: 268), 201)
    }

    func testNonPositiveInputsReturnZero() {
        XCTAssertEqual(FTPCalculator.ftp(fromTwentyMinuteAvgWatts: 0), 0)
        XCTAssertEqual(FTPCalculator.ftp(fromTwentyMinuteAvgWatts: -50), 0)
        XCTAssertEqual(FTPCalculator.ftp(fromRampFinalMinuteWatts: 0), 0)
        XCTAssertEqual(FTPCalculator.ftp(fromRampFinalMinuteWatts: -10), 0)
    }

    func testDispatchByTestType() {
        XCTAssertEqual(
            FTPCalculator.ftp(forTest: .twentyMinute, inputWatts: 250),
            FTPCalculator.ftp(fromTwentyMinuteAvgWatts: 250)
        )
        XCTAssertEqual(
            FTPCalculator.ftp(forTest: .ramp, inputWatts: 300),
            FTPCalculator.ftp(fromRampFinalMinuteWatts: 300)
        )
    }
}
