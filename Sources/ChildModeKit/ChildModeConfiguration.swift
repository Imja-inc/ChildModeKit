import Foundation
import SwiftUI

public class ChildModeConfiguration: ObservableObject {
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
        
        if timeLimitSeconds == 0 {
            timeLimitSeconds = 600
        }
    }
    
    public func isValidPasscode(_ passcode: String) -> Bool {
        return !parentalPasscode.isEmpty && passcode == parentalPasscode
    }
    
    private func storageKey(_ key: String) -> String {
        return "\(appIdentifier)_\(key)"
    }
}