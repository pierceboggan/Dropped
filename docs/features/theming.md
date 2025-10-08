# Theming Feature

## Overview
The Dropped app now supports light, dark, and system theme preferences. Users can customize the app's appearance through the Settings view, and their preference is persisted across app launches.

## Implementation

### Components

1. **AppTheme Enum** (`Dropped/Models/UserData.swift`)
   - Defines three theme options: `system`, `light`, and `dark`
   - Provides a `colorScheme` property that returns the appropriate SwiftUI `ColorScheme`
   - System theme returns `nil` to use the device's system preference

2. **ThemeManager** (`Dropped/DroppedApp.swift`)
   - Observable object that manages the current theme state
   - Loads the user's theme preference on initialization
   - Listens for theme changes via NotificationCenter
   - Automatically updates when theme preference changes

3. **UserData Model** (`Dropped/Models/UserData.swift`)
   - Added `theme: String` field to persist theme preference
   - Provides `appTheme()` helper method to retrieve the AppTheme enum
   - Default theme is set to `.system`

4. **Settings UI** (`Dropped/Views/SettingsView.swift`)
   - New "Appearance" section with theme picker
   - Segmented control with three options: System, Light, Dark
   - Icons for each theme option (sparkles, sun, moon)
   - Updates persist immediately via UserDataManager
   - Notifies ThemeManager of changes

5. **Settings Navigation** (`Dropped/ContentView.swift`)
   - Added navigation link to Settings in main menu

### User Experience

1. **Accessing Theme Settings**
   - Navigate to Settings from the main menu
   - Theme picker appears in the "Appearance" section
   - Select from System, Light, or Dark

2. **Theme Behavior**
   - **System**: Follows device light/dark mode setting
   - **Light**: Forces light mode regardless of device setting
   - **Dark**: Forces dark mode regardless of device setting

3. **Persistence**
   - Theme preference is saved to UserData
   - Persists across app launches
   - Applies immediately when changed

## Testing

### Unit Tests (`DroppedTests/UserDataTests.swift`)
- Tests AppTheme enum functionality and color scheme mapping
- Tests UserData theme field persistence
- Tests appTheme() helper method
- Tests default theme is system
- Tests invalid theme defaults to system

### UI Tests (`DroppedUITests/ThemeUITests.swift`)
- Tests theme selection in Settings view
- Tests theme preference persistence across navigation
- Verifies theme picker accessibility

## Technical Details

### Theme Change Flow
1. User selects theme in SettingsView
2. SettingsViewModel updates UserData and saves to UserDataManager
3. SettingsViewModel posts "ThemeDidChange" notification
4. ThemeManager receives notification and reloads theme preference
5. ThemeManager updates its @Published property
6. DroppedApp observes the change and applies new color scheme

### Migration
- Existing users will default to system theme
- No data migration required as the field has a default value
- OnboardingViewModel sets system theme for new users

## Accessibility
- Theme icons provide visual cues for each option
- Segmented picker is standard iOS control with built-in accessibility
- Theme applies to all system colors and backgrounds
- Works with iOS accessibility features like increased contrast

## Future Enhancements
- Custom color schemes or accent colors
- Per-view theme overrides
- Automatic theme switching based on time of day
- Theme preview when selecting options
