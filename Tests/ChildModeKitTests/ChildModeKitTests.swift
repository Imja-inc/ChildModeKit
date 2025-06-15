import XCTest
@testable import ChildModeKit

final class ChildModeKitTests: XCTestCase {
    
    func testConfigurationInitialization() {
        // Clean up any existing data first
        let appId = "TestAppInit"
        let keys = ["isChildMode", "timeLimitSeconds", "allowCameraSwitch", "allowPhotoCapture", 
                   "parentalPasscode", "allowVideoRecording", "enableAudioRecording", 
                   "autoStartRecording", "allowStopRecording", "allowedVideoContent"]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: "\(appId)_\(key)")
        }
        
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        XCTAssertFalse(config.isChildMode)
        XCTAssertEqual(config.timeLimitSeconds, 600) // Default 10 minutes
        XCTAssertTrue(config.allowCameraSwitch)
        XCTAssertTrue(config.allowPhotoCapture)
        XCTAssertEqual(config.parentalPasscode, "")
        XCTAssertTrue(config.allowVideoRecording)
        XCTAssertTrue(config.enableAudioRecording)
        XCTAssertFalse(config.autoStartRecording)
        XCTAssertTrue(config.allowStopRecording)
    }
    
    func testPasscodeValidation() {
        // Use a unique app identifier to avoid conflicts
        let appId = "PasscodeTestApp"
        let keys = ["parentalPasscode"]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: "\(appId)_\(key)")
        }
        
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        // No passcode set
        XCTAssertFalse(config.isValidPasscode("1234"))
        
        // Set passcode
        config.parentalPasscode = "1234"
        XCTAssertTrue(config.isValidPasscode("1234"))
        XCTAssertFalse(config.isValidPasscode("4321"))
        XCTAssertFalse(config.isValidPasscode(""))
    }
    
    func testTimerManager() {
        let config = ChildModeConfiguration(appIdentifier: "TestApp")
        config.timeLimitSeconds = 10
        config.isChildMode = true
        
        let timerManager = TimerManager(configuration: config)
        
        XCTAssertEqual(timerManager.timeRemaining, 0)
        XCTAssertFalse(timerManager.isTimeLimitReached)
        XCTAssertNil(timerManager.timer)
        
        timerManager.startTimer()
        XCTAssertEqual(timerManager.timeRemaining, 10)
        XCTAssertNotNil(timerManager.timer)
        
        timerManager.addTime(seconds: 5)
        XCTAssertEqual(timerManager.timeRemaining, 15)
        
        timerManager.resetTimer()
        XCTAssertEqual(timerManager.timeRemaining, 10)
        XCTAssertFalse(timerManager.isTimeLimitReached)
        
        timerManager.stopTimer()
        XCTAssertNil(timerManager.timer)
    }
    
    func testFormattedTimeRemaining() {
        let config = ChildModeConfiguration(appIdentifier: "TestApp")
        let timerManager = TimerManager(configuration: config)
        
        timerManager.timeRemaining = 125 // 2:05
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "02:05")
        
        timerManager.timeRemaining = 59 // 0:59
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "00:59")
        
        timerManager.timeRemaining = 3661 // 61:01
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "61:01")
    }
    
    func testAppIdentifierIsolation() {
        let config1 = ChildModeConfiguration(appIdentifier: "App1")
        let config2 = ChildModeConfiguration(appIdentifier: "App2")
        
        config1.parentalPasscode = "1234"
        config1.timeLimitSeconds = 300
        
        config2.parentalPasscode = "5678"
        config2.timeLimitSeconds = 600
        
        // Verify settings are isolated
        XCTAssertEqual(config1.parentalPasscode, "1234")
        XCTAssertEqual(config2.parentalPasscode, "5678")
        XCTAssertEqual(config1.timeLimitSeconds, 300)
        XCTAssertEqual(config2.timeLimitSeconds, 600)
    }
    
    // MARK: - Video Content Tests
    
    func testVideoContentApproval() {
        let config = ChildModeConfiguration(appIdentifier: "VideoTestApp")
        
        // Initially empty
        XCTAssertTrue(config.allowedVideoContent.isEmpty)
        XCTAssertFalse(config.isVideoContentAllowed("video1"))
        
        // Approve a video
        config.approveVideoContent("video1")
        XCTAssertTrue(config.allowedVideoContent.contains("video1"))
        XCTAssertTrue(config.isVideoContentAllowed("video1"))
        
        // Remove approval
        config.removeVideoApproval("video1")
        XCTAssertFalse(config.allowedVideoContent.contains("video1"))
        XCTAssertFalse(config.isVideoContentAllowed("video1"))
    }
    
    func testVideoContentPersistence() {
        let appIdentifier = "VideoTestApp"
        
        // Create config and add video content
        do {
            let config1 = ChildModeConfiguration(appIdentifier: appIdentifier)
            config1.approveVideoContent("video1")
            config1.approveVideoContent("video2")
            config1.approveVideoContent("video3")
            
            XCTAssertEqual(config1.allowedVideoContent.count, 3)
            XCTAssertTrue(config1.allowedVideoContent.contains("video1"))
            XCTAssertTrue(config1.allowedVideoContent.contains("video2"))
            XCTAssertTrue(config1.allowedVideoContent.contains("video3"))
        }
        
        // Create new config with same identifier - should load persisted data
        do {
            let config2 = ChildModeConfiguration(appIdentifier: appIdentifier)
            XCTAssertEqual(config2.allowedVideoContent.count, 3)
            XCTAssertTrue(config2.allowedVideoContent.contains("video1"))
            XCTAssertTrue(config2.allowedVideoContent.contains("video2"))
            XCTAssertTrue(config2.allowedVideoContent.contains("video3"))
        }
        
        // Clean up UserDefaults
        let key = "\(appIdentifier)_allowedVideoContent"
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    func testVideoContentJSONHandling() {
        let config = ChildModeConfiguration(appIdentifier: "JSONTestApp")
        
        // Test with various video IDs including edge cases
        let testVideoIDs: Set<String> = [
            "normal_video_123",
            "video-with-dashes",
            "video_with_underscores",
            "VideoWithNumbers123",
            "😀_emoji_video", // Unicode characters
            "very_long_video_id_that_might_cause_issues_in_some_systems_but_should_work_fine",
            "" // Empty string edge case
        ]
        
        // Set all video IDs
        config.allowedVideoContent = testVideoIDs
        
        // Verify they're all stored
        XCTAssertEqual(config.allowedVideoContent.count, testVideoIDs.count)
        for videoID in testVideoIDs {
            XCTAssertTrue(config.allowedVideoContent.contains(videoID))
        }
        
        // Test persistence
        let newConfig = ChildModeConfiguration(appIdentifier: "JSONTestApp")
        XCTAssertEqual(newConfig.allowedVideoContent.count, testVideoIDs.count)
        for videoID in testVideoIDs {
            XCTAssertTrue(newConfig.allowedVideoContent.contains(videoID))
        }
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "JSONTestApp_allowedVideoContent")
    }
    
    func testVideoContentCorruptedDataHandling() {
        let appIdentifier = "CorruptedTestApp"
        let key = "\(appIdentifier)_allowedVideoContent"
        
        // Manually set corrupted JSON data
        let corruptedData = Data("This is not valid JSON".utf8)
        UserDefaults.standard.set(corruptedData, forKey: key)
        
        // Create config - should handle corrupted data gracefully
        let config = ChildModeConfiguration(appIdentifier: appIdentifier)
        
        // Should have empty set due to corrupted data
        XCTAssertTrue(config.allowedVideoContent.isEmpty)
        
        // Should be able to add new content after corruption
        config.approveVideoContent("new_video")
        XCTAssertTrue(config.allowedVideoContent.contains("new_video"))
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    func testVideoContentLargeDataSet() {
        let config = ChildModeConfiguration(appIdentifier: "LargeDataTestApp")
        
        // Create a large set of video IDs
        let largeVideoSet: Set<String> = Set((1...1000).map { "video_\($0)" })
        
        // Set the large dataset
        config.allowedVideoContent = largeVideoSet
        
        // Verify all videos are stored
        XCTAssertEqual(config.allowedVideoContent.count, 1000)
        
        // Test random sampling
        let sampleIDs = ["video_1", "video_500", "video_999", "video_1000"]
        for videoID in sampleIDs {
            XCTAssertTrue(config.allowedVideoContent.contains(videoID))
        }
        
        // Test persistence of large dataset
        let newConfig = ChildModeConfiguration(appIdentifier: "LargeDataTestApp")
        XCTAssertEqual(newConfig.allowedVideoContent.count, 1000)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "LargeDataTestApp_allowedVideoContent")
    }
    
    func testVideoContentRestrictions() {
        let config = ChildModeConfiguration(appIdentifier: "RestrictionTestApp")
        
        // Test with restriction enabled (default)
        XCTAssertTrue(config.restrictToApprovedContent)
        XCTAssertFalse(config.isVideoContentAllowed("unapproved_video"))
        
        config.approveVideoContent("approved_video")
        XCTAssertTrue(config.isVideoContentAllowed("approved_video"))
        XCTAssertFalse(config.isVideoContentAllowed("unapproved_video"))
        
        // Test with restriction disabled
        config.restrictToApprovedContent = false
        XCTAssertTrue(config.isVideoContentAllowed("unapproved_video"))
        XCTAssertTrue(config.isVideoContentAllowed("approved_video"))
        
        // Re-enable restriction
        config.restrictToApprovedContent = true
        XCTAssertFalse(config.isVideoContentAllowed("unapproved_video"))
        XCTAssertTrue(config.isVideoContentAllowed("approved_video"))
    }
    
    func testPermissionMethods() {
        // Clean unique app identifier
        let appId = "PermissionTestApp_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        // Test parent mode (should allow everything)
        config.isChildMode = false
        XCTAssertTrue(config.canReceiveFiles())
        XCTAssertTrue(config.canUseNFC())
        XCTAssertTrue(config.canReceiveAirDrop())
        
        // Test child mode with permissions disabled (default)
        config.isChildMode = true
        XCTAssertFalse(config.canReceiveFiles())
        XCTAssertFalse(config.canUseNFC())
        XCTAssertFalse(config.canReceiveAirDrop())
        
        // Test child mode with permissions enabled
        config.allowFileSharing = true
        config.allowNFCSharing = true
        config.allowAirDropReceiving = true
        
        XCTAssertTrue(config.canReceiveFiles())
        XCTAssertTrue(config.canUseNFC())
        XCTAssertTrue(config.canReceiveAirDrop())
    }
}
