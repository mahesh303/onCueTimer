import SwiftUI

struct TimerSettingsView: View {
    let timerManager: TimerManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMinutes: Int
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        _selectedMinutes = State(initialValue: timerManager.settings.totalSeconds / 60)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Timer Duration") {
                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach(1...60, id: \.self) { minute in
                            Text("\(minute) minutes")
                        }
                    }
                }
            }
            .navigationTitle("Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        timerManager.setTime(minutes: selectedMinutes)
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
} 