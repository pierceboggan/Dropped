# Functional Specification: Workout Detail Screen

## Overview
This feature will provide users with a detailed view of their scheduled workouts when tapped from the PlanSummaryView. The detailed view will present comprehensive information about the workout, including specific intervals, instructions, progress tracking, and additional details not present in the summary card.

## Current State
Currently, the app shows a simple card-based summary of each workout in the weekly plan within the PlanSummaryView. Users can see basic information about each workout (day, title, description, duration, and intensity) but cannot access more detailed information about how to perform the workout.

## Proposed Solution
Implement a WorkoutDetailView that opens when a user taps on a workout card in the PlanSummaryView. This detailed view will present comprehensive information about the workout, allowing users to better understand and execute their training plan.

## Implementation Plan

### Step 1: Enhance the WorkoutDay Model
**Objective:** Expand the WorkoutDay model to include additional information needed for the detail view.

**Steps:**
1. Update the WorkoutDay struct to include additional properties:
   - Intervals or segments (array of workout segments)
   - Equipment needed
   - Specific instructions
   - Target zones (heart rate, power)
   - Completion status

**Pseudocode:**
```swift
struct WorkoutSegment: Identifiable {
    let id = UUID()
    let name: String
    let duration: Int // minutes
    let intensityLevel: String
    let targetPowerPercentOfFTP: ClosedRange<Int>? // e.g. 85...95 for 85-95% of FTP
    let targetHeartRatePercentOfMax: ClosedRange<Int>?
    let instructions: String
}

struct WorkoutDay: Identifiable {
    let id = UUID()
    let day: String
    let title: String
    let description: String
    let duration: Int // minutes
    let intensity: String
    let equipment: [String]
    let segments: [WorkoutSegment]
    let tips: String
    var isCompleted: Bool = false
}
```

### Step 2: Create the WorkoutDetailView
**Objective:** Design and implement a detailed view for workout information.

**Steps:**
1. Create a new SwiftUI view file named `WorkoutDetailView.swift`
2. Design the UI to display all workout details:
   - Header with workout name, day, and duration
   - Visual intensity indicator
   - Segmented timeline showing workout structure
   - Equipment needed section
   - Detailed instructions for each segment
   - Tips section
   - Completion tracking button

**Pseudocode:**
```swift
struct WorkoutDetailView: View {
    let workout: WorkoutDay
    @State private var isCompleted: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                // Segments timeline
                // Equipment section
                // Instructions section
                // Tips section
                // Completion button
            }
            .padding()
        }
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Helper views and functions
}
```

### Step 3: Update WorkoutCard for Navigation
**Objective:** Enable navigation from workout cards to the detail view.

**Steps:**
1. Update the WorkoutCard view to be tappable and navigate to the detail view
2. Implement NavigationLink to connect to WorkoutDetailView

**Pseudocode:**
```swift
struct WorkoutCard: View {
    let workout: WorkoutDay
    
    var body: some View {
        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
            // Existing WorkoutCard content
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

### Step 4: Implement Workout Completion Tracking
**Objective:** Allow users to mark workouts as completed and persist this data.

**Steps:**
1. Update UserDataManager to handle workout completion status
2. Create methods to mark workouts as completed/incomplete
3. Implement UI for showing completion status on both the summary and detail views

**Pseudocode:**
```swift
// In UserDataManager
func markWorkoutCompleted(id: UUID, completed: Bool) {
    var userData = loadUserData()
    // Logic to update and save completion status
}

// In WorkoutDetailView
Button(action: {
    isCompleted.toggle()
    UserDataManager.shared.markWorkoutCompleted(id: workout.id, completed: isCompleted)
}) {
    Text(isCompleted ? "Completed" : "Mark as Complete")
        .frame(maxWidth: .infinity)
        .padding()
        .background(isCompleted ? Color.green : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
}
```

### Step 5: Update PlanSummaryView for Completion Visibility
**Objective:** Show completion status in the summary view.

**Steps:**
1. Update WorkoutCard to display completion status
2. Add visual indicators for completed workouts

**Pseudocode:**
```swift
// In WorkoutCard
if workout.isCompleted {
    Image(systemName: "checkmark.circle.fill")
        .foregroundColor(.green)
}
```

## User Intervention Required
1. **Design Review:** UI/UX team should review the design of the detail view to ensure it meets brand guidelines and user expectations.
2. **Content Creation:** Workout experts need to provide detailed breakdown of workout segments and specific instructions for different workout types.
3. **Testing:** User testing should be conducted to ensure the detail view is intuitive and provides value to users.

## Future Enhancements
- Integration with device sensors for real-time guidance
- Ability to modify workouts based on user feedback
- Integration with calendar for schedule reminders
- Sharing workouts with friends or coaches
- Exporting workouts to third-party platforms

## Success Metrics
- User engagement with workout detail screens
- Completion rates of scheduled workouts
- User feedback on workout clarity and usefulness
- Time spent reviewing workout details before activity
