//
//  ContentView.swift
//  onCueTimer
//
//  Created by Mahesh Patel on 1/29/25.
//

import SwiftUI

struct ContentView: View {
    let timerManager: TimerManager
    @State private var message = ""
    @State private var displayMessage = ""
    @State private var isTimerRunning = false
    
    // Create DisplayManager here
    private let displayManager: DisplayManager
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        self.displayManager = DisplayManager(timerManager: timerManager)
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left side: Timer Display and Controls
                HStack(spacing: 20) {
                    // Timer display area with controls
                    VStack(spacing: 10) {
                        Text("Program Display")
                            .font(.headline)
                            .padding(.top)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                            
                            VStack {
                                //Counter clock spacing
                                Spacer()
                                    .frame(height: 20)
                                
                                TimeDisplay(seconds: timerManager.settings.remainingSeconds, timerManager: timerManager)
                                
                                Spacer()
                                
                                if !displayMessage.isEmpty {
                                    Text(displayMessage)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(8)
                                }
                                
                                Spacer()
                            }
                            .padding()
                        }
                        .frame(height: geometry.size.height * 0.5)
                        
                        // Control buttons moved here
                        HStack(spacing: -190) {
                            Button("Clear") {
                                timerManager.setTime(seconds: 0)
                            }
                            .buttonStyle(.bordered)
                            .tint(.gray)
                            .frame(width: 300, height: 90)  // 50% bigger (200 * 1.5 = 300, 60 * 1.5 = 90)
                            .font(.title.bold())  // Increased font size to match larger buttons
                            
                            Button("STOP") {
                                timerManager.pauseTimer()
                                isTimerRunning = false
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .frame(width: 300, height: 90)
                            .font(.title.bold())
                            
                            Button(isTimerRunning ? "PAUSE" : "GO") {
                                if isTimerRunning {
                                    timerManager.pauseTimer()
                                } else {
                                    timerManager.startTimer()
                                }
                                isTimerRunning.toggle()
                            }
                            .buttonStyle(.bordered)
                            .tint(isTimerRunning ? .yellow : .green)
                            .frame(width: 300, height: 90)
                            .font(.title.bold())
                        }
                        .padding(.vertical, 10)
                        
                        Spacer()
                    }
                    .frame(width: geometry.size.width * 0.4)
                    
                    // Control panel (now only presets)
                    ControlPanel(timerManager: timerManager)
                }
                .padding()
                
                // Right side: Time Selection and Message
                VStack(alignment: .leading, spacing: 40) {
                    // Time Selection at the top
                    VStack(alignment: .leading) {
                        Text("select time")
                            .padding(.bottom, 5)
                        TimePickerView(timerManager: timerManager)
                    }
                    
                    // Message Area moved up, right below time selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Message Window")
                            .font(.headline)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                            
                            TextEditor(text: $message)
                                .padding()
                                .frame(height: 120)  // Slightly smaller height
                        }
                        .frame(height: 120)  // Fixed container height
                        
                        // Message Controls
                        HStack {
                            Spacer()
                            Button("Clear Message") {
                                message = ""
                                displayMessage = ""
                                displayManager.message = ""  // Clear external display message
                            }
                            .buttonStyle(.bordered)
                            .tint(.yellow)
                            
                            Button("Send Message") {
                                displayMessage = message
                                displayManager.message = message  // Sync with external display
                                // Dismiss keyboard after sending
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                             to: nil, 
                                                             from: nil, 
                                                             for: nil)
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                        }
                    }
                    
                    Spacer() // Push everything up
                }
                .frame(width: geometry.size.width * 0.4)
                .padding()
                .ignoresSafeArea(.keyboard)
            }
        }
    }
}

#Preview {
    ContentView(timerManager: TimerManager())
}
