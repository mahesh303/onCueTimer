//
//  AppSkin.swift
//  SpeechCueTimer
//
//  The visual skins the operator can pick from Settings.
//

import Foundation

/// Stored in UserDefaults under `AppSkin.storageKey` (via @AppStorage), so the choice
/// survives relaunches and the operator screen and external display always agree.
enum AppSkin: String, CaseIterable, Identifiable {
    case glassConsole
    case stageRing

    static let storageKey = "appSkin"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glassConsole: return "Glass Console"
        case .stageRing: return "Stage Ring"
        }
    }

    var summary: String {
        switch self {
        case .glassConsole: return "Large program preview with a floating control dock."
        case .stageRing: return "Progress ring up front, message tools in a side panel."
        }
    }
}
