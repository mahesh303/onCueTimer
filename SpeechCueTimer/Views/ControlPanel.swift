import SwiftUI

struct ControlPanel: View {
    let timerManager: TimerManager

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .trailing, spacing: 12) {
                Image("SCTlogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50)
                    .cornerRadius(6.5)
                    .padding()
                Spacer().frame(height: 44)

                // Time presets — labelled "Time N" to distinguish from message presets
                // in the message panel which are labelled "Preset N".
                ForEach(1...4, id: \.self) { number in
                    HStack(spacing: 4) {
                        Text("Time \(number)")
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

                // +10 / -10 buttons unified with .buttonStyle(.bordered) to match
                // the rest of the app's button language (was using raw .background/.overlay).
                HStack(spacing: 10) {
                    Button("-10") {
                        timerManager.subtractTime(seconds: 10)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .frame(width: 70, height: 40)

                    Button("+10") {
                        timerManager.addTime(seconds: 10)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .frame(width: 70, height: 40)
                }
                .padding(.top, 20)

                Spacer()
            }
            .frame(width: min(120, geometry.size.width * 0.9))
            .padding(.horizontal, 4)
        }
    }
}

