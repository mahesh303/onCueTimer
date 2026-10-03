//
//  ContentView.swift
//  SpeechCueTimer
//
//  Created by Mahesh Patel on 1/29/25.
//

import SwiftUI

/// Hosts the operator screen in the chosen skin, plus everything shared between
/// skins: the floating keyboard, the blinking cursor, and the Settings and Help sheets.
struct ContentView: View {
    let timerManager: TimerManager
    // @State ensures ContentViewModel is created once and SwiftUI tracks its @Observable changes.
    // Previously stored as `let`, which prevented SwiftUI's observation system from subscribing.
    @State private var viewModel: ContentViewModel
    @State private var isKeyboardVisible = false
    @State private var showCursor = false
    @State private var showSettings = false
    @State private var showHelp = false
    @AppStorage(AppSkin.storageKey) private var skin: AppSkin = .glassConsole

    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        // _viewModel wraps the @State storage directly so it is only allocated once.
        _viewModel = State(initialValue: ContentViewModel(timerManager: timerManager))
    }

    var body: some View {
        Group {
            switch skin {
            case .glassConsole:
                GlassConsoleView(
                    timerManager: timerManager,
                    viewModel: viewModel,
                    showCursor: showCursor,
                    isKeyboardVisible: $isKeyboardVisible,
                    onOpenHelp: { showHelp = true },
                    onOpenSettings: { showSettings = true }
                )
            case .stageRing:
                StageRingView(
                    timerManager: timerManager,
                    viewModel: viewModel,
                    showCursor: showCursor,
                    isKeyboardVisible: $isKeyboardVisible,
                    onOpenHelp: { showHelp = true },
                    onOpenSettings: { showSettings = true }
                )
            }
        }
        .transition(.opacity)
        // Both skins are dark; keep system controls (pickers, menus, sheets) matching.
        .preferredColorScheme(.dark)
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
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .speakerDisplayAccessory(timerManager: timerManager, displayManager: viewModel.displayManager)
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
}

#Preview {
    ContentView(timerManager: TimerManager())
}
