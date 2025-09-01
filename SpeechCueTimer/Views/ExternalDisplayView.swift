import SwiftUI

extension Notification.Name {
    static let fontScaleChanged = Notification.Name("fontScaleChanged")
    static let messageZap = Notification.Name("messageZap")
}

struct ExternalDisplayView: View {
    @State var timerManager: TimerManager
    @State var displayManager: DisplayManager
    @State private var fontScale: Double = 1.0
    @State private var isShaking: Bool = false
    
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
                        Text(timerManager.settings.formatTime(timerManager.settings.remainingSeconds))
                            .font(.system(size: min(geometry.size.width * 0.12, 120) * fontScale, weight: .bold, design: .monospaced))
                            .foregroundColor(timerManager.settings.getTimeColor())
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
                            .font(.system(size: min(geometry.size.width * 0.06, 60), weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .minimumScaleFactor(0.6)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 30)
                            .frame(maxWidth: geometry.size.width * 0.85)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isShaking ? Color.orange.opacity(0.3) : Color.blue.opacity(0.2))
                                    .stroke(isShaking ? Color.orange.opacity(0.6) : Color.blue.opacity(0.4), lineWidth: isShaking ? 2 : 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                            .scaleEffect(isShaking ? 1.05 : 1.0)
                            .offset(x: isShaking ? CGFloat.random(in: -8...8) : 0, 
                                   y: isShaking ? CGFloat.random(in: -8...8) : 0)
                            .animation(.easeInOut(duration: 0.1).repeatCount(isShaking ? 8 : 0, autoreverses: true), value: isShaking)
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
        }
        .onAppear {
            fontScale = FontSizeManager.shared.currentScale
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
        
        // Start shaking
        isShaking = true
        
        // Stop shaking after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isShaking = false
        }
    }
}
