import Foundation
import SwiftData

@Model final class Recording {
    var id: UUID
    var startedAt: Date        // also determines which calendar day it belongs to
    var duration: TimeInterval
    var fileName: String       // relative to Documents
    var title: String?         // short handwritten title, optional
    var segments: [TranscriptSegment]  // empty until transcribed

    init(
        id: UUID = UUID(),
        startedAt: Date,
        duration: TimeInterval,
        fileName: String,
        title: String? = nil,
        segments: [TranscriptSegment] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.duration = duration
        self.fileName = fileName
        self.title = title
        self.segments = segments
    }

    var fileURL: URL {
        URL.documentsDirectory.appending(path: fileName)
    }

    /// The title, else the first five words of the transcript, else "new recording".
    /// Always lowercase, since it is written by hand.
    var displayTitle: String {
        if let title = title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title.lowercased()
        }
        let words = segments
            .map(\.text)
            .joined(separator: " ")
            .split(whereSeparator: \.isWhitespace)
            .prefix(5)
        let start = words.joined(separator: " ")
            .trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
        return start.isEmpty ? "new recording" : start.lowercased()
    }
}

struct TranscriptSegment: Codable, Hashable {
    var time: TimeInterval     // offset from start of recording
    var text: String
}
