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
    @State private var fontSizeManager = FontSizeManager.shared

    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        // _viewModel wraps the @State storage directly so it is only allocated once.
        _viewModel = State(initialValue: ContentViewModel(timerManager: timerManager))
    }
    
    var body: some View {
        // @Bindable lets us create $bindings to @Observable properties
        // from a `let` stored property — required for the pulse Toggle below.
        @Bindable var settings = timerManager.settings
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
                            
                            VStack(spacing: 0) {
                                if viewModel.displayMessage.isEmpty {
                                    Spacer()
                                    
                                    TimeDisplay(
                                        seconds: timerManager.settings.remainingSeconds,
                                        timerManager: timerManager,
                                        fontSize: timerFontSize(geometry: geometry, hasMessage: false)
                                    )
                                    .accessibilityLabel("Timer")
                                    .accessibilityValue(timerManager.settings.formatTime(timerManager.settings.remainingSeconds))
                                    .accessibilityHint(viewModel.isTimerRunning ? "Timer is running" : "Timer is stopped")
                                    .padding(.horizontal, 48)
                                    
                                    Spacer()
                                } else {
                                    // Position timer higher in the card
                                    Spacer().frame(height: 12)
                                    
                                    TimeDisplay(
                                        seconds: timerManager.settings.remainingSeconds,
                                        timerManager: timerManager,
                                        fontSize: timerFontSize(geometry: geometry, hasMessage: true)
                                    )
                                    .accessibilityLabel("Timer")
                                    .accessibilityValue(timerManager.settings.formatTime(timerManager.settings.remainingSeconds))
                                    .accessibilityHint(viewModel.isTimerRunning ? "Timer is running" : "Timer is stopped")
                                    .padding(.horizontal, 48)
                                    
                                    // Spaced out generously from the message text below
                                    Spacer().frame(minHeight: 44, idealHeight: 56, maxHeight: 68)

                                    MessageDisplayCard(
                                        message: viewModel.displayMessage,
                                        fontSize: messageFontSize(geometry: geometry),
                                        cornerRadius: 10,
                                        verticalPadding: 10,
                                        horizontalPadding: 16,
                                        lineLimit: 4
                                    )
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity)
                                    .accessibilityLabel("Currently displayed message")
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .animation(.easeInOut(duration: 0.2), value: fontSizeManager.currentScale)
                            
                            // Font size control buttons (top right corner)
                            // Both buttons use matching SF Symbols and identical circular dimensions
                            VStack {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                fontSizeManager.increaseFontSize()
                                            }
                                        } label: {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: 36, height: 36)
                                                .background(fontSizeManager.canIncrease ? Color.blue : Color.gray.opacity(0.4))
                                                .clipShape(Circle())
                                                .shadow(color: .black.opacity(fontSizeManager.canIncrease ? 0.2 : 0.05), radius: 2, x: 0, y: 1)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(!fontSizeManager.canIncrease)
                                        .accessibilityLabel("Increase font size for timer and messages")
                                        .accessibilityValue("\(Int(round(fontSizeManager.currentScale * 100))) percent")
                                        
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                fontSizeManager.decreaseFontSize()
                                            }
                                        } label: {
                                            Image(systemName: "minus")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: 36, height: 36)
                                                .background(fontSizeManager.canDecrease ? Color.blue : Color.gray.opacity(0.4))
                                                .clipShape(Circle())
                                                .shadow(color: .black.opacity(fontSizeManager.canDecrease ? 0.2 : 0.05), radius: 2, x: 0, y: 1)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(!fontSizeManager.canDecrease)
                                        .accessibilityLabel("Decrease font size for timer and messages")
                                        .accessibilityValue("\(Int(round(fontSizeManager.currentScale * 100))) percent")
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
                VStack(alignment: .leading, spacing: 28) {
                    // Time Selection at the top
                    VStack(alignment: .leading) {
                        Text("select time")
                            .padding(.bottom, 8)
                            .accessibilityAddTraits(.isHeader)
                        TimePickerView(timerManager: timerManager)
                    }

                    // Warning threshold control
                    // Lets the operator choose when the timer turns yellow —
                    // e.g. "warn me when 2 minutes are left."
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text("Warn at")
                                .font(.subheadline.bold())
                            Text("(time remaining)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 12) {
                            // Decrease by 30s
                            Button {
                                timerManager.decreaseWarningThreshold()
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Decrease warning threshold by 30 seconds")
                            .disabled(timerManager.settings.warningThresholdSeconds <= 10)

                            // Current threshold displayed in mm:ss
                            Text(timerManager.settings.formatTime(timerManager.settings.warningThresholdSeconds))
                                .font(.system(.title3, design: .monospaced).bold())
                                .foregroundColor(.yellow)
                                .frame(minWidth: 70, alignment: .center)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.yellow.opacity(0.12))
                                        .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                                )
                                .accessibilityLabel("Warning threshold: \(timerManager.settings.formatTime(timerManager.settings.warningThresholdSeconds))")

                            // Increase by 30s
                            Button {
                                timerManager.increaseWarningThreshold()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Increase warning threshold by 30 seconds")
                            .disabled(timerManager.settings.warningThresholdSeconds >= 600)

                            Text("steps: 30s  •  max: 10:00")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Pulse animation toggle — grouped with the threshold stepper
                    // so both warning controls are in one place.
                    HStack(spacing: 8) {
                        Image(systemName: "waveform")
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pulse animation")
                                .font(.subheadline.bold())
                            Text("Zoom in/out during warning")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.pulseAnimationEnabled)
                            .labelsHidden()
                            .tint(.yellow)
                            .accessibilityLabel("Pulse animation when warning")
                            .accessibilityHint("When on, the timer zooms in and out to alert the speaker during the warning period")
                    }

                    // Message Area
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Message Window")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 0) {
                                    if viewModel.message.isEmpty && !isKeyboardVisible {
                                        Text("Enter message")
                                            .foregroundColor(.gray)
                                            .font(.body)
                                            .frame(maxWidth: .infinity, alignment: .topLeading)
                                    } else {
                                        Text(viewModel.message + (showCursor ? "|" : ""))
                                            .foregroundColor(.primary)
                                            .font(.body)
                                            .lineLimit(nil)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(maxWidth: .infinity, alignment: .topLeading)
                                    }
                                }
                                .padding(10)
                            }
                            .frame(height: 130)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Show our floating keyboard. The .task(id: isKeyboardVisible)
                                // modifier on the body handles cursor animation.
                                isKeyboardVisible = true
                            }
                            .accessibilityLabel("Message input")
                            .accessibilityValue(viewModel.message.isEmpty ? "No message" : viewModel.message)
                        }
                        .frame(height: 130)
                        
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
        } else if key == "Return" || key == "\n" {
            // Newline for multi-line messages
            viewModel.message += "\n"
        } else {
            // Regular character input
            viewModel.message += key
        }
    }
    
    // MARK: - Display Sizing Helpers
    
    /// Adaptive timer font size that scales with the + / - buttons
    /// and scales down gracefully when a message card is also on screen so everything
    /// fits comfortably within the Program Display container.
    private func timerFontSize(geometry: GeometryProxy, hasMessage: Bool) -> CGFloat {
        let baseSize: CGFloat = hasMessage
            ? min(geometry.size.width * 0.055, 54)
            : min(geometry.size.width * 0.075, 76)
        return baseSize * fontSizeManager.currentScale
    }

    /// Adaptive message font size that scales with + / - buttons while staying within screen limits.
    private func messageFontSize(geometry: GeometryProxy) -> CGFloat {
        let baseSize: CGFloat = 18
        return baseSize * fontSizeManager.currentScale
    }
}

#Preview {
    ContentView(timerManager: TimerManager())
}
