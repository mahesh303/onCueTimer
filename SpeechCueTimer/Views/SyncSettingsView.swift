//
//  SyncSettingsView.swift
//  SpeechCueTimer
//
//  Opened from the Sync button. Links iPads that use the same show code.
//

import SwiftUI

struct SyncSettingsView: View {
    @Bindable var sync: SyncManager
    @Environment(\.dismiss) private var dismiss
    @State private var codeDraft = ""
    @State private var nameDraft = ""
    @FocusState private var focusedField: Field?

    private enum Field { case code, name }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Sync with other iPads", isOn: $sync.isEnabled)
                        .tint(SkinColor.green)
                } footer: {
                    Text("Every iPad using the same show code shares the timer, the message on screen, quick times, saved messages, text size and the warning settings, and any of them can run the show. Skin and background stay separate on each iPad.")
                }

                Section {
                    HStack {
                        TextField("0000", text: $codeDraft)
                            .keyboardType(.numberPad)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .focused($focusedField, equals: .code)
                            .onChange(of: codeDraft) { _, newValue in
                                let digits = String(newValue.filter(\.isNumber).prefix(SyncManager.codeLength))
                                if digits != newValue { codeDraft = digits }
                                if digits.count == SyncManager.codeLength { sync.showCode = digits }
                            }
                            .accessibilityLabel("Show code")

                        Button("New code") {
                            codeDraft = SyncManager.randomCode()
                        }
                    }
                } header: {
                    Text("Show code")
                } footer: {
                    Text("Enter this code on every iPad for this show.")
                }

                Section {
                    TextField("Name", text: $nameDraft)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.done)
                        .onSubmit(commitName)
                        .accessibilityLabel("Name of this iPad")
                } header: {
                    Text("This iPad")
                } footer: {
                    Text("How this iPad appears on the others, e.g. \"FOH\" or \"Stage left\".")
                }

                if sync.isEnabled {
                    Section {
                        if sync.connectedPeerNames.isEmpty {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text("Looking for iPads using code \(sync.showCode)…")
                                    .foregroundStyle(SkinColor.secondaryText)
                            }
                        } else {
                            ForEach(Array(sync.connectedPeerNames.enumerated()), id: \.offset) { _, name in
                                Label {
                                    Text(name)
                                } icon: {
                                    Image(systemName: "ipad.landscape")
                                        .foregroundStyle(SkinColor.green)
                                }
                            }
                        }
                    } header: {
                        Text("Connected")
                    } footer: {
                        Text("Turn on Wi-Fi and Bluetooth on every iPad. They don't need to share a Wi-Fi network. Keep the app open: iOS disconnects apps in the background.")
                    }
                }
            }
            .navigationTitle("Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        commitName()
                        dismiss()
                    }
                }
            }
            .onAppear {
                codeDraft = sync.showCode
                nameDraft = sync.deviceName
            }
            .onChange(of: focusedField) { oldValue, _ in
                if oldValue == .name { commitName() }
                // Leaving a half-typed code puts the last full one back.
                if oldValue == .code && codeDraft.count != SyncManager.codeLength { codeDraft = sync.showCode }
            }
        }
    }

    /// Renaming reconnects, so only apply it once editing is finished.
    private func commitName() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != sync.deviceName {
            sync.deviceName = trimmed
        }
    }
}
