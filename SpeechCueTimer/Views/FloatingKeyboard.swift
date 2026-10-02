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
    @State private var selectedEmojiCategory = 0

    // Common word dictionary for suggestions
    private let commonWords = [
        "the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "its", "may", "new", "now", "old", "see", "two", "who", "boy", "did", "man", "way", "what", "when", "where", "will", "with", "work", "your", "about", "after", "again", "back", "been", "before", "being", "both", "came", "come", "could", "each", "first", "from", "give", "good", "great", "hand", "here", "into", "just", "know", "last", "left", "life", "like", "live", "look", "made", "make", "many", "most", "move", "much", "must", "name", "need", "next", "only", "over", "part", "play", "place", "right", "said", "same", "seem", "show", "small", "such", "take", "than", "that", "their", "them", "there", "these", "they", "thing", "think", "this", "those", "through", "time", "today", "together", "under", "until", "very", "want", "water", "well", "went", "were", "where", "which", "while", "world", "would", "write", "year", "years", "young"
    ]

    // Emoji categories
    private let emojiCategories = ["😀", "🎉", "❤️", "🍕", "🚗", "⚽"]

    private let emojiSets = [
        // Faces & People
        ["😀", "😃", "😄", "😁", "😅", "😂", "🤣", "😊", "😇", "🙂", "😉", "😌", "😍", "🥰", "😘", "😗", "😙", "😚", "😋", "😛", "😝", "😜", "🤪", "🤨", "🧐", "🤓", "😎", "🤩", "🥳"],
        // Activities & Celebrations
        ["🎉", "🎊", "🎈", "🎁", "🎂", "🎄", "🎆", "🎇", "✨", "🎯", "🎪", "🎨", "🎭", "🎮", "🎲", "🎸", "🎺", "🎤", "🎧", "🎵", "🎶", "🎼", "🏆", "🥇", "🥈", "🥉", "🏅", "🎗️"],
        // Hearts & Love
        ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟", "☮️", "✝️", "☪️", "🕉️", "☸️", "✡️", "🔯", "🕎", "☯️"],
        // Food & Drinks
        ["🍕", "🍔", "🌭", "🥪", "🌮", "🌯", "🥙", "🧆", "🥚", "🍳", "🥘", "🍲", "🥗", "🍿", "🧈", "🧄", "🧅", "🍄", "🥜", "🌰", "🍞", "🥐", "🥖", "🥨", "🥯", "🥞", "🧇", "🍰"],
        // Transport & Travel
        ["🚗", "🚕", "🚙", "🚌", "🚎", "🏎️", "🚓", "🚑", "🚒", "🚐", "🛻", "🚚", "🚛", "🚜", "🏍️", "🛵", "🚲", "🛴", "🛹", "🚁", "✈️", "🛫", "🛬", "🚀", "🛸", "🚢", "⛵", "🚤"],
        // Sports & Games
        ["⚽", "🏀", "🏈", "⚾", "🎾", "🏐", "🏉", "🎱", "🏓", "🏸", "🥅", "⛳", "🏹", "🎣", "🥊", "🥋", "🎽", "🛹", "🛷", "⛸️", "🥌", "🎿", "⛷️", "🏂", "🏋️", "🤸", "🤼", "🤽"]
    ]

    private let uppercaseKeys = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["⇧", "Z", "X", "C", "V", "B", "N", "M", "⌫"],
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["😀", "Space", "Done"]
    ]

    private let lowercaseKeys = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["⇧", "z", "x", "c", "v", "b", "n", "m", "⌫"],
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["😀", "Space", "Done"]
    ]

    private var currentKeys: [[String]] {
        return isUppercase ? uppercaseKeys : lowercaseKeys
    }

    var body: some View {
        VStack(spacing: 10) {
            if showEmojiKeyboard {
                // Emoji category selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<emojiCategories.count, id: \.self) { index in
                            Button(action: {
                                selectedEmojiCategory = index
                            }) {
                                Text(emojiCategories[index])
                                    .font(.system(size: 22))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(selectedEmojiCategory == index ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(height: 44)

                // Emoji grid
                let emojis = emojiSets[selectedEmojiCategory]
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 7), spacing: 13) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            onKeyTap(emoji)
                        }) {
                            Text(emoji)
                                .font(.system(size: 27))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(height: 200)

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
                                        showEmojiKeyboard = true
                                    } else {
                                        handleKeyInput(key)
                                    }
                                }) {
                                    Text(key == "Space" ? "⎵" : key)
                                        .font(.system(size: 21, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(
                                            width: key == "Space" ? 105 : (key == "Done" ? 79 : 44),
                                            height: 44
                                        )
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(
                                                    key == "Done" ? Color.blue.opacity(0.2) :
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
