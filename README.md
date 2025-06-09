# ChildModeKit

A Swift Package for implementing parental controls and child-safe modes in iOS/macOS applications.

## Features

- **Child Mode Configuration**: Complete settings management for child mode restrictions
- **Parental Override**: Secure passcode-protected override system
- **Timer Management**: Built-in session timer with customizable limits
- **Flexible Permissions**: Configurable permissions for different app features
- **Reusable UI Components**: Pre-built SwiftUI views for settings and override screens

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "path/to/ChildModeKit", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the version/branch
4. Add to your target

## Quick Start

### 1. Basic Setup

```swift
import ChildModeKit

// Initialize configuration with app identifier for isolated storage
let configuration = ChildModeConfiguration(appIdentifier: "MyApp")

// Set up timer manager
let timerManager = TimerManager(configuration: configuration)
```

### 2. Add Settings View

```swift
import SwiftUI
import ChildModeKit

struct ContentView: View {
    @StateObject private var configuration = ChildModeConfiguration(appIdentifier: "MyApp")
    @State private var showSettings = false
    
    var body: some View {
        VStack {
            // Your app content
            
            Button("Settings") {
                showSettings = true
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationView {
                ChildModeSettingsView(configuration: configuration)
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showSettings = false
                            }
                        }
                    }
            }
        }
    }
}
```

### 3. Implement Timer and Override

```swift
struct MainAppView: View {
    @StateObject private var configuration = ChildModeConfiguration(appIdentifier: "MyApp")
    @StateObject private var timerManager: TimerManager
    @State private var showOverride = false
    
    init() {
        let config = ChildModeConfiguration(appIdentifier: "MyApp")
        _configuration = StateObject(wrappedValue: config)
        _timerManager = StateObject(wrappedValue: TimerManager(configuration: config))
    }
    
    var body: some View {
        VStack {
            if configuration.isChildMode {
                // Show timer if enabled
                if configuration.timeLimitSeconds > 0 {
                    Text("Time: \(timerManager.formattedTimeRemaining())")
                        .font(.headline)
                        .foregroundColor(timerManager.timeRemaining < 60 ? .red : .primary)
                }
                
                // Your child-mode restricted UI
                ChildModeContent()
            } else {
                // Full app interface
                FullAppContent()
            }
        }
        .onAppear {
            if configuration.isChildMode {
                timerManager.startTimer()
            }
        }
        .onDisappear {
            timerManager.stopTimer()
        }
        .onChange(of: timerManager.isTimeLimitReached) { isReached in
            if isReached {
                showOverride = true
            }
        }
        .sheet(isPresented: $showOverride) {
            ParentalOverrideView(
                configuration: configuration,
                isTimeLimitReached: $timerManager.isTimeLimitReached,
                timeRemaining: $timerManager.timeRemaining,
                timer: $timerManager.timer
            )
        }
    }
}
```

### 4. Custom Permissions

```swift
struct CustomSettingsView: View {
    @StateObject private var configuration = ChildModeConfiguration(appIdentifier: "MyApp")
    @State private var allowGameMode = true
    @State private var allowSocialFeatures = false
    
    var body: some View {
        ChildModeSettingsView(
            configuration: configuration,
            customPermissions: [
                PermissionToggle(title: "Allow Game Mode", binding: $allowGameMode, color: .green),
                PermissionToggle(title: "Allow Social Features", binding: $allowSocialFeatures, color: .purple)
            ]
        )
    }
}
```

## API Reference

### ChildModeConfiguration

Core configuration class that manages all child mode settings:

- `isChildMode: Bool` - Whether child mode is active
- `timeLimitSeconds: Int` - Session time limit in seconds
- `parentalPasscode: String` - Override passcode
- `allowCameraSwitch: Bool` - Camera switching permission
- `allowPhotoCapture: Bool` - Photo capture permission
- `allowVideoRecording: Bool` - Video recording permission
- `enableAudioRecording: Bool` - Audio recording permission
- `autoStartRecording: Bool` - Auto-start recording when entering child mode
- `allowStopRecording: Bool` - Allow stopping recording in child mode

### TimerManager

Manages session timers and time limits:

- `startTimer()` - Begin countdown timer
- `stopTimer()` - Stop and invalidate timer
- `resetTimer()` - Reset to original time limit
- `addTime(seconds:)` - Add additional time to current session
- `formattedTimeRemaining()` - Get formatted time string (MM:SS)

### ParentalOverrideView

Pre-built override interface with:
- Passcode entry
- Timer controls (reset, add time, end session)
- Secure verification

### ChildModeSettingsView

Comprehensive settings interface supporting:
- All built-in permissions
- Custom permission toggles
- Time limit configuration
- Passcode management
- Setup flow integration

## Storage

ChildModeKit uses UserDefaults for persistence with app-specific prefixes to avoid conflicts. All settings are automatically saved when changed.

## License

MIT License - see LICENSE file for details.