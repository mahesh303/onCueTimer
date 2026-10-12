//
//  FloatingKeyboard.swift
//  SpeechCueTimer
//
//  Extracted from ContentView.swift (phase 4 refactor).
//

import SwiftUI

struct FloatingKeyboard: View {
    let onKeyTap: (String) -> Void
    let onDone: () -> Void

    @State private var isUppercase = true
    @State private var currentWord = ""
    @State private var suggestions: [String] = []
    @State private var showEmojiKeyboard = false
    /// Index into `EmojiCatalog.categories`; -1 is Recents.
    @State private var selectedEmojiCategory = 0

    // Common word dictionary for suggestions
    private let commonWords = [
        "the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "its", "may", "new", "now", "old", "see", "two", "who", "boy", "did", "man", "way", "what", "when", "where", "will", "with", "work", "your", "about", "after", "again", "back", "been", "before", "being", "both", "came", "come", "could", "each", "first", "from", "give", "good", "great", "hand", "here", "into", "just", "know", "last", "left", "life", "like", "live", "look", "made", "make", "many", "most", "move", "much", "must", "name", "need", "next", "only", "over", "part", "play", "place", "right", "said", "same", "seem", "show", "small", "such", "take", "than", "that", "their", "them", "there", "these", "they", "thing", "think", "this", "those", "through", "time", "today", "together", "under", "until", "very", "want", "water", "well", "went", "were", "where", "which", "while", "world", "would", "write", "year", "years", "young"
    ]

    // Most recent first, space-separated; kept across launches like the system keyboard's.
    @AppStorage("recentEmoji") private var recentEmojiStorage = ""
    private static let recentLimit = 32

    private var recentEmoji: [String] {
        recentEmojiStorage.split(separator: " ").map(String.init)
    }

    private let uppercaseKeys = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["⇧", "Z", "X", "C", "V", "B", "N", "M", "⌫"],
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["😀", "Space", "Return", "Done"]
    ]

    private let lowercaseKeys = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["⇧", "z", "x", "c", "v", "b", "n", "m", "⌫"],
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["😀", "Space", "Return", "Done"]
    ]

    private var currentKeys: [[String]] {
        return isUppercase ? uppercaseKeys : lowercaseKeys
    }

    var body: some View {
        VStack(spacing: 10) {
            if showEmojiKeyboard {
                emojiCategoryBar
                emojiGrid

                // Control row for emoji mode
                HStack {
                    Button("ABC") {
                        showEmojiKeyboard = false
                    }
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 55, height: 44)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.3)))

                    Spacer()

                    Button("⌫") {
                        onKeyTap("⌫")
                    }
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 55, height: 44)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.3)))

                    Button("Done") {
                        onDone()
                    }
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 79, height: 44)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.2)))
                }
            } else {
                // Word suggestions row
                if !suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(suggestions.prefix(3), id: \.self) { suggestion in
                                Button(action: {
                                    // Remove the current partial word and replace with suggestion
                                    if !currentWord.isEmpty {
                                        for _ in 0..<currentWord.count {
                                            onKeyTap("⌫")
                                        }
                                    }
                                    onKeyTap("SUGGESTION:\(suggestion)")
                                    currentWord = ""
                                    suggestions = []
                                }) {
                                    Text(suggestion)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.blue.opacity(0.1))
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    .frame(height: 40)
                }

                // Main keyboard
                VStack(spacing: 13) {
                    ForEach(0..<currentKeys.count, id: \.self) { rowIndex in
                        HStack(spacing: 9) {
                            ForEach(currentKeys[rowIndex], id: \.self) { key in
                                Button(action: {
                                    if key == "Done" {
                                        onDone()
                                    } else if key == "⇧" {
                                        isUppercase.toggle()
                                    } else if key == "😀" {
                                        // Open on Recents once there are some, like the system keyboard.
                                        selectedEmojiCategory = recentEmoji.isEmpty ? 0 : -1
                                        showEmojiKeyboard = true
                                    } else {
                                        handleKeyInput(key)
                                    }
                                }) {
                                    Group {
                                        if key == "Return" {
                                            Image(systemName: "return")
                                                .font(.system(size: 18, weight: .semibold))
                                        } else {
                                            Text(key == "Space" ? "⎵" : key)
                                                .font(.system(size: 21, weight: .medium))
                                        }
                                    }
                                    .foregroundColor(.primary)
                                    .frame(
                                        width: key == "Space" ? 135 : (key == "Done" ? 75 : (key == "Return" ? 60 : 44)),
                                        height: 44
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                key == "Done" ? Color.blue.opacity(0.2) :
                                                key == "Return" ? Color.blue.opacity(0.15) :
                                                key == "😀" ? Color.yellow.opacity(0.3) :
                                                key == "⇧" ? (isUppercase ? Color.green.opacity(0.3) : Color.gray.opacity(0.3)) :
                                                Color.gray.opacity(0.3)
                                            )
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
        .frame(maxWidth: 490)
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
                                onKeyTap(emoji)
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

    private func handleKeyInput(_ key: String) {
        if key == "⌫" {
            if !currentWord.isEmpty {
                currentWord.removeLast()
                updateSuggestions()
            } else {
                onKeyTap(key)
            }
        } else if key == "Space" {
            onKeyTap(" ")
            currentWord = ""
            suggestions = []
            isUppercase = true // Auto-capitalize after space
        } else if key == "Return" {
            onKeyTap("\n")
            currentWord = ""
            suggestions = []
            isUppercase = true // Auto-capitalize on new line
        } else if key.rangeOfCharacter(from: CharacterSet.letters) != nil {
            let letterToAdd = shouldCapitalize() ? key.uppercased() : key.lowercased()
            currentWord += letterToAdd
            onKeyTap(letterToAdd)
            updateSuggestions()
            // After first letter, switch to lowercase unless shift is pressed
            if currentWord.count == 1 {
                isUppercase = false
            }
        } else {
            onKeyTap(key)
            currentWord = ""
            suggestions = []
            // Auto-capitalize after period
            if key == "." {
                isUppercase = true
            }
        }
    }

    private func updateSuggestions() {
        if currentWord.isEmpty {
            suggestions = []
        } else {
            suggestions = commonWords
                .filter { $0.lowercased().hasPrefix(currentWord.lowercased()) }
                .filter { $0.lowercased() != currentWord.lowercased() }
                .sorted { $0.count < $1.count }
        }
    }

    private func shouldCapitalize() -> Bool {
        return isUppercase || currentWord.isEmpty
    }
}
