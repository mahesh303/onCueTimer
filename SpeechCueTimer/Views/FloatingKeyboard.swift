//
//  FloatingKeyboard.swift
//  SpeechCueTimer
//
//  The operator's on-screen keyboard. It edits the message through a binding and
//  works everything out from that text (capitalisation, the word being typed,
//  suggestions), so deleting or tapping a suggestion can never leave it out of step.
//

import SwiftUI

struct FloatingKeyboard: View {
    @Binding var text: String
    let onDone: () -> Void

    private enum Shift { case off, once, locked }

    @State private var shift: Shift = .off
    /// The operator turned automatic capitals off for the next letter by tapping ⇧.
    @State private var autoShiftDismissed = false
    @State private var lastShiftTap = Date.distantPast
    @State private var showEmojiKeyboard = false
    /// Index into `EmojiCatalog.categories`; -1 is Recents.
    @State private var selectedEmojiCategory = 0

    // Most recent first, space-separated; kept across launches like the system keyboard's.
    @AppStorage("recentEmoji") private var recentEmojiStorage = ""
    private static let recentLimit = 32

    private var recentEmoji: [String] {
        recentEmojiStorage.split(separator: " ").map(String.init)
    }

    private static let letterRows = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"],
    ]
    private static let numberRow = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    private static let contentWidth: CGFloat = 10 * 44 + 9 * 9

    // MARK: - Derived from the text

    private var isShifted: Bool {
        switch shift {
        case .once, .locked: return true
        case .off: return KeyboardText.autoCapitalizes(text) && !autoShiftDismissed
        }
    }

    private var autoCapitalizes: Bool { KeyboardText.autoCapitalizes(text) }
    private var currentWord: String { KeyboardText.currentWord(in: text) }
    private var suggestions: [String] { KeyboardText.suggestions(for: currentWord) }

    // MARK: - Editing

    private func insert(_ string: String) {
        text += string
    }

    private func typeLetter(_ letter: String) {
        insert(isShifted ? letter.uppercased() : letter)
        if shift == .once { shift = .off }
        autoShiftDismissed = false
    }

    private func deleteBackward() {
        if !text.isEmpty { text.removeLast() }
        autoShiftDismissed = false
    }

    private func applySuggestion(_ suggestion: String) {
        text.removeLast(currentWord.count)
        text += suggestion + " "
        autoShiftDismissed = false
    }

    private func tapShift() {
        let now = Date()
        let isDoubleTap = now.timeIntervalSince(lastShiftTap) < 0.35
        lastShiftTap = now

        if isDoubleTap && shift != .locked {
            shift = .locked
        } else if shift == .locked || shift == .once {
            shift = .off
            autoShiftDismissed = autoCapitalizes
        } else if isShifted {
            // Automatic capital is on; ⇧ turns it off for the next letter, like iOS.
            autoShiftDismissed = true
        } else {
            shift = .once
        }
    }

    // MARK: - Layout

    var body: some View {
        VStack(spacing: 10) {
            if showEmojiKeyboard {
                emojiCategoryBar
                emojiGrid

                // Control row for emoji mode
                HStack {
                    KeyButton(width: 55, fill: Color.gray.opacity(0.3), action: { showEmojiKeyboard = false }) {
                        Text("ABC").font(.system(size: 17, weight: .medium))
                    }
                    Spacer()
                    DeleteKey(width: 55, onDelete: deleteBackward)
                    KeyButton(width: 79, fill: Color.blue.opacity(0.2), action: onDone) {
                        Text("Done").font(.system(size: 17, weight: .medium))
                    }
                }
            } else {
                suggestionBar
                letterKeys
            }
        }
        // As wide as the widest row (ten 44pt keys, 9pt apart). It used to be capped
        // narrower, which made the rows spill past the panel and off the screen edge.
        .frame(width: Self.contentWidth)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
    }

    /// Always on screen, so the keyboard doesn't jump as suggestions come and go.
    private var suggestionBar: some View {
        let items = suggestions

        return HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
                if index > 0 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.35))
                        .frame(width: 1, height: 22)
                }
                let suggestion = index < items.count ? items[index] : nil
                Button {
                    if let suggestion { applySuggestion(suggestion) }
                } label: {
                    Text(suggestion ?? " ")
                        .font(.system(size: 18, weight: index == 0 ? .semibold : .regular))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(suggestion == nil)
                .accessibilityHidden(suggestion == nil)
                .accessibilityLabel(suggestion.map { "Suggestion: \($0)" } ?? "")
            }
        }
        .frame(height: 40)
    }

    private var letterKeys: some View {
        let shifted = isShifted

        return VStack(spacing: 13) {
            HStack(spacing: 9) {
                ForEach(Self.letterRows[0], id: \.self) { letterKey($0, shifted: shifted) }
            }
            HStack(spacing: 9) {
                ForEach(Self.letterRows[1], id: \.self) { letterKey($0, shifted: shifted) }
            }
            HStack(spacing: 9) {
                KeyButton(fill: shift == .off ? (shifted ? Color.green.opacity(0.3) : Color.gray.opacity(0.3)) : Color.green.opacity(0.45), action: tapShift) {
                    Image(systemName: shift == .locked ? "capslock.fill" : (shifted ? "shift.fill" : "shift"))
                        .font(.system(size: 18, weight: .semibold))
                }
                .accessibilityLabel(shift == .locked ? "Caps lock" : "Shift")
                .accessibilityValue(shifted ? "On" : "Off")

                ForEach(Self.letterRows[2], id: \.self) { letterKey($0, shifted: shifted) }

                DeleteKey(width: 44, onDelete: deleteBackward)
            }
            HStack(spacing: 9) {
                ForEach(Self.numberRow, id: \.self) { digit in
                    KeyButton(action: { insert(digit) }) {
                        Text(digit).font(.system(size: 21, weight: .medium))
                    }
                }
            }
            HStack(spacing: 9) {
                KeyButton(fill: Color.yellow.opacity(0.3), action: {
                    // Open on Recents once there are some, like the system keyboard.
                    selectedEmojiCategory = recentEmoji.isEmpty ? 0 : -1
                    showEmojiKeyboard = true
                }) {
                    Text("😀").font(.system(size: 21))
                }
                .accessibilityLabel("Emoji")

                punctuationKey(",")
                punctuationKey(".")

                KeyButton(width: 100, action: { insert(" ") }) {
                    Text("space").font(.system(size: 16, weight: .medium))
                }
                .accessibilityLabel("Space")

                punctuationKey("!")
                punctuationKey("?")

                KeyButton(width: 60, fill: Color.blue.opacity(0.15), action: { insert("\n") }) {
                    Image(systemName: "return").font(.system(size: 18, weight: .semibold))
                }
                .accessibilityLabel("Return")

                KeyButton(width: 75, fill: Color.blue.opacity(0.2), action: onDone) {
                    Text("Done").font(.system(size: 17, weight: .medium))
                }
            }
        }
    }

    private func letterKey(_ letter: String, shifted: Bool) -> some View {
        KeyButton(action: { typeLetter(letter) }) {
            Text(shifted ? letter.uppercased() : letter)
                .font(.system(size: 21, weight: .medium))
        }
    }

    private func punctuationKey(_ mark: String) -> some View {
        KeyButton(action: { insert(mark) }) {
            Text(mark).font(.system(size: 22, weight: .semibold))
        }
    }

    // MARK: - Emoji

    private var emojiCategoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                emojiCategoryButton(index: -1, systemImage: "clock", name: "Recents")
                ForEach(Array(EmojiCatalog.categories.enumerated()), id: \.element.id) { index, category in
                    emojiCategoryButton(index: index, systemImage: category.systemImage, name: category.name)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 40)
    }

    private func emojiCategoryButton(index: Int, systemImage: String, name: String) -> some View {
        let isSelected = selectedEmojiCategory == index

        return Button {
            selectedEmojiCategory = index
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .frame(width: 40, height: 40)
                .background(Circle().fill(isSelected ? Color.blue.opacity(0.3) : Color.clear))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var emojiGrid: some View {
        let isRecents = selectedEmojiCategory < 0
        let categories = EmojiCatalog.categories
        let category = categories.indices.contains(selectedEmojiCategory) ? categories[selectedEmojiCategory] : nil
        let emojis = isRecents ? recentEmoji : (category?.emoji ?? [])

        return VStack(alignment: .leading, spacing: 6) {
            Text(isRecents ? "Recently used" : (category?.name ?? ""))
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            if emojis.isEmpty {
                Text(isRecents ? "Emoji you use show up here." : "No emoji available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 8), spacing: 4) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button {
                                insert(emoji)
                                rememberEmoji(emoji)
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 30))
                                    .frame(width: 48, height: 48)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                // New identity per category so switching starts at the top.
                .id(selectedEmojiCategory)
            }
        }
        .frame(height: 230)
    }

    private func rememberEmoji(_ emoji: String) {
        var recents = recentEmoji.filter { $0 != emoji }
        recents.insert(emoji, at: 0)
        recentEmojiStorage = recents.prefix(Self.recentLimit).joined(separator: " ")
    }

}

// MARK: - Text rules

/// What the keyboard works out from the message text. Kept apart from the view so it can be tested.
enum KeyboardText {
    static let commonWords = [
        "the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "its", "may", "new", "now", "old", "see", "two", "who", "boy", "did", "man", "way", "what", "when", "where", "will", "with", "work", "your", "about", "after", "again", "back", "been", "before", "being", "both", "came", "come", "could", "each", "first", "from", "give", "good", "great", "hand", "here", "into", "just", "know", "last", "left", "life", "like", "live", "look", "made", "make", "many", "most", "move", "much", "must", "name", "need", "next", "only", "over", "part", "play", "place", "right", "said", "same", "seem", "show", "small", "such", "take", "than", "that", "their", "them", "there", "these", "they", "thing", "think", "this", "those", "through", "time", "today", "together", "under", "until", "very", "want", "water", "well", "went", "were", "where", "which", "while", "world", "would", "write", "year", "years", "young", "minute", "minutes", "please", "thank", "thanks", "questions", "question", "speaker", "stage", "five", "three", "remaining", "finish", "slow", "down", "louder", "microphone", "camera", "applause", "break", "lunch", "wrap", "up", "seconds", "audience", "slides", "almost", "done"
    ]

    /// Capitalise at the start, after a new line, or after the end of a sentence.
    static func autoCapitalizes(_ text: String) -> Bool {
        guard let last = text.last else { return true }
        if last == "\n" { return true }
        guard last == " " else { return false }
        guard let end = text.reversed().first(where: { $0 != " " }) else { return true }
        return end == "." || end == "!" || end == "?" || end == "\n"
    }

    /// Letters (and apostrophes) at the end of the text: the word being typed.
    static func currentWord(in text: String) -> String {
        String(text.reversed().prefix { $0.isLetter || $0 == "'" }.reversed())
    }

    /// Up to three words starting with `word`, shortest first, in the same case.
    static func suggestions(for word: String) -> [String] {
        guard !word.isEmpty else { return [] }
        let lower = word.lowercased()
        let matches = Set(commonWords.filter { $0.hasPrefix(lower) && $0 != lower })
            .sorted { $0.count != $1.count ? $0.count < $1.count : $0 < $1 }
            .prefix(3)
        // Match the case of what's been typed so far ("Wr" → "Wrap").
        let capitalised = word.first?.isUppercase == true
        return matches.map { capitalised ? $0.prefix(1).uppercased() + $0.dropFirst() : $0 }
    }
}

// MARK: - Keys

/// One key. Highlights the moment it's touched so typing feels immediate.
private struct KeyButton<Label: View>: View {
    var width: CGFloat = 44
    var fill: Color = Color.gray.opacity(0.3)
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .foregroundStyle(Color.primary)
                .frame(width: width, height: 44)
        }
        .buttonStyle(KeyStyle(fill: fill))
    }
}

private struct KeyStyle: ButtonStyle {
    let fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? Color.white.opacity(0.45) : fill)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 1.08 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Deletes on touch, then keeps deleting while held, like the iPad keyboard.
private struct DeleteKey: View {
    let width: CGFloat
    let onDelete: () -> Void

    @State private var isPressed = false
    @State private var repeatTask: Task<Void, Never>?

    var body: some View {
        Image(systemName: isPressed ? "delete.left.fill" : "delete.left")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.primary)
            .frame(width: width, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPressed ? Color.white.opacity(0.45) : Color.gray.opacity(0.3))
                    .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        onDelete()
                        repeatTask = Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(450))
                            while !Task.isCancelled {
                                onDelete()
                                try? await Task.sleep(for: .milliseconds(80))
                            }
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        repeatTask?.cancel()
                        repeatTask = nil
                    }
            )
            .onDisappear { repeatTask?.cancel() }
            .accessibilityElement()
            .accessibilityLabel("Delete")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onDelete() }
    }
}
