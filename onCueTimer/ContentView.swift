//
//  ContentView.swift
//  onCueTimer
//
//  Created by Mahesh Patel on 1/29/25.
//

import SwiftUI

struct ContentView: View {
    @State private var timerManager = TimerManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section with timer and controls
            HStack(alignment: .top, spacing: 20) {
                // Timer display area
                TimerDisplayView(timerManager: timerManager)
                    .frame(maxWidth: .infinity)
                
                // Control buttons
                ControlPanel(timerManager: timerManager)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
