//
//  IntervalCueService.swift
//  Dropped
//
//  Translates `IntervalPlayerCueIntent` values from the interval player view
//  model into audible + tactile feedback. Kept as a thin, side-effect-only
//  wrapper so the view model itself can stay pure and testable.
//
//  Responsibilities:
//    • Configure `AVAudioSession` for `.playback` so cues are heard with the
//      ringer switch silenced (typical fitness-app behavior).
//    • Play short system tones for countdown ticks and interval transitions.
//    • Trigger `UIImpactFeedbackGenerator` haptics matching the cue weight.
//    • Speak the next interval target via `AVSpeechSynthesizer` when a new
//      interval begins.
//

import Foundation
import AVFoundation
import AudioToolbox
import UIKit

/// Plays audio + haptic feedback in response to interval player cue intents.
@MainActor
final class IntervalCueService {

    // MARK: Inputs

    /// The workout being played. Used to read interval watts when speaking a
    /// "Next: X watts" cue.
    private let workout: Workout

    // MARK: Dependencies

    private let synthesizer: AVSpeechSynthesizer
    private let lightHaptic: UIImpactFeedbackGenerator
    private let mediumHaptic: UIImpactFeedbackGenerator
    private let heavyHaptic: UIImpactFeedbackGenerator
    private let notificationHaptic: UINotificationFeedbackGenerator

    // System sound IDs. We use built-in tones to avoid bundling assets.
    private let countdownSoundID: SystemSoundID = 1057   // "Tink"
    private let transitionSoundID: SystemSoundID = 1113  // "Begin Recording"
    private let completionSoundID: SystemSoundID = 1025  // "Fanfare"

    // MARK: Init

    init(workout: Workout) {
        self.workout = workout
        self.synthesizer = AVSpeechSynthesizer()
        self.lightHaptic = UIImpactFeedbackGenerator(style: .light)
        self.mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
        self.heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
        self.notificationHaptic = UINotificationFeedbackGenerator()
    }

    /// Configure the shared audio session for playback. Call once when the
    /// player presents.
    func activate() {
        do {
            let session = AVAudioSession.sharedInstance()
            // `.playback` so cues are audible even when the silent switch is on.
            // `.mixWithOthers` so we don't kill the rider's music.
            try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true, options: [])
        } catch {
            // Audio is best-effort; haptics will still fire.
            print("IntervalCueService: audio session activation failed: \(error)")
        }
        lightHaptic.prepare()
        mediumHaptic.prepare()
        heavyHaptic.prepare()
        notificationHaptic.prepare()
    }

    /// Release the audio session. Call when the player dismisses.
    func deactivate() {
        synthesizer.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    /// Handle a single cue intent emitted by the view model.
    func handle(_ intent: IntervalPlayerCueIntent) {
        switch intent {
        case .countdownTick:
            AudioServicesPlaySystemSound(countdownSoundID)
            lightHaptic.impactOccurred()
            lightHaptic.prepare()

        case .intervalEnded:
            AudioServicesPlaySystemSound(transitionSoundID)
            mediumHaptic.impactOccurred()
            mediumHaptic.prepare()

        case .intervalStarted(let index):
            heavyHaptic.impactOccurred()
            heavyHaptic.prepare()
            speakStart(forIndex: index)

        case .workoutCompleted:
            AudioServicesPlaySystemSound(completionSoundID)
            notificationHaptic.notificationOccurred(.success)
            speak("Workout complete. Nice work.")
        }
    }

    // MARK: Private helpers

    private func speakStart(forIndex index: Int) {
        guard workout.intervals.indices.contains(index) else { return }
        let interval = workout.intervals[index]
        let minutes = Int(interval.duration) / 60
        let seconds = Int(interval.duration) % 60
        let durationPhrase: String
        if minutes > 0 && seconds > 0 {
            durationPhrase = "\(minutes) minute\(minutes == 1 ? "" : "s") \(seconds) second\(seconds == 1 ? "" : "s")"
        } else if minutes > 0 {
            durationPhrase = "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            durationPhrase = "\(seconds) second\(seconds == 1 ? "" : "s")"
        }
        speak("Next: \(interval.watts) watts for \(durationPhrase).")
    }

    private func speak(_ phrase: String) {
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }
}
