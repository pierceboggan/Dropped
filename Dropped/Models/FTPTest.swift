//
//  FTPTest.swift
//  Dropped
//

import Foundation

/// Built-in FTP test protocols.
enum FTPTestType: String, CaseIterable, Identifiable, Codable {
    case twentyMinute = "twentyMinute"
    case ramp = "ramp"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .twentyMinute: return "20-Minute FTP Test"
        case .ramp: return "Ramp FTP Test"
        }
    }

    var shortName: String {
        switch self {
        case .twentyMinute: return "20-Min Test"
        case .ramp: return "Ramp Test"
        }
    }

    var summary: String {
        switch self {
        case .twentyMinute:
            return "Warm up, then ride as hard as you can sustain for 20 minutes. Your FTP is 95% of your average power."
        case .ramp:
            return "Step up power every minute until you can no longer hold the target. Your FTP is 75% of the last fully completed minute's power."
        }
    }

    var resultPrompt: String {
        switch self {
        case .twentyMinute: return "Average power for the 20-minute effort"
        case .ramp: return "Power of the last fully completed 1-minute step"
        }
    }
}

/// Pure FTP-from-test calculations.
enum FTPCalculator {
    /// FTP from a 20-minute average power: `round(avg * 0.95)`.
    /// Returns 0 for non-positive input.
    static func ftp(fromTwentyMinuteAvgWatts watts: Int) -> Int {
        guard watts > 0 else { return 0 }
        return Int(round(Double(watts) * 0.95))
    }

    /// FTP from a ramp test final completed minute: `round(final * 0.75)`.
    /// Returns 0 for non-positive input.
    static func ftp(fromRampFinalMinuteWatts watts: Int) -> Int {
        guard watts > 0 else { return 0 }
        return Int(round(Double(watts) * 0.75))
    }

    /// Convenience dispatch.
    static func ftp(forTest test: FTPTestType, inputWatts: Int) -> Int {
        switch test {
        case .twentyMinute: return ftp(fromTwentyMinuteAvgWatts: inputWatts)
        case .ramp: return ftp(fromRampFinalMinuteWatts: inputWatts)
        }
    }
}

/// Factory for built-in FTP-test `Workout` instances. These are real workouts
/// that flow through the existing `WorkoutManager` and `WorkoutDetailView`, but
/// are tagged via `Workout.testKind` so the UI can offer a "Log result" action.
enum FTPTestWorkouts {
    /// Build a 20-minute FTP test workout. Total ≈ 45 minutes:
    /// 15 min warmup → 20 min effort at ~95% FTP target → 10 min cool-down.
    static func twentyMinute(ftp: Int, date: Date = Date()) -> Workout {
        let warmupWatts = max(1, Int(Double(ftp) * 0.55))
        let effortWatts = max(1, Int(Double(ftp) * 0.95))
        let cooldownWatts = max(1, Int(Double(ftp) * 0.45))

        let intervals: [Interval] = [
            Interval(watts: warmupWatts, duration: 15 * 60),
            Interval(watts: effortWatts, duration: 20 * 60),
            Interval(watts: cooldownWatts, duration: 10 * 60)
        ]

        return Workout(
            title: FTPTestType.twentyMinute.displayName,
            date: date,
            summary: FTPTestType.twentyMinute.summary,
            intervals: intervals,
            status: .scheduled,
            testKind: FTPTestType.twentyMinute.rawValue
        )
    }

    /// Build a ramp test workout. 5-minute warmup at ~50% FTP, then 1-minute
    /// steps starting at ~50% FTP and increasing 25 W per minute for 20 steps.
    static func ramp(ftp: Int, date: Date = Date()) -> Workout {
        let warmupWatts = max(1, Int(Double(ftp) * 0.50))
        var intervals: [Interval] = [
            Interval(watts: warmupWatts, duration: 5 * 60)
        ]

        let startWatts = max(50, Int(Double(ftp) * 0.50))
        let stepWatts = 25
        let stepCount = 20

        for step in 0..<stepCount {
            let watts = startWatts + step * stepWatts
            intervals.append(Interval(watts: watts, duration: 60))
        }

        return Workout(
            title: FTPTestType.ramp.displayName,
            date: date,
            summary: FTPTestType.ramp.summary,
            intervals: intervals,
            status: .scheduled,
            testKind: FTPTestType.ramp.rawValue
        )
    }

    static func workout(for test: FTPTestType, ftp: Int, date: Date = Date()) -> Workout {
        switch test {
        case .twentyMinute: return twentyMinute(ftp: ftp, date: date)
        case .ramp: return ramp(ftp: ftp, date: date)
        }
    }
}
