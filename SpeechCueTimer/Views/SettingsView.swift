//
//  SettingsView.swift
//  SpeechCueTimer
//
//  Opened from the gear button. Lets the operator choose the app's skin and the speaker background.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSkin.storageKey) private var skin: AppSkin = .glassConsole
    @AppStorage(SpeakerBackground.storageKey) private var backgroundHex = SpeakerBackground.defaultHex
    @Environment(\.dismiss) private var dismiss

    private var customColor: Binding<Color> {
        Binding(
            get: { SpeakerBackground.color(fromHex: backgroundHex) },
            set: { backgroundHex = SpeakerBackground.hex(from: $0) }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        ForEach(AppSkin.allCases) { option in
                            SkinOptionCard(skin: option, isSelected: skin == option) {
                                withAnimation(.smooth(duration: 0.35)) { skin = option }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Skin")
                } footer: {
                    Text("Changes both this screen and the speaker display. Timer and messages are kept.")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 8), spacing: 12) {
                        ForEach(SpeakerBackground.presets) { preset in
                            BackgroundSwatch(preset: preset, isSelected: backgroundHex == preset.hex) {
                                backgroundHex = preset.hex
                            }
                        }
                    }
                    .padding(.vertical, 6)

                    ColorPicker("Custom colour", selection: customColor, supportsOpacity: false)
                } header: {
                    Text("Speaker background")
                } footer: {
                    if SpeakerBackground.isTooLightForWhiteText(backgroundHex) {
                        Label("This colour is too light for the white timer digits to read clearly from the stage.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(SkinColor.yellow)
                    } else {
                        Text("The colour behind the timer on the speaker display and the preview.")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct SkinOptionCard: View {
    let skin: AppSkin
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                SkinThumbnail(skin: skin)
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack {
                    Text(skin.title)
                        .font(.headline)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? SkinColor.blue : SkinColor.tertiaryText)
                }

                Text(skin.summary)
                    .font(.footnote)
                    .foregroundStyle(SkinColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: shape)
            .overlay(shape.strokeBorder(isSelected ? SkinColor.blue : .clear, lineWidth: 2))
        }
        .buttonStyle(SkinPressStyle())
        .accessibilityLabel(skin.title)
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityHint(skin.summary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct BackgroundSwatch: View {
    let preset: SpeakerBackground.Preset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(preset.color)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                .padding(4)
                .overlay(Circle().strokeBorder(isSelected ? SkinColor.blue : .clear, lineWidth: 2.5))
                .frame(width: 44, height: 44)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SkinPressStyle())
        .accessibilityLabel(preset.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Simplified drawing of each skin's layout.
private struct SkinThumbnail: View {
    let skin: AppSkin

    var body: some View {
        GeometryReader { geometry in
            let unit = geometry.size.height / 30

            ZStack {
                SkinColor.background

                HStack(spacing: unit) {
                    VStack(spacing: unit) {
                        switch skin {
                        case .glassConsole:
                            RoundedRectangle(cornerRadius: unit * 1.5, style: .continuous)
                                .fill(Color.black)
                                .overlay(
                                    Text("04:32")
                                        .font(.system(size: unit * 4.5, weight: .semibold))
                                        .monospacedDigit()
                                        .foregroundStyle(SkinColor.primaryText)
                                )
                                .overlay(RoundedRectangle(cornerRadius: unit * 1.5, style: .continuous).strokeBorder(Color.white.opacity(0.15)))
                                .aspectRatio(16 / 9, contentMode: .fit)
                            Capsule()
                                .fill(SkinColor.green)
                                .frame(height: unit * 0.6)
                                .padding(.trailing, unit * 6)
                            Spacer(minLength: 0)
                            Capsule()
                                .fill(Color.white.opacity(0.14))
                                .frame(width: unit * 14, height: unit * 3.4)
                                .overlay(Capsule().fill(SkinColor.green).frame(width: unit * 4.5, height: unit * 2.2))
                        case .stageRing:
                            ZStack {
                                Circle().stroke(Color.white.opacity(0.12), lineWidth: unit * 0.9)
                                Circle()
                                    .trim(from: 0, to: 0.55)
                                    .stroke(SkinColor.green, style: StrokeStyle(lineWidth: unit * 0.9, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                Text("04:32")
                                    .font(.system(size: unit * 3.6, weight: .light, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(SkinColor.primaryText)
                            }
                            .padding(unit * 0.5)
                            Capsule()
                                .fill(Color.white.opacity(0.14))
                                .frame(width: unit * 14, height: unit * 3.4)
                                .overlay(Circle().fill(SkinColor.green).frame(width: unit * 2.8))
                        }
                    }
                    .frame(maxWidth: .infinity)

                    RoundedRectangle(cornerRadius: unit * 2, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: geometry.size.width * 0.3)
                }
                .padding(unit * 1.5)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
