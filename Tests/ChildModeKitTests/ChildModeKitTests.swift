import XCTest
@testable import ChildModeKit

final class ChildModeKitTests: XCTestCase {
    
    func testConfigurationInitialization() {
        let config = ChildModeConfiguration(appIdentifier: "TestApp")
        
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
        let config = ChildModeConfiguration(appIdentifier: "TestApp")
        
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
}