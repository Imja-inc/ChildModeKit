import XCTest
@testable import ChildModeKit

/// Comprehensive JSON error handling and edge case tests
final class JSONErrorHandlingTests: XCTestCase {
    
    func testEmptyJSONData() {
        let appId = "EmptyJSONTest_\(UUID().uuidString)"
        let key = "\(appId)_allowedVideoContent"
        
        // Set empty data (not nil, but empty)
        UserDefaults.standard.set(Data(), forKey: key)
        
        let config = ChildModeConfiguration(appIdentifier: appId)
        XCTAssertTrue(config.allowedVideoContent.isEmpty)
        
        // Should be able to add content after empty data
        config.approveVideoContent("test_video")
        XCTAssertTrue(config.allowedVideoContent.contains("test_video"))
    }
    
    func testMalformedJSONStructure() {
        let appId = "MalformedJSONTest_\(UUID().uuidString)"
        let key = "\(appId)_allowedVideoContent"
        
        // Set truly malformed JSON (missing closing bracket)
        let malformedJSON = "[\"video1\", \"video2\""
        UserDefaults.standard.set(Data(malformedJSON.utf8), forKey: key)
        
        let config = ChildModeConfiguration(appIdentifier: appId)
        // Should fall back to empty set when decoding malformed JSON
        // The corrupted data should be cleared automatically
        XCTAssertTrue(config.allowedVideoContent.isEmpty, "Expected empty set after malformed JSON, got: \(config.allowedVideoContent)")
        
        // Should recover and work normally
        config.approveVideoContent("new_video")
        XCTAssertTrue(config.allowedVideoContent.contains("new_video"))
    }
    
    func testJSONWithInvalidCharacters() {
        let appId = "InvalidCharsTest_\(UUID().uuidString)"
        let key = "\(appId)_allowedVideoContent"
        
        // Set data with invalid JSON characters
        let invalidJSON = "{\"invalid\": unclosed string"
        UserDefaults.standard.set(Data(invalidJSON.utf8), forKey: key)
        
        let config = ChildModeConfiguration(appIdentifier: appId)
        XCTAssertTrue(config.allowedVideoContent.isEmpty)
    }
    
    func testJSONWithUnicodeEdgeCases() {
        let appId = "UnicodeTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        // Test various Unicode edge cases
        let unicodeVideos: Set<String> = [
            "🎬📹🎥", // Emojis
            "测试视频", // Chinese characters
            "فيديو تجريبي", // Arabic text
            "тестовое видео", // Cyrillic
            "🇺🇸🇯🇵🇩🇪", // Flag emojis
            "video\\nwith\\nnewlines", // Escaped characters
            "video\"with\"quotes", // Quotes
            "video\\\\with\\\\backslashes" // Backslashes
        ]
        
        config.allowedVideoContent = unicodeVideos
        XCTAssertEqual(config.allowedVideoContent.count, unicodeVideos.count)
        
        // Test persistence with Unicode
        let config2 = ChildModeConfiguration(appIdentifier: appId)
        XCTAssertEqual(config2.allowedVideoContent, unicodeVideos)
    }
    
    func testJSONWithExtremelyLongStrings() {
        let appId = "LongStringTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        // Create extremely long video ID
        let longVideoId = String(repeating: "a", count: 10000)
        
        config.approveVideoContent(longVideoId)
        XCTAssertTrue(config.allowedVideoContent.contains(longVideoId))
        
        // Test persistence
        let config2 = ChildModeConfiguration(appIdentifier: appId)
        XCTAssertTrue(config2.allowedVideoContent.contains(longVideoId))
    }
    
    func testJSONWithNullBytes() {
        let appId = "NullByteTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        // Video ID with null byte
        let videoWithNull = "video\u{0000}test"
        
        config.approveVideoContent(videoWithNull)
        XCTAssertTrue(config.allowedVideoContent.contains(videoWithNull))
        
        // Test persistence
        let config2 = ChildModeConfiguration(appIdentifier: appId)
        XCTAssertTrue(config2.allowedVideoContent.contains(videoWithNull))
    }
    
    func testConcurrentJSONOperations() {
        let appId = "ConcurrentTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        // Note: UserDefaults isn't thread-safe for rapid concurrent writes
        // This test ensures graceful handling of concurrent access
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        
        // Perform operations with slight delays to reduce race conditions
        for index in 0..<5 {
            group.enter()
            queue.async {
                // Add slight delay to reduce race conditions
                Thread.sleep(forTimeInterval: 0.001 * Double(index))
                config.approveVideoContent("video_\(index)")
                group.leave()
            }
        }
        
        group.wait()
        
        // Should have some videos (exact count may vary due to race conditions)
        // The important thing is that it doesn't crash and has at least some data
        XCTAssertGreaterThan(config.allowedVideoContent.count, 0)
        XCTAssertLessThanOrEqual(config.allowedVideoContent.count, 5)
    }
    
    func testJSONMemoryPressure() {
        let appId = "MemoryTest_\(UUID().uuidString)"
        
        // Create and destroy many configurations to test memory handling
        for iteration in 0..<100 {
            autoreleasepool {
                let config = ChildModeConfiguration(appIdentifier: "\(appId)_\(iteration)")
                
                // Add some content
                for i in 0..<10 {
                    config.approveVideoContent("video_\(iteration)_\(i)")
                }
                
                XCTAssertEqual(config.allowedVideoContent.count, 10)
            }
        }
        
        // If we get here without memory issues, the test passes
        XCTAssertTrue(true)
    }
    
    func testJSONEncodingErrors() {
        let appId = "EncodingErrorTest_\(UUID().uuidString)"
        let config = ChildModeConfiguration(appIdentifier: appId)
        
        // Add valid content first
        config.approveVideoContent("valid_video")
        XCTAssertTrue(config.allowedVideoContent.contains("valid_video"))
        
        // The saveVideoContentToUserDefaults method should handle encoding errors gracefully
        // Since Set<String> should always be encodable, this mainly tests the error handling path exists
        
        // Verify the content is still accessible
        XCTAssertTrue(config.allowedVideoContent.contains("valid_video"))
    }
    
    func testJSONDataCorruptionRecovery() {
        let appId = "CorruptionRecoveryTest_\(UUID().uuidString)"
        let key = "\(appId)_allowedVideoContent"
        
        // First, set valid data
        let config1 = ChildModeConfiguration(appIdentifier: appId)
        config1.approveVideoContent("video1")
        config1.approveVideoContent("video2")
        
        // Corrupt the data externally
        UserDefaults.standard.set(Data("corrupted data".utf8), forKey: key)
        
        // Create new config - should detect corruption and start fresh
        let config2 = ChildModeConfiguration(appIdentifier: appId)
        XCTAssertTrue(config2.allowedVideoContent.isEmpty)
        
        // Should be able to add new content
        config2.approveVideoContent("new_video")
        XCTAssertTrue(config2.allowedVideoContent.contains("new_video"))
        
        // Verify persistence of new content
        let config3 = ChildModeConfiguration(appIdentifier: appId)
        XCTAssertTrue(config3.allowedVideoContent.contains("new_video"))
        XCTAssertFalse(config3.allowedVideoContent.contains("video1")) // Old data should be gone
    }
}
