import XCTest
@testable import ChildModeKit

/// Core functionality tests with proper UserDefaults isolation
final class CoreFunctionalityTests: XCTestCase {
    
    // MARK: - JSON Handling Tests
    
    func testJSONEncodingDecoding() {
        let appId = "JSONTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        // Test encoding/decoding of video content
        let testVideos: Set<String> = ["video1", "video2", "video3", "special_chars_😀", ""]
        
        config.allowedVideoContent = testVideos
        XCTAssertEqual(config.allowedVideoContent, testVideos)
        
        // Create new instance to test persistence
        let config2 = ChildModeConfiguration(appIdentifier: appId)
        XCTAssertEqual(config2.allowedVideoContent, testVideos)
    }
    
    func testJSONCorruptionHandling() {
        let appId = "CorruptionTest_\(UUID().uuidString)"
        let key = "\(appId)_allowedVideoContent"
        
        // Set corrupted data
        UserDefaults.standard.set(Data("invalid json".utf8), forKey: key)
        
        // Should handle gracefully
        let config = ChildModeConfiguration(appIdentifier: appId)
        XCTAssertTrue(config.allowedVideoContent.isEmpty)
        
        // Should be able to add new content after corruption
        config.approveVideoContent("test_video")
        XCTAssertTrue(config.allowedVideoContent.contains("test_video"))
    }
    
    func testJSONLargeDataset() {
        let appId = "LargeDataTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        // Create large dataset
        let largeSet: Set<String> = Set((1...100).map { "video_\($0)" })
        config.allowedVideoContent = largeSet
        
        XCTAssertEqual(config.allowedVideoContent.count, 100)
        
        // Test persistence
        let config2 = ChildModeConfiguration(appIdentifier: appId)
        XCTAssertEqual(config2.allowedVideoContent.count, 100)
    }
    
    // MARK: - Video Content Management Tests
    
    func testVideoApprovalWorkflow() {
        let appId = "ApprovalTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        // Initially empty
        XCTAssertTrue(config.allowedVideoContent.isEmpty)
        XCTAssertFalse(config.isVideoContentAllowed("test_video"))
        
        // Approve video
        config.approveVideoContent("test_video")
        XCTAssertTrue(config.isVideoContentAllowed("test_video"))
        XCTAssertTrue(config.allowedVideoContent.contains("test_video"))
        
        // Remove approval
        config.removeVideoApproval("test_video")
        XCTAssertFalse(config.isVideoContentAllowed("test_video"))
        XCTAssertFalse(config.allowedVideoContent.contains("test_video"))
    }
    
    func testVideoContentRestrictions() {
        let appId = "RestrictionTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        // With restrictions enabled (default)
        XCTAssertTrue(config.restrictToApprovedContent)
        XCTAssertFalse(config.isVideoContentAllowed("unapproved_video"))
        
        config.approveVideoContent("approved_video")
        XCTAssertTrue(config.isVideoContentAllowed("approved_video"))
        XCTAssertFalse(config.isVideoContentAllowed("unapproved_video"))
        
        // With restrictions disabled
        config.restrictToApprovedContent = false
        XCTAssertTrue(config.isVideoContentAllowed("unapproved_video"))
        XCTAssertTrue(config.isVideoContentAllowed("approved_video"))
    }
    
    // MARK: - Permission System Tests
    
    func testPermissionSystem() {
        let appId = "PermTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        // Parent mode allows everything
        config.isChildMode = false
        XCTAssertTrue(config.canReceiveFiles())
        XCTAssertTrue(config.canUseNFC())
        XCTAssertTrue(config.canReceiveAirDrop())
        
        // Child mode with default restrictions
        config.isChildMode = true
        XCTAssertFalse(config.canReceiveFiles())
        XCTAssertFalse(config.canUseNFC())
        XCTAssertFalse(config.canReceiveAirDrop())
        
        // Child mode with permissions enabled
        config.allowFileSharing = true
        config.allowNFCSharing = true
        config.allowAirDropReceiving = true
        
        XCTAssertTrue(config.canReceiveFiles())
        XCTAssertTrue(config.canUseNFC())
        XCTAssertTrue(config.canReceiveAirDrop())
    }
    
    // MARK: - Timer Management Tests
    
    func testTimerBasicFunctionality() {
        let appId = "TimerTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        let timerManager = TimerManager(configuration: config)
        
        // Initial state
        XCTAssertEqual(timerManager.timeRemaining, 0)
        XCTAssertFalse(timerManager.isTimeLimitReached)
        XCTAssertNil(timerManager.timer)
        
        // Start timer in child mode
        config.isChildMode = true
        config.timeLimitSeconds = 60
        timerManager.startTimer()
        
        XCTAssertEqual(timerManager.timeRemaining, 60)
        XCTAssertNotNil(timerManager.timer)
        
        // Add time
        timerManager.addTime(seconds: 30)
        XCTAssertEqual(timerManager.timeRemaining, 90)
        
        // Reject negative time
        timerManager.addTime(seconds: -10)
        XCTAssertEqual(timerManager.timeRemaining, 90)
        
        // Reset timer
        timerManager.resetTimer()
        XCTAssertEqual(timerManager.timeRemaining, 60)
        XCTAssertFalse(timerManager.isTimeLimitReached)
        
        timerManager.stopTimer()
        XCTAssertNil(timerManager.timer)
    }
    
    func testTimerFormattedOutput() {
        let appId = "FormatTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        let timerManager = TimerManager(configuration: config)
        
        // Test various time formats
        timerManager.timeRemaining = 0
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "00:00")
        
        timerManager.timeRemaining = 125 // 2:05
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "02:05")
        
        timerManager.timeRemaining = 3661 // 61:01
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "61:01")
    }
    
    // MARK: - Configuration Isolation Tests
    
    func testAppIdentifierIsolation() {
        let appId1 = "App1_\(UUID().uuidString)"
        let appId2 = "App2_\(UUID().uuidString)"
        
        let config1 = ChildModeConfiguration(appIdentifier: appId1)
        let config2 = ChildModeConfiguration(appIdentifier: appId2)
        
        // Set different values
        config1.parentalPasscode = "1234"
        config1.timeLimitSeconds = 300
        config1.approveVideoContent("video1")
        
        config2.parentalPasscode = "5678"
        config2.timeLimitSeconds = 600
        config2.approveVideoContent("video2")
        
        // Verify isolation
        XCTAssertEqual(config1.parentalPasscode, "1234")
        XCTAssertEqual(config2.parentalPasscode, "5678")
        XCTAssertEqual(config1.timeLimitSeconds, 300)
        XCTAssertEqual(config2.timeLimitSeconds, 600)
        XCTAssertTrue(config1.isVideoContentAllowed("video1"))
        XCTAssertFalse(config1.isVideoContentAllowed("video2"))
        XCTAssertTrue(config2.isVideoContentAllowed("video2"))
        XCTAssertFalse(config2.isVideoContentAllowed("video1"))
    }
    
    // MARK: - Video Content Manager Tests
    
    func testVideoContentManagerBasics() {
        let appId = "VMTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        let manager = VideoContentManager(configuration: config)
        
        struct TestVideo: VideoContentProtocol {
            let videoId: String
            let title: String
            var isApproved: Bool
        }
        
        // Test permission checks
        config.isChildMode = false
        XCTAssertTrue(manager.canAddVideo())
        XCTAssertTrue(manager.canDeleteVideo())
        XCTAssertTrue(manager.canModifyApprovalStatus())
        
        config.isChildMode = true
        XCTAssertFalse(manager.canAddVideo())
        XCTAssertFalse(manager.canDeleteVideo())
        XCTAssertFalse(manager.canModifyApprovalStatus())
        
        // Test filtering
        config.restrictToApprovedContent = true
        config.approveVideoContent("video1")
        
        let videos = [
            TestVideo(videoId: "video1", title: "Video 1", isApproved: false),
            TestVideo(videoId: "video2", title: "Video 2", isApproved: false)
        ]
        
        let filtered = manager.filterAllowedVideos(videos)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.videoId, "video1")
    }
}
