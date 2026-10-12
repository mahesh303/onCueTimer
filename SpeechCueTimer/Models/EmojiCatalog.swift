//
//  EmojiCatalog.swift
//  SpeechCueTimer
//
//  The full Unicode emoji set for the floating keyboard, grouped like the system
//  emoji keyboard. Data lives in Resources/Emoji.tsv, generated from Unicode's
//  emoji-test.txt (fully-qualified emoji, skin-tone variants left out).
//

import CoreText
import Foundation

enum EmojiCatalog {
    struct Category: Identifiable {
        let name: String
        let systemImage: String
        let emoji: [String]
        var id: String { name }
    }

    /// Loaded and filtered once. Touch it early (see `preload`) so opening the
    /// emoji keyboard the first time doesn't stall.
    static let categories: [Category] = load()

    static func preload() {
        DispatchQueue.global(qos: .utility).async { _ = categories }
    }

    private static let icons: [String: String] = [
        "Smileys & Emotion": "face.smiling",
        "People & Body": "hand.wave",
        "Animals & Nature": "pawprint",
        "Food & Drink": "fork.knife",
        "Travel & Places": "car",
        "Activities": "soccerball",
        "Objects": "lightbulb",
        "Symbols": "heart",
        "Flags": "flag",
    ]

    private static func load() -> [Category] {
        guard let url = Bundle.main.url(forResource: "Emoji", withExtension: "tsv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }

        let font = CTFontCreateWithName("AppleColorEmoji" as CFString, 24, nil)

        return text.split(separator: "\n").compactMap { line in
            let fields = line.split(separator: "\t", maxSplits: 1)
            guard fields.count == 2 else { return nil }
            let name = String(fields[0])
            let emoji = fields[1].split(separator: " ").map(String.init).filter { isRenderable($0, font: font) }
            guard !emoji.isEmpty else { return nil }
            return Category(name: name, systemImage: icons[name] ?? "square.grid.2x2", emoji: emoji)
        }
    }

    /// The list includes emoji newer than some supported iOS versions. Anything this
    /// device can't draw as a single emoji glyph would show as a box or as its parts
    /// (e.g. 🧑🏽‍🚀 → 🧑 🏽 🚀), so it is left out.
    private static func isRenderable(_ emoji: String, font: CTFont) -> Bool {
        let attributed = NSAttributedString(string: emoji, attributes: [kCTFontAttributeName as NSAttributedString.Key: font])
        let line = CTLineCreateWithAttributedString(attributed)
        guard CTLineGetGlyphCount(line) == 1,
              let run = (CTLineGetGlyphRuns(line) as? [CTRun])?.first else { return false }

        var glyph = CGGlyph()
        CTRunGetGlyphs(run, CFRange(location: 0, length: 1), &glyph)
        guard glyph != 0 else { return false }

        // CoreText falls back to another font (often LastResort) for code points the emoji font lacks.
        let attributes = CTRunGetAttributes(run) as NSDictionary
        guard let runFont = attributes[kCTFontAttributeName] else { return false }
        return (CTFontCopyPostScriptName(runFont as! CTFont) as String) == "AppleColorEmoji"
    }
}
