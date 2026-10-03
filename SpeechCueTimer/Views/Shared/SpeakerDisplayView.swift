//
//  SpeakerDisplayView.swift
//  SpeechCueTimer
//
//  What the speaker sees, drawn in the active skin. ExternalDisplayView shows it full
//  screen and the operator screens embed the same view as their preview, so the two
//  always match — pulse, zap shake and font scale included.
//

import SwiftUI

struct SpeakerDisplayView: View {
    let skin: AppSkin
    let timerManager: TimerManager
    let message: String
    let fontScale: Double

    var body: some View {
        // All sizes are relative to the view's height, so it renders the same on a
        // 1080p screen and in a small preview card.
        GeometryReader { geometry in
            ZStack {
                Color.black

                switch skin {
                case .glassConsole:
                    GlassConsoleDisplay(settings: timerManager.settings, message: message, fontScale: fontScale, size: geometry.size)
                case .stageRing:
                    StageRingDisplay(settings: timerManager.settings, message: message, fontScale: fontScale, size: geometry.size)
                }
            }
        }
    }
}

// MARK: - Skin A

private struct GlassConsoleDisplay: View {
    let settings: TimerSettings
    let message: String
    let fontScale: Double
    let size: CGSize

    var body: some View {
        let cue = CueAppearance(settings: settings)
        let unit = size.height
        let hasMessage = !message.isEmpty

        ZStack(alignment: .bottom) {
            // Soft glow in the state colour; gives the glass card something to pick up.
            Ellipse()
                .fill(cue.accent)
                .frame(width: size.width * 0.7, height: unit * 0.6)
                .blur(radius: unit * 0.18)
                .opacity(0.2)
                .position(x: size.width / 2, y: unit * 0.42)
                .animation(.easeInOut(duration: 0.6), value: cue.statusText)

            VStack(spacing: unit * 0.057) {
                CountdownText(
                    settings: settings,
                    cue: cue,
                    fontSize: unit * (hasMessage ? 0.3 : 0.4) * fontScale
                )

                if hasMessage {
                    SpeakerMessageCard(
                        message: message,
                        fontSize: unit * 0.068 * fontScale,
                        unit: unit,
                        shape: RoundedRectangle(cornerRadius: unit * 0.047, style: .continuous)
                    )
                    .frame(maxWidth: size.width * 0.82)
                }
            }
            .padding(unit * 0.06)
            .frame(width: size.width, height: size.height)
            .animation(.smooth(duration: 0.35), value: hasMessage)

            TimerProgressBar(progress: cue.progress, color: cue.accent)
                .frame(height: max(3, unit * 0.01))
                .padding(.horizontal, unit * 0.062)
                .padding(.bottom, unit * 0.041)
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Skin B

private struct StageRingDisplay: View {
    let settings: TimerSettings
    let message: String
    let fontScale: Double
    let size: CGSize

    var body: some View {
        let cue = CueAppearance(settings: settings)
        let unit = size.height
        let hasMessage = !message.isEmpty
        // The ring grows and shrinks with the font scale, capped so the message still fits.
        let baseRing = unit * (hasMessage ? 0.6 : 0.78)
        let ringCap = min(unit * (hasMessage ? 0.7 : 0.9), size.width * 0.9)
        let ring = min(baseRing * fontScale, ringCap)

        VStack(spacing: unit * 0.052) {
            ZStack {
                Circle()
                    .fill(cue.accent)
                    .blur(radius: ring * 0.25)
                    .opacity(0.16)

                ProgressRing(
                    progress: cue.progress,
                    warningMarker: cue.warningMarker,
                    color: cue.accent,
                    lineWidth: max(3, ring * 0.035)
                )

                CountdownText(settings: settings, cue: cue, fontSize: ring * 0.27, weight: .medium, design: .rounded)
                    .frame(width: ring * 0.8)
            }
            .frame(width: ring, height: ring)

            if hasMessage {
                SpeakerMessageCard(
                    message: message,
                    fontSize: unit * 0.062 * fontScale,
                    unit: unit,
                    shape: RoundedRectangle(cornerRadius: unit * 0.06, style: .continuous)
                )
                .frame(maxWidth: size.width * 0.86)
            }
        }
        .frame(width: size.width, height: size.height)
        .animation(.smooth(duration: 0.35), value: hasMessage)
    }
}

// MARK: - Building blocks

/// The big countdown digits, shared by every skin and preview.
struct CountdownText: View {
    let settings: TimerSettings
    let cue: CueAppearance
    let fontSize: CGFloat
    var weight: Font.Weight = .semibold
    var design: Font.Design = .default
    var pulseScale: CGFloat = 1.1

    var body: some View {
        Text(settings.formatTime(settings.remainingSeconds))
            .font(.system(size: max(fontSize, 1), weight: weight, design: design))
            .monospacedDigit()
            .foregroundStyle(cue.timeColor)
            .lineLimit(1)
            .minimumScaleFactor(0.3)
            .contentTransition(.numericText(countsDown: true))
            .animation(.snappy(duration: 0.3), value: settings.remainingSeconds)
            .modifier(WarningPulse(isActive: cue.shouldPulse, scale: pulseScale))
            .accessibilityLabel("Timer")
            .accessibilityValue(settings.formatTime(settings.remainingSeconds))
    }
}

/// The message the operator sent, on a glass card that shakes on Zap.
private struct SpeakerMessageCard<S: Shape>: View {
    let message: String
    let fontSize: CGFloat
    let unit: CGFloat
    let shape: S

    var body: some View {
        Text(message)
            .font(.system(size: max(fontSize, 1), weight: .semibold))
            .foregroundStyle(SkinColor.primaryText)
            .multilineTextAlignment(.center)
            .lineLimit(4)
            .minimumScaleFactor(0.4)
            .padding(.horizontal, unit * 0.06)
            .padding(.vertical, unit * 0.034)
            .skinGlass(in: shape)
            .modifier(ZapShake())
            .transition(.scale(scale: 0.9).combined(with: .opacity))
            .accessibilityLabel("Currently displayed message")
            .accessibilityValue(message)
    }
}

/// Thin capsule track that fills as time elapses, with an optional warning tick.
struct TimerProgressBar: View {
    let progress: Double
    let color: Color
    var warningMarker: Double? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * progress)

                if let warningMarker {
                    Capsule()
                        .fill(SkinColor.yellow)
                        .frame(width: 3, height: geometry.size.height + 10)
                        .offset(x: geometry.size.width * warningMarker - 1.5)
                }
            }
        }
        .animation(.linear(duration: 1), value: progress)
        .accessibilityHidden(true)
    }
}

/// Circular track that fills clockwise from 12 o'clock, with a yellow dot where the warning starts.
struct ProgressRing: View {
    let progress: Double
    let warningMarker: Double?
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let radius = (diameter - lineWidth) / 2

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
                    .padding(lineWidth / 2)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(lineWidth / 2)
                    .opacity(progress > 0 ? 1 : 0)

                if let warningMarker {
                    let angle = Angle.degrees(warningMarker * 360 - 90)
                    Circle()
                        .fill(SkinColor.yellow)
                        .overlay(Circle().stroke(Color.black, lineWidth: lineWidth * 0.18))
                        .frame(width: lineWidth * 0.95, height: lineWidth * 0.95)
                        .offset(x: radius * cos(angle.radians), y: radius * sin(angle.radians))
                }
            }
            .frame(width: diameter, height: diameter)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.linear(duration: 1), value: progress)
        .accessibilityHidden(true)
    }
}
