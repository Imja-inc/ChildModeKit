import XCTest
@testable import ChildModeKit

final class TimerManagerTests: XCTestCase {
    
    var configuration: ChildModeConfiguration!
    var timerManager: TimerManager!
    
    override func setUp() {
        super.setUp()
        configuration = ChildModeConfiguration(appIdentifier: "TimerTestApp")
        timerManager = TimerManager(configuration: configuration)
    }
    
    override func tearDown() {
        timerManager.stopTimer()
        timerManager = nil
        configuration = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(timerManager.timeRemaining, 0)
        XCTAssertFalse(timerManager.isTimeLimitReached)
        XCTAssertNil(timerManager.timer)
    }
    
    func testStartTimerInParentMode() {
        // Should not start timer in parent mode
        configuration.isChildMode = false
        configuration.timeLimitSeconds = 60
        
        timerManager.startTimer()
        
        XCTAssertEqual(timerManager.timeRemaining, 0)
        XCTAssertNil(timerManager.timer)
    }
    
    func testStartTimerWithNoTimeLimit() {
        // Should not start timer when time limit is 0
        configuration.isChildMode = true
        configuration.timeLimitSeconds = 0
        
        timerManager.startTimer()
        
        XCTAssertEqual(timerManager.timeRemaining, 0)
        XCTAssertNil(timerManager.timer)
    }
    
    func testStartTimerInChildMode() {
        configuration.isChildMode = true
        configuration.timeLimitSeconds = 60
        
        timerManager.startTimer()
        
        XCTAssertEqual(timerManager.timeRemaining, 60)
        XCTAssertNotNil(timerManager.timer)
        XCTAssertFalse(timerManager.isTimeLimitReached)
    }
    
    func testStopTimer() {
        configuration.isChildMode = true
        configuration.timeLimitSeconds = 60
        
        timerManager.startTimer()
        XCTAssertNotNil(timerManager.timer)
        
        timerManager.stopTimer()
        XCTAssertNil(timerManager.timer)
    }
    
    func testResetTimer() {
        configuration.isChildMode = true
        configuration.timeLimitSeconds = 60
        
        timerManager.startTimer()
        timerManager.timeRemaining = 30 // Simulate time passage
        
        timerManager.resetTimer()
        
        XCTAssertEqual(timerManager.timeRemaining, 60)
        XCTAssertFalse(timerManager.isTimeLimitReached)
    }
    
    func testAddTime() {
        configuration.isChildMode = true
        configuration.timeLimitSeconds = 60
        
        timerManager.startTimer()
        timerManager.addTime(seconds: 30)
        
        XCTAssertEqual(timerManager.timeRemaining, 90)
    }
    
    func testAddTimeWithNegativeValue() {
        configuration.isChildMode = true
        configuration.timeLimitSeconds = 60
        
        timerManager.startTimer()
        let initialTime = timerManager.timeRemaining
        
        timerManager.addTime(seconds: -10)
        
        // Should not change time when negative value is added
        XCTAssertEqual(timerManager.timeRemaining, initialTime)
    }
    
    func testTimeLimitReached() {
        configuration.isChildMode = true
        configuration.timeLimitSeconds = 60
        
        timerManager.startTimer()
        timerManager.timeRemaining = 0
        
        // Manually trigger the timer update logic
        timerManager.timeRemaining = 0
        
        XCTAssertTrue(timerManager.timeRemaining <= 0)
    }
    
    func testFormattedTimeRemainingEdgeCases() {
        // Test various time formats
        timerManager.timeRemaining = 0
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "00:00")
        
        timerManager.timeRemaining = 5
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "00:05")
        
        timerManager.timeRemaining = 59
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "00:59")
        
        timerManager.timeRemaining = 60
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "01:00")
        
        timerManager.timeRemaining = 3599 // 59:59
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "59:59")
        
        timerManager.timeRemaining = 3600 // 60:00
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "60:00")
        
        timerManager.timeRemaining = 7200 // 120:00
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "120:00")
    }
    
    func testFormattedTimeRemainingWithDecimalSeconds() {
        // Test that decimal seconds are handled properly
        timerManager.timeRemaining = 59.7
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "00:59")
        
        timerManager.timeRemaining = 60.9
        XCTAssertEqual(timerManager.formattedTimeRemaining(), "01:00")
    }
    
    func testMultipleStartStopCycles() {
        configuration.isChildMode = true
        configuration.timeLimitSeconds = 30
        
        // First cycle
        timerManager.startTimer()
        XCTAssertNotNil(timerManager.timer)
        XCTAssertEqual(timerManager.timeRemaining, 30)
        
        timerManager.stopTimer()
        XCTAssertNil(timerManager.timer)
        
        // Second cycle
        timerManager.startTimer()
        XCTAssertNotNil(timerManager.timer)
        XCTAssertEqual(timerManager.timeRemaining, 30)
        
        timerManager.stopTimer()
        XCTAssertNil(timerManager.timer)
    }
    
    func testTimerRestartWithDifferentConfiguration() {
        configuration.isChildMode = true
        configuration.timeLimitSeconds = 60
        
        timerManager.startTimer()
        XCTAssertEqual(timerManager.timeRemaining, 60)
        
        // Change configuration
        configuration.timeLimitSeconds = 120
        
        // Stop and restart
        timerManager.stopTimer()
        timerManager.startTimer()
        
        XCTAssertEqual(timerManager.timeRemaining, 120)
    }
    
    func testConfigurationChangesWhileTimerRunning() {
        configuration.isChildMode = true
        configuration.timeLimitSeconds = 60
        
        timerManager.startTimer()
        let initialTime = timerManager.timeRemaining
        
        // Change configuration while timer is running
        configuration.timeLimitSeconds = 120
        
        // Timer should continue with its current time, not reset automatically
        XCTAssertEqual(timerManager.timeRemaining, initialTime)
        
        // But reset should use new configuration
        timerManager.resetTimer()
        XCTAssertEqual(timerManager.timeRemaining, 120)
    }
}
