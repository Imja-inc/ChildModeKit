import Foundation
import SwiftUI

public class VideoContentManager: ObservableObject {
    private let configuration: ChildModeConfiguration
    
    public init(configuration: ChildModeConfiguration) {
        self.configuration = configuration
    }
    
    public func filterAllowedVideos<T: VideoContentProtocol>(_ videos: [T]) -> [T] {
        guard configuration.isChildMode && configuration.restrictToApprovedContent else {
            return videos
        }
        
        return videos.filter { video in
            configuration.isVideoContentAllowed(video.videoId)
        }
    }
    
    public func canAddVideo() -> Bool {
        return !configuration.isChildMode
    }
    
    public func canDeleteVideo() -> Bool {
        return !configuration.isChildMode
    }
    
    public func canModifyApprovalStatus() -> Bool {
        return !configuration.isChildMode
    }
    
    public func toggleVideoApproval<T: VideoContentProtocol>(_ video: inout T) {
        guard canModifyApprovalStatus() else { return }
        
        if configuration.isVideoContentAllowed(video.videoId) {
            configuration.removeVideoApproval(video.videoId)
            video.isApproved = false
        } else {
            configuration.approveVideoContent(video.videoId)
            video.isApproved = true
        }
    }
}

public protocol VideoContentProtocol {
    var videoId: String { get }
    var title: String { get }
    var isApproved: Bool { get set }
}

// Extension to make VideoItem conform to VideoContentProtocol
extension VideoContentProtocol {
    public var isApproved: Bool {
        get {
            // This should be handled by the implementing type
            return false
        }
        set(newValue) {
            // This should be handled by the implementing type
            _ = newValue
        }
    }
}
