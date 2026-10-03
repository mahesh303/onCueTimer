//
//  MessageDisplayCard.swift
//  SpeechCueTimer
//
//  A shared message card that shows the currently-displayed message with the
//  shake/zap animation. Used in both ExternalDisplayView (speaker screen) and
//  ContentView's operator preview so the operator always sees exactly what
//  the speaker sees — colours, styling, animation and all.
//

import SwiftUI

/// Displays a message string inside a styled card.
/// When a `.messageZap` notification fires the card plays the same shake
/// keyframe animation that the external display uses.
///
/// - Parameters:
///   - message:   The string currently shown to the speaker.
///   - fontSize:  Point size for the message text (caller scales for context).
///   - cornerRadius: Corner radius of the background card.
struct MessageDisplayCard: View {
    let message: String
    let fontSize: CGFloat
    var cornerRadius: CGFloat = 16
    var verticalPadding: CGFloat = 20
    var horizontalPadding: CGFloat = 24
    var lineLimit: Int? = 5

    /// Incrementing this value re-triggers the keyframe shake animation.
    @State private var shakeClicks: Int = 0

    var body: some View {
        Text(message)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineLimit(lineLimit)
            .minimumScaleFactor(0.4)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.blue.opacity(0.2))
                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
            // Keyframe shake — identical to the external display animation.
            .keyframeAnimator(initialValue: 0, trigger: shakeClicks) { content, value in
                content
                    .rotationEffect(.degrees(value), anchor: .bottom)
                    .offset(x: value * 2)
            } keyframes: { _ in
                KeyframeTrack {
                    SpringKeyframe(0,  duration: 0.00)
                    SpringKeyframe(-5, duration: 0.05)
                    SpringKeyframe( 5, duration: 0.05)
                    SpringKeyframe(-5, duration: 0.05)
                    SpringKeyframe( 5, duration: 0.05)
                    SpringKeyframe(-3, duration: 0.05)
                    SpringKeyframe( 3, duration: 0.05)
                    SpringKeyframe( 0, duration: 0.10)
                }
            }
            // Listen for zap notification and re-trigger shake.
            .onReceive(NotificationCenter.default.publisher(for: .messageZap)) { _ in
                guard !message.isEmpty else { return }
                shakeClicks += 1
            }
    }
}
