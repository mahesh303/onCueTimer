import SwiftUI

struct TimeDisplay: View {
    let seconds: Int
    let timerManager: TimerManager
    
    var body: some View {
        Text(timerManager.settings.formatTime(seconds))
            .font(.system(size: 80, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .foregroundColor(timerManager.settings.getTimeColor())
    }
} 