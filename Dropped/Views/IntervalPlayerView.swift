//
//  IntervalPlayerView.swift
//  Dropped
//
//  Full-screen guided workout player. Drives `IntervalPlayerViewModel` with a
//  10 Hz timer, plays cues through `IntervalCueService`, and keeps the screen
//  awake for the duration of the session.
//
//  This file owns only presentation; all timing/state logic lives in the view
//  model so it can be unit-tested without UIKit.
//

import SwiftUI
import UIKit

/// Full-screen interval player presented from `WorkoutDetailView`.
struct IntervalPlayerView: View {
    let workout: Workout
    let ftp: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel: IntervalPlayerViewModel
    @State private var cueService: IntervalCueService
    @State private var showEndConfirm: Bool = false

    /// 10 Hz tick keeps the displayed seconds smooth without burning battery.
    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    init(workout: Workout, ftp: Int) {
        self.workout = workout
        self.ftp = ftp
        let service = IntervalCueService(workout: workout)
        _cueService = State(initialValue: service)
        _viewModel = StateObject(wrappedValue: IntervalPlayerViewModel(
            workout: workout,
            ftp: ftp,
            cueHandler: { [service] intent in service.handle(intent) }
        ))
    }

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                topBar
                Spacer(minLength: 8)
                BigTargetBlock(
                    watts: viewModel.currentTargetWatts,
                    percentFTP: viewModel.currentPercentFTP,
                    state: viewModel.state
                )
                IntervalTimerBlock(
                    elapsed: viewModel.elapsedInInterval,
                    remaining: viewModel.remainingInInterval,
                    intervalIndex: viewModel.currentIndex,
                    totalIntervals: workout.intervals.count
                )
                Spacer(minLength: 8)
                NextIntervalPreview(next: viewModel.nextInterval, ftp: ftp)
                OverallProgressBar(
                    progress: viewModel.progressFraction,
                    overallElapsed: viewModel.overallElapsed,
                    overallRemaining: viewModel.overallRemaining
                )
                PlayerControlsBar(
                    state: viewModel.state,
                    onPauseResume: { togglePauseResume() },
                    onSkip: { viewModel.skip() },
                    onEnd: { showEndConfirm = true }
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .onAppear {
            cueService.activate()
            UIApplication.shared.isIdleTimerDisabled = true
            viewModel.start()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            cueService.deactivate()
        }
        .onReceive(ticker) { _ in
            viewModel.tick()
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                // Recompute immediately after returning from background so the
                // UI doesn't show a stale frame for the next 100ms.
                viewModel.tick()
            }
        }
        .onChange(of: viewModel.state) { _, newValue in
            if newValue == .finished {
                // Brief delay so the completion cue is heard before dismissing.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            }
        }
        .confirmationDialog(
            "End workout?",
            isPresented: $showEndConfirm,
            titleVisibility: .visible
        ) {
            Button("End workout", role: .destructive) {
                viewModel.endEarly()
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Your progress so far won't be saved.")
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(.systemIndigo).opacity(0.85), Color.black],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var topBar: some View {
        HStack {
            Button {
                if viewModel.state == .running {
                    viewModel.pause()
                }
                showEndConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.15)))
                    .foregroundColor(.white)
            }
            .accessibilityLabel("End workout")

            Spacer()

            Text(workout.title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)

            Spacer()

            // Spacer to balance the X button visually.
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private func togglePauseResume() {
        switch viewModel.state {
        case .running: viewModel.pause()
        case .paused: viewModel.resume()
        default: break
        }
    }
}

// MARK: - Subviews

/// Big primary number showing the current target (watts + %FTP secondary).
private struct BigTargetBlock: View {
    let watts: Int?
    let percentFTP: Double?
    let state: IntervalPlayerState

    var body: some View {
        VStack(spacing: 4) {
            Text("TARGET")
                .font(.caption)
                .tracking(2)
                .foregroundColor(.white.opacity(0.6))
            Text(watts.map { "\($0)" } ?? "—")
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
                .accessibilityLabel(watts.map { "Target \($0) watts" } ?? "No target")
            Text("watts")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            if let percentFTP {
                Text(percentFTPText(percentFTP))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.top, 2)
                    .accessibilityLabel("\(Int((percentFTP * 100).rounded())) percent of F T P")
            }
            if state == .paused {
                Text("PAUSED")
                    .font(.caption)
                    .tracking(3)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.yellow.opacity(0.25)))
                    .foregroundColor(.yellow)
                    .padding(.top, 8)
            }
        }
    }

    private func percentFTPText(_ value: Double) -> String {
        let percent = Int((value * 100).rounded())
        return "\(percent)% FTP"
    }
}

/// Per-interval elapsed/remaining timer with interval index.
private struct IntervalTimerBlock: View {
    let elapsed: TimeInterval
    let remaining: TimeInterval
    let intervalIndex: Int
    let totalIntervals: Int

    var body: some View {
        VStack(spacing: 6) {
            Text("Interval \(min(intervalIndex + 1, totalIntervals)) of \(totalIntervals)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            HStack(spacing: 24) {
                timeColumn(label: "ELAPSED", value: elapsed)
                Divider().frame(height: 36).background(Color.white.opacity(0.2))
                timeColumn(label: "LEFT", value: remaining)
            }
        }
    }

    private func timeColumn(label: String, value: TimeInterval) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .tracking(2)
                .foregroundColor(.white.opacity(0.55))
            Text(formatTime(value))
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label.lowercased()) \(formatTime(value))")
    }
}

/// Compact preview of the upcoming interval, or a "last interval" hint.
private struct NextIntervalPreview: View {
    let next: Interval?
    let ftp: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "forward.end.alt.fill")
                .foregroundColor(.white.opacity(0.7))
            if let next {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Up next")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(detailLine(for: next))
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            } else {
                Text("Last interval — finish strong")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
        .accessibilityElement(children: .combine)
    }

    private func detailLine(for interval: Interval) -> String {
        var parts: [String] = ["\(interval.watts) W"]
        if ftp > 0 {
            let percent = Int((Double(interval.watts) / Double(ftp) * 100).rounded())
            parts.append("\(percent)% FTP")
        }
        parts.append(formatTime(interval.duration))
        return parts.joined(separator: " · ")
    }
}

/// Overall workout progress with elapsed / remaining readouts.
private struct OverallProgressBar: View {
    let progress: Double
    let overallElapsed: TimeInterval
    let overallRemaining: TimeInterval

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15))
                    Capsule()
                        .fill(Color.green)
                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progress))))
                        .animation(.linear(duration: 0.1), value: progress)
                }
            }
            .frame(height: 8)
            HStack {
                Text(formatTime(overallElapsed))
                Spacer()
                Text("-\(formatTime(overallRemaining))")
            }
            .font(.caption)
            .monospacedDigit()
            .foregroundColor(.white.opacity(0.8))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Overall progress \(Int((progress * 100).rounded())) percent")
    }
}

/// Pause/resume + skip + end controls.
private struct PlayerControlsBar: View {
    let state: IntervalPlayerState
    let onPauseResume: () -> Void
    let onSkip: () -> Void
    let onEnd: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            controlButton(
                systemName: "stop.fill",
                label: "End",
                tint: .red.opacity(0.9),
                action: onEnd
            )
            Spacer()
            primaryControl
            Spacer()
            controlButton(
                systemName: "forward.fill",
                label: "Skip",
                tint: .white.opacity(0.2),
                action: onSkip,
                disabled: state == .finished
            )
        }
    }

    private var primaryControl: some View {
        Button(action: onPauseResume) {
            Image(systemName: state == .running ? "pause.fill" : "play.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 84, height: 84)
                .background(Circle().fill(Color.white))
        }
        .disabled(state == .finished || state == .idle)
        .accessibilityLabel(state == .running ? "Pause" : "Resume")
    }

    private func controlButton(
        systemName: String,
        label: String,
        tint: Color,
        action: @escaping () -> Void,
        disabled: Bool = false
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(tint))
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
        .accessibilityLabel(label)
    }
}

// MARK: - Helpers

/// Format a `TimeInterval` as `M:SS` (or `H:MM:SS` for hour-plus durations).
private func formatTime(_ value: TimeInterval) -> String {
    let total = max(0, Int(value.rounded()))
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%d:%02d", minutes, seconds)
}
