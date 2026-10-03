import Foundation
import SwiftUI

@Observable final class TimerSettings {
    var totalSeconds: Int
    var remainingSeconds: Int
    var isRunning: Bool
    var timerState: TimerState
    var presets: [Int: Int]

    // User-configurable threshold (in seconds) at which the timer turns yellow.
    // Stored in UserDefaults so it survives app restarts.
    // Range: 10 ... 600 seconds, step 30. Default: 60 seconds (1 minute).
    var warningThresholdSeconds: Int {
        didSet {
            UserDefaults.standard.set(warningThresholdSeconds, forKey: "warningThresholdSeconds")
        }
    }

    // When true, the timer text pulses (zoom in/out) while in the yellow warning state.
    // Helps catch the speaker's eye when they are close to their time limit.
    var pulseAnimationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(pulseAnimationEnabled, forKey: "pulseAnimationEnabled")
        }
    }

    init(minutes: Int = 0) {
        let seconds = minutes * 60
        self.totalSeconds = seconds
        self.remainingSeconds = seconds
        self.isRunning = false
        self.timerState = .ready
        self.presets = [:]
        // Load persisted threshold; fall back to 60s (1 minute) if never set.
        let saved = UserDefaults.standard.integer(forKey: "warningThresholdSeconds")
        self.warningThresholdSeconds = saved > 0 ? saved : 60
        // Load persisted pulse toggle; defaults to true (on) for new installs.
        // UserDefaults.bool returns false if key missing, so we check explicitly.
        let hasPulseKey = UserDefaults.standard.object(forKey: "pulseAnimationEnabled") != nil
        self.pulseAnimationEnabled = hasPulseKey
            ? UserDefaults.standard.bool(forKey: "pulseAnimationEnabled")
            : true
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