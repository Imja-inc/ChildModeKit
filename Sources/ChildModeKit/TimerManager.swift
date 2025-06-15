import Foundation
import SwiftUI

public class TimerManager: ObservableObject {
    @Published public var timeRemaining: TimeInterval = 0
    @Published public var isTimeLimitReached: Bool = false
    @Published public var timer: Timer?
    
    private let configuration: ChildModeConfiguration
    public var onTimeUp: (() -> Void)?
    
    public init(configuration: ChildModeConfiguration) {
        self.configuration = configuration
    }
    
    public func startTimer() {
        guard configuration.isChildMode && configuration.timeLimitSeconds > 0 else { return }
        
        timeRemaining = TimeInterval(configuration.timeLimitSeconds)
        isTimeLimitReached = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    public func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    public func resetTimer() {
        stopTimer()
        timeRemaining = TimeInterval(configuration.timeLimitSeconds)
        isTimeLimitReached = false
    }
    
    public func addTime(seconds: Int) {
        guard seconds > 0 else { return }
        timeRemaining += TimeInterval(seconds)
        if isTimeLimitReached {
            isTimeLimitReached = false
            startTimer()
        }
    }
    
    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            isTimeLimitReached = true
            stopTimer()
            onTimeUp?()
        }
    }
    
    public func formattedTimeRemaining() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
