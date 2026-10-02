import Foundation
import AVFoundation

final class BackgroundAudioManager {
    static let shared = BackgroundAudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var isPlayingSilentAudio = false
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func startSilentAudio() {
        guard !isPlayingSilentAudio else { return }
        
        // Create a silent audio file programmatically
        if let silentAudioURL = createSilentAudioFile() {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: silentAudioURL)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.volume = 0.0 // Silent
                audioPlayer?.play()
                isPlayingSilentAudio = true
            } catch {
                print("Failed to play silent audio: \(error)")
            }
        }
    }
    
    func stopSilentAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlayingSilentAudio = false
    }
    
    private func createSilentAudioFile() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("silent.wav")
        
        // Check if file already exists
        if FileManager.default.fileExists(atPath: audioURL.path) {
            return audioURL
        }
        
        // Create a 1-second silent audio file
        let sampleRate: Double = 44100
        let channels = 1
        let frames = Int(sampleRate)
        
        var audioFormat = AudioStreamBasicDescription()
        audioFormat.mSampleRate = sampleRate
        audioFormat.mFormatID = kAudioFormatLinearPCM
        audioFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger
        audioFormat.mChannelsPerFrame = UInt32(channels)
        audioFormat.mBitsPerChannel = 16
        audioFormat.mBytesPerFrame = audioFormat.mChannelsPerFrame * audioFormat.mBitsPerChannel / 8
        audioFormat.mFramesPerPacket = 1
        audioFormat.mBytesPerPacket = audioFormat.mBytesPerFrame * audioFormat.mFramesPerPacket
        
        // Create silent audio data
        let dataSize = frames * Int(audioFormat.mBytesPerFrame)
        let audioData = Data(count: dataSize) // All zeros = silence
        
        // Write WAV file
        do {
            var wavData = Data()
            
            // WAV header
            wavData.append("RIFF".data(using: .ascii)!)
            var fileSize = UInt32(36 + dataSize)
            wavData.append(Data(bytes: &fileSize, count: 4))
            wavData.append("WAVE".data(using: .ascii)!)
            
            // Format chunk
            wavData.append("fmt ".data(using: .ascii)!)
            var formatChunkSize = UInt32(16)
            wavData.append(Data(bytes: &formatChunkSize, count: 4))
            var audioFormatType = UInt16(1) // PCM
            wavData.append(Data(bytes: &audioFormatType, count: 2))
            var numChannels = UInt16(channels)
            wavData.append(Data(bytes: &numChannels, count: 2))
            var sampleRateInt = UInt32(sampleRate)
            wavData.append(Data(bytes: &sampleRateInt, count: 4))
            var byteRate = UInt32(sampleRate * Double(audioFormat.mBytesPerFrame))
            wavData.append(Data(bytes: &byteRate, count: 4))
            var blockAlign = UInt16(audioFormat.mBytesPerFrame)
            wavData.append(Data(bytes: &blockAlign, count: 2))
            var bitsPerSample = UInt16(16)
            wavData.append(Data(bytes: &bitsPerSample, count: 2))
            
            // Data chunk
            wavData.append("data".data(using: .ascii)!)
            var dataSizeInt = UInt32(dataSize)
            wavData.append(Data(bytes: &dataSizeInt, count: 4))
            wavData.append(audioData)
            
            try wavData.write(to: audioURL)
            return audioURL
        } catch {
            print("Failed to create silent audio file: \(error)")
            return nil
        }
    }
}
