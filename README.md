# ChildModeKit

A comprehensive Swift Package for implementing parental controls and child-safe modes in iOS/macOS applications, with specialized support for camera and video apps.

## Features

- **🔒 Child Mode Configuration**: Complete settings management for child mode restrictions
- **👨‍👩‍👧‍👦 Parental Override**: Secure passcode-protected override system with timer controls
- **⏱️ Timer Management**: Built-in session timer with customizable limits and real-time countdown
- **🎬 Video Content Management**: Approval workflow for video content with intuitive UI
- **📱 Camera & Recording Controls**: Comprehensive camera permissions and recording management
- **📡 Sharing Controls**: NFC, AirDrop, and file sharing permission management
- **🎨 Reusable UI Components**: Pre-built SwiftUI views for settings and override screens
- **🔧 Flexible Permissions**: Custom permission toggles for app-specific features
- **💾 Persistent Storage**: Automatic settings persistence with app-specific isolation

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

ChildModeKit provides comprehensive support for video apps with content approval, sharing controls, and parental oversight:

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
        .modelContainer(for: VideoItem.self)
    }
}

// Main content view that switches between parent and child modes
struct MainContentView: View {
    @ObservedObject var childModeConfiguration: ChildModeConfiguration
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        if childModeConfiguration.isChildMode {
            ChildModeView(
                childModeConfiguration: childModeConfiguration,
                timerManager: timerManager
            )
        } else {
            ParentModeView(
                childModeConfiguration: childModeConfiguration,
                timerManager: timerManager
            )
        }
    }
}

// Parent mode with video management and approval controls
struct ParentModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var videos: [VideoItem]
    @ObservedObject var childModeConfiguration: ChildModeConfiguration
    @ObservedObject var timerManager: TimerManager
    @State private var showingParentalControls = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Parent Mode")
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                    Button("Controls") {
                        showingParentalControls = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Switch to Child") {
                        childModeConfiguration.isChildMode = true
                        timerManager.startTimer()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                // Video list with approval controls
                List {
                    ForEach(videos) { video in
                        VideoRowView(
                            video: video,
                            modelContext: modelContext,
                            childModeConfiguration: childModeConfiguration
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingParentalControls) {
            ChildModeControlsView(
                childModeConfiguration: childModeConfiguration,
                timerManager: timerManager
            )
        }
    }
}

// Child mode with restricted video access
struct ChildModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allVideos: [VideoItem]
    @ObservedObject var childModeConfiguration: ChildModeConfiguration
    @ObservedObject var timerManager: TimerManager
    
    private var approvedVideos: [VideoItem] {
        return allVideos.filter { video in
            video.isApproved && childModeConfiguration.isVideoContentAllowed(video.videoId)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Kid's Videos")
                            .font(.largeTitle)
                            .bold()
                        if timerManager.timeRemaining > 0 {
                            Text("Time: \(timerManager.formattedTimeRemaining())")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }
                    Spacer()
                    Button("Parent Mode") {
                        // Handle passcode verification if needed
                        childModeConfiguration.isChildMode = false
                        timerManager.stopTimer()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                if approvedVideos.isEmpty {
                    VStack {
                        Image(systemName: "video.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No approved videos")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Ask a parent to approve some videos!")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                        ForEach(approvedVideos) { video in
                            VideoThumbnailView(video: video) {
                                // Play video
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// Video row with approval controls for parent mode
struct VideoRowView: View {
    let video: VideoItem
    let modelContext: ModelContext
    let childModeConfiguration: ChildModeConfiguration
    
    private var isApproved: Bool {
        childModeConfiguration.isVideoContentAllowed(video.videoId)
    }
    
    var body: some View {
        HStack {
            AsyncImage(url: video.url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.3))
                    .overlay(Image(systemName: "video.fill").foregroundColor(.gray))
            }
            .frame(width: 60, height: 40)
            .clipped()
            .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text(video.title).font(.headline)
                Text("Added: \(video.addedDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Clear approval status and action button
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: isApproved ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isApproved ? .green : .red)
                        .font(.caption)
                    Text(isApproved ? "Approved" : "Blocked")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isApproved ? .green : .red)
                }
                
                Button(action: {
                    if isApproved {
                        childModeConfiguration.removeVideoApproval(video.videoId)
                        video.isApproved = false
                    } else {
                        childModeConfiguration.approveVideoContent(video.videoId)
                        video.isApproved = true
                    }
                    try? modelContext.save()
                }) {
                    Text(isApproved ? "Block" : "Approve")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isApproved ? Color.red : Color.green)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

### 6. Camera App Integration

ChildModeKit also provides comprehensive support for camera apps with recording controls and permissions:

```swift
import ChildModeKit

struct CameraApp: App {
    @StateObject private var configuration = ChildModeConfiguration(appIdentifier: "CameraApp")
    @StateObject private var timerManager: TimerManager
    
    init() {
        let config = ChildModeConfiguration(appIdentifier: "CameraApp")
        _configuration = StateObject(wrappedValue: config)
        _timerManager = StateObject(wrappedValue: TimerManager(configuration: config))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configuration)
                .environmentObject(timerManager)
        }
    }
}

struct CameraView: View {
    @EnvironmentObject var configuration: ChildModeConfiguration
    @EnvironmentObject var timerManager: TimerManager
    @State private var showParentalOverride = false
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView()
            
            VStack {
                // Timer display in child mode
                if configuration.isChildMode && configuration.timeLimitSeconds > 0 {
                    HStack {
                        Text("Time: \(timerManager.formattedTimeRemaining())")
                            .font(.headline)
                            .foregroundColor(timerManager.timeRemaining < 60 ? .red : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        Spacer()
                    }
                    .padding()
                }
                
                Spacer()
                
                // Camera controls
                HStack {
                    // Camera switch (if allowed)
                    if configuration.allowCameraSwitch {
                        Button("Switch Camera") {
                            // Switch camera
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Capture button (if allowed)
                    if configuration.allowPhotoCapture || configuration.allowVideoRecording {
                        Button {
                            // Handle capture
                        } label: {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                        .frame(width: 60, height: 60)
                                )
                        }
                    }
                    
                    Spacer()
                    
                    // Settings button (parent mode only)
                    if !configuration.isChildMode {
                        Button("Settings") {
                            // Show settings
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            if configuration.isChildMode {
                timerManager.startTimer()
            }
        }
        .onChange(of: timerManager.isTimeLimitReached) { isReached in
            if isReached {
                showParentalOverride = true
            }
        }
        .sheet(isPresented: $showParentalOverride) {
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

#### Video App Support

- `allowedVideoContent: Set<String>` - Set of approved video IDs
- `restrictToApprovedContent: Bool` - Whether to restrict to only approved content  
- `allowFileSharing: Bool` - File sharing permission in child mode
- `allowNFCSharing: Bool` - NFC sharing permission in child mode
- `allowAirDropReceiving: Bool` - AirDrop receiving permission in child mode

**Video Content Methods:**
- `approveVideoContent(_:)` - Add video to approved list
- `removeVideoApproval(_:)` - Remove video from approved list
- `isVideoContentAllowed(_:)` - Check if video is approved

**Permission Helper Methods:**
- `canReceiveFiles()` - Check file sharing permissions based on child mode status
- `canUseNFC()` - Check NFC permissions based on child mode status  
- `canReceiveAirDrop()` - Check AirDrop permissions based on child mode status

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
- All built-in permissions and video content controls
- Custom permission toggles for app-specific features
- Time limit configuration with preset and custom options
- Passcode management with secure entry
- Setup flow integration for first-time users
- Video content restriction toggles
- Sharing permission controls (NFC, AirDrop, File Sharing)

### VideoContentManager

Utility class for filtering and managing video content:
- `filterAllowedVideos(_:)` - Filter video arrays based on approval status
- `canAddVideo()` - Check if new videos can be added (parent mode only)
- `canDeleteVideo()` - Check if videos can be deleted (parent mode only)  
- `canModifyApprovalStatus()` - Check if approval status can be changed
- `toggleVideoApproval(_:)` - Toggle approval status for VideoContentProtocol items

**VideoContentProtocol**: Protocol for custom video types requiring approval workflow
- `var videoId: String { get }` - Unique identifier for the video
- `var title: String { get }` - Display title for the video
- `var isApproved: Bool { get set }` - Approval status (can be computed)

## Advanced Features

### Sample Video Support
ChildModeKit includes sample video loading with popular test content like Big Buck Bunny for development and testing purposes.

### Intuitive Approval UI
The framework provides clear status indicators and action buttons:
- **"Approved"/"Blocked"** status with color-coded icons
- **"Approve"/"Block"** action buttons with consistent styling
- Dual approval system (VideoItem + ChildModeKit) for flexibility

### Enhanced Controls Panel
Full-screen parental controls interface with:
- Quick Start section for immediate session setup
- Comprehensive settings from ChildModeSettingsView
- Proper sizing and scrollable content
- Done button and automatic dismissal

## Storage

ChildModeKit uses UserDefaults for persistence with app-specific prefixes to avoid conflicts. All settings are automatically saved when changed.

**Storage Keys:**
- Basic settings: `{appIdentifier}_isChildMode`, `{appIdentifier}_timeLimitSeconds`, etc.
- Video content: `{appIdentifier}_allowedVideoContent` (JSON-encoded Set<String>)
- Permissions: `{appIdentifier}_allowFileSharing`, `{appIdentifier}_allowNFCSharing`, etc.

This isolation ensures multiple apps using ChildModeKit won't interfere with each other's settings.

## License

MIT License - see LICENSE file for details.