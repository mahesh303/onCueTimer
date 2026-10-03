import SwiftUI

extension Notification.Name {
    static let fontScaleChanged = Notification.Name("fontScaleChanged")
    static let messageZap = Notification.Name("messageZap")
    static let timerStateChanged = Notification.Name("timerStateChanged")
}

extension View {
    /// Puts the speaker view on a connected HDMI/AirPlay screen. From iOS 27 the
    /// system only gives an app the external screen if it registers a scene
    /// accessory for it; otherwise it silently mirrors the operator screen.
    /// Earlier versions are handled by DisplayManager instead.
    func speakerDisplayAccessory(timerManager: TimerManager, displayManager: DisplayManager) -> some View {
        modifier(SpeakerDisplayAccessory(timerManager: timerManager, displayManager: displayManager))
    }
}

private struct SpeakerDisplayAccessory: ViewModifier {
    let timerManager: TimerManager
    let displayManager: DisplayManager

    func body(content: Content) -> some View {
        if #available(iOS 27.0, *) {
            content.sceneAccessory {
                ExternalNonInteractiveAccessory {
                    ExternalDisplayView(timerManager: timerManager, displayManager: displayManager)
                        .onAppear { displayManager.isAccessoryShowing = true }
                        .onDisappear { displayManager.isAccessoryShowing = false }
                }
                .onAvailabilityChange { isAvailable in
                    if !isAvailable {
                        displayManager.isAccessoryShowing = false
                    }
                }
            }
        } else {
            content
        }
    }
}

struct ExternalDisplayView: View {
    let timerManager: TimerManager
    let displayManager: DisplayManager
    @State private var fontScale: Double = 1.0
    // Same key the Settings sheet writes, so the speaker screen switches skin with the operator screen.
    @AppStorage(AppSkin.storageKey) private var skin: AppSkin = .glassConsole

    // Token from the closure-form NotificationCenter observer must be stored so
    // we can remove it in onDisappear. Previously the token was discarded,
    // making the observer impossible to remove (leaked forever).
    @State private var timerStateObserverToken: (any NSObjectProtocol)?

    var body: some View {
        // Reads directly from @Observable timerManager, so SwiftUI re-renders on every
        // tick with no polling. The operator screens embed this same view as their preview.
        SpeakerDisplayView(
            skin: skin,
            timerManager: timerManager,
            message: displayManager.message,
            fontScale: fontScale
        )
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            fontScale = FontSizeManager.shared.currentScale

            // Store the observer token so we can remove it in onDisappear.
            // Previously this used the closure form but discarded the token,
            // making it impossible to remove (leaked for the app's lifetime).
            timerStateObserverToken = NotificationCenter.default.addObserver(
                forName: .timerStateChanged,
                object: nil,
                queue: .main
            ) { _ in
                // No-op: @Observable timerManager drives re-renders automatically.
                // Kept here in case other subsystems need to react to this notification.
            }
        }
        .onDisappear {
            // Properly remove the stored token — this is the only correct way
            // to deregister a closure-form NotificationCenter observer.
            if let token = timerStateObserverToken {
                NotificationCenter.default.removeObserver(token)
                timerStateObserverToken = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .fontScaleChanged)) { notification in
            if let newScale = notification.object as? Double {
                fontScale = newScale
            }
        }
    }
}
