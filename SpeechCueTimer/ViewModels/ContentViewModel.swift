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
        loadPresets()
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
        savePresets()
        feedbackGenerator.impactOccurred(intensity: 1.0)
    }
    
    // MARK: - Persistence
    
    private func loadPresets() {
        if let savedPresets = UserDefaults.standard.stringArray(forKey: "messagePresets") {
            // Convert [String] to [String?]
            presets = savedPresets.map { $0.isEmpty ? nil : $0 }
        } else {
            presets = Array(repeating: nil, count: 4)
        }
    }
    
    private func savePresets() {
        // Convert [String?] to [String] for UserDefaults
        let presetsToSave = presets.map { $0 ?? "" }
        UserDefaults.standard.set(presetsToSave, forKey: "messagePresets")
    }
} 