import XCTest
@testable import ChildModeKit

final class ChildModeConfigurationExtendedTests: XCTestCase {
    
    var configuration: ChildModeConfiguration!
    var appIdentifier: String!
    
    override func setUp() {
        super.setUp()
        appIdentifier = "ExtendedConfigTest_\(UUID().uuidString)"
        configuration = ChildModeConfiguration(appIdentifier: appIdentifier)
    }
    
    override func tearDown() {
        // Clean up UserDefaults
        let keysToClean = [
            "allowCameraSwitch", "allowPhotoCapture", "parentalPasscode",
            "allowVideoRecording", "enableAudioRecording", "autoStartRecording",
            "allowStopRecording", "allowedVideoContent"
        ]
        for key in keysToClean {
            UserDefaults.standard.removeObject(forKey: "\(appIdentifier!)_\(key)")
        }
        configuration = nil
        appIdentifier = nil
        super.tearDown()
    }
    
    // MARK: - Property didSet UserDefaults Storage Tests
    
    func testAllowCameraSwitchDidSetStorage() {
        let key = "\(appIdentifier!)_allowCameraSwitch"
        
        // Initial state should be saved
        XCTAssertTrue(configuration.allowCameraSwitch)
        
        // Change value and verify it's saved to UserDefaults
        configuration.allowCameraSwitch = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: key))
        
        configuration.allowCameraSwitch = true
        let storedValue = UserDefaults.standard.object(forKey: key) as? Bool
        XCTAssertTrue(storedValue ?? false)
    }
    
    func testAllowPhotoCaptureDidSetStorage() {
        let key = "\(appIdentifier!)_allowPhotoCapture"
        
        // Initial state should be saved
        XCTAssertTrue(configuration.allowPhotoCapture)
        
        // Change value and verify it's saved to UserDefaults
        configuration.allowPhotoCapture = false
        let storedValue = UserDefaults.standard.object(forKey: key) as? Bool
        XCTAssertFalse(storedValue ?? true)
        
        configuration.allowPhotoCapture = true
        let storedValueTrue = UserDefaults.standard.object(forKey: key) as? Bool
        XCTAssertTrue(storedValueTrue ?? false)
    }
    
    func testParentalPasscodeDidSetStorage() {
        let key = "\(appIdentifier!)_parentalPasscode"
        
        // Initial state should be empty
        XCTAssertEqual(configuration.parentalPasscode, "")
        
        // Set passcode and verify it's saved to UserDefaults
        configuration.parentalPasscode = "test123"
        let storedValue = UserDefaults.standard.string(forKey: key)
        XCTAssertEqual(storedValue, "test123")
        
        // Change passcode
        configuration.parentalPasscode = "newpass456"
        let newStoredValue = UserDefaults.standard.string(forKey: key)
        XCTAssertEqual(newStoredValue, "newpass456")
        
        // Clear passcode
        configuration.parentalPasscode = ""
        let clearedValue = UserDefaults.standard.string(forKey: key)
        XCTAssertEqual(clearedValue, "")
    }
    
    func testAllowVideoRecordingDidSetStorage() {
        let key = "\(appIdentifier!)_allowVideoRecording"
        
        // Initial state should be true
        XCTAssertTrue(configuration.allowVideoRecording)
        
        // Change value and verify it's saved to UserDefaults
        configuration.allowVideoRecording = false
        let storedValue = UserDefaults.standard.object(forKey: key) as? Bool
        XCTAssertFalse(storedValue ?? true)
        
        configuration.allowVideoRecording = true
        let storedValueTrue = UserDefaults.standard.object(forKey: key) as? Bool
        XCTAssertTrue(storedValueTrue ?? false)
    }
    
    func testEnableAudioRecordingDidSetStorage() {
        let key = "\(appIdentifier!)_enableAudioRecording"
        
        // Initial state should be true
        XCTAssertTrue(configuration.enableAudioRecording)
        
        // Change value and verify it's saved to UserDefaults
        configuration.enableAudioRecording = false
        let storedValue = UserDefaults.standard.object(forKey: key) as? Bool
        XCTAssertFalse(storedValue ?? true)
        
        configuration.enableAudioRecording = true
        let storedValueTrue = UserDefaults.standard.object(forKey: key) as? Bool
        XCTAssertTrue(storedValueTrue ?? false)
    }
    
    func testAutoStartRecordingDidSetStorage() {
        let key = "\(appIdentifier!)_autoStartRecording"
        
        // Initial state should be false
        XCTAssertFalse(configuration.autoStartRecording)
        
        // Change value and verify it's saved to UserDefaults
        configuration.autoStartRecording = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: key))
        
        configuration.autoStartRecording = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: key))
    }
    
    func testAllowStopRecordingDidSetStorage() {
        let key = "\(appIdentifier!)_allowStopRecording"
        
        // Initial state should be true
        XCTAssertTrue(configuration.allowStopRecording)
        
        // Change value and verify it's saved to UserDefaults
        XCTAssertTrue(configuration.allowStopRecording)
        configuration.allowStopRecording = false
        let storedValue = UserDefaults.standard.object(forKey: key) as? Bool
        XCTAssertFalse(storedValue ?? true)
        
        configuration.allowStopRecording = true
        let storedValueTrue = UserDefaults.standard.object(forKey: key) as? Bool
        XCTAssertTrue(storedValueTrue ?? false)
    }
    
    // MARK: - JSON Encoding Error Handling Tests
    
    func testSaveVideoContentToUserDefaultsSuccess() {
        // Test successful encoding and saving
        let testVideos: Set<String> = ["video1", "video2", "video3"]
        configuration.allowedVideoContent = testVideos
        
        // Verify the content was saved successfully
        let key = "\(appIdentifier!)_allowedVideoContent"
        let data = UserDefaults.standard.data(forKey: key)
        XCTAssertNotNil(data)
        
        // Verify we can decode it back
        do {
            let decodedVideos = try JSONDecoder().decode(Set<String>.self, from: data!)
            XCTAssertEqual(decodedVideos, testVideos)
        } catch {
            XCTFail("Failed to decode saved video content: \(error)")
        }
    }
    
    func testSaveVideoContentWithSpecialCharacters() {
        // Test encoding with special characters that might cause issues
        let specialVideos: Set<String> = [
            "video_with_underscores",
            "video-with-dashes",
            "video with spaces",
            "video😀with🎯emojis",
            "video\\with\\backslashes",
            "video\"with\"quotes",
            "video{with}json{chars}",
            "",  // Empty string
            "very_long_video_id_" + String(repeating: "a", count: 1000)
        ]
        
        configuration.allowedVideoContent = specialVideos
        
        // Verify the content was saved successfully
        let key = "\(appIdentifier!)_allowedVideoContent"
        let data = UserDefaults.standard.data(forKey: key)
        XCTAssertNotNil(data)
        
        // Verify we can decode it back correctly
        do {
            let decodedVideos = try JSONDecoder().decode(Set<String>.self, from: data!)
            XCTAssertEqual(decodedVideos, specialVideos)
        } catch {
            XCTFail("Failed to decode special character video content: \(error)")
        }
    }
    
    func testSaveVideoContentLargeDataset() {
        // Test with a large dataset to ensure JSON encoding handles it
        let largeVideoSet: Set<String> = Set((1...1000).map { "video_\($0)" })
        
        configuration.allowedVideoContent = largeVideoSet
        
        // Verify the large dataset was saved successfully
        let key = "\(appIdentifier!)_allowedVideoContent"
        let data = UserDefaults.standard.data(forKey: key)
        XCTAssertNotNil(data)
        
        // Verify we can decode the large dataset
        do {
            let decodedVideos = try JSONDecoder().decode(Set<String>.self, from: data!)
            XCTAssertEqual(decodedVideos.count, 1000)
            XCTAssertEqual(decodedVideos, largeVideoSet)
        } catch {
            XCTFail("Failed to decode large video content dataset: \(error)")
        }
    }
    
    func testSaveVideoContentEmptySet() {
        // Test with empty set
        configuration.allowedVideoContent = Set<String>()
        
        let key = "\(appIdentifier!)_allowedVideoContent"
        let data = UserDefaults.standard.data(forKey: key)
        XCTAssertNotNil(data)
        
        // Verify empty set decodes correctly
        do {
            let decodedVideos = try JSONDecoder().decode(Set<String>.self, from: data!)
            XCTAssertTrue(decodedVideos.isEmpty)
        } catch {
            XCTFail("Failed to decode empty video content set: \(error)")
        }
    }
    
    // MARK: - Multiple Property Changes Tests
    
    func testMultiplePropertyChangesInSequence() {
        // Test that multiple rapid property changes all get saved correctly
        let initialCameraSwitch = configuration.allowCameraSwitch
        let initialPhotoCapture = configuration.allowPhotoCapture
        let initialVideoRecording = configuration.allowVideoRecording
        
        // Change multiple properties
        configuration.allowCameraSwitch = !initialCameraSwitch
        configuration.allowPhotoCapture = !initialPhotoCapture
        configuration.allowVideoRecording = !initialVideoRecording
        configuration.parentalPasscode = "multi123"
        configuration.enableAudioRecording = false
        configuration.autoStartRecording = true
        configuration.allowStopRecording = false
        
        // Verify all changes were saved
        let cameraSwitchKey = "\(appIdentifier!)_allowCameraSwitch"
        let photoCaptureKey = "\(appIdentifier!)_allowPhotoCapture"
        let videoRecordingKey = "\(appIdentifier!)_allowVideoRecording"
        let passcodeKey = "\(appIdentifier!)_parentalPasscode"
        let audioRecordingKey = "\(appIdentifier!)_enableAudioRecording"
        let autoStartKey = "\(appIdentifier!)_autoStartRecording"
        let allowStopKey = "\(appIdentifier!)_allowStopRecording"
        
        XCTAssertEqual(UserDefaults.standard.object(forKey: cameraSwitchKey) as? Bool, !initialCameraSwitch)
        XCTAssertEqual(UserDefaults.standard.object(forKey: photoCaptureKey) as? Bool, !initialPhotoCapture)
        XCTAssertEqual(UserDefaults.standard.object(forKey: videoRecordingKey) as? Bool, !initialVideoRecording)
        XCTAssertEqual(UserDefaults.standard.string(forKey: passcodeKey), "multi123")
        XCTAssertEqual(UserDefaults.standard.object(forKey: audioRecordingKey) as? Bool, false)
        XCTAssertEqual(UserDefaults.standard.bool(forKey: autoStartKey), true)
        XCTAssertEqual(UserDefaults.standard.object(forKey: allowStopKey) as? Bool, false)
    }
    
    func testPropertyChangesWithVideoContent() {
        // Test property changes combined with video content changes
        configuration.allowCameraSwitch = false
        configuration.parentalPasscode = "combo123"
        configuration.allowedVideoContent = Set(["video1", "video2"])
        configuration.enableAudioRecording = false
        
        // Verify all changes were saved
        let cameraSwitchKey = "\(appIdentifier!)_allowCameraSwitch"
        let passcodeKey = "\(appIdentifier!)_parentalPasscode"
        let videoContentKey = "\(appIdentifier!)_allowedVideoContent"
        let audioRecordingKey = "\(appIdentifier!)_enableAudioRecording"
        
        XCTAssertFalse(UserDefaults.standard.object(forKey: cameraSwitchKey) as? Bool ?? true)
        XCTAssertEqual(UserDefaults.standard.string(forKey: passcodeKey), "combo123")
        XCTAssertNotNil(UserDefaults.standard.data(forKey: videoContentKey))
        XCTAssertFalse(UserDefaults.standard.object(forKey: audioRecordingKey) as? Bool ?? true)
        
        // Verify video content was saved correctly
        if let data = UserDefaults.standard.data(forKey: videoContentKey) {
            do {
                let decodedVideos = try JSONDecoder().decode(Set<String>.self, from: data)
                XCTAssertEqual(decodedVideos, Set(["video1", "video2"]))
            } catch {
                XCTFail("Failed to decode video content: \(error)")
            }
        }
    }
    
    // MARK: - Edge Cases for Property Storage
    
    func testExtremeBooleanToggling() {
        // Test rapid boolean toggling to ensure all changes are captured
        // Test allowCameraSwitch
        let cameraKey = "\(appIdentifier!)_allowCameraSwitch"
        let initialCamera = configuration.allowCameraSwitch
        configuration.allowCameraSwitch = !initialCamera
        configuration.allowCameraSwitch = initialCamera
        configuration.allowCameraSwitch = !initialCamera
        let storedCamera = UserDefaults.standard.object(forKey: cameraKey) as? Bool
        XCTAssertEqual(storedCamera, !initialCamera, "allowCameraSwitch not properly stored")
        
        // Test allowPhotoCapture
        let photoKey = "\(appIdentifier!)_allowPhotoCapture"
        let initialPhoto = configuration.allowPhotoCapture
        configuration.allowPhotoCapture = !initialPhoto
        configuration.allowPhotoCapture = initialPhoto
        configuration.allowPhotoCapture = !initialPhoto
        let storedPhoto = UserDefaults.standard.object(forKey: photoKey) as? Bool
        XCTAssertEqual(storedPhoto, !initialPhoto, "allowPhotoCapture not properly stored")
        
        // Test enableAudioRecording
        let audioKey = "\(appIdentifier!)_enableAudioRecording"
        let initialAudio = configuration.enableAudioRecording
        configuration.enableAudioRecording = !initialAudio
        configuration.enableAudioRecording = initialAudio
        configuration.enableAudioRecording = !initialAudio
        let storedAudio = UserDefaults.standard.object(forKey: audioKey) as? Bool
        XCTAssertEqual(storedAudio, !initialAudio, "enableAudioRecording not properly stored")
    }
    
    func testPasscodeEdgeCases() {
        let passcodeKey = "\(appIdentifier!)_parentalPasscode"
        
        // Test various passcode patterns
        let testPasscodes = [
            "",  // Empty
            " ",  // Single space
            "1",  // Single character
            "123456789012345678901234567890",  // Long numeric
            "!@#$%^&*()_+-=[]{}|;':\",./<>?",  // Special characters
            "🔒🛡️👶🎯🔐",  // Unicode emojis
            "Mixed123!@#",  // Mixed characters
            String(repeating: "a", count: 1000)  // Very long
        ]
        
        for passcode in testPasscodes {
            configuration.parentalPasscode = passcode
            let storedValue = UserDefaults.standard.string(forKey: passcodeKey)
            XCTAssertEqual(storedValue, passcode, "Passcode '\(passcode)' not properly stored")
        }
    }
    
    // MARK: - Configuration Reload Tests
    
    func testPropertyPersistenceAfterReload() {
        // Set all properties to non-default values
        configuration.allowCameraSwitch = false
        configuration.allowPhotoCapture = false
        configuration.parentalPasscode = "persist123"
        configuration.allowVideoRecording = false
        configuration.enableAudioRecording = false
        configuration.autoStartRecording = true
        configuration.allowStopRecording = false
        configuration.allowedVideoContent = Set(["persist_video1", "persist_video2"])
        
        // Create new configuration with same identifier
        let newConfiguration = ChildModeConfiguration(appIdentifier: appIdentifier)
        
        // Verify all properties were loaded correctly
        XCTAssertFalse(newConfiguration.allowCameraSwitch)
        XCTAssertFalse(newConfiguration.allowPhotoCapture)
        XCTAssertEqual(newConfiguration.parentalPasscode, "persist123")
        XCTAssertFalse(newConfiguration.allowVideoRecording)
        XCTAssertFalse(newConfiguration.enableAudioRecording)
        XCTAssertTrue(newConfiguration.autoStartRecording)
        XCTAssertFalse(newConfiguration.allowStopRecording)
        XCTAssertEqual(newConfiguration.allowedVideoContent, Set(["persist_video1", "persist_video2"]))
    }
}