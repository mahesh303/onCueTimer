import Foundation
import SwiftUI

@Observable final class TimerSettings {
    var totalSeconds: Int
    var remainingSeconds: Int
    var isRunning: Bool
    var timerState: TimerState
    var presets: [Int: Int]
    
    init(minutes: Int = 0) {
        let seconds = minutes * 60
        self.totalSeconds = seconds
        self.remainingSeconds = seconds
        self.isRunning = false
        self.timerState = .ready
        self.presets = [:]
    }
    
    func getTimeColor() -> Color {
        if remainingSeconds > 10 {
            return .primary
        } else if remainingSeconds > 0 {
            return .yellow
        } else {
            return .red
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let absSeconds = abs(seconds)
        let h = absSeconds / 3600
        let m = (absSeconds % 3600) / 60
        let s = absSeconds % 60
        
        let timeString: String
        if h > 0 {
            timeString = String(format: "%d:%02d:%02d", h, m, s)
        } else {
            timeString = String(format: "%02d:%02d", m, s)
        }
        
        return seconds < 0 ? "-" + timeString : timeString
    }
    
    enum TimerState {
        case ready
        case running
        case warning // When time is getting low
        case overtime
        case completed
        
        var color: Color {
            switch self {
            case .ready: return .blue
            case .running: return .green
            case .warning: return .yellow
            case .overtime: return .red
            case .completed: return .gray
            }
        }
    }
} 