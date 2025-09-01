import SwiftUI

@Observable final class ContentViewModel {
    private let timerManager: TimerManager
    private let displayManager: DisplayManager
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var message: String = ""
    var displayMessage: String = ""
    var isTimerRunning: Bool = false
    var presets: [String?] = Array(repeating: nil, count: 4)
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        self.displayManager = DisplayManager(timerManager: timerManager)
        self.timerManager.displayManager = displayManager

        feedbackGenerator.prepare()
        // Initialize presets as blank - no loading from UserDefaults
        presets = Array(repeating: nil, count: 4)
        // Clear any existing preset data from UserDefaults to ensure clean state
        clearOldPresetData()
    }
    
    // MARK: - Timer Controls
    
    func startTimer() {
        timerManager.startTimer()
        displayMessage = ""
        isTimerRunning = true
    }
    
    func pauseTimer() {
        timerManager.pauseTimer()
        isTimerRunning = false
    }
    
    func clearTimer() {
        timerManager.setTime(seconds: 0)
    }
    
    func repeatLastTimer() {
        timerManager.repeatLastTimer()
    }
    
    func zapMessage() {
        // Only zap if there's a message displayed
        guard !displayMessage.isEmpty else { return }
        
        NotificationCenter.default.post(name: .messageZap, object: nil)
        feedbackGenerator.impactOccurred(intensity: 1.0)
    }
    

    
    // MARK: - Message Handling
    
    func clearMessage() {
        message = ""
        displayMessage = ""
        displayManager.message = ""
    }
    
    func sendMessage() {
        displayMessage = message
        displayManager.message = message
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                     to: nil, 
                                     from: nil, 
                                     for: nil)
    }
    
    // MARK: - Preset Management
    
    func loadPreset(at index: Int) {
        guard index >= 0 && index < presets.count else { return }
        if let preset = presets[index] {
            message = preset
            feedbackGenerator.impactOccurred(intensity: 0.5)
        }
    }
    
    func savePreset(at index: Int) {
        guard index >= 0 && index < presets.count else { return }
        guard !message.isEmpty else { return }
        
        presets[index] = message
        // No longer saving to UserDefaults - presets are session-only
        feedbackGenerator.impactOccurred(intensity: 1.0)
    }
    
    // MARK: - UserDefaults Cleanup
    
    private func clearOldPresetData() {
        // Remove any existing preset data from UserDefaults to ensure clean state
        UserDefaults.standard.removeObject(forKey: "messagePresets")
    }
} 