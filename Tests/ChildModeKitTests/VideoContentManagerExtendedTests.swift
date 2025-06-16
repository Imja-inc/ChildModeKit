import XCTest
@testable import ChildModeKit

final class VideoContentManagerExtendedTests: XCTestCase {
    
    var configuration: ChildModeConfiguration!
    var contentManager: VideoContentManager!
    
    override func setUp() {
        super.setUp()
        let appId = "VideoContentExtendedTest_\(UUID().uuidString)"
        configuration = ChildModeConfiguration(appIdentifier: appId)
        contentManager = VideoContentManager(configuration: configuration)
    }
    
    override func tearDown() {
        contentManager = nil
        configuration = nil
        super.tearDown()
    }
    
    // MARK: - VideoContentProtocol Default Implementation Tests
    
    // Test struct that uses default isApproved implementation from protocol extension
    struct VideoWithDefaultApproval: VideoContentProtocol {
        let videoId: String
        let title: String
        // Using default isApproved implementation from protocol extension
    }
    
    // Test struct that overrides isApproved implementation
    struct VideoWithCustomApproval: VideoContentProtocol {
        let videoId: String
        let title: String
        var isApproved: Bool
        
        init(id: String, title: String, approved: Bool = false) {
            self.videoId = id
            self.title = title
            self.isApproved = approved
        }
    }
    
    func testVideoContentProtocolDefaultIsApprovedGetter() {
        let video = VideoWithDefaultApproval(videoId: "test_video", title: "Test Video")
        
        // Default implementation should return false
        XCTAssertFalse(video.isApproved)
    }
    
    func testVideoContentProtocolDefaultIsApprovedSetter() {
        var video = VideoWithDefaultApproval(videoId: "test_video", title: "Test Video")
        
        // Default implementation should not crash when setting value
        video.isApproved = true
        
        // But should still return false due to default implementation
        XCTAssertFalse(video.isApproved)
        
        // Setting to false should also work
        video.isApproved = false
        XCTAssertFalse(video.isApproved)
    }
    
    func testVideoContentProtocolDefaultImplementationWithToggle() {
        configuration.isChildMode = false // Allow modifications
        
        var video = VideoWithDefaultApproval(videoId: "test_video", title: "Test Video")
        
        // Initial state - not approved
        XCTAssertFalse(video.isApproved)
        XCTAssertFalse(configuration.isVideoContentAllowed("test_video"))
        
        // Toggle approval - this should work even with default implementation
        contentManager.toggleVideoApproval(&video)
        
        // Configuration should be updated, but video.isApproved stays false due to default implementation
        XCTAssertTrue(configuration.isVideoContentAllowed("test_video"))
        XCTAssertFalse(video.isApproved) // Still false due to default implementation
    }
    
    func testVideoContentProtocolCustomImplementationComparison() {
        configuration.isChildMode = false // Allow modifications
        
        // Video with default implementation
        var videoDefault = VideoWithDefaultApproval(videoId: "default_video", title: "Default Video")
        
        // Video with custom implementation
        var videoCustom = VideoWithCustomApproval(id: "custom_video", title: "Custom Video", approved: false)
        
        // Both start as not approved
        XCTAssertFalse(videoDefault.isApproved)
        XCTAssertFalse(videoCustom.isApproved)
        
        // Toggle approval for both
        contentManager.toggleVideoApproval(&videoDefault)
        contentManager.toggleVideoApproval(&videoCustom)
        
        // Configuration should be updated for both
        XCTAssertTrue(configuration.isVideoContentAllowed("default_video"))
        XCTAssertTrue(configuration.isVideoContentAllowed("custom_video"))
        
        // But only custom implementation should reflect the change in isApproved
        XCTAssertFalse(videoDefault.isApproved) // Still false due to default implementation
        XCTAssertTrue(videoCustom.isApproved) // True due to custom implementation
    }
    
    func testVideoContentProtocolDefaultImplementationMultipleValues() {
        var video = VideoWithDefaultApproval(videoId: "test_video", title: "Test Video")
        
        // Test setting various boolean values
        video.isApproved = true
        XCTAssertFalse(video.isApproved) // Always returns false
        
        video.isApproved = false
        XCTAssertFalse(video.isApproved) // Always returns false
        
        // Multiple assignments
        video.isApproved = true
        video.isApproved = false
        video.isApproved = true
        XCTAssertFalse(video.isApproved) // Always returns false
    }
    
    // MARK: - Mixed Protocol Implementation Tests
    
    func testFilteringWithMixedImplementations() {
        configuration.isChildMode = true
        configuration.restrictToApprovedContent = true
        
        // Approve specific videos in configuration
        configuration.approveVideoContent("default_video")
        configuration.approveVideoContent("custom_video")
        
        // Test with default implementation videos
        let defaultVideos = [
            VideoWithDefaultApproval(videoId: "default_video", title: "Default Video"),
            VideoWithDefaultApproval(videoId: "unapproved_default", title: "Unapproved Default")
        ]
        
        let allowedDefaultVideos = contentManager.filterAllowedVideos(defaultVideos)
        XCTAssertEqual(allowedDefaultVideos.count, 1)
        XCTAssertEqual(allowedDefaultVideos.first?.videoId, "default_video")
        
        // Test with custom implementation videos
        let customVideos = [
            VideoWithCustomApproval(id: "custom_video", title: "Custom Video", approved: false),
            VideoWithCustomApproval(id: "unapproved_custom", title: "Unapproved Custom", approved: false)
        ]
        
        let allowedCustomVideos = contentManager.filterAllowedVideos(customVideos)
        XCTAssertEqual(allowedCustomVideos.count, 1)
        XCTAssertEqual(allowedCustomVideos.first?.videoId, "custom_video")
    }
    
    func testToggleApprovalWithChildModeRestriction() {
        configuration.isChildMode = true // Should prevent modifications
        
        var videoDefault = VideoWithDefaultApproval(videoId: "default_video", title: "Default Video")
        var videoCustom = VideoWithCustomApproval(id: "custom_video", title: "Custom Video", approved: false)
        
        // Neither should be approved initially
        XCTAssertFalse(configuration.isVideoContentAllowed("default_video"))
        XCTAssertFalse(configuration.isVideoContentAllowed("custom_video"))
        XCTAssertFalse(videoDefault.isApproved)
        XCTAssertFalse(videoCustom.isApproved)
        
        // Attempt to toggle approval in child mode - should be ignored
        contentManager.toggleVideoApproval(&videoDefault)
        contentManager.toggleVideoApproval(&videoCustom)
        
        // Nothing should change
        XCTAssertFalse(configuration.isVideoContentAllowed("default_video"))
        XCTAssertFalse(configuration.isVideoContentAllowed("custom_video"))
        XCTAssertFalse(videoDefault.isApproved)
        XCTAssertFalse(videoCustom.isApproved)
    }
    
    // MARK: - Edge Cases with Default Implementation
    
    func testDefaultImplementationWithEmptyVideoId() {
        var video = VideoWithDefaultApproval(videoId: "", title: "Empty ID Video")
        
        XCTAssertFalse(video.isApproved)
        video.isApproved = true
        XCTAssertFalse(video.isApproved)
    }
    
    func testDefaultImplementationWithSpecialCharacters() {
        let specialIds = [
            "video-with-dashes",
            "video_with_underscores", 
            "video with spaces",
            "video😀with🎯emojis",
            "video{with}json{chars}",
            "very_long_video_id_" + String(repeating: "a", count: 1000)
        ]
        
        for specialId in specialIds {
            var video = VideoWithDefaultApproval(videoId: specialId, title: "Special Video")
            
            XCTAssertFalse(video.isApproved)
            video.isApproved = true
            XCTAssertFalse(video.isApproved)
        }
    }
    
    func testDefaultImplementationPerformance() {
        // Test that default implementation doesn't cause performance issues
        let videos = (0..<1000).map { 
            VideoWithDefaultApproval(videoId: "video_\($0)", title: "Video \($0)")
        }
        
        measure {
            for var video in videos {
                let _ = video.isApproved // Getter
                video.isApproved = true  // Setter
                video.isApproved = false // Setter
            }
        }
    }
    
    // MARK: - Protocol Conformance Tests
    
    func testVideoContentProtocolConformance() {
        let defaultVideo: any VideoContentProtocol = VideoWithDefaultApproval(videoId: "test", title: "Test")
        let customVideo: any VideoContentProtocol = VideoWithCustomApproval(id: "test", title: "Test", approved: true)
        
        // Both should conform to the protocol
        XCTAssertEqual(defaultVideo.videoId, "test")
        XCTAssertEqual(defaultVideo.title, "Test")
        XCTAssertFalse(defaultVideo.isApproved) // Default implementation
        
        XCTAssertEqual(customVideo.videoId, "test")
        XCTAssertEqual(customVideo.title, "Test")
        XCTAssertTrue(customVideo.isApproved) // Custom implementation
    }
    
    func testPolymorphicUsage() {
        configuration.isChildMode = false
        
        // Test with default implementation videos
        var defaultVideo1 = VideoWithDefaultApproval(videoId: "default1", title: "Default 1")
        var defaultVideo2 = VideoWithDefaultApproval(videoId: "default2", title: "Default 2")
        
        contentManager.toggleVideoApproval(&defaultVideo1)
        contentManager.toggleVideoApproval(&defaultVideo2)
        
        XCTAssertTrue(configuration.isVideoContentAllowed("default1"))
        XCTAssertTrue(configuration.isVideoContentAllowed("default2"))
        
        // Test with custom implementation videos
        var customVideo1 = VideoWithCustomApproval(id: "custom1", title: "Custom 1", approved: false)
        var customVideo2 = VideoWithCustomApproval(id: "custom2", title: "Custom 2", approved: true)
        
        // Pre-approve customVideo2 in configuration to match its initial state
        configuration.approveVideoContent("custom2")
        
        contentManager.toggleVideoApproval(&customVideo1)
        contentManager.toggleVideoApproval(&customVideo2)
        
        XCTAssertTrue(configuration.isVideoContentAllowed("custom1"))
        XCTAssertFalse(configuration.isVideoContentAllowed("custom2")) // Was true, now toggled to false
    }
    
    // MARK: - Integration Tests
    
    func testDefaultImplementationInRealWorldScenario() {
        // Simulate a real-world scenario where a third-party might use the default implementation
        configuration.isChildMode = true
        configuration.restrictToApprovedContent = true
        
        // Parent approves some content
        configuration.isChildMode = false
        configuration.approveVideoContent("approved_video")
        
        // Back to child mode
        configuration.isChildMode = true
        
        // Create videos with default implementation (like a third-party might do)
        let videos = [
            VideoWithDefaultApproval(videoId: "approved_video", title: "Approved Video"),
            VideoWithDefaultApproval(videoId: "unapproved_video", title: "Unapproved Video")
        ]
        
        let allowedVideos = contentManager.filterAllowedVideos(videos)
        
        // Should work correctly even with default implementation
        XCTAssertEqual(allowedVideos.count, 1)
        XCTAssertEqual(allowedVideos.first?.videoId, "approved_video")
        
        // The video object still reports false due to default implementation
        XCTAssertFalse(allowedVideos.first?.isApproved ?? true)
    }
}