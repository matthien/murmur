import AVFoundation
import Observation

/// Records a single take to the Documents directory.
@Observable final class AudioRecorder {
    struct Take {
        let fileName: String
        let startedAt: Date
        let duration: TimeInterval
    }

    private(set) var isRecording = false
    private(set) var startedAt: Date?

    private var recorder: AVAudioRecorder?
    private var fileName: String?

    /// Asks for microphone access (only prompts the first time) and starts recording.
    /// Returns false if permission was denied or recording could not start.
    @discardableResult
    func start() async -> Bool {
        guard !isRecording else { return true }
        guard await AVAudioApplication.requestRecordPermission() else { return false }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)

            let now = Date()
            let name = Self.fileName(for: now)
            let url = URL.documentsDirectory.appending(path: name)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            guard recorder.record() else { return false }

            self.recorder = recorder
            self.fileName = name
            self.startedAt = now
            self.isRecording = true
            return true
        } catch {
            return false
        }
    }

    /// Stops recording and returns the finished take, if any.
    func stop() -> Take? {
        guard let recorder, let fileName, let startedAt else { return nil }
        let duration = recorder.currentTime
        recorder.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        self.recorder = nil
        self.fileName = nil
        self.startedAt = nil
        self.isRecording = false
        return Take(fileName: fileName, startedAt: startedAt, duration: duration)
    }

    private static func fileName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss"
        return "\(formatter.string(from: date))-\(UUID().uuidString.prefix(8)).m4a"
    }
}
