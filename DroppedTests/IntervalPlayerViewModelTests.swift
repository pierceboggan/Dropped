//
//  IntervalPlayerViewModelTests.swift
//  DroppedTests
//
//  Unit tests for `IntervalPlayerViewModel`. The view model is driven by an
//  injectable clock and cue handler, so every test below operates on a
//  deterministic timeline without sleeping.
//

import XCTest
@testable import Dropped

@MainActor
final class IntervalPlayerViewModelTests: XCTestCase {

    // MARK: Test fixtures

    /// A simple three-interval workout used by most tests:
    ///   • 30s @ 100W
    ///   • 60s @ 200W
    ///   • 30s @ 150W  (total 120s)
    private func makeWorkout() -> Workout {
        Workout(
            title: "Test",
            date: Date(timeIntervalSince1970: 0),
            summary: "fixture",
            intervals: [
                Interval(watts: 100, duration: 30),
                Interval(watts: 200, duration: 60),
                Interval(watts: 150, duration: 30)
            ]
        )
    }

    /// A controllable clock plus a recorder for emitted cue intents.
    private final class Harness {
        var current: Date = Date(timeIntervalSince1970: 1_000)
        var cues: [IntervalPlayerCueIntent] = []

        func now() -> Date { current }
        func record(_ intent: IntervalPlayerCueIntent) { cues.append(intent) }
        func advance(by seconds: TimeInterval) { current = current.addingTimeInterval(seconds) }
    }

    private func makePlayer(
        workout: Workout? = nil,
        ftp: Int = 250,
        harness: Harness = Harness()
    ) -> (IntervalPlayerViewModel, Harness) {
        let w = workout ?? makeWorkout()
        let vm = IntervalPlayerViewModel(
            workout: w,
            ftp: ftp,
            now: { harness.now() },
            cueHandler: { harness.record($0) }
        )
        return (vm, harness)
    }

    // MARK: Lifecycle

    func testStart_setsRunning_andEmitsFirstIntervalStart() {
        let (vm, h) = makePlayer()
        vm.start()
        XCTAssertEqual(vm.state, .running)
        XCTAssertEqual(vm.currentIndex, 0)
        XCTAssertEqual(h.cues, [.intervalStarted(index: 0)])
    }

    func testStart_isNoOp_whenWorkoutHasNoIntervals() {
        let empty = Workout(title: "Empty", date: Date(), summary: "", intervals: [])
        let (vm, h) = makePlayer(workout: empty)
        vm.start()
        XCTAssertEqual(vm.state, .idle)
        XCTAssertTrue(h.cues.isEmpty)
    }

    func testStart_isNoOp_whenAlreadyRunning() {
        let (vm, h) = makePlayer()
        vm.start()
        vm.start()
        XCTAssertEqual(h.cues, [.intervalStarted(index: 0)])
    }

    // MARK: Tick advancement

    func testTick_advancesElapsed_andDecrementsRemaining() {
        let (vm, h) = makePlayer()
        vm.start()
        h.advance(by: 10)
        vm.tick()
        XCTAssertEqual(vm.elapsedInInterval, 10, accuracy: 0.001)
        XCTAssertEqual(vm.remainingInInterval, 20, accuracy: 0.001)
        XCTAssertEqual(vm.overallElapsed, 10, accuracy: 0.001)
        XCTAssertEqual(vm.overallRemaining, 110, accuracy: 0.001)
    }

    func testTick_crossesIntervalBoundary_advancesIndex_andEmitsEndAndStartCues() {
        let (vm, h) = makePlayer()
        vm.start()
        h.advance(by: 31) // 1s into interval 1
        vm.tick()
        XCTAssertEqual(vm.currentIndex, 1)
        XCTAssertEqual(vm.elapsedInInterval, 1, accuracy: 0.01)
        XCTAssertEqual(h.cues, [
            .intervalStarted(index: 0),
            .intervalEnded(index: 0),
            .intervalStarted(index: 1)
        ])
    }

    func testTick_crossesMultipleIntervals_inSingleStep() {
        // Simulate a long background gap that spans the entire second interval.
        let (vm, h) = makePlayer()
        vm.start()
        h.advance(by: 95) // past intervals 0 and 1, 5s into interval 2
        vm.tick()
        XCTAssertEqual(vm.currentIndex, 2)
        XCTAssertEqual(vm.elapsedInInterval, 5, accuracy: 0.01)
        // Boundaries should still emit end+start in order.
        XCTAssertEqual(h.cues, [
            .intervalStarted(index: 0),
            .intervalEnded(index: 0),
            .intervalStarted(index: 1),
            .intervalEnded(index: 1),
            .intervalStarted(index: 2)
        ])
    }

    // MARK: Countdown

    func testCountdown_emits3_2_1_exactlyOnce_perInterval() {
        let (vm, h) = makePlayer()
        vm.start()
        // Walk forward in 0.25s steps through the last 4 seconds of interval 0
        // (i.e. from t=26.0 to t=30.0). Many ticks land in the same second; we
        // expect exactly one cue per integer second.
        var t: TimeInterval = 0
        h.advance(by: 26)
        vm.tick()
        for _ in 0..<16 {
            h.advance(by: 0.25)
            t += 0.25
            vm.tick()
        }
        let countdownCues = h.cues.filter {
            if case .countdownTick = $0 { return true } else { return false }
        }
        XCTAssertEqual(countdownCues, [
            .countdownTick(secondsRemaining: 3),
            .countdownTick(secondsRemaining: 2),
            .countdownTick(secondsRemaining: 1)
        ])
    }

    func testCountdown_resetsBetweenIntervals() {
        let (vm, h) = makePlayer()
        vm.start()
        h.advance(by: 30) // exactly to boundary -> advance to interval 1
        vm.tick()
        // Now sweep through the end of interval 1 (60s long, so countdown
        // happens at remaining=3,2,1 -> elapsedInInterval ~ 57,58,59).
        h.advance(by: 57)
        vm.tick()
        h.advance(by: 1)
        vm.tick()
        h.advance(by: 1)
        vm.tick()
        let countdownCues = h.cues.filter {
            if case .countdownTick = $0 { return true } else { return false }
        }
        XCTAssertEqual(countdownCues, [
            .countdownTick(secondsRemaining: 3),
            .countdownTick(secondsRemaining: 2),
            .countdownTick(secondsRemaining: 1)
        ])
    }

    // MARK: Pause / resume

    func testPause_thenResume_doesNotLoseElapsed_acrossWallClockGap() {
        let (vm, h) = makePlayer()
        vm.start()
        h.advance(by: 10)
        vm.tick()
        vm.pause()
        XCTAssertEqual(vm.state, .paused)
        XCTAssertEqual(vm.elapsedInInterval, 10, accuracy: 0.001)

        // Simulate the user pausing for 5 minutes (e.g. app backgrounded).
        h.advance(by: 300)
        vm.resume()
        XCTAssertEqual(vm.state, .running)
        // No additional in-interval time should have accrued.
        XCTAssertEqual(vm.elapsedInInterval, 10, accuracy: 0.05)

        // Now real workout time advances normally.
        h.advance(by: 5)
        vm.tick()
        XCTAssertEqual(vm.elapsedInInterval, 15, accuracy: 0.05)
    }

    func testPause_isNoOp_whenNotRunning() {
        let (vm, _) = makePlayer()
        vm.pause()
        XCTAssertEqual(vm.state, .idle)
    }

    // MARK: Skip

    func testSkip_movesToNextInterval_andEmitsCues() {
        let (vm, h) = makePlayer()
        vm.start()
        h.advance(by: 5)
        vm.tick()
        h.cues.removeAll()
        vm.skip()
        XCTAssertEqual(vm.currentIndex, 1)
        XCTAssertEqual(vm.elapsedInInterval, 0, accuracy: 0.001)
        XCTAssertEqual(h.cues, [
            .intervalEnded(index: 0),
            .intervalStarted(index: 1)
        ])
    }

    func testSkip_onLastInterval_finishesWorkout_withoutNaturalCompletionCue() {
        let (vm, h) = makePlayer()
        vm.start()
        // Jump straight to the last interval.
        h.advance(by: 90)
        vm.tick()
        XCTAssertEqual(vm.currentIndex, 2)
        h.cues.removeAll()
        vm.skip()
        XCTAssertEqual(vm.state, .finished)
        XCTAssertEqual(h.cues, [.intervalEnded(index: 2)])
        XCTAssertFalse(h.cues.contains(.workoutCompleted))
    }

    // MARK: End early

    func testEndEarly_setsFinished_andStopsFurtherCues() {
        let (vm, h) = makePlayer()
        vm.start()
        h.advance(by: 5)
        vm.tick()
        h.cues.removeAll()
        vm.endEarly()
        XCTAssertEqual(vm.state, .finished)
        XCTAssertTrue(h.cues.isEmpty, "endEarly should not emit a completion cue")

        // Subsequent ticks are no-ops.
        h.advance(by: 60)
        vm.tick()
        XCTAssertTrue(h.cues.isEmpty)
    }

    // MARK: Natural completion

    func testNaturalCompletion_emitsWorkoutCompleted_exactlyOnce() {
        let (vm, h) = makePlayer()
        vm.start()
        h.advance(by: 200) // well past the 120s total
        vm.tick()
        XCTAssertEqual(vm.state, .finished)
        let completionCount = h.cues.filter { $0 == .workoutCompleted }.count
        XCTAssertEqual(completionCount, 1)

        // Extra ticks do not re-fire.
        vm.tick()
        let completionCount2 = h.cues.filter { $0 == .workoutCompleted }.count
        XCTAssertEqual(completionCount2, 1)
    }

    // MARK: Progress + targets

    func testProgressFraction_isMonotonic_andClampedTo0_1() {
        let (vm, h) = makePlayer()
        vm.start()
        var last: Double = -1
        for step in stride(from: 0, through: 200, by: 5) {
            h.current = Date(timeIntervalSince1970: 1_000 + Double(step))
            vm.tick()
            XCTAssertGreaterThanOrEqual(vm.progressFraction, last)
            XCTAssertGreaterThanOrEqual(vm.progressFraction, 0)
            XCTAssertLessThanOrEqual(vm.progressFraction, 1)
            last = vm.progressFraction
        }
        XCTAssertEqual(vm.progressFraction, 1, accuracy: 0.0001)
    }

    func testCurrentTargetWatts_andPercentFTP() {
        let (vm, _) = makePlayer(ftp: 200)
        vm.start()
        XCTAssertEqual(vm.currentTargetWatts, 100)
        XCTAssertEqual(vm.currentPercentFTP ?? 0, 0.5, accuracy: 0.0001)
    }

    func testPercentFTP_isNil_whenFTPIsZero() {
        let (vm, _) = makePlayer(ftp: 0)
        vm.start()
        XCTAssertNil(vm.currentPercentFTP)
    }
}
