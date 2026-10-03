//
//  StageRingView.swift
//  SpeechCueTimer
//
//  Skin B: a large progress ring with the transport dock beneath it, and a glass
//  inspector holding the speaker-display preview, messages and timer settings.
//

import SwiftUI

struct StageRingView: View {
    let timerManager: TimerManager
    let viewModel: ContentViewModel
    let showCursor: Bool
    @Binding var isKeyboardVisible: Bool
    let onOpenHelp: () -> Void
    let onOpenSettings: () -> Void

    @State private var fontSizeManager = FontSizeManager.shared
    @State private var showDurationPicker = false
    @State private var inspectorTab: InspectorTab = .message

    private enum InspectorTab: Hashable {
        case message
        case timer
    }

    private var settings: TimerSettings { timerManager.settings }

    var body: some View {
        let cue = CueAppearance(settings: settings)

        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                Color.black.ignoresSafeArea()

                if isLandscape {
                    HStack(spacing: 24) {
                        mainArea(cue: cue)
                        inspector
                            .frame(width: min(max(geometry.size.width * 0.29, 340), 400))
                    }
                    .padding(.leading, 24)
                    .padding([.top, .bottom, .trailing], 16)
                } else {
                    VStack(spacing: 20) {
                        mainArea(cue: cue)
                            .frame(height: geometry.size.height * 0.56)
                        inspector
                    }
                    .padding(16)
                }
            }
        }
        .foregroundStyle(SkinColor.primaryText)
    }

    // MARK: - Main area

    private func mainArea(cue: CueAppearance) -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Image("SCTlogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .accessibilityHidden(true)
                Text("Timer")
                    .font(.system(size: 26, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                HeaderButtons(onHelp: onOpenHelp, onSettings: onOpenSettings)
            }
            .frame(height: 48)

            ring(cue: cue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            quickTimeChips
            transportDock
        }
        .padding(.top, 8)
    }

    private func ring(cue: CueAppearance) -> some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height, 560)

            ZStack {
                Circle()
                    .fill(cue.accent)
                    .frame(width: diameter, height: diameter)
                    .blur(radius: diameter * 0.28)
                    .opacity(0.18)
                    .animation(.easeInOut(duration: 0.6), value: cue.statusText)

                ProgressRing(
                    progress: cue.progress,
                    warningMarker: cue.warningMarker,
                    color: cue.accent,
                    lineWidth: max(10, diameter * 0.035)
                )
                .frame(width: diameter, height: diameter)

                VStack(spacing: diameter * 0.025) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(cue.accent)
                            .frame(width: 8, height: 8)
                        Text(cue.statusText)
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .frame(height: 30)
                    .background(Color.white.opacity(0.08), in: Capsule())

                    // Tap the digits to set the time (when the timer isn't running).
                    Button {
                        showDurationPicker = true
                    } label: {
                        CountdownText(
                            settings: settings,
                            cue: cue,
                            fontSize: diameter * 0.24,
                            weight: .light,
                            design: .rounded,
                            pulseScale: 1.08
                        )
                    }
                    .buttonStyle(SkinPressStyle(dimsWhenDisabled: false))
                    .disabled(settings.isRunning)
                    .accessibilityHint(settings.isRunning ? "" : "Opens hour, minute and second pickers")
                    .popover(isPresented: $showDurationPicker) {
                        DurationPicker(timerManager: timerManager)
                            .presentationCompactAdaptation(.popover)
                    }

                    Text(ringSubtitle)
                        .font(.system(size: max(15, diameter * 0.036)))
                        .monospacedDigit()
                        .foregroundStyle(SkinColor.secondaryText)
                }
                .frame(width: diameter * 0.78)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var ringSubtitle: String {
        if settings.totalSeconds == 0 && !settings.isRunning {
            return "Tap the time or pick a quick time"
        }
        let total = settings.formatTime(settings.totalSeconds)
        let warning = settings.formatTime(settings.warningThresholdSeconds)
        return "of \(total) · warns at \(warning)"
    }

    private var quickTimeChips: some View {
        HStack(spacing: 10) {
            ForEach(1...4, id: \.self) { number in
                quickTimeChip(number)
            }

            Button {
                showDurationPicker = true
            } label: {
                Label("Custom", systemImage: "pencil")
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .skinGlass(in: Capsule(), interactive: true)
            }
            .buttonStyle(SkinPressStyle())
            .disabled(settings.isRunning)
            .accessibilityHint("Opens hour, minute and second pickers")
        }
    }

    private func quickTimeChip(_ number: Int) -> some View {
        let preset = settings.presets[number]
        let isCurrent = preset != nil && preset == settings.totalSeconds

        return Button {
            timerManager.loadPreset(number: number)
        } label: {
            Group {
                if let preset {
                    Text(settings.shortDurationLabel(preset))
                        .foregroundStyle(isCurrent ? SkinColor.lightBlue : SkinColor.primaryText)
                        .padding(.horizontal, 22)
                        .frame(height: 48)
                        .skinSelectable(isCurrent, in: Capsule())
                } else {
                    Text("Empty")
                        .foregroundStyle(SkinColor.secondaryText)
                        .padding(.horizontal, 22)
                        .frame(height: 48)
                        .skinEmptySlot(in: Capsule())
                }
            }
            .font(.body.weight(.semibold))
            .monospacedDigit()
        }
        .buttonStyle(SkinPressStyle())
        .disabled(settings.isRunning)
        .contextMenu { QuickTimeMenu(timerManager: timerManager, number: number) }
        .accessibilityLabel(preset.map { "Quick time \(number): \(settings.formatTime($0))" } ?? "Quick time \(number): empty")
        .accessibilityHint("Touch and hold to save the current time here")
    }

    private var transportDock: some View {
        HStack(spacing: 8) {
            DockItem(caption: "Clear", accessibilityLabel: "Clear", action: viewModel.clearTimer) {
                Image(systemName: "arrow.counterclockwise").font(.system(size: 22, weight: .semibold))
            }

            DockItem(caption: "Seconds", accessibilityLabel: "Subtract 10 seconds", action: { timerManager.subtractTime(seconds: 10) }) {
                Text("−10").font(.system(size: 20, weight: .semibold)).monospacedDigit()
            }

            startPauseButton
                .padding(.horizontal, 10)

            DockItem(caption: "Seconds", accessibilityLabel: "Add 10 seconds", action: { timerManager.addTime(seconds: 10) }) {
                Text("+10").font(.system(size: 20, weight: .semibold)).monospacedDigit()
            }

            DockItem(caption: "Repeat", accessibilityLabel: "Repeat", action: viewModel.repeatLastTimer) {
                Image(systemName: "repeat").font(.system(size: 22, weight: .semibold))
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 96)
        .skinGlass(in: Capsule())
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
            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(isRunning ? SkinColor.onOrange : SkinColor.onGreen)
                .frame(width: 80, height: 80)
                .skinFilled(isRunning ? SkinColor.orange : SkinColor.green, in: Circle())
        }
        .buttonStyle(SkinPressStyle())
        .disabled(!isRunning && settings.remainingSeconds <= 0)
        .accessibilityLabel(isRunning ? "Pause" : "Start")
    }

    // MARK: - Inspector

    private var inspector: some View {
        ViewThatFits(in: .vertical) {
            inspectorContent
            ScrollView { inspectorContent }
                .scrollBounceBehavior(.basedOnSize)
        }
        .skinGlass(in: RoundedRectangle(cornerRadius: 38, style: .continuous))
    }

    private var inspectorContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Circle()
                    .fill(viewModel.isExternalDisplayConnected ? SkinColor.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(viewModel.isExternalDisplayConnected ? "Speaker display" : "No display")
                    .font(.headline)
                Spacer(minLength: 8)
                FontScaleControl(usesWell: true)
            }
            .frame(minHeight: 44)

            // Collapse the preview while typing so the floating keyboard
            // doesn't cover the Send button on smaller iPads.
            if !isKeyboardVisible {
                speakerPreview
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }

            Picker("Panel", selection: $inspectorTab) {
                Text("Message").tag(InspectorTab.message)
                Text("Timer settings").tag(InspectorTab.timer)
            }
            .pickerStyle(.segmented)

            switch inspectorTab {
            case .message:
                messageTab
            case .timer:
                timerTab
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .animation(.smooth(duration: 0.3), value: isKeyboardVisible)
    }

    private var speakerPreview: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

        return SpeakerDisplayView(
            skin: .stageRing,
            timerManager: timerManager,
            message: viewModel.displayMessage,
            fontScale: fontSizeManager.currentScale
        )
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Speaker display preview")
        .overlay(alignment: .topTrailing) {
            if !viewModel.displayMessage.isEmpty {
                Button(action: viewModel.hideMessage) {
                    Label("Hide message", systemImage: "eye.slash")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .skinGlass(in: Capsule(), interactive: true)
                        .padding(6)
                }
                .buttonStyle(SkinPressStyle())
                .accessibilityHint("Remove the message from the speaker display")
            }
        }
    }

    private var messageTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            MessageComposerField(
                message: viewModel.message,
                showCursor: showCursor,
                isEditing: isKeyboardVisible,
                onTap: { isKeyboardVisible = true }
            )
            .frame(height: 120)

            HStack(spacing: 8) {
                Button(action: viewModel.zapMessage) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(SkinColor.purple)
                        .frame(width: 52, height: 52)
                        .skinWell(in: Circle())
                }
                .buttonStyle(SkinPressStyle())
                .disabled(viewModel.displayMessage.isEmpty)
                .accessibilityLabel("Zap")
                .accessibilityHint("Make the message shake on external display")

                Button(action: viewModel.clearMessage) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 52, height: 52)
                        .skinWell(in: Circle())
                }
                .buttonStyle(SkinPressStyle())
                .accessibilityLabel("Clear message")
                .accessibilityHint("Clear the current message")

                Button(action: viewModel.sendMessage) {
                    Label("Send", systemImage: "arrow.up")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .skinFilled(SkinColor.actionBlue, in: Capsule())
                }
                .buttonStyle(SkinPressStyle())
                .disabled(viewModel.message.isEmpty)
                .accessibilityHint("Send the current message to display")
            }

            HStack(alignment: .firstTextBaseline) {
                Text("Saved messages").font(.subheadline.weight(.semibold))
                Spacer()
                Text("One tap sends").font(.footnote)
            }
            .foregroundStyle(SkinColor.secondaryText)
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(0..<viewModel.presets.count, id: \.self) { index in
                    if index > 0 {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)
                            .padding(.leading, 16)
                    }
                    savedMessageRow(index)
                }
            }
            .skinWell(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func savedMessageRow(_ index: Int) -> some View {
        let preset = viewModel.presets[index]
        let hasDraft = !viewModel.message.isEmpty
        let isOnDisplay = preset != nil && preset == viewModel.displayMessage

        return HStack(spacing: 10) {
            Button {
                // Filled slot loads into the editor; an empty slot saves the draft into it.
                if preset != nil {
                    viewModel.loadPreset(at: index)
                } else if hasDraft {
                    viewModel.savePreset(at: index)
                }
            } label: {
                Text(preset ?? (hasDraft ? "Save draft here" : "Empty slot"))
                    .foregroundStyle(preset != nil ? SkinColor.primaryText : (hasDraft ? SkinColor.lightBlue : SkinColor.secondaryText))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 52)
            }
            .buttonStyle(SkinPressStyle())
            .disabled(preset == nil && !hasDraft)
            .accessibilityLabel(preset.map { "Saved message \(index + 1): \($0)" } ?? "Saved message \(index + 1): empty")
            .accessibilityHint(preset == nil ? "Saves the current message in this slot" : "Loads this message into the editor")

            if isOnDisplay {
                Text("On display")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(SkinColor.lightBlue)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(SkinColor.blue.opacity(0.18), in: Capsule())
                    .padding(.trailing, 6)
            } else if let preset {
                Button {
                    viewModel.sendPreset(at: index)
                } label: {
                    Image(systemName: "arrow.up.circle")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(SkinColor.lightBlue)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(SkinPressStyle())
                .accessibilityLabel("Send \(preset) to display")
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .contextMenu { SavedMessageMenu(viewModel: viewModel, index: index) }
    }

    private var timerTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            WarningSettingsCard(timerManager: timerManager)

            Text("The timer turns yellow at this point and red when time runs out.")
                .font(.footnote)
                .foregroundStyle(SkinColor.secondaryText)
                .padding(.horizontal, 6)

            Button {
                showDurationPicker = true
            } label: {
                HStack(spacing: 12) {
                    SettingsRowIcon(systemImage: "timer", tint: SkinColor.blue, foreground: .white)
                    Text("Set time")
                    Spacer()
                    Text(settings.formatTime(settings.totalSeconds))
                        .monospacedDigit()
                        .foregroundStyle(SkinColor.secondaryText)
                    Image(systemName: settings.isRunning ? "lock.fill" : "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(SkinColor.tertiaryText)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 60)
                .skinWell(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(SkinPressStyle())
            .disabled(settings.isRunning)
            .accessibilityHint("Opens hour, minute and second pickers")
        }
    }
}

/// Icon (or "−10" text) over a caption, sitting directly on the dock's glass.
private struct DockItem<Icon: View>: View {
    let caption: String
    let accessibilityLabel: String
    let action: () -> Void
    @ViewBuilder let icon: Icon

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                icon.frame(height: 26)
                Text(caption)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SkinColor.secondaryText)
            }
            .frame(width: 84, height: 72)
        }
        .buttonStyle(SkinPressStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}
