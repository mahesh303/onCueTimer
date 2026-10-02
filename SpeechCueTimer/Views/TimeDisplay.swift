import SwiftUI

struct TimeDisplay: View {
    let seconds: Int
    let timerManager: TimerManager

    // Drives the scale animation; toggled by the .task below.
    @State private var isPulsing = false

    // Active when the timer is yellow AND the operator has enabled the pulse toggle.
    private var shouldPulse: Bool {
        timerManager.settings.timerState == .warning &&
        timerManager.settings.pulseAnimationEnabled
    }

    var body: some View {
        Text(timerManager.settings.formatTime(seconds))
            .font(.system(size: 80, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .foregroundColor(timerManager.settings.getTimeColor())
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            // .task(id:) is re-launched whenever shouldPulse changes and is
            // automatically cancelled when the view disappears — no leaks.
            .task(id: shouldPulse) {
                if shouldPulse {
                    // Kick off a repeating scale oscillation.
                    while !Task.isCancelled {
                        withAnimation(.easeInOut(duration: 0.65)) { isPulsing = true }
                        try? await Task.sleep(for: .milliseconds(650))
                        withAnimation(.easeInOut(duration: 0.65)) { isPulsing = false }
                        try? await Task.sleep(for: .milliseconds(650))
                    }
                } else {
                    // Return to normal scale smoothly.
                    withAnimation(.easeInOut(duration: 0.3)) { isPulsing = false }
                }
            }
    }
}