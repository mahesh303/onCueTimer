//
//  SpeechCueTimerApp.swift
//  SpeechCueTimer
//
//  Created by Mahesh Patel on 1/29/25.
//

import SwiftUI

@main
struct SpeechCueTimerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(timerManager: TimerManager())
        }
    }
}
