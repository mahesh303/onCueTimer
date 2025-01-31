import SwiftUI
import UIKit

class DisplayManager: ObservableObject {
    var externalWindow: UIWindow?
    let timerManager: TimerManager
    @Published var message: String = ""
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        setupExternalDisplayNotifications()
    }
    
    private func setupExternalDisplayNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneConnectionChange),
            name: UIScene.didActivateNotification,
            object: nil
        )
        
        // Check for already connected displays
        setupExternalDisplay()
    }
    
    private func setupExternalDisplay() {
        guard let mainScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        
        let externalScenes = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .filter { $0 != mainScene }
        
        guard let externalScene = externalScenes.first else {
            return
        }
        
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
        if notification.name == UIScene.didActivateNotification {
            setupExternalDisplay()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 