# Workout Detail View Feature Specification

## Overview
This feature adds a detailed view to display individual workout information when selected from the weekly plan view. The detail view provides comprehensive information about the workout including an overview, specific intervals with power and duration details, and a graphical representation of the intervals.

## User Journey
1. User views their weekly training plan
2. User taps on a specific workout in the plan
3. User is navigated to the workout detail view
4. User views the workout details including intervals and graphical representation
5. User returns to the weekly plan view

## Functional Requirements

### FR-1: Navigation to Workout Detail
**Description:** Allow users to navigate from weekly plan view to a detailed view of a specific workout.

**Acceptance Criteria:**
- Tapping on a workout in the weekly plan view navigates to the workout detail view
- Navigation should feel natural within the app's navigation hierarchy
- Navigation should maintain state of the weekly plan view for when user returns

### FR-2: Workout Overview Display
**Description:** Display basic information about the selected workout at the top of the detail view.

**Acceptance Criteria:**
- Display workout title prominently
- Show workout date
- Display summary information (difficulty level, estimated duration, primary goal)
- Layout should be clean and consistent with app's design language

### FR-3: Interval Information Display
**Description:** Present a list of intervals that make up the workout with relevant metrics.

**Acceptance Criteria:**
- Show each interval as a distinct item in a list
- For each interval, display:
  - Power target (in watts or as percentage of FTP)
  - Duration (in minutes and seconds)
  - Interval type or zone (e.g., recovery, threshold)
- List should be scrollable if many intervals exist
- Visual distinction between different interval types

### FR-4: Graphical Interval Visualization
**Description:** Provide a graphical representation of the workout's power profile over time.

**Acceptance Criteria:**
- Display a power/time graph showing the structure of the workout
- X-axis represents time
- Y-axis represents power (watts or % of FTP)
- Different power zones should be visually distinct (using colors)
- Graph should be appropriately sized for readability
- Graph should maintain readability in both light and dark mode

### FR-5: Return Navigation
**Description:** Allow users to easily return to the weekly plan view.

**Acceptance Criteria:**
- Provide a clear back navigation mechanism (standard iOS back button)
- Returning to weekly plan view should restore its previous state

## UI Considerations
- Maintain consistent visual language with the rest of the app
- Ensure accessibility of all elements (proper contrast, sizing, and labels)
- Design for both portrait and landscape orientations
- Optimize layout for different iPhone screen sizes
- Keep UI simple and focused on workout information

## Technical Considerations
- Create a new SwiftUI view for the workout detail screen
- Leverage existing data models (Workout, Interval) for data display
- Consider using SwiftUI's built-in charts for the graphical visualization
- Ensure smooth transitions between views
