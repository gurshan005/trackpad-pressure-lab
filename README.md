# Trackpad Pressure Lab

A personal macOS input experiment built with SwiftUI. It streams pressure samples from a compatible trackpad, pauses recording when contact is lost, and compares a session against the user's recent history. The original executable is named `TremorCheckMVP`.

## Run the app

Use a Mac running macOS 13 or later with a pressure-capable trackpad and Swift 6.0 or later. Swift Package Manager downloads [OpenMultitouchSupport](https://github.com/Kyome22/OpenMultitouchSupport) on the first build.

```sh
swift run TremorCheckMVP
```

Select **Start session** and follow the hold, pressure-control, and tapping prompts. Each recording stage has a 20-second timer that pauses while contact is unstable. The app saves session summaries to `~/Library/Application Support/TremorCheckMVP/sessions.json`.

## Implementation

- [PressureMonitor](Sources/PressureMonitor.swift) reads touch events from an asynchronous stream. [AssessmentViewModel](Sources/AssessmentViewModel.swift) coordinates the contact gate, countdown, and recording stages.
- [TremorScorer](Sources/TremorScorer.swift) measures pressure variation, mean squared differences between adjacent samples, and variation in tap intervals. After three sessions, it compares each new session with up to seven previous ones.
- The displayed score and confidence are experimental heuristics. They have no clinical validation.

## Tests

```sh
swift test
```

Three XCTest cases feed synthetic pressure traces into the scorer and check constant input, irregular tap spacing, and the rolling baseline. These tests run without a trackpad. Physical trackpad behavior requires an interactive session.
