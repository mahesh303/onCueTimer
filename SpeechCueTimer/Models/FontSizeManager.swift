import Foundation
import UIKit
import SwiftUI

@Observable final class FontSizeManager {
    static let shared = FontSizeManager()
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    /// False for the throwaway instances tests create, so they don't overwrite the saved size.
    private let persists: Bool

    var currentScale: Double {
        didSet {
            if persists {
                UserDefaults.standard.set(currentScale, forKey: "externalDisplayFontScale")
            }
            NotificationCenter.default.post(
                name: .fontScaleChanged,
                object: currentScale
            )
        }
    }
    
    var canIncrease: Bool {
        currentScale < 1.99
    }
    
    var canDecrease: Bool {
        currentScale > 0.51
    }
    
    private init() {
        persists = true
        let saved = UserDefaults.standard.double(forKey: "externalDisplayFontScale")
        self.currentScale = saved > 0 ? saved : 1.0
    }

    /// A separate, unsaved instance, so a test can simulate two devices in one process.
    init(scale: Double) {
        persists = false
        currentScale = scale
    }
    
    func increaseFontSize() {
        guard canIncrease else { return }
        let newScale = min(currentScale + 0.1, 2.0)
        currentScale = (newScale * 10).rounded() / 10
        feedbackGenerator.impactOccurred(intensity: 0.3)
    }
    
    func decreaseFontSize() {
        guard canDecrease else { return }
        let newScale = max(currentScale - 0.1, 0.5)
        currentScale = (newScale * 10).rounded() / 10
        feedbackGenerator.impactOccurred(intensity: 0.3)
    }
}
