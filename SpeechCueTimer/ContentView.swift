//
//  ContentView.swift
//  SpeechCueTimer
//
//  Created by Mahesh Patel on 1/29/25.
//

import SwiftUI

struct ContentView: View {
    let timerManager: TimerManager
    // @State ensures ContentViewModel is created once and SwiftUI tracks its @Observable changes.
    // Previously stored as `let`, which prevented SwiftUI's observation system from subscribing.
    @State private var viewModel: ContentViewModel
    @State private var isKeyboardVisible = false
    @State private var showCursor = false

    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        // _viewModel wraps the @State storage directly so it is only allocated once.
        _viewModel = State(initialValue: ContentViewModel(timerManager: timerManager))
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
                            
                            // Font size control buttons (top right corner)
                            VStack {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Button("+") {
                                            FontSizeManager.shared.increaseFontSize()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.blue)
                                        .frame(width: 40, height: 40)
                                        .font(.title2.bold())
                                        .accessibilityLabel("Increase external display font size for timer and messages")
                                        
                                        Button("-") {
                                            FontSizeManager.shared.decreaseFontSize()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.blue)
                                        .frame(width: 40, height: 40)
                                        .font(.title2.bold())
                                        .accessibilityLabel("Decrease external display font size for timer and messages")
                                    }
                                    .padding(.trailing, 16)
                                    .padding(.top, 16)
                                }
                                Spacer()
                            }
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
                            
                            Button("Zap") {
                                viewModel.zapMessage()
                            }
                            .buttonStyle(.bordered)
                            .tint(.purple)
                            .frame(width: geometry.size.width * 0.08, height: 50)
                            .font(.title3.bold())
                            .accessibilityHint("Make the message shake on external display")
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
                            
                            ZStack(alignment: .topLeading) {
                                // Background text area
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.clear)
                                    .frame(height: 120)
                                
                                // Display text with cursor
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack(alignment: .top, spacing: 0) {
                                            if viewModel.message.isEmpty && !isKeyboardVisible {
                                                Text("Enter message")
                                                    .foregroundColor(.gray)
                                            } else {
                                                Text(viewModel.message + (showCursor ? "|" : ""))
                                                    .foregroundColor(.primary)
                                            }
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(8)
                            }
                            .onTapGesture {
                                // Show our floating keyboard. The .task(id: isKeyboardVisible)
                                // modifier on the body handles cursor animation.
                                isKeyboardVisible = true
                            }
                            .accessibilityLabel("Message input")
                            .accessibilityValue(viewModel.message.isEmpty ? "No message" : viewModel.message)
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
        .overlay(alignment: .bottomTrailing) {
            if isKeyboardVisible {
                FloatingKeyboard(
                    onKeyTap: { key in
                        handleKeyTap(key)
                    },
                    onDone: {
                        isKeyboardVisible = false
                        showCursor = false
                    }
                )
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: isKeyboardVisible)
            }
        }
        .onTapGesture {
            // Dismiss floating keyboard when tapping outside
            if isKeyboardVisible {
                isKeyboardVisible = false
                showCursor = false
            }
        }
        // .task(id:) is re-launched whenever isKeyboardVisible changes and
        // automatically cancelled when the view disappears OR when id changes.
        // This replaces the old Timer.scheduledTimer which leaked a new timer
        // on every tap (multiple overlapping timers could stack up).
        .task(id: isKeyboardVisible) {
            guard isKeyboardVisible else {
                showCursor = false
                return
            }
            showCursor = true
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                if !Task.isCancelled {
                    showCursor.toggle()
                }
            }
        }
    }
    
    private func handleKeyTap(_ key: String) {
        if key.hasPrefix("SUGGESTION:") {
            // Handle word suggestion - replace current partial word
            let suggestion = String(key.dropFirst("SUGGESTION:".count))
            
            // Find the last word to replace
            let words = viewModel.message.components(separatedBy: " ")
            if words.count > 1 {
                let allButLast = words.dropLast().joined(separator: " ")
                viewModel.message = allButLast + " " + suggestion + " "
            } else {
                viewModel.message = suggestion + " "
            }
        } else if key == "⌫" {
            // Backspace
            if !viewModel.message.isEmpty {
                viewModel.message.removeLast()
            }
        } else {
            // Regular character input
            viewModel.message += key
        }
    }
    
}

#Preview {
    ContentView(timerManager: TimerManager())
}
