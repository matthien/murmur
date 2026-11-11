# Voice Diary: design brief for the iOS build

This file describes the app's design so it can be built in SwiftUI. Treat the values here as the source of truth. Where something is not specified, keep it minimal and ask before inventing UI.

## 1. What the app is

A voice memo app that files each recording under the day it was made.

- **Home:** record your voice immediately.
- **Calendar:** a month view. Days with a recording are marked. Tapping one opens that day.
- **Day:** play that day's recording(s) and read the transcript.

Home and Calendar sit side by side. A horizontal swipe moves between them; two text labels at the bottom do the same on tap.

The look: a blank sheet of paper, quick handwriting, a few wobbly pen lines, and one red dot.

## 2. Suggested build order

1. Home screen: layout, record button, record and save a file for today.
2. Calendar screen: month grid, dots on recorded days, today circled.
3. Swipe between Home and Calendar, with the bottom labels and sliding underline.
4. Day screen: playback.
5. Transcripts (on-device speech recognition).

Build and run after each step. Do not start the next step until the current one compiles and works.

## 3. Tech

- SwiftUI, iOS 17 or later.
- AVFoundation for recording and playback (`AVAudioRecorder`, `AVAudioPlayer`, `AVAudioSession` category `.playAndRecord`).
- Speech framework for transcription, on-device where available.
- SwiftData for recording metadata; audio files in the app's Documents directory.
- Info.plist keys required: `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`, and `UIAppFonts` listing the bundled font files.

Suggested model:

```swift
@Model final class Recording {
    var id: UUID
    var startedAt: Date        // also determines which calendar day it belongs to
    var duration: TimeInterval
    var fileName: String       // relative to Documents
    var title: String?         // short handwritten title, optional
    var segments: [TranscriptSegment]  // empty until transcribed
}

struct TranscriptSegment: Codable {
    var time: TimeInterval     // offset from start of recording
    var text: String
}
```

## 4. Design tokens

### Colour

| Name | Hex | Use |
| --- | --- | --- |
| paper | #FFFFFF | Background of every screen. No cards, panels or tints. |
| ink | #111111 | Titles, all line art, day numbers, dots, current tab label |
| inkMuted | #6E6E6E | Date line, year, weekday letters, inactive tab label, captions |
| inkFaint | #767676 | Day numbers for days still to come |
| record | #E5322D | The record button. Nowhere else. |
| onRecord | #FFFFFF | The stop square on the record button |

Light appearance only. Force light mode (`.preferredColorScheme(.light)`); no dark theme has been designed.

### Fonts

- **Gaegu** (handwriting), weights Regular 400 and Bold 700. Open licence, from Google Fonts. Bundle `Gaegu-Regular.ttf` and `Gaegu-Bold.ttf`.
- **Inter** (details), weights 400, 500, 700. Bundle it, or use the system font (SF Pro) if bundling is a problem; the difference is acceptable.

Design sizes are fixed points. Do not scale the two 46pt handwritten titles with Dynamic Type; the small sans text may scale.

### Type styles

| Style | Font | Size / weight | Extra | Colour |
| --- | --- | --- | --- | --- |
| title | Gaegu | 46 / Bold | line height 1.1, tracking 1pt, about 6pt extra space between words | ink |
| month | Gaegu | 46 / Bold | line height 1.0 | ink |
| date | Gaegu | 15 / Regular | line height 1.2, tracking 1pt | inkMuted |
| tab | Inter | 14 / Medium | | ink (current) or inkMuted |
| day | Inter | 16 / Regular | monospaced digits | ink or inkFaint |
| dayToday | Inter | 16 / Bold | monospaced digits | ink |
| caption | Inter | 13 / Regular | | inkMuted |
| timer | Inter | 13 / Medium | monospaced digits | ink |
| weekday | Inter | 11 / Medium | | inkMuted |

All handwritten text is lowercase.

### Sizes and spacing (points)

| Name | Value | Use |
| --- | --- | --- |
| tapTarget | 44 | Minimum tappable size |
| recordButton | 80 | Diameter of the red button |
| stopMark | 24 | Stop square on the button, corner radius 6 |
| dayCell | 60 | Height of a calendar day cell |
| dayDot | 5 | Dot under a recorded day |
| gutter | 16 | Left and right margin on every screen, tab label side inset |
| insetBottom | 36 | Bottom edge to the tab labels |
| strokeLine | 2 | Full-size line art |
| strokeFine | 1.8 | Small line art (today circle, divider) |

## 5. Line art

All line art is a single ink stroke, no fill, round caps and joins. The shapes are deliberately wobbly, and closed shapes overshoot their start point slightly. Convert each SVG path below into a SwiftUI `Shape` (or one generic `SVGPathShape` that scales a path from its view box into the frame) and stroke it with `StrokeStyle(lineWidth:lineCap:.round, lineJoin:.round)`. Keep the stroke width constant when the shape is scaled.

| Name | View box | Path | Drawn at |
| --- | --- | --- | --- |
| Record ring | 220 x 160 | `M110 12 C150 10 179 40 178 80 C177 121 148 149 108 148 C68 147 41 119 42 79 C43 41 72 13 116 13` | 170 x 124, stroke 2, centred on the button |
| Sound lines (4 paths) | 220 x 160 | `M26 58 C18 70 18 90 26 102` / `M12 48 C3 66 3 94 12 112` / `M194 58 C202 70 202 90 194 102` / `M208 48 C217 66 217 94 208 112` | Same box as the ring, recording only |
| Today circle | 44 x 40 | `M22 4 C34 3 41 11 40 21 C39 31 30 37 20 36 C9 35 3 27 5 17 C7 9 14 4 26 5` | 40 x 38, stroke 1.8, centred on the number |
| Squiggle divider | 334 x 12 | `M2 6 C60 2 110 9 170 5 C230 1 280 8 332 4` | Full content width, stroke 1.8 |
| Tab underline | 64 x 10 | `M2 6 C12 2 20 9 32 5 C44 1 52 8 62 4` | 64 x 10, stroke 2 |
| Chevron left | 24 x 24 | `M15 5 C12 7 10 10 8 12 C10 14 13 17 15 20` | 22 x 22, stroke 2 |
| Chevron right | 24 x 24 | `M9 5 C12 7 14 10 16 12 C14 14 11 17 9 20` | 22 x 22, stroke 2 |

The ring's circle is centred at (110, 80) in its view box with a radius of about 68, so at 170 x 124 it is about 105pt across and its centre is the centre of the frame.

## 6. Screens

The design frame is 390 x 844pt (iPhone 14) measured from the very top of the screen, with no status bar drawn. Do not hard-code absolute positions. Anchor to safe areas and edges so it adapts to other iPhones:

- Top measurements: subtract the top safe area (47pt on the design device) and pad from the safe area.
- The record button and tab labels anchor to the bottom.

### Home

Top to bottom:

1. **Date line**, style `date`: today's date written out in lowercase, for example "november 10, 2026". 76pt from the top of the screen (about 29pt below the safe area), at the left margin (`gutter`).
2. **Title**, style `title`, 8pt below the date line, left aligned at the margin.
   - Idle: `how was today?`
   - Recording: `i'm listening…`
3. Empty space. Nothing else in the upper part of the screen.
4. **Record button** inside the record ring, centred horizontally. In the design its centre is 662pt from the top of an 844pt screen, which is 182pt up from the bottom edge. Anchor it from the bottom.
5. **Timer**, recording only, centred, directly above the ring (10pt gap). Just the elapsed time in `timer` (format `0:12`), no dot or caption. Its space is reserved even when idle (it is only hidden), so the button never moves when recording starts.

Record button states:

| State | Button | Around it | Accessibility label |
| --- | --- | --- | --- |
| Idle | Plain red disc, no icon | Ring | "Start recording" |
| Recording | Red disc with a white 24pt rounded square | Ring, sound lines, timer | "Stop recording" |

There is no caption under the button when idle.

Behaviour: tap to start, tap to stop. On stop, save the audio file and a `Recording` for today, then return to idle. Ask for microphone permission on the first tap, not on launch.

### Calendar

Side margin `gutter` (16pt), same as Home. The header mirrors Home's date line and title so they sit in the same place when swiping. Top to bottom:

1. **Year**, style `date` (handwriting, inkMuted), in the same position as Home's date line (about 29pt below the safe area). Just the year ("2026").
2. **Month name**, style `month`, lowercase ("november"), 8pt below the year. On the same row, pushed to the right: previous and next month chevrons, each in a 44pt button, 4pt apart. The pair overhangs the right padding by 10pt so the arrow drawings line up with the grid edge.
3. **Squiggle divider**, 18pt below the month row, full content width.
4. **Weekday letters** S M T W T F S, style `weekday`, 24pt below the divider, seven equal columns, centred. Weeks start on Sunday.
5. **Day grid**, 6pt below the letters: seven equal columns, 60pt rows, 4pt between rows.

Day cell states:

| State | Number | Marks | Tappable |
| --- | --- | --- | --- |
| No recording | ink, Regular | none | no |
| Recorded | ink, Regular | 5pt ink dot centred, 3pt above the cell's bottom edge | yes, opens the Day screen |
| Today | ink, Bold | today circle around the number, plus the dot if it has a recording | yes if it has a recording |
| Upcoming | inkFaint, Regular | none | no |

State is never shown with colour alone, and the red is never used in the calendar.

Accessibility label for a tappable day: "November 10, today, has recordings" (drop "today" when it is not).

### Bottom labels (shown on both Home and Calendar)

Two text buttons, `record` and `calendar`, style `tab`, each taking half the width between the side margins (`gutter`), 44pt tall, sitting 36pt above the bottom edge (respect the bottom safe area). The current one is ink, the other inkMuted. A 64 x 10 tab underline squiggle is centred under the current label.

This bar stays fixed while the two screens slide behind it. No background, border or icons.

### Swipe between Home and Calendar

- Home is on the left, Calendar on the right. A horizontal drag slides both; the content follows the finger.
- While dragging, the underline moves with the finger: it travels the distance between the two labels as the content travels one screen width. Label colours swap at the halfway point.
- On release: a drag of more than about 48pt toward the other screen commits; otherwise it settles on whichever screen is more than half visible. Settle duration about 0.32s with a strong ease-out (cubic-bezier 0.22, 1, 0.36, 1).
- Tapping a label animates to that screen the same way.
- Vertical drags must not trigger the swipe.

A horizontal paging `ScrollView` with a scroll position binding, or a `DragGesture` driving an offset, both work. The underline needs the continuous scroll progress, which a default `TabView` page style does not expose.

### Day

Designed but less settled than the other two; build it last and keep it simple.

- Back control top left: a hand-drawn left arrow and "november", returning to the Calendar.
- Date as a two-line handwritten title: "tuesday," / "november 10" (Gaegu Bold 46).
- A caption line: "2 recordings · 6 min 41 sec".
- Squiggle divider.
- If the day has more than one recording, a row of pill buttons, one per recording, labelled with time and length ("8:12 am · 4:02"). Pills have a 1.5pt ink outline; the selected one is filled ink with white text.
- A short handwritten title for the selected recording (Gaegu Regular 28).
- Player: a play/pause button drawn as a hand-drawn circle with a triangle or two bars, then a waveform of thin vertical bars (played part ink, the rest light grey #C9C9C9), with elapsed and total time under it in 12pt inkMuted.
- "TRANSCRIPT" label (11pt Medium, letter spaced, inkMuted), then the transcript as timestamped paragraphs (15pt, line height 1.55). The paragraph currently being spoken is ink; the others are inkMuted.

## 7. Rules that keep it on style

- Mostly white. One subject per screen. If a screen feels full, remove something.
- Handwriting for the few words with feeling (prompt, month, day title). Sans for everything functional. Never swap them.
- Red means recording, and only that.
- No shadows, gradients, cards, borders around sections, or SF Symbols. If a new icon is needed, draw it as a wobbly single-line path in the same hand.
- No emoji, no exclamation marks, lowercase labels.

## 8. Not in scope yet

Onboarding, settings, search, sharing, iCloud sync, editing or deleting recordings, and a dark theme have not been designed. Do not add them without asking.
