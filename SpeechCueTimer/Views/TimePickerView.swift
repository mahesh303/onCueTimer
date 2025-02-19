import SwiftUI

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
            .disabled(timerManager.settings.isRunning)
            Text("hour")
            
            Picker("Minutes", selection: $selectedMinutes) {
                ForEach(0...59, id: \.self) { minute in
                    Text("\(minute)").tag(minute)
                }
            }
            .frame(maxWidth: 100)
            .disabled(timerManager.settings.isRunning)
            Text("min")
            
            Picker("Seconds", selection: $selectedSeconds) {
                ForEach(0...59, id: \.self) { second in
                    Text("\(second)").tag(second)
                }
            }
            .frame(maxWidth: 100)
            .disabled(timerManager.settings.isRunning)
            Text("sec")
        }
        .onChange(of: selectedHours) { updateTimer() }
        .onChange(of: selectedMinutes) { updateTimer() }
        .onChange(of: selectedSeconds) { updateTimer() }
        .opacity(timerManager.settings.isRunning ? 0.6 : 1.0)
    }
    
    private func updateTimer() {
        // Only update if timer is not running
        guard !timerManager.settings.isRunning else { return }
        
        let totalSeconds = (selectedHours * 3600) + (selectedMinutes * 60) + selectedSeconds
        timerManager.setTime(seconds: totalSeconds)
    }
} 