import Foundation
import AVFoundation

class AudioManager: ObservableObject {
    var audioPlayers: [DeviceType: AVAudioPlayer] = [:]
    @Published var isPlaying = false
    private var currentPlayingDevice: DeviceType?
    
    init() {
        setupAudioSession()
        prepareAudio()
    }
    
    private func setupAudioSession() {
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func prepareAudio() {
        let musicFiles: [DeviceType: String] = [
            .iPad: "funkbreakbeat",
            .macbookM1: "gvidongvidon",
            .macbookM3: "rhythmwalkfunk"
        ]
        
        for (deviceType, filename) in musicFiles {
            if let url = Bundle.main.url(forResource: filename, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.numberOfLoops = -1 // Loop indefinitely
                    player.prepareToPlay()
                    audioPlayers[deviceType] = player
                } catch {
                    print("Failed to initialize audio player for \(filename): \(error)")
                }
            } else {
                print("Could not find \(filename).mp3 in bundle")
            }
        }
    }
    
    func play(for deviceType: DeviceType) {
        // If already playing the same device's music, do nothing
        if isPlaying, currentPlayingDevice == deviceType {
            return
        }
        
        // Pause any currently playing music
        pause()
        
        guard let player = audioPlayers[deviceType] else { return }
        player.play()
        currentPlayingDevice = deviceType
        DispatchQueue.main.async {
            self.isPlaying = true
        }
    }
    
    func pause() {
        guard let currentDevice = currentPlayingDevice, let player = audioPlayers[currentDevice], player.isPlaying else { return }
        player.pause()
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}
