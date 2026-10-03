//
//  HelpView.swift
//  SpeechCueTimer
//
//  The in-app user guide, opened from the ? button next to Settings.
//  The words live in HelpContent.swift.
//

import SwiftUI

struct HelpView: View {
    @AppStorage(AppSkin.storageKey) private var skin: AppSkin = .glassConsole
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let topics = HelpContent.topics(for: skin)

        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image("SCTlogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("User Guide")
                                .font(.title2.bold())
                            Text("Everything you need to run the timer and cue your speaker.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                } footer: {
                    Text(LocalizedStringKey("These instructions match the **\(skin.title)** skin you're using. Change skins with the gear button."))
                }

                Section("Topics") {
                    ForEach(topics) { topic in
                        NavigationLink(value: topic.id) {
                            HStack(spacing: 14) {
                                SettingsRowIcon(systemImage: topic.systemImage, tint: topic.tint, foreground: topic.iconForeground)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(topic.title)
                                    Text(topic.summary)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section {
                } footer: {
                    Text(versionText)
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { id in
                if let index = topics.firstIndex(where: { $0.id == id }) {
                    HelpTopicView(
                        topic: topics[index],
                        next: index + 1 < topics.count ? topics[index + 1] : nil
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationSizing(.page)
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let name = info?["CFBundleDisplayName"] as? String ?? info?["CFBundleName"] as? String ?? "SpeechCueTimer"
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        return version.isEmpty ? name : "\(name) · Version \(version)"
    }
}

/// One topic of the guide, laid out as a readable column.
private struct HelpTopicView: View {
    let topic: HelpTopic
    let next: HelpTopic?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(spacing: 14) {
                    Image(systemName: topic.systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(topic.iconForeground)
                        .frame(width: 52, height: 52)
                        .background(topic.tint, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .accessibilityHidden(true)
                    Text(topic.summary)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                ForEach(topic.sections.indices, id: \.self) { index in
                    HelpSectionView(section: topic.sections[index])
                }

                if let next {
                    NavigationLink(value: next.id) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Next")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text(next.title)
                                    .font(.headline)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(SkinPressStyle())
                    .foregroundStyle(.primary)
                }
            }
            .padding(24)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct HelpSectionView: View {
    let section: HelpSection

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let heading = section.heading {
                Text(heading)
                    .font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
            }

            ForEach(section.items.indices, id: \.self) { index in
                itemView(section.items[index])
            }
        }
    }

    @ViewBuilder
    private func itemView(_ item: HelpItem) -> some View {
        switch item {
        case .paragraph(let text):
            Text(LocalizedStringKey(text))
                .fixedSize(horizontal: false, vertical: true)

        case .steps(let steps):
            VStack(alignment: .leading, spacing: 14) {
                ForEach(steps.indices, id: \.self) { index in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.subheadline.bold())
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(SkinColor.actionBlue, in: Circle())
                            .accessibilityLabel("Step \(index + 1)")
                        Text(LocalizedStringKey(steps[index]))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .rows(let rows):
            VStack(alignment: .leading, spacing: 0) {
                ForEach(rows.indices, id: \.self) { index in
                    if index > 0 {
                        Divider().padding(.leading, rows[index].systemImage == nil ? 16 : 60)
                    }
                    HStack(alignment: .top, spacing: 14) {
                        if let systemImage = rows[index].systemImage {
                            Image(systemName: systemImage)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 30, height: 30)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rows[index].title)
                                .font(.headline)
                            Text(LocalizedStringKey(rows[index].detail))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .accessibilityElement(children: .combine)
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

        case .legend(let swatches):
            VStack(alignment: .leading, spacing: 14) {
                ForEach(swatches.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 14) {
                        Circle()
                            .fill(swatches[index].color)
                            .frame(width: 18, height: 18)
                            .padding(.top, 2)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(swatches[index].title)
                                .font(.headline)
                            Text(LocalizedStringKey(swatches[index].detail))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }

        case .tip(let text):
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(SkinColor.yellow)
                    .accessibilityHidden(true)
                Text(LocalizedStringKey(text))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SkinColor.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(SkinColor.yellow.opacity(0.3), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Tip")
            .accessibilityValue(Text(LocalizedStringKey(text)))
        }
    }
}

#Preview {
    HelpView()
        .preferredColorScheme(.dark)
}
