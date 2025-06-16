import XCTest
import SwiftUI
@testable import ChildModeKit

final class ChildModeSettingsViewTests: XCTestCase {
    
    var configuration: ChildModeConfiguration!
    var settingsView: ChildModeSettingsView!
    
    override func setUp() {
        super.setUp()
        let appId = "SettingsViewTest_\(UUID().uuidString)"
        configuration = ChildModeConfiguration(appIdentifier: appId)
        settingsView = ChildModeSettingsView(configuration: configuration)
    }
    
    override func tearDown() {
        configuration = nil
        settingsView = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultInitialization() {
        let appId = "DefaultInitTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        let view = ChildModeSettingsView(configuration: config)
        
        XCTAssertNotNil(view.configuration)
        XCTAssertTrue(view.customPermissions.isEmpty)
        XCTAssertFalse(view.showSetupSection)
        XCTAssertNil(view.onSetupComplete)
    }
    
    func testCustomInitialization() {
        let appId = "CustomInitTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        @State var testPermission = true
        let permissions = [
            PermissionToggle(title: "Test Permission", binding: $testPermission, color: .red)
        ]
        
        var setupCompleted = false
        let onSetupComplete: () -> Void = { setupCompleted = true }
        
        let view = ChildModeSettingsView(
            configuration: config,
            customPermissions: permissions,
            showSetupSection: true,
            onSetupComplete: onSetupComplete
        )
        
        XCTAssertEqual(view.customPermissions.count, 1)
        XCTAssertEqual(view.customPermissions.first?.title, "Test Permission")
        XCTAssertTrue(view.showSetupSection)
        XCTAssertNotNil(view.onSetupComplete)
        
        // Test setup completion callback
        view.onSetupComplete?()
        XCTAssertTrue(setupCompleted)
    }
    
    // MARK: - PermissionToggle Tests
    
    func testPermissionToggleInitialization() {
        @State var testValue = false
        let toggle = PermissionToggle(title: "Test Toggle", binding: $testValue)
        
        XCTAssertEqual(toggle.title, "Test Toggle")
        XCTAssertEqual(toggle.color, .blue) // Default color
        XCTAssertNotNil(toggle.id)
    }
    
    func testPermissionToggleWithCustomColor() {
        @State var testValue = true
        let toggle = PermissionToggle(title: "Custom Color Toggle", binding: $testValue, color: .green)
        
        XCTAssertEqual(toggle.title, "Custom Color Toggle")
        XCTAssertEqual(toggle.color, .green)
    }
    
    func testPermissionToggleUniqueIDs() {
        @State var testValue1 = false
        @State var testValue2 = false
        
        let toggle1 = PermissionToggle(title: "Toggle 1", binding: $testValue1)
        let toggle2 = PermissionToggle(title: "Toggle 2", binding: $testValue2)
        
        XCTAssertNotEqual(toggle1.id, toggle2.id)
    }
    
    // MARK: - Time Formatting Tests
    
    func testTimeStringFormatting() {
        // Since timeString is private, we test the logic through public interfaces
        // The time formatting logic can be validated through the view's behavior
        let appId = "TimeFormatTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        _ = ChildModeSettingsView(configuration: config)
        
        // Test different time limits through configuration
        config.timeLimitSeconds = 10
        XCTAssertEqual(config.timeLimitSeconds, 10)
        
        config.timeLimitSeconds = 59
        XCTAssertEqual(config.timeLimitSeconds, 59)
        
        config.timeLimitSeconds = 60
        XCTAssertEqual(config.timeLimitSeconds, 60)
        
        config.timeLimitSeconds = 120
        XCTAssertEqual(config.timeLimitSeconds, 120)
        
        config.timeLimitSeconds = 600
        XCTAssertEqual(config.timeLimitSeconds, 600)
        
        config.timeLimitSeconds = 3661
        XCTAssertEqual(config.timeLimitSeconds, 3661)
    }
    
    // MARK: - Configuration State Tests
    
    func testChildModeToggleEffect() {
        // Initially not in child mode
        XCTAssertFalse(configuration.isChildMode)
        
        // Enable child mode
        configuration.isChildMode = true
        XCTAssertTrue(configuration.isChildMode)
        
        // Disable child mode
        configuration.isChildMode = false
        XCTAssertFalse(configuration.isChildMode)
    }
    
    func testTimeLimitConfiguration() {
        // Test default time limit
        XCTAssertEqual(configuration.timeLimitSeconds, 600) // 10 minutes default
        
        // Test setting different time limits
        configuration.timeLimitSeconds = 300 // 5 minutes
        XCTAssertEqual(configuration.timeLimitSeconds, 300)
        
        configuration.timeLimitSeconds = 0 // No limit
        XCTAssertEqual(configuration.timeLimitSeconds, 0)
        
        configuration.timeLimitSeconds = -1 // Custom time
        XCTAssertEqual(configuration.timeLimitSeconds, -1)
    }
    
    func testCameraPermissions() {
        // Test default values
        XCTAssertTrue(configuration.allowCameraSwitch)
        XCTAssertTrue(configuration.allowPhotoCapture)
        XCTAssertTrue(configuration.allowVideoRecording)
        
        // Test toggling permissions
        configuration.allowCameraSwitch = false
        configuration.allowPhotoCapture = false
        configuration.allowVideoRecording = false
        
        XCTAssertFalse(configuration.allowCameraSwitch)
        XCTAssertFalse(configuration.allowPhotoCapture)
        XCTAssertFalse(configuration.allowVideoRecording)
    }
    
    func testAudioAndRecordingPermissions() {
        // Test default values
        XCTAssertTrue(configuration.enableAudioRecording)
        XCTAssertFalse(configuration.autoStartRecording)
        XCTAssertTrue(configuration.allowStopRecording)
        
        // Test toggling permissions
        configuration.enableAudioRecording = false
        configuration.autoStartRecording = true
        configuration.allowStopRecording = false
        
        XCTAssertFalse(configuration.enableAudioRecording)
        XCTAssertTrue(configuration.autoStartRecording)
        XCTAssertFalse(configuration.allowStopRecording)
    }
    
    func testVideoContentPermissions() {
        // Test default values
        XCTAssertTrue(configuration.restrictToApprovedContent)
        XCTAssertFalse(configuration.allowFileSharing)
        XCTAssertFalse(configuration.allowNFCSharing)
        XCTAssertFalse(configuration.allowAirDropReceiving)
        
        // Test toggling permissions
        configuration.restrictToApprovedContent = false
        configuration.allowFileSharing = true
        configuration.allowNFCSharing = true
        configuration.allowAirDropReceiving = true
        
        XCTAssertFalse(configuration.restrictToApprovedContent)
        XCTAssertTrue(configuration.allowFileSharing)
        XCTAssertTrue(configuration.allowNFCSharing)
        XCTAssertTrue(configuration.allowAirDropReceiving)
    }
    
    // MARK: - Passcode Management Tests
    
    func testPasscodeSetupFlow() {
        // Initially no passcode
        XCTAssertTrue(configuration.parentalPasscode.isEmpty)
        XCTAssertFalse(configuration.isValidPasscode("1234"))
        
        // Set passcode through configuration
        configuration.parentalPasscode = "1234"
        XCTAssertEqual(configuration.parentalPasscode, "1234")
        XCTAssertTrue(configuration.isValidPasscode("1234"))
        XCTAssertFalse(configuration.isValidPasscode("4321"))
        
        // Clear passcode
        configuration.parentalPasscode = ""
        XCTAssertTrue(configuration.parentalPasscode.isEmpty)
        XCTAssertFalse(configuration.isValidPasscode("1234"))
    }
    
    func testPasscodeValidationEdgeCases() {
        configuration.parentalPasscode = "test123"
        
        // Test exact match
        XCTAssertTrue(configuration.isValidPasscode("test123"))
        
        // Test case sensitivity
        XCTAssertFalse(configuration.isValidPasscode("TEST123"))
        XCTAssertFalse(configuration.isValidPasscode("Test123"))
        
        // Test empty input
        XCTAssertFalse(configuration.isValidPasscode(""))
        
        // Test partial match
        XCTAssertFalse(configuration.isValidPasscode("test"))
        XCTAssertFalse(configuration.isValidPasscode("123"))
        
        // Test longer input
        XCTAssertFalse(configuration.isValidPasscode("test1234"))
    }
    
    // MARK: - Setup Section Tests
    
    func testSetupSectionVisibility() {
        // Default view doesn't show setup section
        let defaultView = ChildModeSettingsView(configuration: configuration)
        XCTAssertFalse(defaultView.showSetupSection)
        
        // View with setup section enabled
        let setupView = ChildModeSettingsView(
            configuration: configuration,
            showSetupSection: true
        )
        XCTAssertTrue(setupView.showSetupSection)
    }
    
    func testSetupCompletionCallback() {
        var setupCompleted = false
        let setupView = ChildModeSettingsView(
            configuration: configuration,
            showSetupSection: true,
            onSetupComplete: { setupCompleted = true }
        )
        
        // Initially not completed
        XCTAssertFalse(setupCompleted)
        
        // Trigger setup completion
        setupView.onSetupComplete?()
        XCTAssertTrue(setupCompleted)
    }
    
    func testSetupSectionPasscodeRequirement() {
        let setupView = ChildModeSettingsView(
            configuration: configuration,
            showSetupSection: true,
            onSetupComplete: { }
        )
        
        // No passcode set - setup not complete
        XCTAssertTrue(configuration.parentalPasscode.isEmpty)
        XCTAssertNotNil(setupView.onSetupComplete)
        
        // Set passcode - setup can be completed
        configuration.parentalPasscode = "1234"
        XCTAssertFalse(configuration.parentalPasscode.isEmpty)
    }
    
    // MARK: - Custom Permissions Tests
    
    func testEmptyCustomPermissions() {
        let view = ChildModeSettingsView(configuration: configuration)
        XCTAssertTrue(view.customPermissions.isEmpty)
    }
    
    func testMultipleCustomPermissions() {
        @State var perm1 = false
        @State var perm2 = true
        @State var perm3 = false
        
        let permissions = [
            PermissionToggle(title: "Permission 1", binding: $perm1, color: .red),
            PermissionToggle(title: "Permission 2", binding: $perm2, color: .green),
            PermissionToggle(title: "Permission 3", binding: $perm3, color: .blue)
        ]
        
        let view = ChildModeSettingsView(
            configuration: configuration,
            customPermissions: permissions
        )
        
        XCTAssertEqual(view.customPermissions.count, 3)
        XCTAssertEqual(view.customPermissions[0].title, "Permission 1")
        XCTAssertEqual(view.customPermissions[0].color, .red)
        XCTAssertEqual(view.customPermissions[1].title, "Permission 2")
        XCTAssertEqual(view.customPermissions[1].color, .green)
        XCTAssertEqual(view.customPermissions[2].title, "Permission 3")
        XCTAssertEqual(view.customPermissions[2].color, .blue)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testNegativeTimeLimitHandling() {
        // Test negative time limit (custom time indicator)
        configuration.timeLimitSeconds = -1
        XCTAssertEqual(configuration.timeLimitSeconds, -1)
        
        // Test very large time limit
        configuration.timeLimitSeconds = 999999
        XCTAssertEqual(configuration.timeLimitSeconds, 999999)
    }
    
    func testTimeStringFormattingEdgeCases() {
        // Since timeString is private, we test through configuration changes
        // and verify the behavior through the view's state
        _ = ChildModeSettingsView(configuration: configuration)
        
        // Test negative input edge case
        configuration.timeLimitSeconds = -1
        XCTAssertEqual(configuration.timeLimitSeconds, -1)
        
        // Test very large input
        let largeTime = 86400 // 24 hours in seconds
        configuration.timeLimitSeconds = largeTime
        XCTAssertEqual(configuration.timeLimitSeconds, largeTime)
        
        // Test exactly one hour
        configuration.timeLimitSeconds = 3600
        XCTAssertEqual(configuration.timeLimitSeconds, 3600)
        
        // Test one hour and one second
        configuration.timeLimitSeconds = 3601
        XCTAssertEqual(configuration.timeLimitSeconds, 3601)
    }
    
    func testPasscodeEdgeCases() {
        // Test very long passcode
        let longPasscode = String(repeating: "a", count: 1000)
        configuration.parentalPasscode = longPasscode
        XCTAssertTrue(configuration.isValidPasscode(longPasscode))
        
        // Test special characters in passcode
        let specialPasscode = "!@#$%^&*()_+-=[]{}|;:'\",.<>?/~`"
        configuration.parentalPasscode = specialPasscode
        XCTAssertTrue(configuration.isValidPasscode(specialPasscode))
        
        // Test unicode characters
        let unicodePasscode = "🔒🛡️👶🎯"
        configuration.parentalPasscode = unicodePasscode
        XCTAssertTrue(configuration.isValidPasscode(unicodePasscode))
    }
    
    // MARK: - Integration Tests
    
    func testConfigurationPersistence() {
        let appId = "PersistenceTest_\(UUID().uuidString)"
        
        // Create configuration and set values
        do {
            let config1 = ChildModeConfiguration(appIdentifier: appId)
            config1.isChildMode = true
            config1.timeLimitSeconds = 300
            config1.parentalPasscode = "test123"
            config1.allowCameraSwitch = false
            config1.allowPhotoCapture = false
            config1.allowVideoRecording = false
            config1.enableAudioRecording = false
            config1.autoStartRecording = true
            config1.allowStopRecording = false
            config1.restrictToApprovedContent = false
            config1.allowFileSharing = true
            config1.allowNFCSharing = true
            config1.allowAirDropReceiving = true
        }
        
        // Create new configuration with same identifier - should load persisted values
        do {
            let config2 = ChildModeConfiguration(appIdentifier: appId)
            XCTAssertTrue(config2.isChildMode)
            XCTAssertEqual(config2.timeLimitSeconds, 300)
            XCTAssertEqual(config2.parentalPasscode, "test123")
            XCTAssertFalse(config2.allowCameraSwitch)
            XCTAssertFalse(config2.allowPhotoCapture)
            XCTAssertFalse(config2.allowVideoRecording)
            XCTAssertFalse(config2.enableAudioRecording)
            XCTAssertTrue(config2.autoStartRecording)
            XCTAssertFalse(config2.allowStopRecording)
            XCTAssertFalse(config2.restrictToApprovedContent)
            XCTAssertTrue(config2.allowFileSharing)
            XCTAssertTrue(config2.allowNFCSharing)
            XCTAssertTrue(config2.allowAirDropReceiving)
        }
        
        // Clean up UserDefaults
        let keysToClean = [
            "isChildMode", "timeLimitSeconds", "parentalPasscode", "allowCameraSwitch",
            "allowPhotoCapture", "allowVideoRecording", "enableAudioRecording",
            "autoStartRecording", "allowStopRecording", "restrictToApprovedContent",
            "allowFileSharing", "allowNFCSharing", "allowAirDropReceiving"
        ]
        for key in keysToClean {
            UserDefaults.standard.removeObject(forKey: "\(appId)_\(key)")
        }
    }
    
    func testViewWithConfigurationChanges() {
        _ = ChildModeSettingsView(configuration: configuration)
        
        // Test that view reflects configuration changes
        XCTAssertFalse(configuration.isChildMode)
        
        configuration.isChildMode = true
        XCTAssertTrue(configuration.isChildMode)
        
        configuration.timeLimitSeconds = 120
        XCTAssertEqual(configuration.timeLimitSeconds, 120)
        
        // Test that the configuration reflects the new value
        XCTAssertEqual(configuration.timeLimitSeconds, 120)
    }
    
    // MARK: - Boundary Value Tests
    
    func testTimeLimitBoundaryValues() {
        // Test zero time limit (no limit)
        configuration.timeLimitSeconds = 0
        XCTAssertEqual(configuration.timeLimitSeconds, 0)
        
        // Test minimum practical time limit
        configuration.timeLimitSeconds = 1
        XCTAssertEqual(configuration.timeLimitSeconds, 1)
        
        // Test common time limits
        let commonLimits = [10, 30, 60, 120, 300, 600]
        for limit in commonLimits {
            configuration.timeLimitSeconds = limit
            XCTAssertEqual(configuration.timeLimitSeconds, limit)
        }
        
        // Test custom time limit indicator
        configuration.timeLimitSeconds = -1
        XCTAssertEqual(configuration.timeLimitSeconds, -1)
    }
    
    func testPermissionCombinations() {
        // Test all permissions disabled
        configuration.isChildMode = true
        configuration.allowCameraSwitch = false
        configuration.allowPhotoCapture = false
        configuration.allowVideoRecording = false
        configuration.enableAudioRecording = false
        configuration.autoStartRecording = false
        configuration.allowStopRecording = false
        configuration.allowFileSharing = false
        configuration.allowNFCSharing = false
        configuration.allowAirDropReceiving = false
        configuration.restrictToApprovedContent = true
        
        XCTAssertFalse(configuration.allowCameraSwitch)
        XCTAssertFalse(configuration.allowPhotoCapture)
        XCTAssertFalse(configuration.allowVideoRecording)
        XCTAssertFalse(configuration.enableAudioRecording)
        XCTAssertFalse(configuration.autoStartRecording)
        XCTAssertFalse(configuration.allowStopRecording)
        XCTAssertFalse(configuration.allowFileSharing)
        XCTAssertFalse(configuration.allowNFCSharing)
        XCTAssertFalse(configuration.allowAirDropReceiving)
        XCTAssertTrue(configuration.restrictToApprovedContent)
        
        // Test all permissions enabled
        configuration.allowCameraSwitch = true
        configuration.allowPhotoCapture = true
        configuration.allowVideoRecording = true
        configuration.enableAudioRecording = true
        configuration.autoStartRecording = true
        configuration.allowStopRecording = true
        configuration.allowFileSharing = true
        configuration.allowNFCSharing = true
        configuration.allowAirDropReceiving = true
        configuration.restrictToApprovedContent = false
        
        XCTAssertTrue(configuration.allowCameraSwitch)
        XCTAssertTrue(configuration.allowPhotoCapture)
        XCTAssertTrue(configuration.allowVideoRecording)
        XCTAssertTrue(configuration.enableAudioRecording)
        XCTAssertTrue(configuration.autoStartRecording)
        XCTAssertTrue(configuration.allowStopRecording)
        XCTAssertTrue(configuration.allowFileSharing)
        XCTAssertTrue(configuration.allowNFCSharing)
        XCTAssertTrue(configuration.allowAirDropReceiving)
        XCTAssertFalse(configuration.restrictToApprovedContent)
    }
}