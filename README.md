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
    .package(url: "https://github.com/Imja-inc/ChildModeKit", from: "1.0.0")
]
```

### Xcode Integration

#### Method 1: Remote Package (Recommended for published packages)
1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/Imja-inc/ChildModeKit`
3. Select the version/branch
4. Add to your target

#### Method 2: Local Package (For development/local projects)
1. **Open your iOS/macOS project in Xcode**
2. **Add Local Package Dependency:**
   - Select your project in the navigator (top-level project file)
   - Select your app target
   - Go to "Package Dependencies" tab
   - Click the "+" button
3. **Add Local Package:**
   - Click "Add Local..."
   - Navigate to your ChildModeKit folder (e.g., `../ChildModeKit` if it's in the same parent directory)
   - Select the ChildModeKit folder and click "Add Package"
4. **Add to Target:**
   - Make sure "ChildModeKit" is checked for your app target
   - Click "Add Package"

The local package method is useful when:
- You're developing ChildModeKit alongside your app
- You want to modify ChildModeKit for your specific needs
- You're working with the latest unreleased features

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

### 5. Video App Integration

For video apps requiring content approval and sharing controls:

```swift
import ChildModeKit
import SwiftData

struct VideoApp: App {
    @StateObject private var childModeConfiguration = ChildModeConfiguration(appIdentifier: "VideoApp")
    @StateObject private var timerManager: TimerManager
    
    init() {
        let config = ChildModeConfiguration(appIdentifier: "VideoApp")
        _childModeConfiguration = StateObject(wrappedValue: config)
        _timerManager = StateObject(wrappedValue: TimerManager(configuration: config))
    }
    
    var body: some Scene {
        WindowGroup {
            MainContentView(
                childModeConfiguration: childModeConfiguration,
                timerManager: timerManager
            )
        }
    }
}

struct VideoPlayerView: View {
    @ObservedObject var childModeConfiguration: ChildModeConfiguration
    let videos: [VideoItem]
    
    private var allowedVideos: [VideoItem] {
        videos.filter { video in
            childModeConfiguration.isVideoContentAllowed(video.id)
        }
    }
    
    var body: some View {
        VStack {
            if childModeConfiguration.isChildMode {
                // Show only approved videos in child mode
                VideoGrid(videos: allowedVideos)
            } else {
                // Show all videos with approval controls in parent mode
                VideoManagementView(
                    videos: videos,
                    configuration: childModeConfiguration
                )
            }
        }
    }
}
```

**VideoContentManager Usage:**
```swift
import ChildModeKit

// For custom video types, implement VideoContentProtocol
extension VideoItem: VideoContentProtocol {
    var videoId: String { id }
    var title: String { name }
    var isApproved: Bool {
        get { childModeConfiguration.isVideoContentAllowed(videoId) }
        set { 
            if newValue {
                childModeConfiguration.approveVideoContent(videoId)
            } else {
                childModeConfiguration.removeVideoApproval(videoId)
            }
        }
    }
}

// Use VideoContentManager for filtering
let contentManager = VideoContentManager(configuration: childModeConfiguration)
let allowedVideos = contentManager.filterAllowedVideos(allVideos)
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

#### Video App Support (New in v1.1)

- `allowedVideoContent: Set<String>` - Set of approved video IDs
- `restrictToApprovedContent: Bool` - Whether to restrict to only approved content
- `allowFileSharing: Bool` - File sharing permission in child mode
- `allowNFCSharing: Bool` - NFC sharing permission in child mode
- `allowAirDropReceiving: Bool` - AirDrop receiving permission in child mode

**Helper Methods:**
- `approveVideoContent(_:)` - Add video to approved list
- `removeVideoApproval(_:)` - Remove video from approved list
- `isVideoContentAllowed(_:)` - Check if video is approved
- `canReceiveFiles()` - Check file sharing permissions
- `canUseNFC()` - Check NFC permissions
- `canReceiveAirDrop()` - Check AirDrop permissions

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