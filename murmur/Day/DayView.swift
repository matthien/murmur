import SwiftData
import SwiftUI

/// One day's recordings on a hand-drawn timeline. Pushed from the Calendar.
struct DayView: View {
    let day: Date

    @Query private var recordings: [Recording]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(TranscriptionQueue.self) private var transcriptions

    @State private var player = DayPlayer()
    @State private var recorder = AudioRecorder()
    @State private var isStartingRecording = false
    /// The one expanded row, if any.
    @State private var openID: UUID?
    /// Transcript of the open row. Never remembered: hidden on open and on every row change.
    @State private var showsTranscript = false
    @State private var levels: [UUID: [Float]] = [:]

    private static let sidePadding: CGFloat = 28
    private static let rowGap: CGFloat = 26
    private static let expand = Animation.easeOut(duration: 0.25)

    init(day: Date) {
        let calendar = CalendarView.calendar
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        self.day = start
        _recordings = Query(
            filter: #Predicate<Recording> { $0.startedAt >= start && $0.startedAt < end },
            sort: \Recording.startedAt
        )
    }

    private var isToday: Bool { CalendarView.calendar.isDateInToday(day) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            backControl
                // The arrow and month sit 29pt below the safe area, level with
                // Home's date line. The 44pt hit area extends 10pt above them.
                .padding(.top, 29 - 10)

            HStack(alignment: .bottom, spacing: 0) {
                DayTitle(day: day)
                Spacer(minLength: 8)
                DayDrawing(day: day)
            }
            .padding(.horizontal, Self.sidePadding)
            .padding(.top, 14)

            ScrollView {
                timeline
                    .padding(.horizontal, Self.sidePadding)
                    .padding(.bottom, 40)
            }
            .padding(.top, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task(id: openID) { await loadLevelsForOpenRow() }
        .onDisappear {
            player.stop()
            if recorder.isRecording { finishRecording() }
        }
    }

    // MARK: Header

    private var backControl: some View {
        Button { dismiss() } label: {
            LineArt.backArrow
                .stroke(Color.ink, style: .pen(Metrics.strokeLine))
                .frame(width: 24, height: 24)
                // 44pt square hit area; the arrow stays at the side margin.
                .frame(width: Metrics.tapTarget, height: Metrics.tapTarget, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Self.sidePadding)
        .accessibilityLabel("Back to calendar")
    }

    // MARK: Timeline

    private var timeline: some View {
        VStack(alignment: .leading, spacing: Self.rowGap) {
            ForEach(recordings) { recording in
                RecordingRow(
                    recording: recording,
                    isOpen: openID == recording.id,
                    player: player,
                    levels: levels[recording.id],
                    isTranscribing: transcriptions.isPending(recording),
                    playDisabled: recorder.isRecording,
                    showsTranscript: $showsTranscript,
                    onTapPlay: { tapPlay(recording) },
                    onTapTitle: { tapTitle(recording) }
                )
            }

            if isToday {
                recordRow
            }
        }
        .backgroundPreferenceValue(TimelineStopKey.self) { stops in
            TimelineLine(stops: stops)
        }
    }

    private func tapTitle(_ recording: Recording) {
        withAnimation(Self.expand) {
            player.stop()
            showsTranscript = false
            openID = openID == recording.id ? nil : recording.id
        }
    }

    private func tapPlay(_ recording: Recording) {
        if openID == recording.id {
            player.toggle(recording)
        } else {
            withAnimation(Self.expand) {
                player.stop()
                showsTranscript = false
                openID = recording.id
            }
            player.play(recording)
        }
    }

    private func loadLevelsForOpenRow() async {
        guard let id = openID, levels[id] == nil,
              let recording = recordings.first(where: { $0.id == id })
        else { return }
        let url = recording.fileURL
        let computed = await Task.detached(priority: .userInitiated) {
            WaveformLevels.compute(url: url)
        }.value
        if let computed { levels[id] = computed }
    }

    // MARK: Recording (today only)

    private var recordRow: some View {
        HStack(alignment: .center, spacing: 16) {
            Button(action: toggleRecording) {
                ZStack {
                    HandDrawnCircle()
                    Circle()
                        .fill(Color.record)
                        .frame(width: 26, height: 26)
                    if recorder.isRecording {
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .fill(Color.onRecord)
                            .frame(width: 9, height: 9)
                    }
                }
                .frame(width: Metrics.tapTarget, height: Metrics.tapTarget)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isStartingRecording)
            .accessibilityLabel(recorder.isRecording ? "Stop recording" : "Record another for today")
            .timelineStop()

            if recorder.isRecording {
                VStack(alignment: .leading, spacing: 2) {
                    Text("i'm listening…")
                        .font(.listening)
                        .foregroundStyle(Color.ink)
                    TimerRow(startedAt: recorder.startedAt ?? .now)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: recorder.isRecording)
    }

    private func toggleRecording() {
        if recorder.isRecording {
            finishRecording()
        } else {
            player.pause()
            isStartingRecording = true
            Task {
                await recorder.start()
                isStartingRecording = false
            }
        }
    }

    private func finishRecording() {
        guard let take = recorder.stop() else { return }
        let recording = Recording(startedAt: take.startedAt, duration: take.duration, fileName: take.fileName)
        modelContext.insert(recording)
        try? modelContext.save()
        transcriptions.transcribe(recording, in: modelContext)
    }
}

// MARK: - Title

/// "tuesday," / "november 10" in Gaegu Bold 46 with a 0.98 line height.
private struct DayTitle: View {
    let day: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            line(Self.string(day, template: "EEEE") + ",")
            line(Self.string(day, template: "MMMMd"))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).month(.wide).day()))
        .accessibilityAddTraits(.isHeader)
    }

    /// A fixed 0.98 line box. Glyphs may spill past it, as in CSS line-height.
    private func line(_ text: String) -> some View {
        Text(text)
            .font(.dayTitle)
            .foregroundStyle(Color.ink)
            .lineLimit(1)
            .fixedSize()
            .frame(height: 46 * 0.98, alignment: .center)
    }

    private static func string(_ date: Date, template: String) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date).lowercased()
    }
}

/// One of 13 doodles, 84pt, picked by the day's ordinal in the year so the same
/// day always shows the same one. Black line art, shown untinted.
private struct DayDrawing: View {
    let day: Date

    private static let names = [
        "armchair", "bed", "blanket", "book", "bowl", "candle", "cat",
        "mug", "plant", "socks", "sprig", "window-sun", "window-sunrise",
    ]

    var body: some View {
        Image(Self.name(for: day))
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: 84, height: 84)
            .accessibilityHidden(true)
    }

    static func name(for day: Date) -> String {
        let ordinal = CalendarView.calendar.ordinality(of: .day, in: .year, for: day) ?? 1
        return names[ordinal % names.count]
    }
}

// MARK: - Row

private struct RecordingRow: View {
    let recording: Recording
    let isOpen: Bool
    let player: DayPlayer
    let levels: [Float]?
    let isTranscribing: Bool
    let playDisabled: Bool
    @Binding var showsTranscript: Bool
    let onTapPlay: () -> Void
    let onTapTitle: () -> Void

    private var isPlaying: Bool { player.plays(recording) }
    private var title: String { recording.displayTitle }
    private var hasTranscript: Bool { !recording.segments.isEmpty || isTranscribing }

    var body: some View {
        HStack(alignment: .headerCentre, spacing: 16) {
            PlayButton(isPlaying: isPlaying, title: title, action: onTapPlay)
                .disabled(playDisabled)
                .alignmentGuide(.headerCentre) { $0[VerticalAlignment.center] }
                .timelineStop()

            VStack(alignment: .leading, spacing: 0) {
                Button(action: onTapTitle) { header }
                    .buttonStyle(.plain)
                    .alignmentGuide(.headerCentre) { $0[VerticalAlignment.center] }
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(isOpen ? "expanded" : "collapsed")
                    .accessibilityHint(isOpen ? "Hides the player" : "Shows the player")

                if isOpen {
                    expanded
                        .transition(.opacity)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(Self.clockTime(recording.startedAt)) · \(Self.length(recording.duration))")
                .font(.caption13Digits)
                .foregroundStyle(Color.inkMuted)
            Text(title)
                .font(.recordingTitle)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, minHeight: Metrics.tapTarget, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var expanded: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !isPlaying)) { _ in
            let elapsed = player.elapsed(for: recording)
            let total = max(recording.duration, 0.001)

            VStack(alignment: .leading, spacing: 0) {
                WaveformBars(levels: levels, progress: min(elapsed / total, 1))
                    .padding(.top, 10)

                HStack {
                    Text(Self.length(elapsed))
                    Spacer(minLength: 8)
                    Text(Self.length(recording.duration))
                }
                .font(.caption12Digits)
                .foregroundStyle(Color.inkMuted)
                .padding(.top, 6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(Self.length(elapsed)) of \(Self.length(recording.duration))")

                if hasTranscript {
                    transcriptButton
                        .padding(.top, 4)
                    if showsTranscript {
                        transcript(elapsed: elapsed)
                            .padding(.top, 4)
                            .transition(.opacity)
                    }
                }
            }
        }
    }

    private var transcriptButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { showsTranscript.toggle() }
        } label: {
            HStack(spacing: 4) {
                Text(showsTranscript ? "hide transcript" : "show transcript")
                    .font(.textButton)
                    .foregroundStyle(Color.ink)
                LineArt.chevronDown
                    .stroke(Color.ink, style: .pen(Metrics.strokeFine))
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(showsTranscript ? 180 : 0))
                    .accessibilityHidden(true)
            }
            .frame(height: Metrics.tapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(showsTranscript ? "expanded" : "collapsed")
    }

    @ViewBuilder
    private func transcript(elapsed: TimeInterval) -> some View {
        if recording.segments.isEmpty {
            Text("writing out what you said…")
                .font(.transcript)
                .foregroundStyle(Color.inkMuted)
        } else {
            let current = currentSegment(at: elapsed)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(recording.segments.enumerated()), id: \.offset) { index, segment in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(Self.length(segment.time))
                            .font(.caption12Digits)
                            .foregroundStyle(Color.inkMuted)
                            .frame(minWidth: 28, alignment: .leading)
                        Text(segment.text)
                            .font(.transcript)
                            .lineSpacing(5) // about 1.55 line height for a 14pt sans
                            .foregroundStyle(index == current ? Color.ink : Color.inkMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    /// The segment being spoken, once this recording has started playing.
    private func currentSegment(at elapsed: TimeInterval) -> Int? {
        guard player.recordingID == recording.id else { return nil }
        return recording.segments.lastIndex { $0.time <= elapsed }
    }

    private static func clockTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter.string(from: date)
    }

    static func length(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }
}

// MARK: - Pieces

/// The 44pt hand-drawn circle, filled white so it hides the timeline behind it.
private struct HandDrawnCircle: View {
    var body: some View {
        ZStack {
            LineArt.handCircle.fill(Color.paper)
            LineArt.handCircle.stroke(Color.ink, style: .pen(Metrics.strokeLine))
        }
        .frame(width: Metrics.tapTarget, height: Metrics.tapTarget)
    }
}

private struct PlayButton: View {
    let isPlaying: Bool
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                HandDrawnCircle()
                (isPlaying ? LineArt.pause : LineArt.play)
                    .stroke(Color.ink, style: .pen(Metrics.strokeLine))
            }
            .frame(width: Metrics.tapTarget, height: Metrics.tapTarget)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Pause \(title)" : "Play \(title)")
    }
}

/// 40 bars, 2pt wide, spread across the row; played bars in ink.
private struct WaveformBars: View {
    let levels: [Float]?
    let progress: Double

    private static let count = 40

    var body: some View {
        let played = Int(progress * Double(Self.count))
        HStack(alignment: .center, spacing: 0) {
            ForEach(0..<Self.count, id: \.self) { index in
                if index > 0 { Spacer(minLength: 0) }
                Capsule()
                    .fill(index < played ? Color.ink : Color.waveIdle)
                    .frame(width: 2, height: max(2, CGFloat(level(index)) * 40))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .accessibilityHidden(true)
    }

    private func level(_ index: Int) -> Float {
        guard let levels, levels.indices.contains(index) else { return 0 }
        return levels[index]
    }
}

// MARK: - Timeline line

private extension VerticalAlignment {
    private enum HeaderCentre: AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat { d[VerticalAlignment.center] }
    }
    /// Centres each play button on its row's time and title.
    static let headerCentre = VerticalAlignment(HeaderCentre.self)
}

/// The frames of the timeline's buttons, top to bottom.
private nonisolated struct TimelineStopKey: PreferenceKey {
    static let defaultValue: [Anchor<CGRect>] = []
    static func reduce(value: inout [Anchor<CGRect>], nextValue: () -> [Anchor<CGRect>]) {
        value.append(contentsOf: nextValue())
    }
}

private extension View {
    func timelineStop() -> some View {
        anchorPreference(key: TimelineStopKey.self, value: .bounds) { [$0] }
    }
}

/// Runs through the centre of every button: from just below the top of the
/// first to the centre of the last. The buttons' white fill hides it inside them.
private struct TimelineLine: View {
    let stops: [Anchor<CGRect>]

    var body: some View {
        GeometryReader { geo in
            if let first = stops.first, let last = stops.last {
                let top = geo[first].minY + 4
                let bottom = geo[last].midY
                if bottom > top {
                    TimelineLineShape()
                        .stroke(Color.ink, style: .pen(Metrics.strokeFine))
                        .frame(width: 8, height: bottom - top)
                        .position(x: geo[first].midX, y: (top + bottom) / 2)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        DayView(day: .now)
    }
    .modelContainer(for: Recording.self, inMemory: true)
    .environment(TranscriptionQueue())
}
