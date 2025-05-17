# Implementation Plan for Detail View for Weekly Plan Workout

- [ ] Step 1: Update Weekly Plan Summary to Make Workouts Tappable
  - **Task**: Ensure each workout in the weekly plan summary is a tappable item that triggers navigation to a detail view.
  - **Files**:
    - `Views/PlanSummaryView.swift`: Update workout list to use `NavigationLink` or similar, passing selected workout data.
      - Pseudocode:
        ```
        ForEach(workouts) { workout in
          NavigationLink(destination: WorkoutDetailView(workout: workout)) {
            WorkoutRow(workout: workout)
          }
        }
        ```
  - **Dependencies**: SwiftUI navigation, workout data model.

- [ ] Step 2: Create Workout Detail View
  - **Task**: Implement a new SwiftUI view to display workout details (name/type, duration, intensity, description).
  - **Files**:
    - `Views/WorkoutDetailView.swift`: New file for the detail view.
      - Pseudocode:
        ```
        struct WorkoutDetailView: View {
          let workout: Workout
          var body: some View {
            VStack {
              Text(workout.name)
              Text(workout.type)
              Text("\(workout.duration) min")
              Text("Intensity: \(workout.intensity)")
              if let desc = workout.description {
                Text(desc)
              }
            }
            .navigationTitle("Workout Details")
          }
        }
        ```
  - **Dependencies**: Workout data model.

- [ ] Step 3: Update Workout Data Model if Needed
  - **Task**: Ensure the workout model contains all required fields (name/type, duration, intensity, description).
  - **Files**:
    - `Models/UserData.swift`: Update or confirm the workout struct/class.
      - Pseudocode:
        ```
        struct Workout: Identifiable {
          let id: UUID
          let name: String
          let type: String
          let duration: Int
          let intensity: String
          let description: String?
        }
        ```
  - **Dependencies**: None.

- [ ] Step 4: Ensure Navigation Back to Weekly Plan Summary
  - **Task**: Use SwiftUI navigation to allow users to return to the summary (back button in navigation bar).
  - **Files**:
    - `Views/WorkoutDetailView.swift`: Confirm navigation bar is present.
      - Pseudocode:
        ```
        // No extra code needed if using NavigationStack/NavigationView
        ```
  - **Dependencies**: SwiftUI navigation.

- [ ] Step 5: Polish UI for Clarity and Minimalism
  - **Task**: Apply clean, minimal styling to the detail view for readability.
  - **Files**:
    - `Views/WorkoutDetailView.swift`: Add spacing, font weights, and accessibility labels.
      - Pseudocode:
        ```
        VStack(spacing: 16) {
          // ...fields...
        }
        .accessibilityElement(children: .combine)
        ```
  - **Dependencies**: SwiftUI modifiers.

- [ ] Step 6: Build and Run the App
  - **Task**: Build and run the app in the iOS simulator to verify navigation and UI.
  - **User Intervention**: None (handled by build/run instructions).

- [ ] Step 7: Write Unit and UI Tests for the Feature
  - **Task**: Add tests to verify navigation, data passing, and UI rendering.
  - **Files**:
    - `DroppedTests/UserDataTests.swift`: Test workout model.
    - `DroppedUITests/DroppedUITests.swift`: Test navigation from summary to detail and back.
      - Pseudocode:
        ```
        func testWorkoutDetailNavigation() {
          // Launch app, tap workout, assert detail view appears
        }
        ```
  - **Dependencies**: XCTest, XCUITest.

- [ ] Step 8: Run All Unit and UI Tests
  - **Task**: Execute all tests to ensure feature works and nothing is broken.
  - **User Intervention**: None (handled by test runner).

