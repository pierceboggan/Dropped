## Project Architecture Overview

This project is a SwiftUI-based iOS cycling training application.

### Root files

- **README.md**: Project overview, setup instructions, OpenAI configuration, and test command.

### docs/

- **idea.md**: Project ideas and brainstorming notes.
- **memory.md**: This file. Documents the current project structure and file purposes.
- **openai.md**: Notes for calling OpenAI APIs from Swift without an SDK.
- **research.md**: Research notes and references for the project.
- **specs/**: Feature specifications.
- **plans/**: Historical implementation plans.

### Dropped/

- **ContentView.swift**: App root view. Shows onboarding until the user profile is complete, then exposes the training plan and AI workout generator entry points.
- **Dropped.entitlements**: App entitlements configuration.
- **DroppedApp.swift**: SwiftUI app entry point. Handles UI-test reset launch arguments before showing ContentView.
- **Assets.xcassets/**: Asset catalog for app icons and colors.

#### Dropped/Models/

- **UserData.swift**: Core user, workout, interval, and workout-day models. Also contains persisted `UserDataManager` and `WorkoutManager` storage helpers (workouts, workout days, and completion logs). `Workout` carries an optional `testKind` marker (back-compat decoded) for built-in tests; `UserData` exposes a computed `powerZones` property.
- **WorkoutType.swift**: Enum defining AI workout types: endurance, threshold, VO2 max, sprint, and recovery.
- **AIWorkoutGenerator.swift**: OpenAI chat-completions client for generated workouts. Reads API keys from configuration, requests a strict JSON schema, and converts responses into `Workout` models.
- **WorkoutLog.swift**: Persisted record of a completed workout (RPE, optional avg power / HR / duration override, notes, plus a `UserData` snapshot). Exposes derived `effectiveDuration`, `intensityFactor`, and `estimatedTSS` for future TSS / charts / streak surfaces.
- **PowerZones.swift**: `PowerZone` enum (Coggan Z1–Z7 with %FTP bounds, names, colors) and `PowerZones` struct that maps an FTP value to per-zone watt ranges.
- **FTPTest.swift**: `FTPTestType` enum (`.twentyMinute`, `.ramp`), `FTPCalculator` (FTP from 20-min avg or ramp final-minute power), and `FTPTestWorkouts` factory that builds standard `Workout` instances for each protocol.

#### Dropped/ViewModels/

- **OnboardingViewModel.swift**: Onboarding validation, unit conversion, and profile-save logic.
- **WorkoutGeneratorViewModel.swift**: AI workout generator state, loading/error handling, and generated-workout acceptance into persisted workout storage.
- **WorkoutLogViewModel.swift**: Form-state owner for the workout-completion sheet. Validates RPE, manages optional metric toggles, and bridges save / delete to `WorkoutManager`.
- **FTPTestResultViewModel.swift**: Validates a rider's FTP-test result entry, computes the new FTP, and persists it via injected `UserDataManager`/`WorkoutManager` (also marks the source test workout completed).
- **IntervalPlayerViewModel.swift**: Pure, testable state machine for the in-app interval player. Drives interval progression via an injectable wall-clock and emits `IntervalPlayerCueIntent` values for audio/haptic side effects.

#### Dropped/Services/

- **IntervalCueService.swift**: Translates `IntervalPlayerCueIntent` values into AVFoundation system sounds, `UIImpactFeedbackGenerator` haptics, and `AVSpeechSynthesizer` spoken cues. Configures the shared `AVAudioSession` for playback during a session.

#### Dropped/Views/

- **InfoPopupView.swift**: Informational modal used for onboarding help.
- **OnboardingView.swift**: Rider profile setup screen.
- **PlanSummaryView.swift**: Training plan summary, generated workout cards (with completion badges), settings entry point, and onboarding reset.
- **SettingsView.swift**: Settings screen for preferred weight units and app information.
- **WorkoutDetailView.swift**: Detailed workout screen with overview, completion summary, interval list, inline power/time graph, a "Start workout" CTA that presents the full-screen interval player, and the "Mark Complete" / "Edit Log" CTA.
- **IntervalPlayerView.swift**: Full-screen guided interval player. Hosts `IntervalPlayerViewModel`, drives a 10 Hz timer, plays cues via `IntervalCueService`, keeps the screen awake (`isIdleTimerDisabled`), and exposes pause/resume/skip/end-early controls.
- **WorkoutGeneratorView.swift**: AI workout type selection and generation screen.
- **WorkoutGeneratorReviewView.swift**: Review surface for accepting or regenerating an AI-generated workout.
- **WorkoutLogSheet.swift**: Modal form for logging a completed workout — RPE, optional avg power / HR / duration override, notes, and "Remove Log" when editing.
- **PowerZonesView.swift**: Lists Coggan zones Z1–Z7 with %FTP ranges and target wattages computed from the rider's current FTP. Includes a link to the FTP tests screen.
- **FTPTestsView.swift**: Lists built-in FTP test protocols (20-minute and Ramp), starts them as scheduled workouts, and provides `FTPTestResultEntryView` — the post-test result entry sheet that previews the new FTP and writes it to the user profile on confirm.

### Dropped.xcodeproj/

- **project.pbxproj**: Xcode project configuration.
- **project.xcworkspace/**: Xcode workspace metadata.

### DroppedTests/

- **OnboardingViewModelTests.swift**: Unit tests for onboarding validation, unit conversion, and user-data saving.
- **UserDataTests.swift**: Unit tests for unit conversion, user-data persistence, onboarding completion, and workout/log persistence reset behavior.
- **WorkoutLogTests.swift**: Unit tests for the `WorkoutLog` model (RPE clamping, notes normalization, derived IF/TSS) and the `WorkoutManager` log persistence APIs.
- **FTPCalculatorTests.swift**: Unit tests for FTP-from-test math (20-minute and ramp formulas, rounding boundaries, non-positive guards).
- **PowerZonesTests.swift**: Unit tests for Coggan zone boundary classification, watt-range computation across FTPs (including FTP=0), and `UserData.powerZones`.
- **FTPTestWorkoutsTests.swift**: Unit tests for the structure of built-in FTP test workouts and `Workout` codable backward compatibility for the new `testKind` field.
- **FTPTestResultViewModelTests.swift**: Unit tests for the result-entry view model using isolated `UserDefaults`, covering profile updates, validation, and the source-workout completion side effect.
- **IntervalPlayerViewModelTests.swift**: Unit tests for the interval player state machine: lifecycle, tick advancement across boundaries (including multi-interval jumps), countdown cue de-duplication, pause/resume across simulated background gaps, skip, end-early, natural completion, progress monotonicity, and watts/%FTP calculations.

### DroppedUITests/

- **DroppedUITests.swift**: UI tests for onboarding and basic plan access.
- **DroppedUITestsLaunchTests.swift**: UI launch tests.
