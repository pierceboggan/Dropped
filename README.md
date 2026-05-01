# Dropped

Dropped is a SwiftUI iOS app for creating personalized cycling training plans from a rider's weight, FTP, weekly training time, and training goal.

## Current features

- Onboarding flow for rider profile setup.
- Unit switching between pounds, stones, and kilograms.
- Persisted user profile and workout schedule data.
- Generated weekly workout plans with detailed interval views.
- Optional AI workout generation backed by OpenAI chat completions.
- Unit and UI test targets.

## Project structure

- `Dropped/` contains the app target source.
- `Dropped/Models/` contains profile, workout, and AI generation models/services.
- `Dropped/ViewModels/` contains screen state and workflow logic.
- `Dropped/Views/` contains SwiftUI screens and reusable view components.
- `DroppedTests/` and `DroppedUITests/` contain XCTest coverage.
- `docs/` contains project notes, specs, and historical implementation plans.

## OpenAI configuration

AI workout generation does not hardcode an API key. To enable it, provide `OPENAI_API_KEY` through the app's Info.plist or launch environment. Without a configured key, the generator shows a user-facing error and the rest of the app continues to work.

## Testing

Run tests with:

```sh
xcodebuild -project Dropped.xcodeproj -scheme Dropped -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' test
```

## Getting started

1. Clone the repo.
2. Open `Dropped.xcodeproj` in Xcode.
3. Build and run the `Dropped` scheme on an iOS simulator.
