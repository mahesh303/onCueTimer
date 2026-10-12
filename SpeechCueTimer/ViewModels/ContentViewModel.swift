import SwiftUI

@Observable final class ContentViewModel {
    private let timerManager: TimerManager
    let displayManager: DisplayManager
    let sync: SyncManager
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var message: String = ""
    /// What the speaker display shows. Lives on DisplayManager so a message sent
    /// from another synced iPad shows up here too.
    var displayMessage: String {
        get { displayManager.message }
        set { displayManager.message = newValue }
    }
    var isTimerRunning: Bool = false
    var presets: [String?] = Array(repeating: nil, count: 4)

    var isExternalDisplayConnected: Bool {
        displayManager.isExternalDisplayConnected
    }

    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        self.displayManager = DisplayManager(timerManager: timerManager)
        self.timerManager.displayManager = displayManager
        self.sync = SyncManager(engine: SyncEngine(timerManager: timerManager, displayManager: displayManager))

        feedbackGenerator.prepare()
        // Message presets are session-only (not persisted across launches).
        presets = Array(repeating: nil, count: 4)
        presets[0] = "Times up!" // Default message for preset 1
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
    }
    
    func sendMessage() {
        displayMessage = message
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                     to: nil, 
                                     from: nil, 
                                     for: nil)
    }

    /// Takes the message off the speaker display but keeps the draft being typed.
    func hideMessage() {
        displayMessage = ""
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

    /// Sends a saved message straight to the display without touching the draft.
    func sendPreset(at index: Int) {
        guard index >= 0 && index < presets.count else { return }
        guard let preset = presets[index] else { return }

        displayMessage = preset
        feedbackGenerator.impactOccurred(intensity: 0.5)
    }
    
}