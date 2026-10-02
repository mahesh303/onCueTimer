import SwiftUI

extension Notification.Name {
    static let fontScaleChanged = Notification.Name("fontScaleChanged")
    static let messageZap = Notification.Name("messageZap")
    static let timerStateChanged = Notification.Name("timerStateChanged")
}

struct ExternalDisplayView: View {
    let timerManager: TimerManager
    let displayManager: DisplayManager
    @State private var fontScale: Double = 1.0
    // Drives the pulse scale animation on the timer text.
    @State private var isPulsing = false

    // Token from the closure-form NotificationCenter observer must be stored so
    // we can remove it in onDisappear. Previously the token was discarded,
    // making the observer impossible to remove (leaked forever).
    @State private var timerStateObserverToken: (any NSObjectProtocol)?

    // Active when the timer is yellow AND the operator has enabled the pulse toggle.
    private var shouldPulse: Bool {
        timerManager.settings.timerState == .warning &&
        timerManager.settings.pulseAnimationEnabled
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background for external display
                Color.black
                    .ignoresSafeArea(.all)

                VStack(spacing: 40) {
                    Spacer()

                    // Timer Display — reads directly from @Observable timerManager.
                    // SwiftUI's observation system re-renders this view automatically
                    // when remainingSeconds changes; no local @State copy or polling needed.
                    VStack(spacing: 20) {
                        Text(timerManager.settings.formatTime(timerManager.settings.remainingSeconds))
                            .font(.system(size: min(geometry.size.width * 0.12, 120) * fontScale, weight: .bold, design: .monospaced))
                            .foregroundColor(getTimeColor(for: timerManager.settings.remainingSeconds))
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                            .minimumScaleFactor(0.5)
                            // Pulse animation: scale up/down while in yellow warning state.
                            // Slightly more dramatic (1.12) than operator view since this
                            // is meant to grab the speaker's attention on the big screen.
                            .scaleEffect(isPulsing ? 1.12 : 1.0)
                            .task(id: shouldPulse) {
                                if shouldPulse {
                                    while !Task.isCancelled {
                                        withAnimation(.easeInOut(duration: 0.65)) { isPulsing = true }
                                        try? await Task.sleep(for: .milliseconds(650))
                                        withAnimation(.easeInOut(duration: 0.65)) { isPulsing = false }
                                        try? await Task.sleep(for: .milliseconds(650))
                                    }
                                } else {
                                    withAnimation(.easeInOut(duration: 0.3)) { isPulsing = false }
                                }
                            }
                    }
                    .frame(maxWidth: geometry.size.width * 0.9)
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                    Spacer()

                    // Message Display — delegates shake/zap animation to shared card.
                    if !displayManager.message.isEmpty {
                        MessageDisplayCard(
                            message: displayManager.message,
                            fontSize: min(geometry.size.width * 0.06, 60) * fontScale
                        )
                        .padding(.horizontal, 40)
                        .frame(maxWidth: geometry.size.width * 0.85)
                    }

                    Spacer()
                }
                .padding(20)
            }
        }
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

    private func getTimeColor(for seconds: Int) -> Color {
        if seconds > timerManager.settings.warningThresholdSeconds {
            return .primary
        } else if seconds > 0 {
            return .yellow
        } else {
            return .red
        }
    }
}
