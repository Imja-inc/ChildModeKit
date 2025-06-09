// The Swift Programming Language
// https://docs.swift.org/swift-book

/// ChildModeKit provides a comprehensive solution for implementing parental controls
/// and child-safe modes in iOS and macOS applications.
///
/// ## Key Features
/// - Child mode configuration management
/// - Timer-based session controls
/// - Parental override system with passcode protection
/// - Flexible permission management
/// - Pre-built SwiftUI components
///
/// ## Quick Start
/// ```swift
/// import ChildModeKit
/// 
/// let configuration = ChildModeConfiguration(appIdentifier: "MyApp")
/// let timerManager = TimerManager(configuration: configuration)
/// ```
public struct ChildModeKit {
    /// Current version of ChildModeKit
    public static let version = "1.0.0"
    
    /// Supported platforms
    public static let supportedPlatforms = ["iOS 15.0+", "macOS 12.0+"]
}