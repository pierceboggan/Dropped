# Calendar View Feature Specification

## Overview
This document describes the Calendar View feature that was added to the Dropped cycling training app. The calendar view displays all workouts for the current month in a grid layout, allowing users to quickly see their training schedule at a glance.

## User Journey
1. User navigates to the main menu after completing onboarding
2. User taps on "Calendar" in the navigation menu
3. User sees a monthly calendar grid showing the current month
4. Days with workouts are highlighted with colored dots indicating workout intensity
5. User taps on a day with workouts to see all workouts scheduled for that day
6. User can tap on individual workouts to see detailed workout information
7. User can navigate back to return to the calendar or main menu

## Functional Requirements

### FR-1: Calendar Grid Display
**Description:** Display a monthly calendar grid showing all days of the current month.

**Acceptance Criteria:**
- Display the current month and year at the top
- Show weekday headers (Sun, Mon, Tue, Wed, Thu, Fri, Sat)
- Display a grid of all days in the month
- Empty cells before the first day of the month
- Days are numbered 1 through the last day of the month

### FR-2: Workout Indicators
**Description:** Display visual indicators on days that have scheduled workouts.

**Acceptance Criteria:**
- Days with workouts show a colored dot indicator
- Dot color corresponds to workout intensity (same color scheme as WorkoutCard)
- Days without workouts have no indicator
- Day numbers for workout days are displayed in bold

### FR-3: Navigation to Workout Details
**Description:** Allow users to tap on workout days to see more details.

**Acceptance Criteria:**
- Tapping a day with workouts navigates to a day detail view
- Day detail view shows all workouts scheduled for that day
- Users can tap individual workouts to see full workout details
- Navigation maintains proper back button functionality

### FR-4: Accessibility
**Description:** Ensure the calendar is fully accessible.

**Acceptance Criteria:**
- Calendar days have descriptive accessibility labels
- Screen readers announce day numbers and workout counts
- All interactive elements are keyboard accessible
- Proper accessibility identifiers for UI testing

## Technical Implementation

### Components Created
1. **CalendarView**: Main view displaying the monthly calendar
   - Calculates month boundaries and weekday alignment
   - Loads workouts from WorkoutManager for the current month
   - Renders calendar grid using LazyVGrid
   
2. **CalendarDayCell**: Individual day cell component
   - Displays day number
   - Shows workout indicator dot if workouts exist
   - Color-coded based on workout intensity
   - Accessible with proper labels and identifiers

3. **WorkoutDayDetailView**: View for a specific day's workouts
   - Shows formatted date at the top
   - Lists all workouts for that day using WorkoutCard
   - Provides navigation to WorkoutDetailView

### Integration Points
- **ContentView**: Added navigation link to CalendarView
- **WorkoutManager**: Uses `getWorkouts(from:to:)` to fetch workouts for the month
- **WorkoutCard**: Reused for consistent workout display
- **WorkoutDetailView**: Existing detail view for individual workouts

### Testing
- **CalendarViewUITests.swift**: Comprehensive UI tests covering:
  - Navigation from main menu to calendar
  - Display of month and year
  - Navigation to workout details
  - Back navigation
  - Uses proper `waitForExistence` instead of sleep calls
  - Robust element queries

## Design Considerations
- Maintains visual consistency with existing app design
- Uses same color scheme for intensity indicators as WorkoutCard
- Supports both light and dark mode
- Responsive layout adapts to different screen sizes
- Clean, minimal design focusing on workout information

## Edge Cases Handled
- Months with different numbers of days (28-31)
- First day of month on different weekdays
- Multiple workouts on the same day
- Days with no workouts
- Empty months (no workouts scheduled)

## Future Enhancements
Potential improvements for future versions:
- Month navigation (previous/next month buttons)
- Year view showing all months
- Filter by workout type or intensity
- Add new workout from calendar
- Drag and drop to reschedule workouts
- Calendar sync with external calendars
