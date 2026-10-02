//
//  PresetButton.swift
//  SpeechCueTimer
//
//  Extracted from ContentView.swift (phase 4 refactor).
//

import SwiftUI

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
