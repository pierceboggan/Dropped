//
//  WorkoutLog.swift
//  Dropped
//
//  Persisted record of a completed workout. A `WorkoutLog` captures what
//  actually happened during a session (perceived exertion, optional power /
//  heart-rate / duration metrics, freeform notes) and is keyed back to the
//  scheduled `Workout` it completes. Workouts represent the plan; logs
//  represent the actuals.
//
//  The model is intentionally forward-compatible with future surfaces
//  (adaptation, streaks, charts, TSS). It snapshots the rider's `UserData`
//  at completion time so derived metrics like Intensity Factor (IF) and
//  Training Stress Score (TSS) can be recomputed accurately later, even
//  if the rider's FTP changes.
//

import Foundation

/// A persisted record of a completed workout session.
///
/// One log corresponds to a single completion of a scheduled `Workout`,
/// linked via `workoutID`. Optional metrics may be left `nil` when the
/// rider did not record them (e.g. no power meter, no heart-rate strap).
struct WorkoutLog: Identifiable, Codable, Equatable {
    /// Valid range for Rate of Perceived Exertion (Borg CR10-style).
    static let rpeRange: ClosedRange<Int> = 1...10

    let id: UUID
    /// Identifier of the scheduled `Workout` this log completes.
    let workoutID: UUID
    /// When the rider marked the workout complete. Defaults to "now" but is
    /// editable so past sessions can be back-logged.
    var completedAt: Date
    /// Rider's perceived exertion on the 1–10 scale. Always clamped into
    /// `rpeRange` by the initializer so persisted data stays valid.
    var perceivedExertion: Int
    /// Average power for the session in watts. Optional.
    var averagePower: Int?
    /// Average heart rate for the session in bpm. Optional.
    var averageHeartRate: Int?
    /// Override for the session's actual duration (seconds). When `nil` the
    /// planned `Workout.totalDuration` is used.
    var durationOverride: TimeInterval?
    /// Freeform rider notes about how the session went.
    var notes: String?
    /// Snapshot of the rider's `UserData` at log time. Captured so future
    /// recomputations (TSS, IF, weight-relative power) remain accurate.
    let userDataSnapshot: UserData

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - id: Stable identifier for the log itself. Defaults to a new UUID.
    ///   - workoutID: Identifier of the scheduled `Workout` being completed.
    ///   - completedAt: Timestamp the rider attributes to the session.
    ///   - perceivedExertion: RPE value; values outside `rpeRange` are clamped.
    ///   - averagePower: Optional average power in watts.
    ///   - averageHeartRate: Optional average heart rate in bpm.
    ///   - durationOverride: Optional actual duration in seconds.
    ///   - notes: Optional freeform rider notes. Empty/whitespace-only strings
    ///     are normalized to `nil`.
    ///   - userDataSnapshot: Rider profile snapshot captured at log time.
    init(
        id: UUID = UUID(),
        workoutID: UUID,
        completedAt: Date,
        perceivedExertion: Int,
        averagePower: Int? = nil,
        averageHeartRate: Int? = nil,
        durationOverride: TimeInterval? = nil,
        notes: String? = nil,
        userDataSnapshot: UserData
    ) {
        self.id = id
        self.workoutID = workoutID
        self.completedAt = completedAt
        self.perceivedExertion = WorkoutLog.clampRPE(perceivedExertion)
        self.averagePower = averagePower
        self.averageHeartRate = averageHeartRate
        self.durationOverride = durationOverride
        self.notes = WorkoutLog.normalize(notes)
        self.userDataSnapshot = userDataSnapshot
    }

    // MARK: - Derived metrics

    /// Returns the duration we should attribute to this session, falling back
    /// to the planned duration when the rider did not provide an override.
    ///
    /// - Parameter planned: The `Workout.totalDuration` of the scheduled session.
    /// - Returns: `durationOverride` when set, otherwise `planned`.
    func effectiveDuration(planned: TimeInterval) -> TimeInterval {
        durationOverride ?? planned
    }

    /// Intensity Factor (IF) — average power as a fraction of the snapshot
    /// FTP. Returns `nil` when average power is unknown or FTP is non-positive.
    ///
    /// IF is the ratio used by TSS and many adaptation models. We expose it
    /// even though no UI surfaces it yet, so future charts and TSS can use a
    /// single shared definition.
    var intensityFactor: Double? {
        guard let averagePower, userDataSnapshot.ftp > 0 else { return nil }
        return Double(averagePower) / Double(userDataSnapshot.ftp)
    }

    /// Estimated Training Stress Score for this session.
    ///
    /// Uses the standard simplified formula `TSS = duration_hours * IF^2 * 100`.
    /// Returns `nil` when `intensityFactor` cannot be computed or the effective
    /// duration is non-positive.
    ///
    /// - Parameter planned: The planned duration to fall back to when the
    ///   rider did not provide a `durationOverride`.
    func estimatedTSS(planned: TimeInterval) -> Double? {
        guard let intensityFactor else { return nil }
        let duration = effectiveDuration(planned: planned)
        guard duration > 0 else { return nil }
        let durationHours = duration / 3600.0
        return durationHours * intensityFactor * intensityFactor * 100.0
    }

    // MARK: - Helpers

    /// Clamp an arbitrary integer into the supported RPE range.
    static func clampRPE(_ value: Int) -> Int {
        min(max(value, rpeRange.lowerBound), rpeRange.upperBound)
    }

    /// Normalize freeform notes — treats empty / whitespace-only strings as `nil`.
    private static func normalize(_ notes: String?) -> String? {
        guard let trimmed = notes?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
