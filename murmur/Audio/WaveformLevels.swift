import Accelerate
import AVFoundation

enum WaveformLevels {
    /// Splits the file into `count` equal slices and returns each slice's RMS,
    /// scaled so the loudest slice is 1. Slow for long files: call off the main actor.
    nonisolated static func compute(url: URL, count: Int = 40) -> [Float]? {
        guard let file = try? AVAudioFile(forReading: url), file.length > 0 else { return nil }

        let perSlice = AVAudioFrameCount(max(1, file.length / AVAudioFramePosition(count)))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: perSlice) else {
            return nil
        }

        var levels: [Float] = []
        levels.reserveCapacity(count)
        for _ in 0..<count {
            var rms: Float = 0
            if (try? file.read(into: buffer, frameCount: perSlice)) != nil,
               let samples = buffer.floatChannelData?[0],
               buffer.frameLength > 0 {
                vDSP_rmsqv(samples, 1, &rms, vDSP_Length(buffer.frameLength))
            }
            levels.append(rms)
        }

        guard let peak = levels.max(), peak > 0 else { return levels }
        return levels.map { $0 / peak }
    }
}
