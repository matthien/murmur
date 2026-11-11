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

Pushed from the Calendar when a day with recordings is tapped. Swipe back, or the back control, returns to the Calendar. Swipe left and right to move between days that have recordings (earlier days to the left). Side padding 28pt; anchored to the top safe area.

1. **Back control**, level with Home's date line (arrow 29pt below the top safe area, 76pt from the top of the design frame): hand-drawn left arrow only, no text. 44pt square hit area. Accessibility label "Back to calendar".
2. **Title**, 14pt below: Gaegu Bold 46, line height 0.98, lowercase, two lines: "tuesday," / "november 10". No summary line.
   - To its right, at the right margin and bottom-aligned with it: one 84pt drawing from the asset catalog (armchair, bed, blanket, book, bowl, candle, cat, mug, plant, socks, sprig, window-sun, window-sunrise), chosen by the day's ordinal in the year modulo 13, so a day always shows the same one. Black line art, never tinted.
3. **Timeline**, 28pt below the title, in a vertical scroll view.

**Timeline.** One wobbly vertical ink line, 1.8pt, round caps, through the centre of the play buttons (50pt from the left edge), starting just below the top of the first play button. One row per recording, oldest first, 26pt apart:

- Left: a 44pt play button, the hand-drawn circle with a play triangle (pause bars while playing), filled white so it covers the line.
- Right, 16pt gap: time and length in Inter 13 Regular, inkMuted, monospaced digits ("8:12 am · 4:02"); 4pt below, the title in Gaegu Bold 28, lowercase.

**Progressive disclosure.**

- At rest a row shows only the play button, the time line and the title.
- Tapping the title area expands the row: a waveform (40 bars, 2pt wide, 40pt tall row, played bars ink, the rest #C9C9C9) 10pt below the title; elapsed time left and total right under it (Inter 12, inkMuted); then a "show transcript" text button (Inter 13 Medium, ink, small hand-drawn chevron, 44pt tall). Tapping the title again collapses it.
- Play on a collapsed row expands it and starts playing. Play on the open row toggles play and pause. At the end, play restarts from 0.
- Only one row is open at a time. Collapsing or switching rows stops playback.
- "show transcript" reveals the transcript and becomes "hide transcript" with the chevron rotated 180 degrees. Each segment: timestamp (Inter 12, inkMuted, 28pt column) and text (Inter 14, line height 1.55), 12pt apart. The segment being spoken is ink, the others inkMuted.
- The transcript is always hidden when the screen opens. It is not remembered.

**Adding a recording (today only).** If the day is today, the line continues 26pt past the last row to a record button: the same 44pt hand-drawn circle with a 26pt red disc inside, no label, accessibility label "Record another for today". Tap to record in place: the disc shows a 9pt white rounded square, and to the right "i'm listening…" (Gaegu Regular 24) with the elapsed time under it (`timer` style). Tap again to stop: the recording is saved and added as a new row above the record button, and transcribed in the background; until that finishes its transcript reads "writing out what you said…". On past days there is no record button and the line ends at the last play button.

**Titles.** `Recording.title`; if empty, the first five words of the transcript in lowercase; before there is a transcript, "new recording".

**Waveform.** 40 levels computed from the audio file's samples.

**Accessibility.** Play buttons read "Play <title>" or "Pause <title>". The title area and the transcript button expose their expanded state.

**Details settled in the build.** Values the brief did not give:

- Each play button is centred on its row's time and title, and stays there when the row expands.
- 6pt between the waveform and the elapsed/total times; 4pt above the transcript button and above the transcript; 8pt between a timestamp and its text.
- Silent waveform bars still show as 2pt dots. Play and pause lines are 2pt; the record button's stop square has a 2.5pt corner radius; 2pt between "i'm listening…" and the timer.
- The 0.98 title line height is a fixed 45pt box per line; glyphs may spill past it.
- Transcripts are split into passages at the end of each sentence or after a pause longer than 1.2 seconds.
- "show transcript" appears only when there is a transcript or one is being written.
- Starting a recording pauses playback; play buttons are disabled while recording.
- Moving to another day stops playback, and stops and saves a recording in progress.

| Name | View box | Path | Drawn at |
| --- | --- | --- | --- |
| Circle | 44 x 44 | `M22 3 C33 2 41 10 41 21 C41 33 33 41 22 41 C10 41 3 33 3 22 C3 11 11 3 25 4` | 44 x 44, stroke 2 |
| Play | 44 x 44 | `M18 14 L31 22 L18 30 C17 25 17 19 18 14` | 44 x 44, stroke 2 |
| Pause (2 paths) | 44 x 44 | `M17 15 L17 29` / `M27 15 L27 29` | 44 x 44, stroke 2 |
| Back arrow (2 paths) | 24 x 24 | `M21 12 C15 11 10 13 4 12` / `M10 6 C8 8 6 10 4 12 C6 14 8 16 10 19` | 24 x 24, stroke 2 |
| Chevron down | 24 x 24 | `M5 9 C7 12 10 14 12 16 C14 14 17 11 19 9` | 16 x 16, stroke 1.8 |
| Timeline line | 8 wide | `M4 0 C7 75 1 150 4 225`, repeated every 225pt | Not scaled, stroke 1.8 |

## 7. Rules that keep it on style

- Mostly white. One subject per screen. If a screen feels full, remove something.
- Handwriting for the few words with feeling (prompt, month, day title). Sans for everything functional. Never swap them.
- Red means recording, and only that.
- No shadows, gradients, cards, borders around sections, or SF Symbols. If a new icon is needed, draw it as a wobbly single-line path in the same hand.
- No emoji, no exclamation marks, lowercase labels.

## 8. Not in scope yet

Onboarding, settings, search, sharing, iCloud sync, editing or deleting recordings, and a dark theme have not been designed. Do not add them without asking.
