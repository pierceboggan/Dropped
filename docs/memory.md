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

- **UserData.swift**: Core user, workout, interval, and workout-day models. Also contains persisted `UserDataManager` and `WorkoutManager` storage helpers. `UserDataManager` exposes `updateWeightFromHealth(kg:sampleDate:)` for HealthKit sync, and `WorkoutManager` exposes `markWorkoutCompleted(_:summary:)` which writes to HealthKit when the user has enabled `WorkoutManager.healthSyncEnabledKey`.
- **WorkoutType.swift**: Enum defining AI workout types: endurance, threshold, VO2 max, sprint, and recovery.
- **AIWorkoutGenerator.swift**: OpenAI chat-completions client for generated workouts. Reads API keys from configuration, requests a strict JSON schema, and converts responses into `Workout` models.
- **HealthKitService.swift**: HealthKit integration. Defines the `HealthKitServicing` protocol, default `HealthKitService` implementation backed by `HKHealthStore` + `HKWorkoutBuilder`, the `CompletedWorkoutSummary` value type used to write cycling workouts, energy estimation helpers, and a `syncBodyMassToProfile(using:)` extension that pushes newer Health weights into `UserDataManager`. Simulator/macOS-safe via availability gates.

#### Dropped/ViewModels/

- **OnboardingViewModel.swift**: Onboarding validation, unit conversion, and profile-save logic.
- **WorkoutGeneratorViewModel.swift**: AI workout generator state, loading/error handling, and generated-workout acceptance into persisted workout storage.

#### Dropped/Views/

- **InfoPopupView.swift**: Informational modal used for onboarding help.
- **OnboardingView.swift**: Rider profile setup screen.
- **PlanSummaryView.swift**: Training plan summary, generated workout cards, settings entry point, and onboarding reset.
- **SettingsView.swift**: Settings screen for preferred weight units and app information.
- **WorkoutDetailView.swift**: Detailed workout screen with overview, interval list, and inline power/time graph.
- **WorkoutGeneratorView.swift**: AI workout type selection and generation screen.
- **WorkoutGeneratorReviewView.swift**: Review surface for accepting or regenerating an AI-generated workout.

### Dropped.xcodeproj/

- **project.pbxproj**: Xcode project configuration.
- **project.xcworkspace/**: Xcode workspace metadata.

### DroppedTests/

- **OnboardingViewModelTests.swift**: Unit tests for onboarding validation, unit conversion, and user-data saving.
- **UserDataTests.swift**: Unit tests for unit conversion, user-data persistence, onboarding completion, and workout persistence reset behavior.
- **HealthKitServiceTests.swift**: Unit tests for the HealthKit integration. Uses a `MockHealthKitService` to verify body-mass sync logic, energy estimation math, and `WorkoutManager.markWorkoutCompleted` write-through behavior driven by the Health-sync toggle.

### DroppedUITests/

- **DroppedUITests.swift**: UI tests for onboarding and basic plan access.
- **DroppedUITestsLaunchTests.swift**: UI launch tests.
