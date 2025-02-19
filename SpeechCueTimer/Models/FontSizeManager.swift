import Foundation
import UIKit

class FontSizeManager {
    static let shared = FontSizeManager()
    
    private init() {}
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var currentScale: Double {
        let saved = UserDefaults.standard.double(forKey: "externalDisplayFontScale")
        return saved > 0 ? saved : 1.0
    }
    
    func increaseFontSize() {
        let newScale = min(currentScale + 0.1, 2.0) // Max 200%
        UserDefaults.standard.set(newScale, forKey: "externalDisplayFontScale")
        
        NotificationCenter.default.post(
            name: .fontScaleChanged,
            object: newScale
        )
        
        feedbackGenerator.impactOccurred(intensity: 0.3)
    }
    
    func decreaseFontSize() {
        let newScale = max(currentScale - 0.1, 0.5) // Min 50%
        UserDefaults.standard.set(newScale, forKey: "externalDisplayFontScale")
        
        NotificationCenter.default.post(
            name: .fontScaleChanged,
            object: newScale
        )
        
        feedbackGenerator.impactOccurred(intensity: 0.3)
    }
}
