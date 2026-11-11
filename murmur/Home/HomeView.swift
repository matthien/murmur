import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var recorder = AudioRecorder()
    @State private var isStarting = false

    private var isRecording: Bool { recorder.isRecording }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 8) {
                Text(Self.todayString())
                    .font(.dateLine)
                    .tracking(1)
                    .foregroundStyle(Color.inkMuted)

                HandwrittenTitle(isRecording ? "i'm listening…" : "how was today?")
            }
            .padding(.top, 29)
            .padding(.horizontal, Metrics.gutter)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            recordControl
                // Button centre sits 182pt above the screen's bottom edge on the
                // design device (34pt bottom safe area): 148pt above the safe area,
                // minus half the 124pt ring frame.
                .padding(.bottom, 148 - 62)
        }
    }

    private var recordControl: some View {
        VStack(spacing: 10) {
            // Always laid out so the button never shifts; hidden until recording.
            TimerRow(startedAt: recorder.startedAt ?? .now)
                .fixedSize()
                .opacity(isRecording ? 1 : 0)
                .accessibilityHidden(!isRecording)

            recordButton
        }
        .animation(.easeOut(duration: 0.2), value: isRecording)
    }

    private var recordButton: some View {
        ZStack {
            LineArt.recordRing
                .stroke(Color.ink, style: .pen(Metrics.strokeLine))

            if isRecording {
                LineArt.soundLines
                    .stroke(Color.ink, style: .pen(Metrics.strokeLine))
                    .transition(.opacity)
            }

            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .fill(Color.record)
                    if isRecording {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.onRecord)
                            .frame(width: Metrics.stopMark, height: Metrics.stopMark)
                    }
                }
                .frame(width: Metrics.recordButton, height: Metrics.recordButton)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isStarting)
            .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        }
        .frame(width: 170, height: 124)
    }

    private func toggleRecording() {
        if isRecording {
            guard let take = recorder.stop() else { return }
            let recording = Recording(
                startedAt: take.startedAt,
                duration: take.duration,
                fileName: take.fileName
            )
            modelContext.insert(recording)
            try? modelContext.save()
        } else {
            isStarting = true
            Task {
                await recorder.start()
                isStarting = false
            }
        }
    }

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMdyyyy")
        return formatter.string(from: .now).lowercased()
    }
}

/// Gaegu Bold 46 with 1pt tracking and about 6pt extra space between words.
private struct HandwrittenTitle: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(styled)
            .font(.title)
            .lineSpacing(46 * 0.1)
            .foregroundStyle(Color.ink)
            .accessibilityLabel(text)
    }

    private var styled: AttributedString {
        var result = AttributedString()
        for (index, word) in text.split(separator: " ").enumerated() {
            if index > 0 {
                var space = AttributedString(" ")
                space.tracking = 1 + 6
                result += space
            }
            var piece = AttributedString(String(word))
            piece.tracking = 1
            result += piece
        }
        return result
    }
}

private struct TimerRow: View {
    let startedAt: Date

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 0.5)) { context in
            Text(Self.format(context.date.timeIntervalSince(startedAt)))
                .font(.timer)
                .foregroundStyle(Color.ink)
        }
    }

    private static func format(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Recording.self, inMemory: true)
}
