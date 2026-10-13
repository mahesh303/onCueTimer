//
//  ContentView.swift
//  SpeechCueTimer
//
//  Created by Mahesh Patel on 1/29/25.
//

import SwiftUI

/// Hosts the operator screen in the chosen skin, plus everything shared between
/// skins: the floating keyboard and the Settings, Help and Sync sheets.
struct ContentView: View {
    let timerManager: TimerManager
    // Owned by SpeechCueTimerApp so every window shares one view model (and one sync connection).
    @State private var viewModel: ContentViewModel
    @State private var isKeyboardVisible = false
    @State private var showSettings = false
    @State private var showHelp = false
    @State private var showSync = false
    @AppStorage(AppSkin.storageKey) private var skin: AppSkin = .glassConsole

    init(timerManager: TimerManager, viewModel: ContentViewModel) {
        self.timerManager = timerManager
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch skin {
            case .glassConsole:
                GlassConsoleView(
                    timerManager: timerManager,
                    viewModel: viewModel,
                    isKeyboardVisible: $isKeyboardVisible,
                    onOpenHelp: { showHelp = true },
                    onOpenSettings: { showSettings = true },
                    onOpenSync: { showSync = true }
                )
            case .stageRing:
                StageRingView(
                    timerManager: timerManager,
                    viewModel: viewModel,
                    isKeyboardVisible: $isKeyboardVisible,
                    onOpenHelp: { showHelp = true },
                    onOpenSettings: { showSettings = true },
                    onOpenSync: { showSync = true }
                )
            }
        }
        .transition(.opacity)
        // Both skins are dark; keep system controls (pickers, menus, sheets) matching.
        .preferredColorScheme(.dark)
        .overlay(alignment: .bottomTrailing) {
            if isKeyboardVisible {
                // A binding, so only the keyboard and the message box redraw as you type.
                FloatingKeyboard(text: $viewModel.message, onDone: { isKeyboardVisible = false })
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
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .sheet(isPresented: $showSync) {
            SyncSettingsView(sync: viewModel.sync)
        }
        .speakerDisplayAccessory(timerManager: timerManager, displayManager: viewModel.displayManager)
    }
}

#Preview {
    let timerManager = TimerManager()
    return ContentView(timerManager: timerManager, viewModel: ContentViewModel(timerManager: timerManager))
}
