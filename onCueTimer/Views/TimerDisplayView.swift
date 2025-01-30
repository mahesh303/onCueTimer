import SwiftUI

struct TimerDisplayView: View {
    let timerManager: TimerManager
    @State private var message: String = ""
    @State private var displayMessage: String = ""
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    Text("Program Display")
                        .font(.headline)
                    
                    // Timer Display
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                        
                        VStack {
                            Spacer()
                                .frame(height: 20)
                            
                            TimeDisplay(seconds: timerManager.settings.remainingSeconds, timerManager: timerManager)
                                .frame(maxWidth: .infinity)
                            
                            Spacer()
                            
                            if !displayMessage.isEmpty {
                                Text(displayMessage)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                    .frame(height: min(400, geometry.size.height * 0.4))
                    
                    // Time Selection
                    HStack {
                        Text("select time")
                        Spacer()
                    }
                    
                    TimePickerView(timerManager: timerManager)
                        .frame(maxWidth: geometry.size.width * 0.8)
                    
                    // Message Input Area
                    Text("Message Window")
                        .font(.headline)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: min(250, geometry.size.height * 0.3))
                        
                        TextEditor(text: $message)
                            .frame(height: min(200, geometry.size.height * 0.25))
                            .padding()
                    }
                    
                    // Message Controls
                    HStack {
                        Spacer()
                        Button("Clear Message") {
                            message = ""
                            displayMessage = ""
                        }
                        .buttonStyle(.bordered)
                        .tint(.yellow)
                        
                        Button("Send Message") {
                            displayMessage = message
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }
                }
                .padding()
            }
        }
    }
}

struct TimeDisplay: View {
    let seconds: Int
    let timerManager: TimerManager
    
    var body: some View {
        Text(timeString)
            .font(.system(size: 80, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .foregroundColor(timerManager.settings.getTimeColor())
    }
    
    private var timeString: String {
        let isNegative = seconds < 0
        let absSeconds = abs(seconds)
        let hours = absSeconds / 3600
        let minutes = (absSeconds % 3600) / 60
        let remainingSeconds = absSeconds % 60
        
        let timeStr = if hours > 0 {
            String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            String(format: "%02d:%02d", minutes, remainingSeconds)
        }
        
        return isNegative ? "-\(timeStr)" : timeStr
    }
}

struct TimePickerView: View {
    let timerManager: TimerManager
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    @State private var selectedSeconds = 0
    
    var body: some View {
        HStack {
            Picker("Hours", selection: $selectedHours) {
                ForEach(0...23, id: \.self) { hour in
                    Text("\(hour)").tag(hour)
                }
            }
            .frame(maxWidth: 100)
            .disabled(timerManager.settings.isRunning)  // Disable when timer is running
            Text("hour")
            
            Picker("Minutes", selection: $selectedMinutes) {
                ForEach(0...59, id: \.self) { minute in
                    Text("\(minute)").tag(minute)
                }
            }
            .frame(maxWidth: 100)
            .disabled(timerManager.settings.isRunning)  // Disable when timer is running
            Text("min")
            
            Picker("Seconds", selection: $selectedSeconds) {
                ForEach(0...59, id: \.self) { second in
                    Text("\(second)").tag(second)
                }
            }
            .frame(maxWidth: 100)
            .disabled(timerManager.settings.isRunning)  // Disable when timer is running
            Text("sec")
        }
        .onChange(of: selectedHours) { updateTimer() }
        .onChange(of: selectedMinutes) { updateTimer() }
        .onChange(of: selectedSeconds) { updateTimer() }
        .opacity(timerManager.settings.isRunning ? 0.6 : 1.0)  // Visual feedback when disabled
    }
    
    private func updateTimer() {
        // Only update if timer is not running
        guard !timerManager.settings.isRunning else { return }
        
        let totalSeconds = (selectedHours * 3600) + (selectedMinutes * 60) + selectedSeconds
        timerManager.setTime(seconds: totalSeconds)
    }
} 
