import XCTest
@testable import ChildModeKit

final class VideoContentManagerTests: XCTestCase {
    
    var configuration: ChildModeConfiguration!
    var contentManager: VideoContentManager!
    
    override func setUp() {
        super.setUp()
        // Use unique app identifier for each test run to avoid UserDefaults conflicts
        let uniqueAppId = "VideoContentTestApp_\(UUID().uuidString)"
        configuration = ChildModeConfiguration(appIdentifier: uniqueAppId)
        contentManager = VideoContentManager(configuration: configuration)
    }
    
    override func tearDown() {
        contentManager = nil
        configuration = nil
        super.tearDown()
    }
    
    // MARK: - Test Helper Structures
    
    struct TestVideo: VideoContentProtocol {
        let videoId: String
        let title: String
        var isApproved: Bool
        
        init(id: String, title: String, approved: Bool = false) {
            self.videoId = id
            self.title = title
            self.isApproved = approved
        }
    }
    
    // MARK: - Permission Tests
    
    func testCanAddVideoInParentMode() {
        configuration.isChildMode = false
        XCTAssertTrue(contentManager.canAddVideo())
    }
    
    func testCanAddVideoInChildMode() {
        configuration.isChildMode = true
        XCTAssertFalse(contentManager.canAddVideo())
    }
    
    func testCanDeleteVideoInParentMode() {
        configuration.isChildMode = false
        XCTAssertTrue(contentManager.canDeleteVideo())
    }
    
    func testCanDeleteVideoInChildMode() {
        configuration.isChildMode = true
        XCTAssertFalse(contentManager.canDeleteVideo())
    }
    
    func testCanModifyApprovalStatusInParentMode() {
        configuration.isChildMode = false
        XCTAssertTrue(contentManager.canModifyApprovalStatus())
    }
    
    func testCanModifyApprovalStatusInChildMode() {
        configuration.isChildMode = true
        XCTAssertFalse(contentManager.canModifyApprovalStatus())
    }
    
    // MARK: - Video Filtering Tests
    
    func testFilterAllowedVideosWithEmptyList() {
        let videos: [TestVideo] = []
        let allowedVideos = contentManager.filterAllowedVideos(videos)
        XCTAssertTrue(allowedVideos.isEmpty)
    }
    
    func testFilterAllowedVideosInParentMode() {
        configuration.isChildMode = false
        
        let videos = [
            TestVideo(id: "video1", title: "Video 1", approved: false),
            TestVideo(id: "video2", title: "Video 2", approved: true),
            TestVideo(id: "video3", title: "Video 3", approved: false)
        ]
        
        let allowedVideos = contentManager.filterAllowedVideos(videos)
        
        // In parent mode, all videos should be allowed regardless of approval status
        XCTAssertEqual(allowedVideos.count, 3)
    }
    
    func testFilterAllowedVideosInChildModeWithRestrictions() {
        configuration.isChildMode = true
        configuration.restrictToApprovedContent = true
        
        // Approve specific videos
        configuration.approveVideoContent("video2")
        configuration.approveVideoContent("video4")
        
        let videos = [
            TestVideo(id: "video1", title: "Video 1", approved: false),
            TestVideo(id: "video2", title: "Video 2", approved: true),
            TestVideo(id: "video3", title: "Video 3", approved: false),
            TestVideo(id: "video4", title: "Video 4", approved: true),
            TestVideo(id: "video5", title: "Video 5", approved: false)
        ]
        
        let allowedVideos = contentManager.filterAllowedVideos(videos)
        
        // Only approved videos should be allowed
        XCTAssertEqual(allowedVideos.count, 2)
        XCTAssertTrue(allowedVideos.contains { $0.videoId == "video2" })
        XCTAssertTrue(allowedVideos.contains { $0.videoId == "video4" })
    }
    
    func testFilterAllowedVideosInChildModeWithoutRestrictions() {
        configuration.isChildMode = true
        configuration.restrictToApprovedContent = false
        
        let videos = [
            TestVideo(id: "video1", title: "Video 1", approved: false),
            TestVideo(id: "video2", title: "Video 2", approved: true),
            TestVideo(id: "video3", title: "Video 3", approved: false)
        ]
        
        let allowedVideos = contentManager.filterAllowedVideos(videos)
        
        // All videos should be allowed when restrictions are disabled
        XCTAssertEqual(allowedVideos.count, 3)
    }
    
    func testFilterAllowedVideosWithMixedApprovalStates() {
        // Clean up any existing approvals first
        configuration.allowedVideoContent.removeAll()
        
        configuration.isChildMode = true
        configuration.restrictToApprovedContent = true
        
        // Approve some videos in configuration but not in video objects
        configuration.approveVideoContent("video1")
        configuration.approveVideoContent("video3")
        
        let videos = [
            TestVideo(id: "video1", title: "Video 1", approved: false), // Approved in config
            TestVideo(id: "video2", title: "Video 2", approved: true),  // Not approved in config
            TestVideo(id: "video3", title: "Video 3", approved: false), // Approved in config
            TestVideo(id: "video4", title: "Video 4", approved: true)   // Not approved in config
        ]
        
        let allowedVideos = contentManager.filterAllowedVideos(videos)
        
        // Should only include videos approved in configuration
        XCTAssertEqual(allowedVideos.count, 2)
        XCTAssertTrue(allowedVideos.contains { $0.videoId == "video1" })
        XCTAssertTrue(allowedVideos.contains { $0.videoId == "video3" })
    }
    
    // MARK: - Toggle Approval Tests
    
    func testToggleVideoApprovalFromUnapprovedToApproved() {
        // Must be in parent mode to modify approval status
        configuration.isChildMode = false
        
        var video = TestVideo(id: "test_video", title: "Test Video", approved: false)
        
        // Video should not be approved initially
        XCTAssertFalse(video.isApproved)
        XCTAssertFalse(configuration.isVideoContentAllowed("test_video"))
        
        contentManager.toggleVideoApproval(&video)
        
        // Video should now be approved
        XCTAssertTrue(video.isApproved)
        XCTAssertTrue(configuration.isVideoContentAllowed("test_video"))
    }
    
    func testToggleVideoApprovalFromApprovedToUnapproved() {
        // Must be in parent mode to modify approval status
        configuration.isChildMode = false
        
        var video = TestVideo(id: "test_video", title: "Test Video", approved: true)
        configuration.approveVideoContent("test_video")
        
        // Video should be approved initially
        XCTAssertTrue(video.isApproved)
        XCTAssertTrue(configuration.isVideoContentAllowed("test_video"))
        
        contentManager.toggleVideoApproval(&video)
        
        // Video should now be unapproved
        XCTAssertFalse(video.isApproved)
        XCTAssertFalse(configuration.isVideoContentAllowed("test_video"))
    }
    
    func testToggleVideoApprovalWithMultipleVideos() {
        // Clean up any existing approvals first
        configuration.allowedVideoContent.removeAll()
        
        // Must be in parent mode to modify approval status
        configuration.isChildMode = false
        
        var video1 = TestVideo(id: "video1", title: "Video 1", approved: false)
        var video2 = TestVideo(id: "video2", title: "Video 2", approved: false)
        var video3 = TestVideo(id: "video3", title: "Video 3", approved: false)
        
        // Toggle approval for all videos
        contentManager.toggleVideoApproval(&video1)
        contentManager.toggleVideoApproval(&video2)
        contentManager.toggleVideoApproval(&video3)
        
        // All videos should be approved
        XCTAssertTrue(video1.isApproved)
        XCTAssertTrue(video2.isApproved)
        XCTAssertTrue(video3.isApproved)
        XCTAssertTrue(configuration.isVideoContentAllowed("video1"))
        XCTAssertTrue(configuration.isVideoContentAllowed("video2"))
        XCTAssertTrue(configuration.isVideoContentAllowed("video3"))
        
        // Toggle approval again
        contentManager.toggleVideoApproval(&video2)
        
        // Only video2 should be unapproved
        XCTAssertTrue(video1.isApproved)
        XCTAssertFalse(video2.isApproved)
        XCTAssertTrue(video3.isApproved)
        XCTAssertTrue(configuration.isVideoContentAllowed("video1"))
        XCTAssertFalse(configuration.isVideoContentAllowed("video2"))
        XCTAssertTrue(configuration.isVideoContentAllowed("video3"))
    }
    
    // MARK: - Edge Case Tests
    
    func testFilterAllowedVideosWithEmptyVideoIds() {
        configuration.isChildMode = true
        configuration.restrictToApprovedContent = true
        configuration.approveVideoContent("") // Empty string
        
        let videos = [
            TestVideo(id: "", title: "Empty ID Video", approved: false),
            TestVideo(id: "normal_video", title: "Normal Video", approved: false)
        ]
        
        let allowedVideos = contentManager.filterAllowedVideos(videos)
        
        // Should handle empty video ID
        XCTAssertEqual(allowedVideos.count, 1)
        XCTAssertTrue(allowedVideos.contains { $0.videoId.isEmpty })
    }
    
    func testFilterAllowedVideosWithDuplicateVideoIds() {
        configuration.isChildMode = true
        configuration.restrictToApprovedContent = true
        configuration.approveVideoContent("duplicate_video")
        
        let videos = [
            TestVideo(id: "duplicate_video", title: "First Duplicate", approved: false),
            TestVideo(id: "duplicate_video", title: "Second Duplicate", approved: false),
            TestVideo(id: "unique_video", title: "Unique Video", approved: false)
        ]
        
        let allowedVideos = contentManager.filterAllowedVideos(videos)
        
        // Should include both videos with duplicate IDs if they're approved
        XCTAssertEqual(allowedVideos.count, 2)
        XCTAssertTrue(allowedVideos.allSatisfy { $0.videoId == "duplicate_video" })
    }
    
    func testFilterAllowedVideosWithLargeDataset() {
        configuration.isChildMode = true
        configuration.restrictToApprovedContent = true
        
        // Approve every 10th video
        for i in stride(from: 0, to: 1000, by: 10) {
            configuration.approveVideoContent("video_\(i)")
        }
        
        // Create 1000 test videos
        let videos = (0..<1000).map { TestVideo(id: "video_\($0)", title: "Video \($0)", approved: false) }
        
        let allowedVideos = contentManager.filterAllowedVideos(videos)
        
        // Should have 100 approved videos (every 10th video from 0 to 990)
        XCTAssertEqual(allowedVideos.count, 100)
        
        // Verify the correct videos are included
        for video in allowedVideos {
            let index = Int(video.videoId.dropFirst(6)) // Remove "video_" prefix
            XCTAssertEqual(index! % 10, 0)
        }
    }
    
    // MARK: - Performance Tests
    
    func testFilterPerformanceWithLargeDataset() {
        configuration.isChildMode = true
        configuration.restrictToApprovedContent = true
        
        // Approve half of the videos
        for i in 0..<5000 {
            configuration.approveVideoContent("video_\(i)")
        }
        
        // Create 10000 test videos
        let videos = (0..<10000).map { TestVideo(id: "video_\($0)", title: "Video \($0)", approved: false) }
        
        measure {
            let allowedVideos = contentManager.filterAllowedVideos(videos)
            XCTAssertEqual(allowedVideos.count, 5000)
        }
    }
}
