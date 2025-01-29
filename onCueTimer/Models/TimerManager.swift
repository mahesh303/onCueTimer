import Foundation

@Observable final class TimerManager {
    private var timer: Timer?
    var settings: TimerSettings
    
    // Add a property to track which preset is currently running
    private var activePresetNumber: Int? = nil
    
    init(settings: TimerSettings = TimerSettings()) {
        self.settings = settings
    }
    
    func startTimer() {
        // Don't start if we're at zero
        guard settings.remainingSeconds > 0 else { return }
        
        settings.isRunning = true
        settings.timerState = .running
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    func pauseTimer() {
        settings.isRunning = false
        settings.timerState = .ready
        timer?.invalidate()
        timer = nil
    }
    
    func resetTimer() {
        pauseTimer()
        settings.remainingSeconds = settings.totalSeconds
        settings.timerState = .ready
        activePresetNumber = nil
    }
    
    private func updateTimer() {
        settings.remainingSeconds -= 1
        
        // Update warning state based on remaining time
        if settings.remainingSeconds <= 0 {
            settings.timerState = .overtime
        } else if settings.remainingSeconds <= 10 {
            settings.timerState = .warning
        }
    }
    
    func setTime(minutes: Int) {
        settings.totalSeconds = minutes * 60
        resetTimer()
    }
    
    func setTime(seconds: Int) {
        settings.totalSeconds = seconds
        resetTimer()
        
        // If setting to zero, ensure we're stopped
        if seconds == 0 {
            settings.timerState = .completed
            pauseTimer()
        }
    }
    
    func savePreset(number: Int) {
        // Don't allow saving to the active preset while it's running
        guard !isPresetActive(number) else { return }
        settings.presets[number] = settings.totalSeconds
    }
    
    func loadPreset(number: Int) {
        // Don't load a new preset if timer is running
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
} 