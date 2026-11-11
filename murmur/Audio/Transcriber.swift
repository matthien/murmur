import Foundation
import Observation
import os
import Speech
import SwiftData

/// Tracks recordings whose transcript is still being written, app-wide,
/// so a Day screen opened later still knows a transcript is on its way.
@Observable final class TranscriptionQueue {
    private(set) var pending: Set<UUID> = []

    func isPending(_ recording: Recording) -> Bool {
        pending.contains(recording.id)
    }

    /// Transcribes in the background and saves the segments onto the recording.
    func transcribe(_ recording: Recording, in context: ModelContext) {
        pending.insert(recording.id)
        let url = recording.fileURL
        Task {
            let segments = await Transcriber.transcribe(url: url) ?? []
            recording.segments = segments
            try? context.save()
            pending.remove(recording.id)
        }
    }
}

enum Transcriber {
    /// Returns nil if speech recognition is unavailable, not allowed, or fails.
    nonisolated static func transcribe(url: URL) async -> [TranscriptSegment]? {
        guard await authorize(),
              let recognizer = SFSpeechRecognizer(),
              recognizer.isAvailable
        else { return nil }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.addsPunctuation = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        let resumed = OSAllocatedUnfairLock(initialState: false)
        return await withCheckedContinuation { continuation in
            func finish(_ value: [TranscriptSegment]?) {
                let first = resumed.withLock { done in
                    defer { done = true }
                    return !done
                }
                if first { continuation.resume(returning: value) }
            }
            recognizer.recognitionTask(with: request) { result, error in
                _ = recognizer // keep the recognizer alive until the task finishes
                if let result, result.isFinal {
                    finish(segments(from: result.bestTranscription))
                } else if error != nil {
                    finish(nil)
                }
            }
        }
    }

    nonisolated private static func authorize() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        default:
            return false
        }
    }

    /// Groups recognised words into short passages: a new one starts after a
    /// sentence ends or after a pause of more than 1.2 seconds.
    nonisolated private static func segments(from transcription: SFTranscription) -> [TranscriptSegment] {
        var result: [TranscriptSegment] = []
        var words: [String] = []
        var start: TimeInterval = 0
        var lastEnd: TimeInterval = 0

        func flush() {
            guard !words.isEmpty else { return }
            result.append(TranscriptSegment(time: start, text: words.joined(separator: " ")))
            words.removeAll()
        }

        for word in transcription.segments {
            if !words.isEmpty, word.timestamp - lastEnd > 1.2 { flush() }
            if words.isEmpty { start = word.timestamp }
            words.append(word.substring)
            lastEnd = word.timestamp + word.duration
            if let last = word.substring.last, ".?!".contains(last) { flush() }
        }
        flush()
        return result
    }
}
