import SwiftUI

extension Notification.Name {
    static let fontScaleChanged = Notification.Name("fontScaleChanged")
}

struct ExternalDisplayView: View {
    let timerManager: TimerManager
    let displayManager: DisplayManager
    @State private var currentTime: Int = 0
    @State private var fontScale: Double = 1.0
    
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
                                    .fill(Color.blue.opacity(0.2))
                                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
        }
        .onAppear {
            currentTime = timerManager.settings.remainingSeconds
            fontScale = FontSizeManager.shared.currentScale
        }
        .onChange(of: timerManager.settings.remainingSeconds) { oldValue, newValue in
            currentTime = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .fontScaleChanged)) { notification in
            if let newScale = notification.object as? Double {
                fontScale = newScale
            }
        }
    }
}
