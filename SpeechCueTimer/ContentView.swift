//
//  ContentView.swift
//  SpeechCueTimer
//
//  Created by Mahesh Patel on 1/29/25.
//

import SwiftUI

struct ContentView: View {
    let timerManager: TimerManager
    let viewModel: ContentViewModel
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        self.viewModel = ContentViewModel(timerManager: timerManager)
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
                            .accessibilityAddTraits(.isHeader)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                            
                            VStack {
                                Spacer()
                                    .frame(height: 20)
                                
                                TimeDisplay(seconds: timerManager.settings.remainingSeconds, timerManager: timerManager)
                                    .accessibilityLabel("Timer")
                                    .accessibilityValue(timerManager.settings.formatTime(timerManager.settings.remainingSeconds))
                                    .accessibilityHint(viewModel.isTimerRunning ? "Timer is running" : "Timer is stopped")
                                
                                Spacer()
                                
                                if !viewModel.displayMessage.isEmpty {
                                    Text(viewModel.displayMessage)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(8)
                                        .accessibilityLabel("Display message")
                                }
                                
                                Spacer()
                            }
                            .padding()
                        }
                        .frame(height: geometry.size.height * 0.5)
                        
                        // Control buttons
                        HStack(spacing: 16) {
                            Button("Clear") {
                                viewModel.clearTimer()
                            }
                            .buttonStyle(.bordered)
                            .tint(.gray)
                            .frame(width: geometry.size.width * 0.08, height: 50)
                            .font(.title3.bold())
                            .accessibilityHint("Clear the timer")
                            
                            Button("STOP") {
                                viewModel.pauseTimer()
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .frame(width: geometry.size.width * 0.08, height: 50)
                            .font(.title3.bold())
                            .accessibilityHint("Stop the timer")
                            
                            Button(viewModel.isTimerRunning ? "Pause" : "GO") {
                                if viewModel.isTimerRunning {
                                    viewModel.pauseTimer()
                                } else {
                                    viewModel.startTimer()
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(viewModel.isTimerRunning ? .yellow : .green)
                            .frame(width: geometry.size.width * 0.08, height: 50)
                            .font(.title3.bold())
                            .accessibilityHint(viewModel.isTimerRunning ? "Pause the timer" : "Start the timer")
                            
                            Button("Repeat") {
                                viewModel.repeatLastTimer()
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                            .frame(width: geometry.size.width * 0.08, height: 50)
                            .font(.title3.bold())
                            .accessibilityHint("Repeat the last timer duration")
                        }
                        .padding(.vertical, 16)
                        
                        Spacer()
                    }
                    .frame(width: geometry.size.width * 0.44)
                    
                    // Control panel
                    ControlPanel(timerManager: timerManager)
                }
                .padding(.bottom, 280)
                
                // Right side: Time Selection and Message
                VStack(alignment: .leading, spacing: 40) {
                    // Time Selection at the top
                    VStack(alignment: .leading) {
                        Text("select time")
                            .padding(.bottom, 8)
                            .accessibilityAddTraits(.isHeader)
                        TimePickerView(timerManager: timerManager)
                    }
                    
                    // Message Area
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Message Window")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                            
                            TextField("Enter message", text: .init(
                                get: { viewModel.message },
                                set: { viewModel.message = $0 }
                            ))
                            .padding()
                            .frame(height: 120)
                            .accessibilityLabel("Message input")
                        }
                        .frame(height: 120)
                        
                        // Preset buttons
                        HStack {
                            ForEach(0..<4, id: \.self) { index in
                                PresetButton(
                                    index: index,
                                    hasPreset: viewModel.presets[index] != nil,
                                    onSingleTap: {
                                        viewModel.loadPreset(at: index)
                                    },
                                    onDoubleTap: {
                                        viewModel.savePreset(at: index)
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Message Controls
                        HStack {
                            Spacer()
                            Button("Clear Message") {
                                viewModel.clearMessage()
                            }
                            .buttonStyle(.bordered)
                            .tint(.yellow)
                            .accessibilityHint("Clear the current message")
                            
                            Button("Send Message") {
                                viewModel.sendMessage()
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                            .accessibilityHint("Send the current message to display")
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

struct PresetButton: View {
    let index: Int
    let hasPreset: Bool
    let onSingleTap: () -> Void
    let onDoubleTap: () -> Void
    
    @State private var timeoutTask: Task<Void, Never>?
    
    var body: some View {
        VStack {
            Text("Preset \(index + 1)")
                .font(.caption)
            
            Image(systemName: "square.and.pencil")
                .font(.system(size: 20))
        }
        .padding(8)
        .background(hasPreset ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(hasPreset ? Color.green : Color.blue, lineWidth: 1)
        )
        .onTapGesture(count: 2) {
            timeoutTask?.cancel()
            onDoubleTap()
        }
        .onTapGesture(count: 1) {
            timeoutTask?.cancel()
            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
                if !Task.isCancelled {
                    await MainActor.run {
                        onSingleTap()
                    }
                }
            }
        }
        .accessibilityLabel("Message preset \(index + 1)")
        .accessibilityHint("Double tap to save current message, single tap to load saved message")
    }
}
