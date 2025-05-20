# Implementation Plan for AI-Powered Cycling Training Plan Generator

- [ ] Step 1: Create WorkoutType Model and AIWorkoutGenerator Service
  - **Task**: Define the workout types and create a service to communicate with OpenAI API
  - **Files**:
    - `Dropped/Models/WorkoutType.swift`: Create enum for workout types with descriptions
    - `Dropped/Services/AIWorkoutGenerator.swift`: Create service for OpenAI API communication
  - **Dependencies**: None

- [ ] Step 2: Create WorkoutGeneratorViewModel
  - **Task**: Create ViewModel to handle the workout generation logic and state
  - **Files**:
    - `Dropped/ViewModels/WorkoutGeneratorViewModel.swift`: Create ViewModel with methods for workout type selection and workout generation
  - **Dependencies**: AIWorkoutGenerator service, UserData model

- [ ] Step 3: Implement WorkoutGeneratorView
  - **Task**: Create the main view for workout type selection and generation
  - **Files**:
    - `Dropped/Views/WorkoutGeneratorView.swift`: Create view with workout type selection UI and generate button
  - **Dependencies**: WorkoutGeneratorViewModel

- [ ] Step 4: Implement Generated Workout Review and Acceptance
  - **Task**: Use existing WorkoutDetailView to display the generated workout and add accept/reject buttons
  - **Files**:
    - `Dropped/Views/WorkoutGeneratorReviewView.swift`: Create wrapper view for the existing WorkoutDetailView with accept/reject controls
  - **Dependencies**: WorkoutDetailView, WorkoutGeneratorViewModel

- [ ] Step 5: Update ContentView to Include Workout Generator
  - **Task**: Add navigation to the new WorkoutGeneratorView
  - **Files**:
    - `Dropped/ContentView.swift`: Update to include navigation to WorkoutGeneratorView
  - **Dependencies**: WorkoutGeneratorView

- [ ] Step 6: Update UserData Model to Handle Generated Workouts
  - **Task**: Add functions to save generated workouts to the weekly schedule
  - **Files**:
    - `Dropped/Models/UserData.swift`: Add method to add workout to the weekly schedule
  - **Dependencies**: Workout model

- [ ] Step 7: Implement Loading State and Error Handling
  - **Task**: Add loading indicators and error handling for API calls
  - **Files**:
    - `Dropped/ViewModels/WorkoutGeneratorViewModel.swift`: Update with loading state and error handling
    - `Dropped/Views/WorkoutGeneratorView.swift`: Update with loading indicator and error messages
  - **Dependencies**: None

- [ ] Step 8: Build and Run the App
  - **Task**: Test the feature in the simulator
  - **Files**: No file changes required
  - **Dependencies**: Completed implementation

- [ ] Step 9: Write Unit and UI Tests
  - **Task**: Create tests for the new functionality
  - **Files**:
    - `DroppedTests/WorkoutGeneratorViewModelTests.swift`: Unit tests for the ViewModel
    - `DroppedTests/AIWorkoutGeneratorTests.swift`: Unit tests for the OpenAI service
    - `DroppedUITests/WorkoutGeneratorUITests.swift`: UI tests for the workout generator feature
  - **Dependencies**: Completed implementation

- [ ] Step 10: Run All Tests
  - **Task**: Verify all tests pass
  - **Files**: No file changes required
  - **Dependencies**: Completed tests

## Implementation Details

### Step 1: Create WorkoutType Model and AIWorkoutGenerator Service

The `WorkoutType` enum will define the different types of workouts that can be generated:

```swift
// WorkoutType.swift pseudocode
enum WorkoutType: String, CaseIterable, Identifiable {
    case endurance, threshold, vo2Max, sprint, recovery
    
    var id: String { rawValue }
    
    var title: String {
        // Return user-friendly title
    }
    
    var description: String {
        // Return description and benefits
    }
}
```

The `AIWorkoutGenerator` service will handle communication with OpenAI:

```swift
// AIWorkoutGenerator.swift pseudocode
class AIWorkoutGenerator {
    func generateWorkout(type: WorkoutType, ftp: Int) async throws -> Workout {
        // Format prompt for OpenAI
        // Make API call
        // Parse response into Workout object
        // Return structured workout
    }
    
    private func createPrompt(type: WorkoutType, ftp: Int) -> String {
        // Create specific prompt based on workout type and FTP
    }
    
    private func parseResponse(response: String, ftp: Int) -> Workout {
        // Parse OpenAI response into a structured Workout
    }
}
```

### Step 2: Create WorkoutGeneratorViewModel

The ViewModel will manage the state and logic for workout generation:

```swift
// WorkoutGeneratorViewModel.swift pseudocode
class WorkoutGeneratorViewModel: ObservableObject {
    @Published var selectedWorkoutType: WorkoutType = .endurance
    @Published var generatedWorkout: Workout?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let workoutGenerator = AIWorkoutGenerator()
    private let userData: UserData
    
    init(userData: UserData) {
        self.userData = userData
    }
    
    func generateWorkout() async {
        isLoading = true
        do {
            let workout = try await workoutGenerator.generateWorkout(
                type: selectedWorkoutType, 
                ftp: userData.ftp
            )
            generatedWorkout = workout
            errorMessage = nil
        } catch {
            errorMessage = "Failed to generate workout: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func acceptWorkout() {
        guard let workout = generatedWorkout else { return }
        userData.addWorkoutToSchedule(workout)
    }
}
```

### Step 3: Implement WorkoutGeneratorView

The main view for selecting workout type and generating:

```swift
// WorkoutGeneratorView.swift pseudocode
struct WorkoutGeneratorView: View {
    @StateObject var viewModel: WorkoutGeneratorViewModel
    @State private var showingReview = false
    
    var body: some View {
        // Display workout type options with descriptions
        // Provide generate button
        // Show loading indicator when isLoading
        // Display error message if present
        // Navigate to review view when workout is generated
    }
}
```

### Step 4: Implement Generated Workout Review and Acceptance

The review view that wraps the existing WorkoutDetailView:

```swift
// WorkoutGeneratorReviewView.swift pseudocode
struct WorkoutGeneratorReviewView: View {
    @ObservedObject var viewModel: WorkoutGeneratorViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        // Display WorkoutDetailView with the generated workout
        // Add accept/reject buttons
        // Handle accept action by calling viewModel.acceptWorkout()
        // Return to previous screen or main view after action
    }
}
```

### Step 5: Update ContentView

Add navigation to the new WorkoutGeneratorView:

```swift
// ContentView.swift pseudocode updates
// Add navigation link to WorkoutGeneratorView
```

### Step 6: Update UserData Model

Update the UserData model to handle adding workouts to the schedule:

```swift
// UserData.swift pseudocode additions
func addWorkoutToSchedule(_ workout: Workout) {
    // Create WorkoutDay from workout
    // Add to top of schedule
    // Save changes
}
```

### Step 7: Implement Loading State and Error Handling

Enhance the UI components with loading indicators and error messages.

### Steps 8-10: Building, Testing, and Running

These steps involve building and running the app in the simulator and creating comprehensive tests for the new functionality.
