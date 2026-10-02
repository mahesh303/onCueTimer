import Foundation
import SwiftUI
import UIKit

@Observable final class TimerManager {
    private var timer: Timer?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // Core state
    var settings: TimerSettings
    
    // Timer calculation state
    private var targetDate: Date?
    
    // Add a property to track which preset is currently running
    private var activePresetNumber: Int? = nil
    
    var lastUsedDuration: Int = 0
    
    weak var displayManager: DisplayManager?
    
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
    
    @objc private func appDidEnterBackground() {
        if settings.isRunning {
            startBackgroundTask()
            BackgroundAudioManager.shared.startSilentAudio()
        }
    }
    
    @objc private func appWillEnterForeground() {
        if settings.isRunning {
             // Force an immediate update upon returning to ensure UI is fresh
             updateTimer()
        }
        BackgroundAudioManager.shared.stopSilentAudio()
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
        
        BackgroundAudioManager.shared.stopSilentAudio()
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
            guard let self = self, let target = self.targetDate else { return }
            
            let timeLeft = target.timeIntervalSince(Date())
            // ceil to match typical timer behavior (2.1s is 3s display usually, or floor? 
            // formatTime typically floors? Wait. 2:00 -> 1:59 immediately? 
            // If I have 10s. start. target is +10. now is 0. diff is 10.
            // 0.1s later: diff is 9.9. 
            // If I floor, it's 9. 
            // If I ceil, it's 10.
            // Usually timers stay on "10" for the first second. So ceil is correct for visual "10... 9...".
            
            let ceilSeconds = Int(ceil(timeLeft))
            
            // Note: If timeLeft is negative (overtime), ceil still works correctly (-0.1 -> 0, -1.1 -> -1)
            // Wait. ceil(-0.1) is 0. ceil(-1.1) is -1.
            // This seems fine.
            
            // Only update if the integer value changed
            if self.settings.remainingSeconds != ceilSeconds {
                self.settings.remainingSeconds = ceilSeconds
                
                // Update warning state
                if self.settings.remainingSeconds <= 0 {
                    self.settings.timerState = .overtime
                } else if self.settings.remainingSeconds <= 10 {
                    self.settings.timerState = .warning
                }
                
                // Notify external display
                NotificationCenter.default.post(name: .timerStateChanged, object: nil)
            }
        }
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
}