import Foundation
import SwiftUI
import UIKit

@Observable final class TimerManager {
    private var timer: Timer?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // Core state
    var settings: TimerSettings
    
    // Timer calculation state. Read by SyncEngine to share a running countdown.
    private(set) var targetDate: Date?
    
    // Add a property to track which preset is currently running
    private var activePresetNumber: Int? = nil
    
    var lastUsedDuration: Int = 0
    
    weak var displayManager: DisplayManager?

    /// Called once when a running countdown reaches 00:00 (ContentViewModel uses it
    /// to send a waiting message). Not called again while it carries on into overtime.
    @ObservationIgnored var onReachedZero: (() -> Void)?
    
    init(settings: TimerSettings = TimerSettings()) {
        self.settings = settings
        setupBackgroundNotifications()
    }
    
    private func setupBackgroundNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // The app has no background modes (App Review only allows background audio for
    // sound people can hear). iOS gives a short grace period here; after that the app
    // is suspended, and the countdown, which is based on the clock, catches up on return.
    @objc private func appDidEnterBackground() {
        if settings.isRunning {
            startBackgroundTask()
        }
    }
    
    @objc private func appWillEnterForeground() {
        if settings.isRunning {
             // Force an immediate update upon returning to ensure UI is fresh
             updateTimer()
        }
        endBackgroundTask()
    }
    
    private func startBackgroundTask() {
        endBackgroundTask() // End any existing background task
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "TimerBackground") { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        endBackgroundTask()
        timer?.invalidate()
    }
    
    func startTimer() {
        // Update lastUsedDuration when starting
        if !settings.isRunning { // Only if starting from fresh or paused
             lastUsedDuration = settings.remainingSeconds
        }
        
        guard settings.remainingSeconds > 0 else { return }
        
        // Clear the display message
        displayManager?.message = ""
        
        settings.isRunning = true
        settings.timerState = .running
        
        // Calculate when the timer should end based on current time
        // We use addingTimeInterval with remainingSeconds
        targetDate = Date().addingTimeInterval(TimeInterval(settings.remainingSeconds))
        
        // Start the tick timer
        timer?.invalidate()
        // We check every 0.1s to be responsive, but UI updates only on second change usually
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        
        // Notify external display
        NotificationCenter.default.post(name: .timerStateChanged, object: nil)
    }
    
    func pauseTimer() {
        timer?.invalidate()
        timer = nil
        
        // Capture exact remaining time before clearing target
        // If we were running, update remainingSeconds one last time
        if let target = targetDate {
            let remaining = target.timeIntervalSince(Date())
            settings.remainingSeconds = max(Int(ceil(remaining)), 0)
        }
        targetDate = nil
        
        endBackgroundTask()
        
        settings.isRunning = false
        settings.timerState = .ready
        
        // Notify external display
        NotificationCenter.default.post(name: .timerStateChanged, object: nil)
    }
    
    func resetTimer() {
        pauseTimer()
        settings.remainingSeconds = settings.totalSeconds
        settings.timerState = .ready
        activePresetNumber = nil
        targetDate = nil
        
        // Notify external display
        NotificationCenter.default.post(name: .timerStateChanged, object: nil)
    }
    
    private func updateTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshRemaining()
        }
    }

    private func refreshRemaining() {
        guard let target = targetDate else { return }
        let timeLeft = target.timeIntervalSince(Date())
        // ceil to match typical timer behavior (2.1s is 3s display usually, or floor? 
        // formatTime typically floors? Wait. 2:00 -> 1:59 immediately? 
        // If I have 10s. start. target is +10. now is 0. diff is 10.
        // 0.1s later: diff is 9.9. 
        // If I floor, it's 9. 
        // If I ceil, it's 10.
        // Usually timers stay on "10" for the first second. So ceil is correct for visual "10... 9...".
        
        let ceilSeconds = Int(ceil(timeLeft))
        let reachedZero = settings.remainingSeconds > 0 && ceilSeconds <= 0

        if ceilSeconds <= 0 && settings.stopsAtZero {
            stopAtZero()
            if reachedZero { onReachedZero?() }
            return
        }

        // Note: If timeLeft is negative (overtime), ceil still works correctly (-0.1 -> 0, -1.1 -> -1)
        // Wait. ceil(-0.1) is 0. ceil(-1.1) is -1.
        // This seems fine.
        
        // Only update if the integer value changed
        if settings.remainingSeconds != ceilSeconds {
            settings.remainingSeconds = ceilSeconds
            
            // Update warning state based on user-configured threshold
            if settings.remainingSeconds <= 0 {
                settings.timerState = .overtime
            } else if settings.remainingSeconds <= settings.warningThresholdSeconds {
                settings.timerState = .warning
            }
            
            // Notify external display
            NotificationCenter.default.post(name: .timerStateChanged, object: nil)

            if reachedZero { onReachedZero?() }
        }
    }

    /// Ends a run at 00:00 when "Stop at zero" is on, instead of counting into overtime.
    private func stopAtZero() {
        timer?.invalidate()
        timer = nil
        targetDate = nil

        endBackgroundTask()

        settings.remainingSeconds = 0
        settings.isRunning = false
        settings.timerState = .overtime

        NotificationCenter.default.post(name: .timerStateChanged, object: nil)
    }

    // MARK: - Sync

    /// Adopts a timer state received from another device. `endDate` has already been
    /// converted to this device's clock. Unlike startTimer, the message is left alone;
    /// SyncEngine sets it from the same state.
    func applySyncedState(_ state: SyncState, endDate: Date?) {
        settings.warningThresholdSeconds = state.warningThresholdSeconds
        settings.pulseAnimationEnabled = state.pulseAnimationEnabled
        settings.stopsAtZero = state.stopsAtZero
        settings.totalSeconds = state.totalSeconds
        settings.presets = state.timePresets
        activePresetNumber = nil

        if let endDate {
            if !settings.isRunning {
                lastUsedDuration = settings.remainingSeconds
            }
            targetDate = endDate
            settings.isRunning = true
            settings.timerState = .running
            if timer == nil {
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.updateTimer()
                }
            }
            refreshRemaining()
            if settings.isRunning && settings.remainingSeconds > 0 && settings.remainingSeconds <= settings.warningThresholdSeconds {
                settings.timerState = .warning
            }
        } else {
            timer?.invalidate()
            timer = nil
            targetDate = nil
            endBackgroundTask()

            settings.isRunning = false
            settings.remainingSeconds = state.remainingSeconds
            if state.remainingSeconds == 0 && state.totalSeconds == 0 {
                settings.timerState = .completed
            } else if state.remainingSeconds <= 0 {
                settings.timerState = .overtime
            } else {
                settings.timerState = .ready
            }
        }

        NotificationCenter.default.post(name: .timerStateChanged, object: nil)
    }

    func setTime(minutes: Int) {
        settings.totalSeconds = minutes * 60
        resetTimer()
    }
    
    func setTime(seconds: Int) {
        pauseTimer()
        settings.totalSeconds = seconds
        settings.remainingSeconds = seconds
        
        if seconds == 0 {
            settings.timerState = .completed
        } else {
            settings.timerState = .ready
        }
    }
    
    func savePreset(number: Int) {
        guard !isPresetActive(number) else { return }
        settings.presets[number] = settings.totalSeconds
    }
    
    func loadPreset(number: Int) {
        guard !settings.isRunning else { return }
        
        if let presetSeconds = settings.presets[number] {
            setTime(seconds: presetSeconds)
            activePresetNumber = number
        }
    }
    
    func getPresetTimeString(number: Int) -> String? {
        guard let seconds = settings.presets[number] else { return nil }
        return settings.formatTime(seconds)
    }
    
    func isPresetActive(_ number: Int) -> Bool {
        return settings.isRunning && activePresetNumber == number
    }
    
    func canEditPreset(_ number: Int) -> Bool {
        return !isPresetActive(number)
    }
    
    func repeatLastTimer() {
        setTime(seconds: lastUsedDuration)
    }
    
    func addTime(seconds: Int) {
        if settings.isRunning {
             if let target = targetDate {
                 targetDate = target.addingTimeInterval(TimeInterval(seconds))
                 // Force update to reflect immediate change if needed
                 updateTimer()
             }
        } else {
            let newTime = settings.remainingSeconds + seconds
            settings.remainingSeconds = max(newTime, 0)
        }
        
        // Update total seconds to accommodate new remaining time if it's larger
        // We use the simpler check here: if remaining is now larger than total, update total.
        // We need to compute 'currentRemaining' logic correctly if running because settings.remainingSeconds
        // might not be perfectly up to date with the fractional targetDate change yet?
        // Actually, updateTimer() will handle settings.remainingSeconds shortly.
        // But for totalSeconds, let's just use the value we expect.
        
        // Wait, if running, we updated targetDate. The next updateTimer will update settings.remainingSeconds.
        // But we might want to update totalSeconds immediately.
        // Let's rely on the next tick for strict correctness of remainingSeconds, 
        // but for totalSeconds we can approximate or wait. 
        // Let's just update totalSeconds based on what it WOULD be.
        
        // Actually, safer to just:
        let likelyRemaining = settings.remainingSeconds + seconds // Approximation
        settings.totalSeconds = max(settings.totalSeconds, likelyRemaining)
    }
    
    func subtractTime(seconds: Int) {
        if settings.isRunning {
            if let target = targetDate {
                targetDate = target.addingTimeInterval(TimeInterval(-seconds))
                updateTimer()
            }
        } else {
            let newTime = settings.remainingSeconds - seconds
            settings.remainingSeconds = max(newTime, 0)
        }
        // Subtracting typically doesn't extend totalSeconds
    }

    // MARK: - Warning Threshold

    /// Step the warning threshold UP by 30 seconds (max 600s / 10 min).
    func increaseWarningThreshold() {
        settings.warningThresholdSeconds = min(settings.warningThresholdSeconds + 30, 600)
    }

    /// Step the warning threshold DOWN by 30 seconds (min 10s).
    func decreaseWarningThreshold() {
        settings.warningThresholdSeconds = max(settings.warningThresholdSeconds - 30, 10)
    }
}