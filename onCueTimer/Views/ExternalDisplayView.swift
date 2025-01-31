import SwiftUI

struct ExternalDisplayView: View {
    let timerManager: TimerManager
    @ObservedObject var displayManager: DisplayManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Timer Display - matching the exact style from ContentView
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                    
                    VStack {
                        Spacer()
                            .frame(height: 50)
                        
                        TimeDisplay(seconds: timerManager.settings.remainingSeconds, timerManager: timerManager)
                            .frame(maxWidth: .infinity)
                            .scaleEffect(2.3)  // Make the timer 30% larger
                        
                        Spacer()
                        
                        if !displayManager.message.isEmpty {
                            Text(displayManager.message)
                                .font(.system(size: 60, weight: .bold))
                                .minimumScaleFactor(0.5)
                                .lineLimit(3)
                                .multilineTextAlignment(.center)
                                .padding(40)
                                .frame(maxWidth: geometry.size.width * 0.8)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(16)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .padding(40)
            }
        }
    }
}
