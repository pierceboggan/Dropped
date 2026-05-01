//
//  PowerZones.swift
//  Dropped
//

import Foundation
import SwiftUI

/// Coggan-style cycling power training zones, derived from FTP.
///
/// Boundary policy: lower bound inclusive, upper bound inclusive (integer %FTP).
/// Z1 covers 0–55%, Z7 is anything above 150%. This guarantees every integer
/// %FTP maps to exactly one zone with no gaps or overlaps.
enum PowerZone: Int, CaseIterable, Identifiable, Codable {
    case z1 = 1
    case z2
    case z3
    case z4
    case z5
    case z6
    case z7

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .z1: return "Active Recovery"
        case .z2: return "Endurance"
        case .z3: return "Tempo"
        case .z4: return "Threshold"
        case .z5: return "VO2 Max"
        case .z6: return "Anaerobic"
        case .z7: return "Neuromuscular"
        }
    }

    var shortLabel: String {
        switch self {
        case .z1: return "Z1"
        case .z2: return "Z2"
        case .z3: return "Z3"
        case .z4: return "Z4"
        case .z5: return "Z5"
        case .z6: return "Z6"
        case .z7: return "Z7"
        }
    }

    /// Percentage-of-FTP bounds (integers, both inclusive). Use `Int.max`
    /// for Z7's open-ended upper bound.
    var percentRange: ClosedRange<Int> {
        switch self {
        case .z1: return 0...55
        case .z2: return 56...75
        case .z3: return 76...90
        case .z4: return 91...105
        case .z5: return 106...120
        case .z6: return 121...150
        case .z7: return 151...Int.max
        }
    }

    /// Human-readable %FTP range, e.g. "56–75%" or ">150%".
    var percentRangeDescription: String {
        switch self {
        case .z7: return ">150%"
        case .z1: return "<55%"
        default:
            let r = percentRange
            return "\(r.lowerBound)–\(r.upperBound)%"
        }
    }

    var color: Color {
        switch self {
        case .z1: return .blue
        case .z2: return .green
        case .z3: return .yellow
        case .z4: return .orange
        case .z5: return .red
        case .z6: return .purple
        case .z7: return .pink
        }
    }

    /// Which zone an integer percentage of FTP falls in. Negative values clamp to Z1.
    static func zone(forPercentFTP percent: Int) -> PowerZone {
        let p = max(0, percent)
        for zone in PowerZone.allCases where zone.percentRange.contains(p) {
            return zone
        }
        return .z7
    }
}

/// Watt ranges for each Coggan power zone, computed from the rider's FTP.
struct PowerZones: Equatable {
    let ftp: Int

    init(ftp: Int) {
        self.ftp = max(0, ftp)
    }

    /// Watt range for a given zone. For FTP=0, every range collapses to 0...0.
    /// Z7's upper bound is `Int.max` to represent "no ceiling".
    func range(for zone: PowerZone) -> ClosedRange<Int> {
        guard ftp > 0 else { return 0...0 }
        let pct = zone.percentRange
        let lower = wattValue(forPercent: pct.lowerBound)
        if zone == .z7 {
            return lower...Int.max
        }
        let upper = wattValue(forPercent: pct.upperBound)
        return lower...max(lower, upper)
    }

    /// Human-readable watt range, e.g. "112–150 W" or ">301 W".
    func wattRangeDescription(for zone: PowerZone) -> String {
        guard ftp > 0 else { return "—" }
        let r = range(for: zone)
        if zone == .z7 {
            return ">\(r.lowerBound) W"
        }
        return "\(r.lowerBound)–\(r.upperBound) W"
    }

    /// All zones in ascending order.
    var all: [PowerZone] { PowerZone.allCases }

    /// Determine which zone a given wattage falls into for this FTP.
    func zone(forWatts watts: Int) -> PowerZone {
        guard ftp > 0 else { return .z1 }
        let percent = Int((Double(watts) / Double(ftp)) * 100.0)
        return PowerZone.zone(forPercentFTP: percent)
    }

    private func wattValue(forPercent percent: Int) -> Int {
        Int(round(Double(ftp) * Double(percent) / 100.0))
    }
}
