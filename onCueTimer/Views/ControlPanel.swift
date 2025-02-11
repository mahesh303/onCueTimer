import SwiftUI

struct ControlPanel: View {
    let timerManager: TimerManager
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .trailing, spacing: 12) {
                Image("OCTlogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50)
                    .padding()
                Spacer().frame(height: 44)
                
               
                
                // Only Presets remain
                ForEach(1...4, id: \.self) { number in
                    HStack(spacing: 4) {
                        Text("Preset \(number)")
                            .frame(width: 45, alignment: .trailing)
                            .font(.system(size: 10))
                        
                        Button {
                            if !timerManager.settings.isRunning {
                                timerManager.loadPreset(number: number)
                            }
                        } label: {
                            Text(timerManager.getPresetTimeString(number: number) ?? "00:00")
                                .frame(width: 50)
                                .contentShape(Rectangle())
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.bordered)
                        .tint(.yellow)
                        .disabled(timerManager.isPresetActive(number))
                        .opacity(timerManager.isPresetActive(number) ? 0.6 : 1.0)
                        .onTapGesture(count: 2) {
                            if !timerManager.isPresetActive(number) {
                                timerManager.savePreset(number: number)
                            }
                        }
                    }
                }
                
                // Add the -10 and +10 buttons
                HStack(spacing: 10) {
                    Button(action: {
                        timerManager.subtractTime(seconds: 10)
                    }) {
                        Text("-10")
                            .frame(width: 70, height: 40)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                    
                    Button(action: {
                        timerManager.addTime(seconds: 10)
                    }) {
                        Text("+10")
                            //.font(.title.bold())
                            .frame(width: 70, height: 40)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                    }
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .frame(width: min(120, geometry.size.width * 0.9))
            .padding(.horizontal, 4)
        }
    }
} 
