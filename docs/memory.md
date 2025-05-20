## Project Architecture Overview

This project is a SwiftUI-based iOS application structured as follows:

### Root Files
- **README.md**: Project overview and setup instructions.

### docs/
- **idea.md**: Project ideas and brainstorming notes.
- **memory.md**: (This file) Documentation of project architecture and file purposes.
- **research.md**: Research notes and references for the project.
    - **openai.md**: Guide for calling OpenAI APIs in Swift without SDKs.
- **specs/**: Folder containing feature specifications.
  - **workout-detail-view.md**: Specification for the workout detail view feature.
- **plans/**: Folder containing implementation plans.
  - **workout-detail-view-plan.md**: Implementation plan for the workout detail view feature.

### Dropped/
- **ContentView.swift**: The main SwiftUI view for the app's content. Now includes navigation to the AI Workout Generator via a prominent navigation link.
- **Dropped.entitlements**: App entitlements configuration for permissions.
- **DroppedApp.swift**: The main app entry point, sets up the SwiftUI app lifecycle.
- **Assets.xcassets/**: Asset catalog for images, colors, and app icons.
  - **AccentColor.colorset/**: Accent color definition.
  - **AppIcon.appiconset/**: App icon images and metadata.

#### Models/
- **UserData.swift**: Defines the user data model and related logic. Also contains the `Interval`, `Workout`, and `WorkoutDay` models:
  - `Interval`: Represents a single workout interval (power, duration, etc).
  - `Workout`: Represents a workout, including title, date, summary, and intervals.
  - `WorkoutDay`: Merges user data and workout data for a specific day, associating a user's state with a performed workout and optional notes.

- **WorkoutType.swift**: Enum defining the types of cycling workouts (endurance, threshold, vo2Max, sprint, recovery) for user selection and AI prompt construction. Used in the workout generator feature.
- **AIWorkoutGenerator.swift**: Service for generating structured cycling workouts using the OpenAI API. Handles prompt construction, API requests, and response parsing for the workout generator feature.

#### ViewModels/
- **OnboardingViewModel.swift**: ViewModel for onboarding logic and state management.
- **WorkoutGeneratorViewModel.swift**: ViewModel for the AI-powered workout generator feature. Manages state for workout type selection, workout generation, loading, and error handling. Coordinates with AIWorkoutGenerator to fetch structured workouts from OpenAI and handles user acceptance of generated workouts.

#### Views/
 - **InfoPopupView.swift**: SwiftUI view for displaying informational popups.
 - **OnboardingView.swift**: SwiftUI view for onboarding screens.
 - **PlanSummaryView.swift**: SwiftUI view summarizing user plans.
 - **SettingsView.swift**: SwiftUI view for app settings.
 - **WorkoutGeneratorView.swift**: SwiftUI view for the AI-powered workout generator feature. Allows users to select a workout type, generate a workout using AI, and view loading/error states and the generated workout preview.
- **WorkoutGeneratorReviewView.swift**: SwiftUI view for reviewing and accepting a generated workout. Wraps WorkoutDetailView, provides accessible Accept/Regenerate buttons, and smooth transitions.
 - **WorkoutDetailView.swift**: SwiftUI view displaying detailed information about a specific workout, including overview, intervals list, and power graph. Created as part of the workout detail feature. Accessible, supports light/dark mode, and is visually consistent with the app. Contains the `WorkoutDetailGraph` component for inline power/time graph visualization.
 - ~~**WorkoutDetailGraph.swift**~~: (Deprecated; the graph is now implemented inline in WorkoutDetailView.swift as a private component.)

### Dropped.xcodeproj/
- **project.pbxproj**: Xcode project configuration file.
- **project.xcworkspace/**: Xcode workspace data.
  - **contents.xcworkspacedata**: Workspace metadata.
- **xcuserdata/**: User-specific Xcode data (schemes, settings).
  - **xcschemes/**: Xcode scheme management files.

### DroppedTests/
- **DroppedTests.swift**: General unit tests for the app.
- **OnboardingViewModelTests.swift**: Unit tests for onboarding ViewModel.
- **UserDataTests.swift**: Unit tests for user data model.
- **WorkoutDetailTests.swift**: Unit tests for the workout detail functionality.

### DroppedUITests/
- **DroppedUITests.swift**: UI tests for the app.
- **DroppedUITestsLaunchTests.swift**: UI launch tests for the app.
- **WorkoutDetailUITests.swift**: UI tests for the workout detail view.
