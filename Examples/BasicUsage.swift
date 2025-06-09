import SwiftUI
import ChildModeKit

// Example 1: Basic Child Mode App
struct BasicChildModeApp: App {
    @StateObject private var configuration = ChildModeConfiguration(appIdentifier: "BasicChildApp")
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configuration)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var configuration: ChildModeConfiguration
    @StateObject private var timerManager: TimerManager
    @State private var showSettings = false
    @State private var showOverride = false
    
    init() {
        let config = ChildModeConfiguration(appIdentifier: "BasicChildApp")
        _timerManager = StateObject(wrappedValue: TimerManager(configuration: config))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if configuration.isChildMode {
                    ChildModeInterface()
                } else {
                    FullInterface()
                }
            }
            .navigationTitle("My App")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showSettings = true
                    }
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
            .sheet(isPresented: $showOverride) {
                ParentalOverrideView(
                    configuration: configuration,
                    isTimeLimitReached: $timerManager.isTimeLimitReached,
                    timeRemaining: $timerManager.timeRemaining,
                    timer: $timerManager.timer
                )
            }
            .onChange(of: timerManager.isTimeLimitReached) { isReached in
                if isReached {
                    showOverride = true
                }
            }
            .onAppear {
                if configuration.isChildMode {
                    timerManager.startTimer()
                }
            }
        }
    }
}

struct ChildModeInterface: View {
    @EnvironmentObject var configuration: ChildModeConfiguration
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.child")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Child Mode Active")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Limited features available")
                .foregroundColor(.secondary)
            
            if configuration.allowPhotoCapture {
                Button("Take Photo") {
                    // Photo capture logic
                }
                .buttonStyle(.borderedProminent)
            }
            
            if configuration.allowVideoRecording {
                Button("Record Video") {
                    // Video recording logic
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

struct FullInterface: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Full Mode")
                .font(.title)
                .fontWeight(.bold)
            
            Text("All features available")
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Button("Take Photo") {
                    // Photo capture logic
                }
                .buttonStyle(.borderedProminent)
                
                Button("Record Video") {
                    // Video recording logic
                }
                .buttonStyle(.bordered)
                
                Button("Edit Settings") {
                    // Settings logic
                }
                .buttonStyle(.bordered)
                
                Button("Advanced Features") {
                    // Advanced features logic
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

// Example 2: Custom Permissions
struct CustomPermissionsExample: View {
    @StateObject private var configuration = ChildModeConfiguration(appIdentifier: "CustomApp")
    @State private var allowGameMode = true
    @State private var allowSocialFeatures = false
    @State private var allowPurchases = false
    
    var body: some View {
        NavigationView {
            ChildModeSettingsView(
                configuration: configuration,
                customPermissions: [
                    PermissionToggle(title: "Game Mode", binding: $allowGameMode, color: .green),
                    PermissionToggle(title: "Social Features", binding: $allowSocialFeatures, color: .purple),
                    PermissionToggle(title: "In-App Purchases", binding: $allowPurchases, color: .red)
                ],
                showSetupSection: true,
                onSetupComplete: {
                    print("Setup completed!")
                }
            )
            .navigationTitle("App Settings")
        }
    }
}

// Example 3: Timer Integration
struct TimerIntegrationExample: View {
    @StateObject private var configuration = ChildModeConfiguration(appIdentifier: "TimerApp")
    @StateObject private var timerManager: TimerManager
    
    init() {
        let config = ChildModeConfiguration(appIdentifier: "TimerApp")
        _timerManager = StateObject(wrappedValue: TimerManager(configuration: config))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if configuration.isChildMode && configuration.timeLimitSeconds > 0 {
                VStack(spacing: 8) {
                    Text("Time Remaining")
                        .font(.headline)
                    
                    Text(timerManager.formattedTimeRemaining())
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(timerManager.timeRemaining < 60 ? .red : .primary)
                    
                    ProgressView(value: Double(timerManager.timeRemaining), 
                               total: Double(configuration.timeLimitSeconds))
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 8)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(configuration.isChildMode ? "Exit Child Mode" : "Enter Child Mode") {
                configuration.isChildMode.toggle()
                if configuration.isChildMode {
                    timerManager.startTimer()
                } else {
                    timerManager.stopTimer()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onChange(of: timerManager.isTimeLimitReached) { isReached in
            if isReached {
                // Handle time limit reached
                print("Time limit reached!")
            }
        }
    }
}