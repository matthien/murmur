import AVFoundation
import Observation

/// Plays one recording at a time on the Day screen.
@Observable final class DayPlayer: NSObject, AVAudioPlayerDelegate {
    /// The recording currently loaded, playing or paused.
    private(set) var recordingID: UUID?
    private(set) var isPlaying = false
    /// True after a recording plays to the end; the next play starts from 0.
    private(set) var reachedEnd = false

    @ObservationIgnored private var player: AVAudioPlayer?

    /// Not observed: read it inside a `TimelineView` while playing.
    var currentTime: TimeInterval {
        guard let player else { return 0 }
        return reachedEnd ? player.duration : player.currentTime
    }

    func plays(_ recording: Recording) -> Bool {
        isPlaying && recordingID == recording.id
    }

    func elapsed(for recording: Recording) -> TimeInterval {
        recordingID == recording.id ? currentTime : 0
    }

    func toggle(_ recording: Recording) {
        if plays(recording) { pause() } else { play(recording) }
    }

    func play(_ recording: Recording) {
        if recordingID != recording.id || player == nil {
            stop()
            guard let player = try? AVAudioPlayer(contentsOf: recording.fileURL) else { return }
            player.delegate = self
            player.prepareToPlay()
            self.player = player
            recordingID = recording.id
        }
        guard let player else { return }

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try? session.setActive(true)

        if reachedEnd {
            player.currentTime = 0
            reachedEnd = false
        }
        isPlaying = player.play()
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func stop() {
        player?.stop()
        player = nil
        recordingID = nil
        isPlaying = false
        reachedEnd = false
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let finished = ObjectIdentifier(player)
        Task { @MainActor in
            guard let current = self.player, ObjectIdentifier(current) == finished else { return }
            self.isPlaying = false
            self.reachedEnd = true
        }
    }
}
