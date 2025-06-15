import Foundation
import SwiftUI

/// ChildModeConfiguration is intentionally open to allow external inheritance
/// External libraries should be able to extend this class for custom functionality
open class ChildModeConfiguration: ObservableObject {
    /// Public properties are intentionally mutable for external library configuration
    @Published public var isChildMode: Bool {
        didSet {
            UserDefaults.standard.set(isChildMode, forKey: storageKey("isChildMode"))
        }
    }
    
    @Published public var timeLimitSeconds: Int {
        didSet {
            UserDefaults.standard.set(timeLimitSeconds, forKey: storageKey("timeLimitSeconds"))
        }
    }
    
    @Published public var allowCameraSwitch: Bool {
        didSet {
            UserDefaults.standard.set(allowCameraSwitch, forKey: storageKey("allowCameraSwitch"))
        }
    }
    
    @Published public var allowPhotoCapture: Bool {
        didSet {
            UserDefaults.standard.set(allowPhotoCapture, forKey: storageKey("allowPhotoCapture"))
        }
    }
    
    @Published public var parentalPasscode: String {
        didSet {
            UserDefaults.standard.set(parentalPasscode, forKey: storageKey("parentalPasscode"))
        }
    }
    
    @Published public var allowVideoRecording: Bool {
        didSet {
            UserDefaults.standard.set(allowVideoRecording, forKey: storageKey("allowVideoRecording"))
        }
    }
    
    @Published public var enableAudioRecording: Bool {
        didSet {
            UserDefaults.standard.set(enableAudioRecording, forKey: storageKey("enableAudioRecording"))
        }
    }
    
    @Published public var autoStartRecording: Bool {
        didSet {
            UserDefaults.standard.set(autoStartRecording, forKey: storageKey("autoStartRecording"))
        }
    }
    
    @Published public var allowStopRecording: Bool {
        didSet {
            UserDefaults.standard.set(allowStopRecording, forKey: storageKey("allowStopRecording"))
        }
    }
    
    @Published public var allowedVideoContent: Set<String> {
        didSet {
            saveVideoContentToUserDefaults()
        }
    }
    
    @Published public var restrictToApprovedContent: Bool {
        didSet {
            UserDefaults.standard.set(restrictToApprovedContent, forKey: storageKey("restrictToApprovedContent"))
        }
    }
    
    @Published public var allowFileSharing: Bool {
        didSet {
            UserDefaults.standard.set(allowFileSharing, forKey: storageKey("allowFileSharing"))
        }
    }
    
    @Published public var allowNFCSharing: Bool {
        didSet {
            UserDefaults.standard.set(allowNFCSharing, forKey: storageKey("allowNFCSharing"))
        }
    }
    
    @Published public var allowAirDropReceiving: Bool {
        didSet {
            UserDefaults.standard.set(allowAirDropReceiving, forKey: storageKey("allowAirDropReceiving"))
        }
    }
    
    private let appIdentifier: String
    
    public init(appIdentifier: String = "DefaultApp") {
        self.appIdentifier = appIdentifier
        
        let keyPrefix = "\(appIdentifier)_"
        self.isChildMode = UserDefaults.standard.bool(forKey: keyPrefix + "isChildMode")
        self.timeLimitSeconds = UserDefaults.standard.integer(forKey: keyPrefix + "timeLimitSeconds")
        self.allowCameraSwitch = UserDefaults.standard.object(forKey: keyPrefix + "allowCameraSwitch") as? Bool ?? true
        self.allowPhotoCapture = UserDefaults.standard.object(forKey: keyPrefix + "allowPhotoCapture") as? Bool ?? true
        self.parentalPasscode = UserDefaults.standard.string(forKey: keyPrefix + "parentalPasscode") ?? ""
        self.allowVideoRecording = UserDefaults.standard.object(forKey: keyPrefix + "allowVideoRecording") as? Bool ?? true
        self.enableAudioRecording = UserDefaults.standard.object(forKey: keyPrefix + "enableAudioRecording") as? Bool ?? true
        self.autoStartRecording = UserDefaults.standard.bool(forKey: keyPrefix + "autoStartRecording")
        self.allowStopRecording = UserDefaults.standard.object(forKey: keyPrefix + "allowStopRecording") as? Bool ?? true
        
        // Video app specific settings
        if let data = UserDefaults.standard.data(forKey: keyPrefix + "allowedVideoContent") {
            do {
                self.allowedVideoContent = try JSONDecoder().decode(Set<String>.self, from: data)
            } catch {
                print("ChildModeKit: Failed to decode video content during init - \(error.localizedDescription)")
                UserDefaults.standard.removeObject(forKey: keyPrefix + "allowedVideoContent")
                self.allowedVideoContent = Set<String>()
            }
        } else {
            self.allowedVideoContent = Set<String>()
        }
        self.restrictToApprovedContent = UserDefaults.standard.object(forKey: keyPrefix + "restrictToApprovedContent") as? Bool ?? true
        self.allowFileSharing = UserDefaults.standard.object(forKey: keyPrefix + "allowFileSharing") as? Bool ?? false
        self.allowNFCSharing = UserDefaults.standard.object(forKey: keyPrefix + "allowNFCSharing") as? Bool ?? false
        self.allowAirDropReceiving = UserDefaults.standard.object(forKey: keyPrefix + "allowAirDropReceiving") as? Bool ?? false
        
        if timeLimitSeconds == 0 {
            timeLimitSeconds = 600
        }
    }
    
    public func isValidPasscode(_ passcode: String) -> Bool {
        return !parentalPasscode.isEmpty && passcode == parentalPasscode
    }
    
    public func approveVideoContent(_ videoId: String) {
        allowedVideoContent.insert(videoId)
    }
    
    public func removeVideoApproval(_ videoId: String) {
        allowedVideoContent.remove(videoId)
    }
    
    public func isVideoContentAllowed(_ videoId: String) -> Bool {
        if !restrictToApprovedContent {
            return true
        }
        return allowedVideoContent.contains(videoId)
    }
    
    public func canReceiveFiles() -> Bool {
        return !isChildMode || allowFileSharing
    }
    
    public func canUseNFC() -> Bool {
        return !isChildMode || allowNFCSharing
    }
    
    public func canReceiveAirDrop() -> Bool {
        return !isChildMode || allowAirDropReceiving
    }
    
    private func storageKey(_ key: String) -> String {
        return "\(appIdentifier)_\(key)"
    }
    
    // MARK: - JSON Handling
    
    /// Safely saves video content to UserDefaults with proper error handling
    private func saveVideoContentToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(allowedVideoContent)
            UserDefaults.standard.set(data, forKey: storageKey("allowedVideoContent"))
        } catch {
            print("ChildModeKit: Failed to encode video content - \(error.localizedDescription)")
            // Fallback: clear the corrupted data
            UserDefaults.standard.removeObject(forKey: storageKey("allowedVideoContent"))
        }
    }
    
}
