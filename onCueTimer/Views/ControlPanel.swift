import SwiftUI

struct ControlPanel: View {
    let timerManager: TimerManager
    @State private var isEditingPreset = false
    @State private var selectedPresetNumber = 1
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            // Add some top padding to align with the "Program Display" text
            Spacer().frame(height: 44)
            
            
            
            // Presets
            ForEach(1...4, id: \.self) { number in
                HStack(spacing: 4) {
                    Text("Preset \(number)")
                        .frame(width: 45, alignment: .trailing)
                        .font(.system(size: 10))
                    
                    Button {
                        // Single tap to load preset
                        if !timerManager.settings.isRunning {
                            timerManager.loadPreset(number: number)
                        }
                    } label: {
                        Text(timerManager.getPresetTimeString(number: number) ?? "00:00")
                            .frame(width: 50)
                            .contentShape(Rectangle())
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.bordered)
                    .tint(.yellow)
                    .disabled(timerManager.isPresetActive(number))
                    .opacity(timerManager.isPresetActive(number) ? 0.6 : 1.0)
                    // Add double tap gesture
                    .onTapGesture(count: 2) {
                        if !timerManager.isPresetActive(number) {
                            timerManager.savePreset(number: number)
                        }
                    }
                }
            }
            
            Spacer().frame(height: 20)
            
            // Clear button
            Button("Clear") {
                timerManager.setTime(seconds: 0)
            }
            .buttonStyle(.bordered)
            .tint(.gray)
            .frame(width: 100)
            
            Spacer().frame(height: 10)
            
            // Control buttons
            Button("STOP") {
                timerManager.pauseTimer()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .frame(width: 100)
            
            Button("GO") {
                timerManager.startTimer()
            }
            .buttonStyle(.bordered)
            .tint(.green)
            .frame(width: 100)
            
            // Fill remaining space
            Spacer()
        }
        .frame(width: 120)
    }
} 
