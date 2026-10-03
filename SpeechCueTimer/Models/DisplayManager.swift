import SwiftUI
import UIKit

@Observable final class DisplayManager {
    var externalWindow: UIWindow?
    /// iOS 27+: true while the speaker view is up on the external screen through
    /// the scene accessory (see `speakerDisplayAccessory`).
    var isAccessoryShowing = false
    let timerManager: TimerManager
    var message: String = ""

    var isExternalDisplayConnected: Bool {
        externalWindow != nil || isAccessoryShowing
    }

    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        setupExternalDisplayNotifications()
    }

    private func setupExternalDisplayNotifications() {
        // From iOS 27 the system only hands over the external screen through the
        // scene accessory, which draws the speaker view itself. Adding our own
        // window to that scene as well would stack a second copy on top.
        guard #unavailable(iOS 27.0) else { return }

        // External display scenes are non-interactive and may never become active,
        // so watch for them connecting rather than activating.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneWillConnect),
            name: UIScene.willConnectNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneDidDisconnect),
            name: UIScene.didDisconnectNotification,
            object: nil
        )
        
        // Check for a display that was already connected at launch
        // Defer this to the next run loop to avoid blocking app launch
        DispatchQueue.main.async { [weak self] in
            let externalScene = UIApplication.shared.connectedScenes
                .first(where: Self.isExternalDisplay) as? UIWindowScene
            if let externalScene {
                self?.setupExternalDisplay(on: externalScene)
            }
        }
    }
    
    /// Before iOS 27 the HDMI/AirPlay screen arrives as its own scene with this role.
    private static func isExternalDisplay(_ scene: UIScene) -> Bool {
        scene.session.role == .windowExternalDisplayNonInteractive
    }
    
    func setupExternalDisplay(on externalScene: UIWindowScene) {
        guard externalWindow?.windowScene !== externalScene else { return }
        
        // Clear any existing external window
        externalWindow?.isHidden = true
        
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
    
    @objc private func handleSceneWillConnect(_ notification: Notification) {
        guard let scene = notification.object as? UIWindowScene, Self.isExternalDisplay(scene) else { return }
        setupExternalDisplay(on: scene)
    }
    
    @objc private func handleSceneDidDisconnect(_ notification: Notification) {
        guard let scene = notification.object as? UIScene, Self.isExternalDisplay(scene) else { return }
        externalWindow?.isHidden = true
        externalWindow = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
