//
//  SpeechCueTimerApp.swift
//  SpeechCueTimer
//
//  Created by Mahesh Patel on 1/29/25.
//

import SwiftUI

@main
struct SpeechCueTimerApp: App {
    // @State ensures TimerManager is created once and survives WindowGroup re-evaluations.
    // Previously it was created inline in body, which risked resetting all timer state
    // on any scene refresh.
    @State private var timerManager = TimerManager()

    var body: some Scene {
        WindowGroup {
            ContentView(timerManager: timerManager)
        }
    }
}
