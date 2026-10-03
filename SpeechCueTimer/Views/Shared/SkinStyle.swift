//
//  SkinStyle.swift
//  SpeechCueTimer
//
//  Colours, materials and effects shared by every skin and the external display.
//

import SwiftUI

/// iOS dark-mode system colours, pinned so the skins and the external display agree.
enum SkinColor {
    static let background = Color(red: 0.039, green: 0.039, blue: 0.047)    // #0A0A0C
    static let primaryText = Color(red: 0.961, green: 0.961, blue: 0.969)   // #F5F5F7
    static let secondaryText = Color(red: 0.922, green: 0.922, blue: 0.961).opacity(0.6)
    static let tertiaryText = Color(red: 0.922, green: 0.922, blue: 0.961).opacity(0.35)
    static let green = Color(red: 0.188, green: 0.820, blue: 0.345)         // #30D158
    static let yellow = Color(red: 1.0, green: 0.839, blue: 0.039)          // #FFD60A
    static let red = Color(red: 1.0, green: 0.271, blue: 0.227)             // #FF453A
    static let orange = Color(red: 1.0, green: 0.624, blue: 0.039)          // #FF9F0A
    static let blue = Color(red: 0.039, green: 0.518, blue: 1.0)            // #0A84FF
    static let lightBlue = Color(red: 0.392, green: 0.824, blue: 1.0)       // #64D2FF
    static let purple = Color(red: 0.855, green: 0.561, blue: 1.0)          // #DA8FFF
    // Darker blue for filled buttons so white text keeps 4.5:1 contrast.
    static let actionBlue = Color(red: 0.0, green: 0.443, blue: 0.890)     // #0071E3
    // Label colours for text sitting on the bright fills above.
    static let onGreen = Color(red: 0.012, green: 0.125, blue: 0.047)       // #03200C
    static let onOrange = Color(red: 0.169, green: 0.090, blue: 0.0)        // #2B1700
    static let onYellow = Color(red: 0.110, green: 0.086, blue: 0.0)        // #1C1600
}

/// Colours, progress and status text for the current timer, derived from `TimerSettings`.
/// Every skin and the external display read from this so they never disagree.
struct CueAppearance {
    let accent: Color
    let timeColor: Color
    /// Fraction of the set time that has elapsed, 0...1.
    let progress: Double
    /// Where the warning begins on a progress track (0...1), or nil when the
    /// set time is already shorter than the warning threshold.
    let warningMarker: Double?
    let statusText: String
    let shouldPulse: Bool

    init(settings: TimerSettings) {
        let remaining = settings.remainingSeconds
        let total = settings.totalSeconds
        let threshold = settings.warningThresholdSeconds

        if total > 0 {
            progress = min(max(Double(total - remaining) / Double(total), 0), 1)
            warningMarker = total > threshold ? Double(total - threshold) / Double(total) : nil
        } else {
            progress = 0
            warningMarker = nil
        }

        if total == 0 && !settings.isRunning {
            // Cleared timer: nothing to count, so stay neutral rather than alarm red.
            accent = SkinColor.blue
            timeColor = SkinColor.primaryText
            statusText = "Set a time"
        } else if remaining <= 0 {
            accent = SkinColor.red
            timeColor = SkinColor.red
            statusText = settings.isRunning ? "Over time" : "Time's up"
        } else if remaining <= threshold {
            accent = SkinColor.yellow
            timeColor = SkinColor.yellow
            statusText = settings.isRunning ? "Wrap-up time" : (remaining < total ? "Paused" : "Ready")
        } else if settings.isRunning {
            accent = SkinColor.green
            timeColor = SkinColor.primaryText
            statusText = "Running"
        } else {
            accent = SkinColor.blue
            timeColor = SkinColor.primaryText
            statusText = remaining < total ? "Paused" : "Ready"
        }

        shouldPulse = settings.timerState == .warning && settings.pulseAnimationEnabled
    }
}

// MARK: - Materials

extension View {
    /// Liquid Glass on iOS 26 and later; frosted material with a hairline edge before that.
    @ViewBuilder
    func skinGlass<S: Shape>(in shape: S, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.tint(tint).interactive(interactive), in: shape)
        } else {
            background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    if let tint {
                        shape.fill(tint.opacity(0.25))
                    }
                    shape.stroke(Color.white.opacity(0.14), lineWidth: 1)
                }
            }
        }
    }

    /// Recessed fill for inputs and secondary controls that sit on top of glass.
    func skinWell<S: Shape>(in shape: S) -> some View {
        background {
            ZStack {
                shape.fill(Color.white.opacity(0.065))
                shape.stroke(Color.white.opacity(0.07), lineWidth: 1)
            }
        }
    }

    /// Solid bright fill for the one primary action in a group (Start/Pause, Send).
    func skinFilled<S: InsettableShape>(_ color: Color, in shape: S) -> some View {
        background(color, in: shape)
            .overlay(
                shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0)], startPoint: .top, endPoint: .center),
                    lineWidth: 1
                )
            )
            .shadow(color: color.opacity(0.35), radius: 14, y: 8)
    }

    /// Blue selected state for chips and tiles; plain glass otherwise.
    @ViewBuilder
    func skinSelectable<S: InsettableShape>(_ isSelected: Bool, in shape: S) -> some View {
        if isSelected {
            background(SkinColor.blue.opacity(0.18), in: shape)
                .overlay(shape.strokeBorder(SkinColor.blue, lineWidth: 2))
        } else {
            skinGlass(in: shape, interactive: true)
        }
    }

    /// Dashed outline for an empty preset slot.
    func skinEmptySlot<S: InsettableShape>(in shape: S) -> some View {
        overlay(shape.strokeBorder(SkinColor.tertiaryText, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
    }
}

/// Press feedback and disabled dimming. The visuals live in each button's label so
/// one style works for glass, well and filled buttons alike.
struct SkinPressStyle: ButtonStyle {
    var dimsWhenDisabled = true
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(.rect)
            .opacity(isEnabled || !dimsWhenDisabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Effects

/// Repeating zoom while the timer is in its warning period (cadence unchanged since phase 8).
struct WarningPulse: ViewModifier {
    let isActive: Bool
    var scale: CGFloat = 1.1

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1)
            // .task(id:) restarts when isActive flips and is cancelled on disappear — no leaks.
            .task(id: isActive) {
                if isActive {
                    while !Task.isCancelled {
                        withAnimation(.easeInOut(duration: 0.65)) { isPulsing = true }
                        try? await Task.sleep(for: .milliseconds(650))
                        withAnimation(.easeInOut(duration: 0.65)) { isPulsing = false }
                        try? await Task.sleep(for: .milliseconds(650))
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) { isPulsing = false }
                }
            }
    }
}

/// Shakes the message card when the operator presses Zap. Every card on screen
/// (external display and operator preview) listens, so they shake together.
struct ZapShake: ViewModifier {
    @State private var shakeClicks = 0

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: 0, trigger: shakeClicks) { content, value in
                content
                    .rotationEffect(.degrees(value), anchor: .bottom)
                    .offset(x: value * 2)
            } keyframes: { _ in
                KeyframeTrack {
                    SpringKeyframe(0, duration: 0.00)
                    SpringKeyframe(-5, duration: 0.05)
                    SpringKeyframe(5, duration: 0.05)
                    SpringKeyframe(-5, duration: 0.05)
                    SpringKeyframe(5, duration: 0.05)
                    SpringKeyframe(-3, duration: 0.05)
                    SpringKeyframe(3, duration: 0.05)
                    SpringKeyframe(0, duration: 0.10)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .messageZap)) { _ in
                shakeClicks += 1
            }
    }
}
