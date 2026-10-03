//
//  GlassConsoleView.swift
//  SpeechCueTimer
//
//  Skin A: a large program preview with a floating transport dock, and a glass
//  side panel for the message, warning settings and the set time.
//

import SwiftUI

struct GlassConsoleView: View {
    let timerManager: TimerManager
    let viewModel: ContentViewModel
    let showCursor: Bool
    @Binding var isKeyboardVisible: Bool
    let onOpenHelp: () -> Void
    let onOpenSettings: () -> Void

    @State private var fontSizeManager = FontSizeManager.shared
    @State private var showDurationPicker = false

    private var settings: TimerSettings { timerManager.settings }

    var body: some View {
        let cue = CueAppearance(settings: settings)

        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                SkinColor.background.ignoresSafeArea()

                // Ambient glow in the timer's state colour, so the glass has something to refract.
                Ellipse()
                    .fill(cue.accent)
                    .frame(width: 760, height: 560)
                    .blur(radius: 150)
                    .opacity(0.14)
                    .position(x: geometry.size.width * 0.33, y: geometry.size.height * 0.3)
                    .animation(.easeInOut(duration: 0.6), value: cue.statusText)
                    .allowsHitTesting(false)

                if isLandscape {
                    HStack(alignment: .top, spacing: 24) {
                        programColumn(cue: cue)
                        sidePanel
                            .frame(width: min(max(geometry.size.width * 0.3, 360), 420))
                    }
                    .padding(24)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            programColumn(cue: cue)
                            sidePanel
                        }
                        .padding(24)
                    }
                }
            }
        }
        .foregroundStyle(SkinColor.primaryText)
    }

    // MARK: - Program column

    private func programColumn(cue: CueAppearance) -> some View {
        VStack(spacing: 18) {
            header

            VStack(spacing: 14) {
                SpeakerDisplayView(
                    skin: .glassConsole,
                    timerManager: timerManager,
                    message: viewModel.displayMessage,
                    fontScale: fontSizeManager.currentScale
                )
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 30, y: 20)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Program preview")

                progressRow(cue: cue)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            transportDock
            quickTimes
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image("SCTlogo")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .accessibilityHidden(true)

            Text("Program")
                .font(.system(size: 26, weight: .bold))
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 12)

            DisplayStatusPill(isConnected: viewModel.isExternalDisplayConnected)
            FontScaleControl()
            HeaderButtons(onHelp: onOpenHelp, onSettings: onOpenSettings)
        }
        .frame(height: 48)
    }

    private func progressRow(cue: CueAppearance) -> some View {
        let elapsed = max(settings.totalSeconds - settings.remainingSeconds, 0)

        return HStack(spacing: 14) {
            HStack(spacing: 4) {
                Text(settings.formatTime(elapsed)).fontWeight(.semibold)
                Text("elapsed").foregroundStyle(SkinColor.secondaryText)
            }

            TimerProgressBar(progress: cue.progress, color: cue.accent, warningMarker: cue.warningMarker)
                .frame(height: 8)

            Text("of \(settings.formatTime(settings.totalSeconds))")
                .foregroundStyle(SkinColor.secondaryText)
        }
        .font(.subheadline)
        .monospacedDigit()
        .padding(.horizontal, 4)
        .frame(height: 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(settings.formatTime(elapsed)) elapsed of \(settings.formatTime(settings.totalSeconds))")
    }

    // MARK: - Transport

    private var transportDock: some View {
        HStack(spacing: 22) {
            DockButton(caption: "Clear", accessibilityLabel: "Clear", action: viewModel.clearTimer) {
                Image(systemName: "arrow.counterclockwise").font(.system(size: 22, weight: .semibold))
            }
            .accessibilityHint("Clear the timer")

            DockButton(caption: "Seconds", accessibilityLabel: "Subtract 10 seconds", action: { timerManager.subtractTime(seconds: 10) }) {
                Text("−10").font(.system(size: 18, weight: .semibold)).monospacedDigit()
            }

            startPauseButton

            DockButton(caption: "Seconds", accessibilityLabel: "Add 10 seconds", action: { timerManager.addTime(seconds: 10) }) {
                Text("+10").font(.system(size: 18, weight: .semibold)).monospacedDigit()
            }

            DockButton(caption: "Repeat", accessibilityLabel: "Repeat", action: viewModel.repeatLastTimer) {
                Image(systemName: "repeat").font(.system(size: 22, weight: .semibold))
            }
            .accessibilityHint("Repeat the last timer duration")
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .skinGlass(in: Capsule())
        .frame(maxWidth: .infinity)
    }

    private var startPauseButton: some View {
        let isRunning = settings.isRunning

        return Button {
            if isRunning {
                viewModel.pauseTimer()
            } else {
                viewModel.startTimer()
            }
        } label: {
            Label(isRunning ? "Pause" : "Start", systemImage: isRunning ? "pause.fill" : "play.fill")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(isRunning ? SkinColor.onOrange : SkinColor.onGreen)
                .frame(width: 196, height: 76)
                .skinFilled(isRunning ? SkinColor.orange : SkinColor.green, in: Capsule())
        }
        .buttonStyle(SkinPressStyle())
        .disabled(!isRunning && settings.remainingSeconds <= 0)
        .accessibilityHint(isRunning ? "Pause the timer" : "Start the timer")
    }

    // MARK: - Quick times

    private var quickTimes: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Quick times").font(.subheadline.weight(.semibold))
                Spacer()
                Text("Touch and hold to save the current time").font(.footnote)
            }
            .foregroundStyle(SkinColor.secondaryText)
            .padding(.horizontal, 4)

            HStack(spacing: 12) {
                ForEach(1...4, id: \.self) { number in
                    quickTimeTile(number)
                }
            }
        }
    }

    private func quickTimeTile(_ number: Int) -> some View {
        let preset = settings.presets[number]
        let isCurrent = preset != nil && preset == settings.totalSeconds
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

        return Button {
            timerManager.loadPreset(number: number)
        } label: {
            Group {
                if let preset {
                    Text(settings.formatTime(preset))
                        .font(.system(size: 22, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(isCurrent ? SkinColor.lightBlue : SkinColor.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .skinSelectable(isCurrent, in: shape)
                } else {
                    Text("Empty")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(SkinColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .skinEmptySlot(in: shape)
                }
            }
        }
        .buttonStyle(SkinPressStyle())
        .disabled(settings.isRunning)
        .contextMenu { QuickTimeMenu(timerManager: timerManager, number: number) }
        .accessibilityLabel(preset.map { "Quick time \(number): \(settings.formatTime($0))" } ?? "Quick time \(number): empty")
        .accessibilityHint("Touch and hold to save the current time here")
    }

    // MARK: - Side panel

    private var sidePanel: some View {
        // Fill the panel when everything fits; scroll on shorter screens.
        ViewThatFits(in: .vertical) {
            sidePanelContent
            ScrollView { sidePanelContent }
                .scrollBounceBehavior(.basedOnSize)
        }
        .skinGlass(in: RoundedRectangle(cornerRadius: 34, style: .continuous))
    }

    private var sidePanelContent: some View {
        // Message sits at the top so the floating keyboard (bottom-right) doesn't cover it.
        VStack(alignment: .leading, spacing: 26) {
            messageSection
            warningSection
            setTimeSection
        }
        .padding(22)
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Message")
                    .font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: viewModel.zapMessage) {
                    Label("Zap", systemImage: "bolt.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SkinColor.purple)
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .skinWell(in: Capsule())
                }
                .buttonStyle(SkinPressStyle())
                .disabled(viewModel.displayMessage.isEmpty)
                .accessibilityHint("Make the message shake on external display")
            }

            if !viewModel.displayMessage.isEmpty {
                onDisplayBanner
            }

            MessageComposerField(
                message: viewModel.message,
                showCursor: showCursor,
                isEditing: isKeyboardVisible,
                onTap: { isKeyboardVisible = true }
            )
            .frame(minHeight: 110, maxHeight: .infinity)

            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    savedMessageTile(0)
                    savedMessageTile(1)
                }
                GridRow {
                    savedMessageTile(2)
                    savedMessageTile(3)
                }
            }

            HStack(spacing: 10) {
                Button(action: viewModel.clearMessage) {
                    Text("Clear")
                        .font(.body.weight(.semibold))
                        .padding(.horizontal, 22)
                        .frame(height: 54)
                        .skinWell(in: Capsule())
                }
                .buttonStyle(SkinPressStyle())
                .accessibilityHint("Clear the current message")

                Button(action: viewModel.sendMessage) {
                    Label("Send to display", systemImage: "arrow.up")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .skinFilled(SkinColor.actionBlue, in: Capsule())
                }
                .buttonStyle(SkinPressStyle())
                .disabled(viewModel.message.isEmpty)
                .accessibilityHint("Send the current message to display")
            }
        }
    }

    private var onDisplayBanner: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        return HStack(spacing: 10) {
            Circle()
                .fill(SkinColor.blue)
                .frame(width: 8, height: 8)
            HStack(spacing: 4) {
                Text("On display:").foregroundStyle(SkinColor.secondaryText)
                Text(viewModel.displayMessage.replacingOccurrences(of: "\n", with: " "))
            }
            .font(.subheadline)
            .lineLimit(1)
            Spacer(minLength: 4)
            Button(action: viewModel.hideMessage) {
                Text("Hide")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SkinColor.lightBlue)
                    .padding(.horizontal, 8)
                    .frame(minHeight: 44)
            }
            .buttonStyle(SkinPressStyle())
            .accessibilityHint("Remove the message from the speaker display")
        }
        .padding(.leading, 14)
        .padding(.trailing, 4)
        .background(SkinColor.blue.opacity(0.14), in: shape)
        .overlay(shape.strokeBorder(SkinColor.blue.opacity(0.35), lineWidth: 1))
    }

    private func savedMessageTile(_ index: Int) -> some View {
        let preset = viewModel.presets[index]
        let hasDraft = !viewModel.message.isEmpty
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)

        return Button {
            // Filled slot loads into the editor; an empty slot saves the draft into it.
            if preset != nil {
                viewModel.loadPreset(at: index)
            } else if hasDraft {
                viewModel.savePreset(at: index)
            }
        } label: {
            Group {
                if let preset {
                    Text(preset)
                        .foregroundStyle(SkinColor.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .skinWell(in: shape)
                } else {
                    Text(hasDraft ? "Save draft here" : "Empty slot")
                        .foregroundStyle(hasDraft ? SkinColor.lightBlue : SkinColor.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .skinEmptySlot(in: shape)
                }
            }
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
        }
        .buttonStyle(SkinPressStyle())
        .disabled(preset == nil && !hasDraft)
        .contextMenu { SavedMessageMenu(viewModel: viewModel, index: index) }
        .accessibilityLabel(preset.map { "Saved message \(index + 1): \($0)" } ?? "Saved message \(index + 1): empty")
        .accessibilityHint(preset == nil ? "Saves the current message in this slot" : "Loads this message into the editor")
    }

    private var warningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Warning")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)
            WarningSettingsCard(timerManager: timerManager)
        }
    }

    private var setTimeSection: some View {
        let total = settings.totalSeconds

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Set time")
                    .font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if settings.isRunning {
                    Label("Locked while running", systemImage: "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(SkinColor.secondaryText)
                }
            }

            Button {
                showDurationPicker = true
            } label: {
                HStack(spacing: 6) {
                    timeWell(min(total / 3600, 99), unit: "hr")
                    timeSeparator
                    timeWell((total % 3600) / 60, unit: "min")
                    timeSeparator
                    timeWell(total % 60, unit: "sec")
                }
            }
            .buttonStyle(SkinPressStyle())
            .disabled(settings.isRunning)
            .popover(isPresented: $showDurationPicker) {
                DurationPicker(timerManager: timerManager)
                    .presentationCompactAdaptation(.popover)
            }
            .accessibilityLabel("Set time")
            .accessibilityValue(settings.formatTime(total))
            .accessibilityHint("Opens hour, minute and second pickers")
        }
    }

    private func timeWell(_ value: Int, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text(unit)
                .font(.caption)
                .foregroundStyle(SkinColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 88)
        .skinWell(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var timeSeparator: some View {
        Text(":")
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(SkinColor.tertiaryText)
    }
}

/// Round well button with a caption underneath, used in the transport dock.
private struct DockButton<Icon: View>: View {
    let caption: String
    let accessibilityLabel: String
    let action: () -> Void
    @ViewBuilder let icon: Icon

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                icon
                    .frame(width: 56, height: 56)
                    .skinWell(in: Circle())
                Text(caption)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SkinColor.secondaryText)
            }
            .frame(width: 64)
        }
        .buttonStyle(SkinPressStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}
