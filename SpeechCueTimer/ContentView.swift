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
    @State private var isKeyboardVisible = false
    @State private var showCursor = false
    
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
                                        .accessibilityLabel("Increase external display font size")
                                        
                                        Button("-") {
                                            FontSizeManager.shared.decreaseFontSize()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.blue)
                                        .frame(width: 40, height: 40)
                                        .font(.title2.bold())
                                        .accessibilityLabel("Decrease external display font size")
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
                                // Show our floating keyboard and start cursor animation
                                isKeyboardVisible = true
                                startCursorAnimation()
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
    
    private func startCursorAnimation() {
        showCursor = true
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if isKeyboardVisible {
                showCursor.toggle()
            } else {
                showCursor = false
                timer.invalidate()
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

struct FloatingKeyboard: View {
    let onKeyTap: (String) -> Void
    let onDone: () -> Void
    
    @State private var isUppercase = true
    @State private var currentWord = ""
    @State private var suggestions: [String] = []
    
    // Common word dictionary for suggestions
    private let commonWords = [
        "the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "its", "may", "new", "now", "old", "see", "two", "who", "boy", "did", "man", "way", "what", "when", "where", "will", "with", "work", "your", "about", "after", "again", "back", "been", "before", "being", "both", "came", "come", "could", "each", "first", "from", "give", "good", "great", "hand", "here", "into", "just", "know", "last", "left", "life", "like", "live", "look", "made", "make", "many", "most", "move", "much", "must", "name", "need", "next", "only", "over", "part", "play", "place", "right", "said", "same", "seem", "show", "small", "such", "take", "than", "that", "their", "them", "there", "these", "they", "thing", "think", "this", "those", "through", "time", "today", "together", "under", "until", "very", "want", "water", "well", "went", "were", "where", "which", "while", "world", "would", "write", "year", "years", "young"
    ]
    
    private let uppercaseKeys = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["⇧", "Z", "X", "C", "V", "B", "N", "M", "⌫"],
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["Space", "Done"]
    ]
    
    private let lowercaseKeys = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["⇧", "z", "x", "c", "v", "b", "n", "m", "⌫"],
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["Space", "Done"]
    ]
    
    private var currentKeys: [[String]] {
        return isUppercase ? uppercaseKeys : lowercaseKeys
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Word suggestions row
            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions.prefix(3), id: \.self) { suggestion in
                            Button(action: {
                                // Remove the current partial word and replace with suggestion
                                if !currentWord.isEmpty {
                                    // Send backspaces to remove current word
                                    for _ in 0..<currentWord.count {
                                        onKeyTap("⌫")
                                    }
                                }
                                // Send the suggestion
                                onKeyTap("SUGGESTION:\(suggestion)")
                                currentWord = ""
                                suggestions = []
                            }) {
                                Text(suggestion)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.1))
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(height: 32)
            }
            
            // Main keyboard
            VStack(spacing: 10) { // Increased spacing for 40%
                ForEach(0..<currentKeys.count, id: \.self) { rowIndex in
                    HStack(spacing: 7) { // Increased spacing for 40%
                        ForEach(currentKeys[rowIndex], id: \.self) { key in
                            Button(action: {
                                if key == "Done" {
                                    onDone()
                                } else if key == "⇧" {
                                    isUppercase.toggle()
                                } else {
                                    handleKeyInput(key)
                                }
                            }) {
                                Text(key == "Space" ? "⎵" : key)
                                    .font(.system(size: 17, weight: .medium)) // 40% larger: 12→17
                                    .foregroundColor(.primary)
                                    .frame(
                                        width: key == "Space" ? 84 : (key == "Done" ? 63 : 35), // 40% larger: 60→84, 45→63, 25→35
                                        height: 35 // 40% larger: 25→35
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 6) // Larger corner radius
                                            .fill(
                                                key == "Done" ? Color.blue.opacity(0.2) :
                                                key == "⇧" ? (isUppercase ? Color.green.opacity(0.3) : Color.gray.opacity(0.3)) :
                                                Color.gray.opacity(0.3)
                                            )
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(14) // Increased padding for 40%
        .background(
            RoundedRectangle(cornerRadius: 16) // Larger corner radius
                .fill(.regularMaterial)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6) // Larger shadow
        .frame(maxWidth: 392) // 40% larger: 280→392
    }
    
    private func handleKeyInput(_ key: String) {
        if key == "⌫" {
            // Handle backspace
            if !currentWord.isEmpty {
                currentWord.removeLast()
                updateSuggestions()
            } else {
                onKeyTap(key)
            }
        } else if key == "Space" {
            // Add space and auto-capitalize next letter
            onKeyTap(" ")
            currentWord = ""
            suggestions = []
            isUppercase = true // Auto-capitalize after space
        } else if key.rangeOfCharacter(from: CharacterSet.letters) != nil {
            // Letter key - add to current word and send immediately
            let letterToAdd = shouldCapitalize() ? key.uppercased() : key.lowercased()
            currentWord += letterToAdd
            onKeyTap(letterToAdd)
            updateSuggestions()
            
            // After first letter, switch to lowercase unless shift is pressed
            if currentWord.count == 1 {
                isUppercase = false
            }
        } else {
            // Numbers, punctuation, etc.
            onKeyTap(key)
            currentWord = ""
            suggestions = []
            
            // Auto-capitalize after period
            if key == "." {
                isUppercase = true
            }
        }
    }
    
    private func updateSuggestions() {
        if currentWord.isEmpty {
            suggestions = []
        } else {
            suggestions = commonWords
                .filter { $0.lowercased().hasPrefix(currentWord.lowercased()) }
                .filter { $0.lowercased() != currentWord.lowercased() }
                .sorted { $0.count < $1.count }
        }
    }
    
    private func shouldCapitalize() -> Bool {
        return isUppercase || currentWord.isEmpty
    }
    

}
