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
    @State private var timerManager: TimerManager
    // Created here, once per launch, rather than in ContentView: iPadOS can open
    // several windows of the app, and each window builds its own ContentView. A view
    // model per window meant a sync connection per window, which connected to each
    // other and echoed every change. All windows now share this one.
    @State private var viewModel: ContentViewModel

    init() {
        EmojiCatalog.preload()
        let timerManager = TimerManager()
        _timerManager = State(initialValue: timerManager)
        _viewModel = State(initialValue: ContentViewModel(timerManager: timerManager))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(timerManager: timerManager, viewModel: viewModel)
        }
    }
}
