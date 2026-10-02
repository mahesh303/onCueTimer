import SwiftUI

extension Notification.Name {
    static let fontScaleChanged = Notification.Name("fontScaleChanged")
    static let messageZap = Notification.Name("messageZap")
    static let timerStateChanged = Notification.Name("timerStateChanged")
}

struct ExternalDisplayView: View {
    let timerManager: TimerManager
    let displayManager: DisplayManager
    @State private var currentTime: Int = 0
    @State private var fontScale: Double = 1.0
    @State private var shakeClicks: Int = 0 // Used to trigger the animation
    @State private var refreshTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background for external display
                Color.black
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Timer Display
                    VStack(spacing: 20) {
                        Text(timerManager.settings.formatTime(currentTime))
                            .font(.system(size: min(geometry.size.width * 0.12, 120) * fontScale, weight: .bold, design: .monospaced))
                            .foregroundColor(getTimeColor(for: currentTime))
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                            .minimumScaleFactor(0.5)
                    }
                    .frame(maxWidth: geometry.size.width * 0.9)
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    // Message Display
                    if !displayManager.message.isEmpty {
                        Text(displayManager.message)
                            .font(.system(size: min(geometry.size.width * 0.06, 60) * fontScale, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .minimumScaleFactor(0.6)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 30)
                            .frame(maxWidth: geometry.size.width * 0.85)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue.opacity(0.2))
                                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                            // Apply keyframe animator for shake
                            .keyframeAnimator(initialValue: 0, trigger: shakeClicks) { content, value in
                                content
                                    .rotationEffect(.degrees(value), anchor: .bottom)
                                    .offset(x: value * 2)
                            } keyframes: { _ in
                                KeyframeTrack {
                                    SpringKeyframe(0, duration: 0.0)
                                    SpringKeyframe(-5, duration: 0.05)
                                    SpringKeyframe(5, duration: 0.05)
                                    SpringKeyframe(-5, duration: 0.05)
                                    SpringKeyframe(5, duration: 0.05)
                                    SpringKeyframe(-3, duration: 0.05)
                                    SpringKeyframe(3, duration: 0.05)
                                    SpringKeyframe(0, duration: 0.1)
                                }
                            }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
        }
        .onAppear {
            fontScale = FontSizeManager.shared.currentScale
            
            // Immediate initialization
            currentTime = timerManager.settings.remainingSeconds
            
            // Start a more aggressive refresh timer to force updates
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                DispatchQueue.main.async {
                    let newTime = timerManager.settings.remainingSeconds
                    currentTime = newTime
                }
            }
            
            // Also try to observe timer state changes
            NotificationCenter.default.addObserver(
                forName: .timerStateChanged,
                object: nil,
                queue: .main
            ) { _ in
                currentTime = timerManager.settings.remainingSeconds
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
            NotificationCenter.default.removeObserver(self, name: .timerStateChanged, object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .fontScaleChanged)) { notification in
            if let newScale = notification.object as? Double {
                fontScale = newScale
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .messageZap)) { _ in
            triggerShakeAnimation()
        }
    }
    
    private func triggerShakeAnimation() {
        // Only shake if there's a message to shake
        guard !displayManager.message.isEmpty else { return }
        shakeClicks += 1
    }
    
    private func getTimeColor(for seconds: Int) -> Color {
        if seconds > 10 {
            return .primary
        } else if seconds > 0 {
            return .yellow
        } else {
            return .red
        }
    }
}

