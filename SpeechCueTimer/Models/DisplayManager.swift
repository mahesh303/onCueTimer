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
    
    private func setupExternalDisplay() {
        // Clear any existing external window
        externalWindow?.isHidden = true
        externalWindow = nil
        
        // Get all active scenes
        let scenes = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
        
        // Find the main scene (iPad display)
        guard let mainScene = scenes.first(where: { scene in
            // Main scene typically has a single window that's key and visible
            if let windows = scene.windows as? [UIWindow],
               let mainWindow = windows.first,
               mainWindow.isKeyWindow {
                return true
            }
            return false
        }) else {
            return
        }
        
        // Find external display scene
        let externalScenes = scenes.filter { $0 != mainScene }
        guard let externalScene = externalScenes.first else {
            return
        }
        
        // Create and setup external window
        let window = UIWindow(windowScene: externalScene)
        let controller = UIHostingController(
            rootView: ExternalDisplayView(
                timerManager: timerManager,
                displayManager: self
            )
        )
        
        window.rootViewController = controller
        window.isHidden = false
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