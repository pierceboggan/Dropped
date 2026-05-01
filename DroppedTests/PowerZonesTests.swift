//
//  PowerZonesTests.swift
//  DroppedTests
//

import XCTest
@testable import Dropped

final class PowerZonesTests: XCTestCase {
    func testZoneBoundariesByPercent() {
        // Z1 boundary
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 0), .z1)
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 55), .z1)
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 56), .z2)
        // Z2/Z3
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 75), .z2)
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 76), .z3)
        // Z3/Z4
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 90), .z3)
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 91), .z4)
        // Z4/Z5
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 105), .z4)
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 106), .z5)
        // Z5/Z6
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 120), .z5)
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 121), .z6)
        // Z6/Z7
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 150), .z6)
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 151), .z7)
        XCTAssertEqual(PowerZone.zone(forPercentFTP: 1000), .z7)
        // Negative clamps to Z1
        XCTAssertEqual(PowerZone.zone(forPercentFTP: -10), .z1)
    }

    func testWattRangesForFTP200() {
        let zones = PowerZones(ftp: 200)
        // Z1: 0–55% of 200 = 0–110
        XCTAssertEqual(zones.range(for: .z1), 0...110)
        // Z2: 56–75% = 112–150
        XCTAssertEqual(zones.range(for: .z2), 112...150)
        // Z3: 76–90% = 152–180
        XCTAssertEqual(zones.range(for: .z3), 152...180)
        // Z4: 91–105% = 182–210
        XCTAssertEqual(zones.range(for: .z4), 182...210)
        // Z5: 106–120% = 212–240
        XCTAssertEqual(zones.range(for: .z5), 212...240)
        // Z6: 121–150% = 242–300
        XCTAssertEqual(zones.range(for: .z6), 242...300)
        // Z7: 151%+ = 302...Int.max
        XCTAssertEqual(zones.range(for: .z7).lowerBound, 302)
        XCTAssertEqual(zones.range(for: .z7).upperBound, Int.max)
    }

    func testZoneForWattsAtFTP200() {
        let zones = PowerZones(ftp: 200)
        // 100 W = 50% → Z1
        XCTAssertEqual(zones.zone(forWatts: 100), .z1)
        // 150 W = 75% → Z2
        XCTAssertEqual(zones.zone(forWatts: 150), .z2)
        // 180 W = 90% → Z3
        XCTAssertEqual(zones.zone(forWatts: 180), .z3)
        // 200 W = 100% → Z4
        XCTAssertEqual(zones.zone(forWatts: 200), .z4)
        // 240 W = 120% → Z5
        XCTAssertEqual(zones.zone(forWatts: 240), .z5)
        // 300 W = 150% → Z6
        XCTAssertEqual(zones.zone(forWatts: 300), .z6)
        // 320 W = 160% → Z7
        XCTAssertEqual(zones.zone(forWatts: 320), .z7)
    }

    func testFTPZeroIsDegenerateButSafe() {
        let zones = PowerZones(ftp: 0)
        for zone in zones.all {
            XCTAssertEqual(zones.range(for: zone), 0...0)
        }
        XCTAssertEqual(zones.zone(forWatts: 500), .z1)
    }

    func testNegativeFTPClampsToZero() {
        let zones = PowerZones(ftp: -100)
        XCTAssertEqual(zones.ftp, 0)
    }

    func testAllOrderingAndCount() {
        let zones = PowerZones(ftp: 250)
        XCTAssertEqual(zones.all, [.z1, .z2, .z3, .z4, .z5, .z6, .z7])
        XCTAssertEqual(zones.all.count, 7)
    }

    func testUserDataExposesPowerZones() {
        let user = UserData(
            weight: 70,
            weightUnit: WeightUnit.kilograms.rawValue,
            ftp: 250,
            trainingHoursPerWeek: 5,
            trainingGoal: TrainingGoal.haveFun.rawValue
        )
        XCTAssertEqual(user.powerZones.ftp, 250)
        XCTAssertEqual(user.powerZones.range(for: .z4).lowerBound, Int(round(250 * 0.91)))
    }
}
