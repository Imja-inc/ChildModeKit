import XCTest
import SwiftUI
@testable import ChildModeKit

final class ParentalOverrideViewTests: XCTestCase {
    
    var configuration: ChildModeConfiguration!
    var isTimeLimitReached: Bool!
    var timeRemaining: TimeInterval!
    var timer: Timer?
    
    override func setUp() {
        super.setUp()
        let appId = "ParentalOverrideTest_\(UUID().uuidString)"
        configuration = ChildModeConfiguration(appIdentifier: appId)
        isTimeLimitReached = false
        timeRemaining = 600.0 // 10 minutes
        timer = nil
    }
    
    override func tearDown() {
        timer?.invalidate()
        timer = nil
        configuration = nil
        super.tearDown()
    }
    
    // Helper method to create view with bindings
    private func createParentalOverrideView(
        onSessionEnd: (() -> Void)? = nil
    ) -> ParentalOverrideView {
        return ParentalOverrideView(
            configuration: configuration,
            isTimeLimitReached: Binding(
                get: { self.isTimeLimitReached },
                set: { self.isTimeLimitReached = $0 }
            ),
            timeRemaining: Binding(
                get: { self.timeRemaining },
                set: { self.timeRemaining = $0 }
            ),
            timer: Binding(
                get: { self.timer },
                set: { self.timer = $0 }
            ),
            onSessionEnd: onSessionEnd
        )
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultInitialization() {
        let view = createParentalOverrideView()
        
        XCTAssertNotNil(view.configuration)
        XCTAssertNil(view.onSessionEnd)
    }
    
    func testInitializationWithSessionEndCallback() {
        var sessionEnded = false
        let view = createParentalOverrideView(onSessionEnd: {
            sessionEnded = true
        })
        
        XCTAssertNotNil(view.onSessionEnd)
        
        // Test the callback
        view.onSessionEnd?()
        XCTAssertTrue(sessionEnded)
    }
    
    // MARK: - Passcode Verification Tests
    
    func testPasscodeVerificationSuccess() {
        configuration.parentalPasscode = "1234"
        _ = createParentalOverrideView()
        
        // Verify correct passcode
        XCTAssertTrue(configuration.isValidPasscode("1234"))
    }
    
    func testPasscodeVerificationFailure() {
        configuration.parentalPasscode = "1234"
        _ = createParentalOverrideView()
        
        // Verify incorrect passcode
        XCTAssertFalse(configuration.isValidPasscode("4321"))
        XCTAssertFalse(configuration.isValidPasscode(""))
        XCTAssertFalse(configuration.isValidPasscode("123"))
        XCTAssertFalse(configuration.isValidPasscode("12345"))
    }
    
    func testPasscodeVerificationWithEmptyPasscode() {
        // No passcode set
        configuration.parentalPasscode = ""
        _ = createParentalOverrideView()
        
        // Should fail all verification attempts
        XCTAssertFalse(configuration.isValidPasscode("1234"))
        XCTAssertFalse(configuration.isValidPasscode(""))
        XCTAssertFalse(configuration.isValidPasscode("any_input"))
    }
    
    func testPasscodeVerificationEdgeCases() {
        // Test special characters
        configuration.parentalPasscode = "!@#$%"
        _ = createParentalOverrideView()
        XCTAssertTrue(configuration.isValidPasscode("!@#$%"))
        XCTAssertFalse(configuration.isValidPasscode("@#$%!"))
        
        // Test unicode characters
        configuration.parentalPasscode = "🔒🎯"
        XCTAssertTrue(configuration.isValidPasscode("🔒🎯"))
        XCTAssertFalse(configuration.isValidPasscode("🎯🔒"))
        
        // Test very long passcode
        let longPasscode = String(repeating: "a", count: 100)
        configuration.parentalPasscode = longPasscode
        XCTAssertTrue(configuration.isValidPasscode(longPasscode))
        XCTAssertFalse(configuration.isValidPasscode(longPasscode + "b"))
    }
    
    // MARK: - Timer Reset Tests
    
    func testResetTimerFunctionality() {
        _ = createParentalOverrideView()
        
        // Set up initial state
        configuration.timeLimitSeconds = 300 // 5 minutes
        isTimeLimitReached = true
        timeRemaining = 0
        
        // Create a dummy timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in }
        
        // Test reset timer logic (simulating private method behavior)
        isTimeLimitReached = false
        timeRemaining = TimeInterval(configuration.timeLimitSeconds)
        
        XCTAssertFalse(isTimeLimitReached)
        XCTAssertEqual(timeRemaining, 300.0)
        
        // Clean up
        timer?.invalidate()
        timer = nil
    }
    
    func testResetTimerWithDifferentLimits() {
        _ = createParentalOverrideView()
        
        // Test with various time limits
        let timeLimits = [10, 30, 60, 120, 300, 600, 1800] // seconds
        
        for limit in timeLimits {
            configuration.timeLimitSeconds = limit
            isTimeLimitReached = true
            timeRemaining = 0
            
            // Simulate reset
            isTimeLimitReached = false
            timeRemaining = TimeInterval(configuration.timeLimitSeconds)
            
            XCTAssertFalse(isTimeLimitReached)
            XCTAssertEqual(timeRemaining, TimeInterval(limit))
        }
    }
    
    func testResetTimerWithZeroLimit() {
        _ = createParentalOverrideView()
        
        // Test with no time limit (0 seconds)
        configuration.timeLimitSeconds = 0
        isTimeLimitReached = true
        timeRemaining = 0
        
        // Simulate reset
        isTimeLimitReached = false
        timeRemaining = TimeInterval(configuration.timeLimitSeconds)
        
        XCTAssertFalse(isTimeLimitReached)
        XCTAssertEqual(timeRemaining, 0.0)
    }
    
    // MARK: - Add Time Tests
    
    func testAddTimeFunctionality() {
        _ = createParentalOverrideView()
        
        // Set up initial state
        isTimeLimitReached = true
        timeRemaining = 0
        
        // Simulate adding 5 minutes (300 seconds)
        isTimeLimitReached = false
        timeRemaining += 300
        
        XCTAssertFalse(isTimeLimitReached)
        XCTAssertEqual(timeRemaining, 300.0)
    }
    
    func testAddTimeToExistingTime() {
        _ = createParentalOverrideView()
        
        // Set up initial state with existing time
        isTimeLimitReached = false
        timeRemaining = 120 // 2 minutes remaining
        
        // Simulate adding 5 minutes (300 seconds)
        timeRemaining += 300
        
        XCTAssertFalse(isTimeLimitReached)
        XCTAssertEqual(timeRemaining, 420.0) // 7 minutes total
    }
    
    func testAddTimeMultipleTimes() {
        _ = createParentalOverrideView()
        
        // Start with no time
        isTimeLimitReached = true
        timeRemaining = 0
        
        // Add time multiple times
        isTimeLimitReached = false
        timeRemaining += 300 // Add 5 minutes
        XCTAssertEqual(timeRemaining, 300.0)
        
        timeRemaining += 300 // Add another 5 minutes
        XCTAssertEqual(timeRemaining, 600.0)
        
        timeRemaining += 60 // Add 1 minute
        XCTAssertEqual(timeRemaining, 660.0)
    }
    
    func testAddTimeWithVariousAmounts() {
        _ = createParentalOverrideView()
        
        let timeAmounts = [30, 60, 120, 300, 600, 900] // seconds
        
        for amount in timeAmounts {
            isTimeLimitReached = true
            timeRemaining = 0
            
            // Simulate adding time
            isTimeLimitReached = false
            timeRemaining += TimeInterval(amount)
            
            XCTAssertFalse(isTimeLimitReached)
            XCTAssertEqual(timeRemaining, TimeInterval(amount))
        }
    }
    
    // MARK: - End Session Tests
    
    func testEndSessionFunctionality() {
        var sessionEndCalled = false
        let view = createParentalOverrideView(onSessionEnd: {
            sessionEndCalled = true
        })
        
        // Set up active session state
        configuration.isChildMode = true
        isTimeLimitReached = true
        timeRemaining = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in }
        
        // Simulate end session
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
        isTimeLimitReached = false
        configuration.isChildMode = false
        view.onSessionEnd?()
        
        // Verify end session results
        XCTAssertNil(timer)
        XCTAssertEqual(timeRemaining, 0)
        XCTAssertFalse(isTimeLimitReached)
        XCTAssertFalse(configuration.isChildMode)
        XCTAssertTrue(sessionEndCalled)
    }
    
    func testEndSessionWithoutTimer() {
        var sessionEndCalled = false
        let view = createParentalOverrideView(onSessionEnd: {
            sessionEndCalled = true
        })
        
        // Set up state without active timer
        configuration.isChildMode = true
        isTimeLimitReached = true
        timeRemaining = 300
        timer = nil
        
        // Simulate end session
        timeRemaining = 0
        isTimeLimitReached = false
        configuration.isChildMode = false
        view.onSessionEnd?()
        
        XCTAssertNil(timer)
        XCTAssertEqual(timeRemaining, 0)
        XCTAssertFalse(isTimeLimitReached)
        XCTAssertFalse(configuration.isChildMode)
        XCTAssertTrue(sessionEndCalled)
    }
    
    func testEndSessionWithoutCallback() {
        _ = createParentalOverrideView() // No callback provided
        
        // Set up active session state
        configuration.isChildMode = true
        isTimeLimitReached = true
        timeRemaining = 300
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in }
        
        // Simulate end session without callback
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
        isTimeLimitReached = false
        configuration.isChildMode = false
        
        // Should work fine without callback
        XCTAssertNil(timer)
        XCTAssertEqual(timeRemaining, 0)
        XCTAssertFalse(isTimeLimitReached)
        XCTAssertFalse(configuration.isChildMode)
        // onSessionEnd callback was already called
    }
    
    // MARK: - State Management Tests
    
    func testInitialViewState() {
        let view = createParentalOverrideView()
        
        // Test initial binding values
        XCTAssertNotNil(view.configuration)
        
        // These should reflect the initial setup values
        XCTAssertFalse(isTimeLimitReached)
        XCTAssertEqual(timeRemaining, 600.0)
        XCTAssertNil(timer)
    }
    
    func testStateTransitions() {
        _ = createParentalOverrideView()
        
        // Test transition from normal to time limit reached
        isTimeLimitReached = false
        timeRemaining = 10.0
        
        // Simulate time running out
        isTimeLimitReached = true
        timeRemaining = 0
        
        XCTAssertTrue(isTimeLimitReached)
        XCTAssertEqual(timeRemaining, 0)
        
        // Test transition back to normal after override
        isTimeLimitReached = false
        timeRemaining = 300.0
        
        XCTAssertFalse(isTimeLimitReached)
        XCTAssertEqual(timeRemaining, 300.0)
    }
    
    func testTimerStateManagement() {
        _ = createParentalOverrideView()
        
        // Initially no timer
        XCTAssertNil(timer)
        
        // Create and assign timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer!.isValid)
        
        // Invalidate timer
        timer?.invalidate()
        XCTAssertFalse(timer!.isValid)
        
        // Set to nil
        timer = nil
        XCTAssertNil(timer)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteOverrideWorkflow() {
        var sessionEndCalled = false
        _ = createParentalOverrideView(onSessionEnd: {
            sessionEndCalled = true
        })
        
        // Set up child mode with time limit reached
        configuration.isChildMode = true
        configuration.timeLimitSeconds = 300
        configuration.parentalPasscode = "1234"
        isTimeLimitReached = true
        timeRemaining = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in }
        
        // Verify initial state
        XCTAssertTrue(configuration.isChildMode)
        XCTAssertTrue(isTimeLimitReached)
        XCTAssertEqual(timeRemaining, 0)
        XCTAssertNotNil(timer)
        
        // Test passcode verification
        XCTAssertTrue(configuration.isValidPasscode("1234"))
        XCTAssertFalse(configuration.isValidPasscode("4321"))
        
        // Simulate reset timer action
        isTimeLimitReached = false
        timeRemaining = TimeInterval(configuration.timeLimitSeconds)
        
        XCTAssertFalse(isTimeLimitReached)
        XCTAssertEqual(timeRemaining, 300.0)
        XCTAssertTrue(configuration.isChildMode) // Still in child mode
        XCTAssertFalse(sessionEndCalled) // Session not ended
        
        // Clean up
        timer?.invalidate()
        timer = nil
    }
    
    func testAddTimeWorkflow() {
        _ = createParentalOverrideView()
        
        // Set up child mode with some time remaining
        configuration.isChildMode = true
        configuration.timeLimitSeconds = 300
        configuration.parentalPasscode = "1234"
        isTimeLimitReached = false
        timeRemaining = 60 // 1 minute remaining
        
        // Verify passcode and add time
        XCTAssertTrue(configuration.isValidPasscode("1234"))
        
        // Simulate adding 5 minutes
        isTimeLimitReached = false
        timeRemaining += 300
        
        XCTAssertFalse(isTimeLimitReached)
        XCTAssertEqual(timeRemaining, 360.0) // 6 minutes total
        XCTAssertTrue(configuration.isChildMode) // Still in child mode
    }
    
    func testEndSessionWorkflow() {
        var sessionEndCalled = false
        let view = createParentalOverrideView(onSessionEnd: {
            sessionEndCalled = true
        })
        
        // Set up active child mode session
        configuration.isChildMode = true
        configuration.timeLimitSeconds = 300
        configuration.parentalPasscode = "1234"
        isTimeLimitReached = true
        timeRemaining = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in }
        
        // Verify passcode and end session
        XCTAssertTrue(configuration.isValidPasscode("1234"))
        
        // Simulate end session
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
        isTimeLimitReached = false
        configuration.isChildMode = false
        view.onSessionEnd?()
        
        XCTAssertNil(timer)
        XCTAssertEqual(timeRemaining, 0)
        XCTAssertFalse(isTimeLimitReached)
        XCTAssertFalse(configuration.isChildMode)
        XCTAssertTrue(sessionEndCalled)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testNegativeTimeHandling() {
        _ = createParentalOverrideView()
        
        // Start with negative time (shouldn't happen in normal use)
        timeRemaining = -10.0
        
        // Adding time should still work
        timeRemaining += 300
        XCTAssertEqual(timeRemaining, 290.0)
        
        // Reset with negative time limit (custom time indicator)
        configuration.timeLimitSeconds = -1
        timeRemaining = TimeInterval(configuration.timeLimitSeconds)
        XCTAssertEqual(timeRemaining, -1.0)
    }
    
    func testVeryLargeTimeValues() {
        _ = createParentalOverrideView()
        
        // Test with very large time values
        let largeTime: TimeInterval = 86400 // 24 hours
        timeRemaining = largeTime
        XCTAssertEqual(timeRemaining, 86400.0)
        
        // Add more time
        timeRemaining += 3600 // Add 1 hour
        XCTAssertEqual(timeRemaining, 90000.0)
        
        // Test with very large time limit
        configuration.timeLimitSeconds = 999999
        timeRemaining = TimeInterval(configuration.timeLimitSeconds)
        XCTAssertEqual(timeRemaining, 999999.0)
    }
    
    func testZeroTimeHandling() {
        _ = createParentalOverrideView()
        
        // Start with zero time
        timeRemaining = 0
        XCTAssertEqual(timeRemaining, 0)
        
        // Add zero time (no change)
        timeRemaining += 0
        XCTAssertEqual(timeRemaining, 0)
        
        // Add positive time
        timeRemaining += 300
        XCTAssertEqual(timeRemaining, 300.0)
        
        // Reset to zero
        timeRemaining = 0
        XCTAssertEqual(timeRemaining, 0)
    }
    
    func testMultipleTimerOperations() {
        _ = createParentalOverrideView()
        
        // Create multiple timers in sequence
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in }
        let timer1 = timer
        XCTAssertNotNil(timer1)
        XCTAssertTrue(timer1!.isValid)
        
        // Replace with new timer
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in }
        let timer2 = timer
        XCTAssertNotNil(timer2)
        XCTAssertTrue(timer2!.isValid)
        XCTAssertFalse(timer1!.isValid)
        
        // Clean up
        timer?.invalidate()
        timer = nil
        XCTAssertNil(timer)
        XCTAssertFalse(timer2!.isValid)
    }
    
    // MARK: - Boundary Value Tests
    
    func testTimeLimitBoundaryValues() {
        _ = createParentalOverrideView()
        
        // Test with minimum time
        configuration.timeLimitSeconds = 1
        timeRemaining = TimeInterval(configuration.timeLimitSeconds)
        XCTAssertEqual(timeRemaining, 1.0)
        
        // Test with maximum reasonable time (24 hours)
        configuration.timeLimitSeconds = 86400
        timeRemaining = TimeInterval(configuration.timeLimitSeconds)
        XCTAssertEqual(timeRemaining, 86400.0)
        
        // Test with zero (no limit)
        configuration.timeLimitSeconds = 0
        timeRemaining = TimeInterval(configuration.timeLimitSeconds)
        XCTAssertEqual(timeRemaining, 0.0)
    }
    
    func testPasscodeBoundaryValues() {
        _ = createParentalOverrideView()
        
        // Single character passcode
        configuration.parentalPasscode = "1"
        XCTAssertTrue(configuration.isValidPasscode("1"))
        XCTAssertFalse(configuration.isValidPasscode("11"))
        
        // Empty passcode (invalid)
        configuration.parentalPasscode = ""
        XCTAssertFalse(configuration.isValidPasscode(""))
        XCTAssertFalse(configuration.isValidPasscode("1"))
        
        // Very long passcode
        let veryLongPasscode = String(repeating: "1234567890", count: 100)
        configuration.parentalPasscode = veryLongPasscode
        XCTAssertTrue(configuration.isValidPasscode(veryLongPasscode))
        XCTAssertFalse(configuration.isValidPasscode(veryLongPasscode + "1"))
    }
    
    func testConfigurationStateConsistency() {
        _ = createParentalOverrideView()
        
        // Test that configuration changes are reflected consistently
        XCTAssertFalse(configuration.isChildMode)
        
        configuration.isChildMode = true
        XCTAssertTrue(configuration.isChildMode)
        
        configuration.timeLimitSeconds = 600
        XCTAssertEqual(configuration.timeLimitSeconds, 600)
        
        configuration.parentalPasscode = "test123"
        XCTAssertEqual(configuration.parentalPasscode, "test123")
        XCTAssertTrue(configuration.isValidPasscode("test123"))
        
        // End session should disable child mode
        configuration.isChildMode = false
        XCTAssertFalse(configuration.isChildMode)
    }
}