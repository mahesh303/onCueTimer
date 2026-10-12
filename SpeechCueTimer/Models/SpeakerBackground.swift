//
//  SpeakerBackground.swift
//  SpeechCueTimer
//
//  The colour behind the timer on the speaker display, picked in Settings.
//

import SwiftUI
import UIKit

/// Stored in UserDefaults under `storageKey` as an RRGGBB hex string (via @AppStorage),
/// so the external display, the operator preview and Settings always agree.
enum SpeakerBackground {
    static let storageKey = "speakerBackgroundHex"
    static let defaultHex = "000000"

    struct Preset: Identifiable {
        let name: String
        let hex: String
        var id: String { hex }
        var color: Color { SpeakerBackground.color(fromHex: hex) }
    }

    /// Dark tones keep the white digits and the yellow/red states readable.
    static let presets: [Preset] = [
        Preset(name: "Black", hex: "000000"),
        Preset(name: "Charcoal", hex: "1C1C1E"),
        Preset(name: "Navy", hex: "0B1A3A"),
        Preset(name: "Midnight Blue", hex: "102A54"),
        Preset(name: "Forest", hex: "0E2A1B"),
        Preset(name: "Plum", hex: "2A1036"),
        Preset(name: "Burgundy", hex: "3A0E16"),
        Preset(name: "Brown", hex: "2B1C10"),
    ]

    static func color(fromHex hex: String) -> Color {
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return .black }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    static func hex(from color: Color) -> String {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func byte(_ component: CGFloat) -> Int { Int((min(max(component, 0), 1) * 255).rounded()) }
        return String(format: "%02X%02X%02X", byte(red), byte(green), byte(blue))
    }

    /// WCAG relative luminance, 0 (black) ... 1 (white).
    static func luminance(ofHex hex: String) -> Double {
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return 0 }
        func linear(_ byte: UInt32) -> Double {
            let c = Double(byte) / 255
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear((value >> 16) & 0xFF) + 0.7152 * linear((value >> 8) & 0xFF) + 0.0722 * linear(value & 0xFF)
    }

    /// True when white timer digits would fall below 4.5:1 contrast on this colour.
    static func isTooLightForWhiteText(_ hex: String) -> Bool {
        (1.05) / (luminance(ofHex: hex) + 0.05) < 4.5
    }
}
