import SwiftUI
import UIKit

@Observable final class DisplayManager {
    var externalWindow: UIWindow?
    let timerManager: TimerManager
    var message: String = ""
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        setupExternalDisplayNotifications()
    }
    
    private func setupExternalDisplayNotifications() {
        // Observe both scene connection and disconnection
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneConnectionChange),
            name: UIScene.didActivateNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneConnectionChange),
            name: UIScene.didDisconnectNotification,
            object: nil
        )
        
        // Check for already connected displays
        setupExternalDisplay()
    }
    
    func setupExternalDisplay() {
        // Clear any existing external window
        externalWindow?.isHidden = true
        externalWindow = nil
        
        // Get all window scenes
        let allScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        
        // Only proceed if we have more than one scene (external display connected)
        guard allScenes.count > 1 else {
            return
        }
        
        // Find the main scene (built-in display) by checking screen properties
        let mainScene = allScenes.first { scene in
            // Main scene is typically the one with the built-in screen
            return scene.screen == UIScreen.main
        }
        
        // Find external display scenes (not the main screen)
        let externalScenes = allScenes.filter { scene in
            return scene.screen != UIScreen.main && scene != mainScene
        }
        
        guard let externalScene = externalScenes.first else {
            return
        }
        
        // Create and setup external window only for the external scene
        let window = UIWindow(windowScene: externalScene)
        let controller = UIHostingController(
            rootView: ExternalDisplayView(
                timerManager: timerManager,
                displayManager: self
            )
        )
        
        window.rootViewController = controller
        window.isHidden = false
        window.makeKeyAndVisible()
        self.externalWindow = window
    }
    
    @objc private func handleSceneConnectionChange(_ notification: Notification) {
        // Add a small delay to ensure scene activation is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupExternalDisplay()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 