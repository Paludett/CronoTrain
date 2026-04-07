# CronoTrain

CronoTrain is a SwiftUI workout app prototype focused on guided interval sessions, workout planning, and clean iOS-first UX.

Built as a portfolio project to demonstrate product thinking, SwiftUI architecture, and maintainable code organization in a Swift Playgrounds `.swiftpm` app.

## Highlights

- Guided workout runner with timed segments
- Workout creation/editing flow with segment management
- Active session control through a central session manager
- Profile and progression surfaces (history, XP/rank)
- Reusable visual system (colors, cards, buttons, motion)

## Tech Stack

- Swift 6
- SwiftUI (iOS 16+)
- `ObservableObject` + `@MainActor`
- `@EnvironmentObject` for app-wide state
- Swift Playgrounds package app (`.swiftpm`)

## Architecture

The app follows responsibility-based separation:

- **App entry and DI**: `MyApp.swift`
- **Navigation shell**: `ContentView.swift`
- **Domain models and store**: `Models.swift`
- **Session runtime**: `WorkoutSessionManager.swift`
- **Feature state logic**: `WorkoutRunnerViewModel.swift`
- **Feature UI**: `TimerView.swift`, `TrainsView.swift`, `WorkoutRunnerView.swift`, `ProfileView.swift`
- **Shared UI/utilities**: `Helpers.swift`, `FeedbackManager.swift`, `ConfettiView.swift`

### State Flow

1. `MyApp.swift` creates root state objects and injects them with `.environmentObject`.
2. `ContentView.swift` hosts the tab navigation.
3. Feature views read shared state from environment objects.
4. ViewModels/managers coordinate business logic on the main actor.

## Project Structure (Current)

```text
CronoTrain.swiftpm/
├── MyApp.swift
├── ContentView.swift
├── Models.swift
├── Helpers.swift
├── TrainsView.swift
├── TimerView.swift
├── WorkoutRunnerView.swift
├── WorkoutRunnerViewModel.swift
├── WorkoutSessionManager.swift
├── WorkoutCompletionSheet.swift
├── ProfileView.swift
├── XPManager.swift
├── WorkoutHistoryManager.swift
├── FeedbackManager.swift
├── OnboardingView.swift
├── RankDetailsView.swift
├── RankUpOverlay.swift
├── ActivityHeatmapView.swift
├── ConfettiView.swift
├── MockDataSeeder.swift
├── Assets.xcassets/
├── README.md
└── Package.swift
```

## Important Build Constraint (`.swiftpm`)

In this Swift Playgrounds setup, `Package.swift` is auto-generated and should not be edited manually.

Because the app target points to the project root path, new `.swift` files should be created in the root directory (same level as `MyApp.swift`) to avoid preview/build issues like `NoBuildableEntriesError`.

If previews get stuck after valid changes, a DerivedData cleanup is a common fix:

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/CronoTrain-*
```

## Clean Code Organization Guidelines

Even with root-level file placement, the project stays organized through naming and responsibility rules:

- One primary type per file (`...View`, `...ViewModel`, `...Manager`)
- Keep views focused on rendering and interaction wiring
- Keep timing/session/business logic in ViewModels/managers
- Reuse style tokens and shared modifiers from `Helpers.swift`
- Prefer extending existing shared components over duplicating UI logic

## Running Locally

Open `CronoTrain.swiftpm` in Xcode and run on an iOS 16+ simulator/device.

## Portfolio Notes

This project emphasizes:

- Practical SwiftUI architecture for medium-size features
- State management clarity across tabs and active sessions
- Consistent visual language and reusable UI primitives
- Maintainability via explicit file responsibilities

## Next Improvements

- Add automated tests for timer/session logic
- Add persistence hardening for workout/history data
- Add localization (PT-BR/EN)
- Expand accessibility coverage (Dynamic Type, VoiceOver)

## Author

- Name: Lorenzo Paludett
- LinkedIn: https://www.linkedin.com/in/lorenzopaludett/
- GitHub: https://github.com/Paludett
- Contact email: lorenzopaludettbenedetti@gmail.com

