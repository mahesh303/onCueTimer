//
//  OperatorControls.swift
//  SpeechCueTimer
//
//  Controls used by both operator skins.
//

import SwiftUI

/// A− 100% A+ capsule that scales the timer and message on the speaker display.
struct FontScaleControl: View {
    /// Use a recessed well instead of glass when the control already sits on a glass panel.
    var usesWell = false

    @State private var fontSizeManager = FontSizeManager.shared

    var body: some View {
        let percent = "\(Int(round(fontSizeManager.currentScale * 100))) percent"

        let content = HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { fontSizeManager.decreaseFontSize() }
            } label: {
                Text("A")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 44, height: 44)
            }
            .disabled(!fontSizeManager.canDecrease)
            .accessibilityLabel("Decrease font size for timer and messages")
            .accessibilityValue(percent)

            Text("\(Int(round(fontSizeManager.currentScale * 100)))%")
                .font(.footnote.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(SkinColor.secondaryText)
                .frame(minWidth: 44)
                .accessibilityHidden(true)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { fontSizeManager.increaseFontSize() }
            } label: {
                Text("A")
                    .font(.system(size: 21, weight: .bold))
                    .frame(width: 44, height: 44)
            }
            .disabled(!fontSizeManager.canIncrease)
            .accessibilityLabel("Increase font size for timer and messages")
            .accessibilityValue(percent)
        }
        .buttonStyle(SkinPressStyle())
        .foregroundStyle(SkinColor.primaryText)
        .padding(.horizontal, 4)

        if usesWell {
            content.skinWell(in: Capsule())
        } else {
            content.skinGlass(in: Capsule())
        }
    }
}

/// Green when an external screen is attached, grey otherwise.
struct DisplayStatusPill: View {
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isConnected ? SkinColor.green : Color.gray)
                .frame(width: 8, height: 8)
            Image(systemName: "display")
            Text(isConnected ? "Display connected" : "No display")
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(SkinColor.primaryText)
        .padding(.horizontal, 16)
        .frame(height: 44)
        .skinGlass(in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

/// Help and Settings, grouped in one glass capsule like an iOS toolbar.
struct HeaderButtons: View {
    let onHelp: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onHelp) {
                Image(systemName: "questionmark")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Help")
            .accessibilityHint("Opens the user guide")

            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 19, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Settings")
        }
        .buttonStyle(SkinPressStyle())
        .foregroundStyle(SkinColor.primaryText)
        .padding(.horizontal, 2)
        .skinGlass(in: Capsule(), interactive: true)
    }
}

/// Coloured rounded-square icon, as used in iOS Settings rows.
struct SettingsRowIcon: View {
    let systemImage: String
    var tint: Color = SkinColor.yellow
    var foreground: Color = SkinColor.onYellow

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: 30, height: 30)
            .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Tappable area showing the message being typed. Tapping it opens the floating keyboard.
struct MessageComposerField: View {
    let message: String
    let showCursor: Bool
    let isEditing: Bool
    let onTap: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

        ScrollView {
            Group {
                if message.isEmpty && !isEditing {
                    Text("Type a message for the speaker")
                        .foregroundStyle(SkinColor.secondaryText)
                } else {
                    // The cursor is always laid out and only its colour blinks,
                    // so the text never reflows while the cursor flashes.
                    Text("\(Text(verbatim: message))\(Text(verbatim: "|").foregroundStyle(showCursor ? SkinColor.blue : .clear))")
                        .foregroundStyle(SkinColor.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .font(.system(size: 19))
            .lineSpacing(3)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .skinWell(in: shape)
        .overlay(shape.strokeBorder(SkinColor.blue, lineWidth: isEditing ? 2 : 0))
        .contentShape(shape)
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Message input")
        .accessibilityValue(message.isEmpty ? "No message" : message)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
    }
}

/// "Warn at" stepper and pulse toggle, grouped like an iOS Settings section.
struct WarningSettingsCard: View {
    let timerManager: TimerManager

    var body: some View {
        // @Bindable lets us create $bindings to @Observable properties from a `let`.
        @Bindable var settings = timerManager.settings
        let threshold = settings.formatTime(settings.warningThresholdSeconds)

        VStack(spacing: 0) {
            HStack(spacing: 12) {
                SettingsRowIcon(systemImage: "exclamationmark.triangle.fill")
                Text("Warn at")
                Spacer(minLength: 8)
                HStack(spacing: 0) {
                    Button {
                        timerManager.decreaseWarningThreshold()
                    } label: {
                        Image(systemName: "minus").frame(width: 44, height: 40)
                    }
                    .disabled(settings.warningThresholdSeconds <= 10)
                    .accessibilityLabel("Decrease warning threshold by 30 seconds")

                    Text(threshold)
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(SkinColor.yellow)
                        .frame(minWidth: 58)
                        .accessibilityLabel("Warning threshold: \(threshold)")

                    Button {
                        timerManager.increaseWarningThreshold()
                    } label: {
                        Image(systemName: "plus").frame(width: 44, height: 40)
                    }
                    .disabled(settings.warningThresholdSeconds >= 600)
                    .accessibilityLabel("Increase warning threshold by 30 seconds")
                }
                .font(.system(size: 16, weight: .semibold))
                .buttonStyle(SkinPressStyle())
                .background(Color.white.opacity(0.08), in: Capsule())
            }
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .frame(minHeight: 60)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.leading, 56)

            HStack(spacing: 12) {
                SettingsRowIcon(systemImage: "waveform")
                Toggle("Pulse during warning", isOn: $settings.pulseAnimationEnabled)
                    .tint(SkinColor.green)
                    .accessibilityHint("When on, the timer zooms in and out to alert the speaker during the warning period")
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 60)
        }
        .foregroundStyle(SkinColor.primaryText)
        .skinWell(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// Hour / minute / second wheels. Changes apply immediately, like the old inline pickers.
struct DurationPicker: View {
    let timerManager: TimerManager

    @State private var hours: Int
    @State private var minutes: Int
    @State private var seconds: Int

    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        // Seed from the current time in init (not onAppear) so opening the picker
        // doesn't fire onChange and reset a paused timer.
        let total = timerManager.settings.totalSeconds
        _hours = State(initialValue: min(total / 3600, 23))
        _minutes = State(initialValue: (total % 3600) / 60)
        _seconds = State(initialValue: total % 60)
    }

    var body: some View {
        HStack(spacing: 0) {
            wheel("Hours", unit: "hours", range: 0...23, selection: $hours)
            wheel("Minutes", unit: "min", range: 0...59, selection: $minutes)
            wheel("Seconds", unit: "sec", range: 0...59, selection: $seconds)
        }
        .padding(.horizontal, 12)
        .frame(width: 380, height: 216)
        .onChange(of: hours) { apply() }
        .onChange(of: minutes) { apply() }
        .onChange(of: seconds) { apply() }
    }

    private func wheel(_ title: String, unit: String, range: ClosedRange<Int>, selection: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            Picker(title, selection: selection) {
                ForEach(range, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 64)
            .clipped()

            Text(unit)
                .font(.body.weight(.semibold))
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
    }

    private func apply() {
        guard !timerManager.settings.isRunning else { return }
        timerManager.setTime(seconds: hours * 3600 + minutes * 60 + seconds)
    }
}

/// Long-press menu for a quick-time slot.
struct QuickTimeMenu: View {
    let timerManager: TimerManager
    let number: Int

    var body: some View {
        let total = timerManager.settings.totalSeconds
        Button {
            timerManager.savePreset(number: number)
        } label: {
            Label("Save \(timerManager.settings.formatTime(total)) here", systemImage: "square.and.arrow.down")
        }
        .disabled(total == 0)
    }
}

/// Long-press menu for a saved-message slot.
struct SavedMessageMenu: View {
    let viewModel: ContentViewModel
    let index: Int

    var body: some View {
        Button("Save current message here", systemImage: "square.and.arrow.down") {
            viewModel.savePreset(at: index)
        }
        .disabled(viewModel.message.isEmpty)

        if viewModel.presets[index] != nil {
            Button("Send to display", systemImage: "arrow.up.circle") {
                viewModel.sendPreset(at: index)
            }
        }
    }
}

extension TimerSettings {
    /// Short chip label: "5 min", "1 hr", or "01:30" for anything uneven.
    func shortDurationLabel(_ seconds: Int) -> String {
        if seconds > 0 && seconds % 3600 == 0 {
            return "\(seconds / 3600) hr"
        }
        if seconds > 0 && seconds < 3600 && seconds % 60 == 0 {
            return "\(seconds / 60) min"
        }
        return formatTime(seconds)
    }
}
