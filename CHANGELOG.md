# Changelog

All notable changes to ChildModeKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) with distance-based patch versioning.

## [Unreleased]

## [1.0.0] - 2025-06-14

### Added
- Comprehensive video content management system with approval workflow
- Intuitive video approval UI with clear status indicators and action buttons
- Camera app support with recording controls and permissions
- NFC, AirDrop, and file sharing permission management
- VideoContentManager utility class for filtering and managing video content
- VideoContentProtocol for custom video types requiring approval workflow
- Enhanced ParentalOverrideView with timer controls (reset, add time, end session)
- Full-screen ChildModeControlsView with proper sizing and layout
- Sample video support for testing with popular content like Big Buck Bunny
- Auto-approval system for sample videos in testing environments
- Distance-based versioning system for automated release management
- Comprehensive CI/CD pipeline with security-first approach

### Enhanced
- ChildModeConfiguration now supports video-specific settings and permissions
- ChildModeSettingsView with video content controls and sharing permissions
- TimerManager with real-time countdown and session management
- Storage system with app-specific isolation using prefixes
- Open class architecture allowing inheritance across modules

### Fixed
- Build issues with inheritance across Swift Package modules
- SwiftLint violations in VideoContentManager
- UI sizing issues in parental controls panel
- Missing trailing newlines and unused setter value warnings

### Security
- Automatic settings persistence with UserDefaults isolation
- Secure passcode verification for parental override
- Permission-based access controls for child mode restrictions
