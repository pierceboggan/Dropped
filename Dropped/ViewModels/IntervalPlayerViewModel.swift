//
//  IntervalPlayerViewModel.swift
//  Dropped
//
//  State machine and timing engine for the in-app interval player.
//
//  This view model is intentionally pure: it has no SwiftUI, AVFoundation, or UIKit
//  dependencies. Time is read through an injectable `now` closure so unit tests can
//  drive the timeline deterministically. Audio / haptic side effects are produced
//  as `CueIntent` values handed to an injected `cueHandler` closure, keeping the
//  view model fully testable without mocks.
//

import Foundation
import Combine

// MARK: - Cue intents

/// A side-effect intent emitted by the player. The view layer (or a service) is
/// responsible for translating intents into audio + haptic feedback.
enum IntervalPlayerCueIntent: Equatable {
    /// Final 3, 2, or 1 second tick before an interval ends. The associated value
    /// is the seconds remaining (3, 2, or 1).
    case countdownTick(secondsRemaining: Int)
    /// An interval just began. Carries the index (zero-based) of the started interval.
    case intervalStarted(index: Int)
    /// An interval just finished naturally. Carries the index of the interval that ended.
    case intervalEnded(index: Int)
    /// The full workout finished naturally (last interval reached its duration).
    case workoutCompleted
}

// MARK: - Player state

/// High-level state of the player session.
enum IntervalPlayerState: Equatable {
    /// Not yet started, or just constructed.
    case idle
    /// Actively progressing through intervals.
    case running
    /// User paused; elapsed time is frozen.
    case paused
    /// Workout finished, either naturally or via end-early.
    case finished
}

// MARK: - View model

/// Drives the in-app interval player UI. Backed by a wall-clock anchor so the
/// session remains accurate after backgrounding or screen sleep.
///
/// Threading: all mutating methods must be called on the main actor; published
/// properties feed SwiftUI directly.
@MainActor
final class IntervalPlayerViewModel: ObservableObject {

    // MARK: Inputs

    /// The workout being played.
    let workout: Workout

    /// User FTP, used to display target power as a percentage of FTP. A value of
    /// zero or negative disables the percentage readout.
    let ftp: Int

    // MARK: Published state

    @Published private(set) var state: IntervalPlayerState = .idle
    /// Index of the currently active interval. Always within
    /// `0..<workout.intervals.count` while the player is running, paused, or
    /// finished naturally; for an empty workout it stays at 0.
    @Published private(set) var currentIndex: Int = 0
    /// Elapsed time inside the current interval, in seconds. Clamped to
    /// `[0, currentInterval.duration]`.
    @Published private(set) var elapsedInInterval: TimeInterval = 0

    // MARK: Dependencies

    private let now: () -> Date
    private let cueHandler: (IntervalPlayerCueIntent) -> Void

    // MARK: Internal timing state

    /// Wall-clock anchor for "when the current interval started". When the player
    /// is paused this value is a sentinel; resume recomputes it from
    /// `frozenElapsed` so backgrounded time does not bleed into the session.
    private var intervalStartReference: Date = .distantPast
    /// Snapshot of `elapsedInInterval` taken when paused, used to restore the
    /// timeline on resume.
    private var frozenElapsed: TimeInterval = 0
    /// Last countdown second already emitted for the current interval. Prevents
    /// duplicate haptic / audio cues when `tick()` runs faster than 1 Hz.
    private var lastEmittedCountdownSecond: Int = 0
    /// Tracks whether the natural completion cue has been emitted, so it fires at
    /// most once per session.
    private var didEmitCompletion: Bool = false

    // MARK: Init

    /// Creates a new view model.
    ///
    /// - Parameters:
    ///   - workout: The workout to play.
    ///   - ftp: User functional threshold power (watts). Pass 0 to hide %FTP.
    ///   - now: Clock used for wall-clock arithmetic. Defaults to `Date.init`.
    ///   - cueHandler: Receiver for audio/haptic intents. Defaults to a no-op,
    ///     which makes the type trivially constructible from tests.
    init(
        workout: Workout,
        ftp: Int,
        now: @escaping () -> Date = Date.init,
        cueHandler: @escaping (IntervalPlayerCueIntent) -> Void = { _ in }
    ) {
        self.workout = workout
        self.ftp = ftp
        self.now = now
        self.cueHandler = cueHandler
    }

    // MARK: Derived values

    /// The current interval, or `nil` for an empty workout / past-the-end index.
    var currentInterval: Interval? {
        guard workout.intervals.indices.contains(currentIndex) else { return nil }
        return workout.intervals[currentIndex]
    }

    /// The next interval after the current one, or `nil` if this is the last.
    var nextInterval: Interval? {
        let nextIndex = currentIndex + 1
        guard workout.intervals.indices.contains(nextIndex) else { return nil }
        return workout.intervals[nextIndex]
    }

    /// Seconds remaining in the current interval. Zero when no interval is active.
    var remainingInInterval: TimeInterval {
        guard let interval = currentInterval else { return 0 }
        return max(0, interval.duration - elapsedInInterval)
    }

    /// Total elapsed seconds across the entire workout, including completed
    /// intervals plus the in-progress portion of the current one.
    var overallElapsed: TimeInterval {
        let completed = workout.intervals.prefix(currentIndex).reduce(0) { $0 + $1.duration }
        return completed + min(elapsedInInterval, currentInterval?.duration ?? 0)
    }

    /// Seconds remaining across the entire workout.
    var overallRemaining: TimeInterval {
        max(0, workout.totalDuration - overallElapsed)
    }

    /// Overall progress in the range `[0, 1]`. Zero for an empty workout.
    var progressFraction: Double {
        let total = workout.totalDuration
        guard total > 0 else { return 0 }
        return min(1, max(0, overallElapsed / total))
    }

    /// Target watts for the current interval, or `nil` when no interval is active.
    var currentTargetWatts: Int? {
        currentInterval?.watts
    }

    /// Target as a percentage of FTP (e.g. `0.85` for 85% FTP). `nil` when FTP is
    /// unset or no interval is active.
    var currentPercentFTP: Double? {
        guard ftp > 0, let watts = currentTargetWatts else { return nil }
        return Double(watts) / Double(ftp)
    }

    // MARK: Lifecycle

    /// Begins the workout from the first interval. No-op if already running, or
    /// if the workout has no intervals.
    func start() {
        guard state == .idle else { return }
        guard !workout.intervals.isEmpty else { return }
        currentIndex = 0
        elapsedInInterval = 0
        intervalStartReference = now()
        lastEmittedCountdownSecond = 0
        didEmitCompletion = false
        state = .running
        cueHandler(.intervalStarted(index: 0))
    }

    /// Pauses the session. Elapsed time inside the current interval is frozen
    /// until `resume()` is called.
    func pause() {
        guard state == .running else { return }
        // Capture latest elapsed before freezing, so the UI matches what the
        // user saw at the moment they tapped pause.
        recomputeElapsed()
        frozenElapsed = elapsedInInterval
        state = .paused
    }

    /// Resumes a paused session. Re-anchors the wall clock so any time spent
    /// paused (even across backgrounding) is excluded from the workout.
    func resume() {
        guard state == .paused else { return }
        intervalStartReference = now().addingTimeInterval(-frozenElapsed)
        state = .running
        // Re-emit the most recent countdown if we're still inside the 3..1 window
        // — but only for a second we have not yet announced for this interval.
        tick()
    }

    /// Advances immediately to the next interval. If already on the last
    /// interval, finishes the workout (without emitting `workoutCompleted`,
    /// since the user manually skipped past it rather than completing it).
    func skip() {
        guard state == .running || state == .paused else { return }
        let endingIndex = currentIndex
        cueHandler(.intervalEnded(index: endingIndex))
        let nextIndex = endingIndex + 1
        if workout.intervals.indices.contains(nextIndex) {
            currentIndex = nextIndex
            elapsedInInterval = 0
            frozenElapsed = 0
            intervalStartReference = now()
            lastEmittedCountdownSecond = 0
            cueHandler(.intervalStarted(index: nextIndex))
            if state == .paused {
                // Stay paused at the start of the new interval.
            }
        } else {
            finish(natural: false)
        }
    }

    /// Ends the workout immediately at the user's request. Does not emit
    /// `workoutCompleted` (that intent is reserved for natural completion).
    func endEarly() {
        guard state == .running || state == .paused else { return }
        finish(natural: false)
    }

    /// Recomputes elapsed time from the wall clock and advances intervals as
    /// needed. Call from a Timer publisher or on `scenePhase` resume. Safe to
    /// call repeatedly; it is idempotent for a fixed `now()` value.
    func tick() {
        guard state == .running else { return }
        advance()
    }

    // MARK: Private

    /// Pulls the latest wall-clock reading into `elapsedInInterval` without
    /// crossing interval boundaries (used for pause snapshot / countdown checks
    /// inside the current interval).
    private func recomputeElapsed() {
        guard let interval = currentInterval else { return }
        let raw = now().timeIntervalSince(intervalStartReference)
        elapsedInInterval = min(max(0, raw), interval.duration)
    }

    /// Walk forward through any intervals that have completed since the last
    /// tick, emitting end / start cues with carry-over so we don't drift even
    /// after long background gaps.
    private func advance() {
        while state == .running, let interval = currentInterval {
            let raw = now().timeIntervalSince(intervalStartReference)
            if raw < interval.duration {
                elapsedInInterval = max(0, raw)
                emitCountdownIfNeeded(interval: interval)
                return
            }
            // Interval boundary crossed.
            cueHandler(.intervalEnded(index: currentIndex))
            let overflow = raw - interval.duration
            let nextIndex = currentIndex + 1
            if workout.intervals.indices.contains(nextIndex) {
                currentIndex = nextIndex
                elapsedInInterval = 0
                lastEmittedCountdownSecond = 0
                // Carry overflow into the new interval so a slow tick doesn't
                // lose time.
                intervalStartReference = now().addingTimeInterval(-overflow)
                cueHandler(.intervalStarted(index: nextIndex))
            } else {
                // Last interval finished naturally.
                elapsedInInterval = interval.duration
                finish(natural: true)
                return
            }
        }
    }

    /// Emits a countdown cue when the remaining seconds (rounded up) enters the
    /// 3..1 window for the first time within the current interval.
    private func emitCountdownIfNeeded(interval: Interval) {
        let remaining = interval.duration - elapsedInInterval
        // Use ceil so we announce "3" while remaining is in (2, 3], etc.
        let secondsLeft = Int(ceil(remaining))
        guard (1...3).contains(secondsLeft) else { return }
        guard secondsLeft != lastEmittedCountdownSecond else { return }
        // Only count down when we are crossing each integer boundary, not when
        // we resume mid-window with a smaller value than already announced.
        if lastEmittedCountdownSecond == 0 || secondsLeft < lastEmittedCountdownSecond {
            lastEmittedCountdownSecond = secondsLeft
            cueHandler(.countdownTick(secondsRemaining: secondsLeft))
        }
    }

    /// Finalize the session and, when reached naturally, emit the completion
    /// cue exactly once.
    private func finish(natural: Bool) {
        state = .finished
        if natural, !didEmitCompletion {
            didEmitCompletion = true
            cueHandler(.workoutCompleted)
        }
    }
}
