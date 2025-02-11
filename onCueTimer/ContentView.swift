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
    @State private var presets: [String?] = Array(repeating: nil, count: 4)
    
    // Create DisplayManager here
    private let displayManager: DisplayManager
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        self.displayManager = DisplayManager(timerManager: timerManager)
        self.timerManager.displayManager = displayManager
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
                                    displayMessage = ""
                                }
                                isTimerRunning.toggle()
                            }
                            .buttonStyle(.bordered)
                            .tint(isTimerRunning ? .yellow : .green)
                            .frame(width: 300, height: 90)
                            .font(.title.bold())
                            
                            Button("Repeat") {
                                timerManager.repeatLastTimer()
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                            .frame(width: 300, height: 90)
                            .font(.title.bold())
                        }
                        .padding(.vertical, 10)
                        
                        Spacer()
                    }
                    .frame(width: geometry.size.width * 0.44)
                    
                    // Control panel (now only presets)
                    ControlPanel(timerManager: timerManager)
                    
                }
                .padding(.bottom, 280)
                
                // Right side: Time Selection and Message
                VStack(alignment: .leading, spacing: 40) {
                    // Time Selection at the top
                    VStack(alignment: .leading) {
                        Text("select time")
                            .padding(.bottom, 8)
                        TimePickerView(timerManager: timerManager)
                    }
                    
                    // Message Area
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Message Window")
                            .font(.headline)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                            
                            TextEditor(text: $message)
                                .padding()
                                .frame(height: 120)
                        }
                        .frame(height: 120)
                        
                        // Preset buttons
                        HStack {
                            ForEach(0..<4, id: \.self) { index in
                                Button(action: {
                                    if let preset = presets[index] {
                                        message = preset
                                    }
                                }) {
                                    VStack {
                                        Text("Preset \(index + 1)")
                                            .font(.caption)
                                        
                                        Image(systemName: "square.and.pencil")
                                            .font(.system(size: 20))
                                    }
                                    .padding(8)
                                    .background(presets[index] != nil ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(presets[index] != nil ? Color.green : Color.blue, lineWidth: 1)
                                    )
                                    .onTapGesture(count: 2) {
                                        presets[index] = message
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Message Controls
                        HStack {
                            Spacer()
                            Button("Clear Message") {
                                message = ""
                                displayMessage = ""
                                displayManager.message = ""
                            }
                            .buttonStyle(.bordered)
                            .tint(.yellow)
                            
                            Button("Send Message") {
                                displayMessage = message
                                displayManager.message = message
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                             to: nil, 
                                                             from: nil, 
                                                             for: nil)
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                        }
                    }
                    
                    Spacer()
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
