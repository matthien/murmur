# murmur

A voice diary for iPhone. Tap once to talk about your day, and each recording is filed under the date it was made.

The look is a blank sheet of paper: handwriting, a few wobbly pen lines, and one red record button.

## What it does

- **Record:** open the app and tap the red button to start. Tap it again to stop and save.
- **Calendar:** swipe left, or tap "calendar", to see the month. Days with a recording have a dot, and today is circled.
- **Day:** tap a day with a dot to see its recordings on a timeline. Tap one to play it, see its waveform and read the transcript. Swipe left and right to move between days. On today's page you can record another.

Recordings made on the Day screen are transcribed on the device. Recordings made on the record screen are not transcribed yet.

## Running it

1. Open `murmur.xcodeproj` in Xcode.
2. Pick a simulator or your iPhone as the run destination, then press ⌘R.
3. To run on a real iPhone, choose your team under **Signing & Capabilities** first.

The app asks for microphone access the first time you tap record, and for speech recognition the first time it writes out a recording.

## Project layout

```
murmur/
  Home/        record screen
  Calendar/    month view
  Day/         one day's recordings, playback and transcripts
  Audio/       recording, playback, waveforms and transcription
  Model/       saved recordings (SwiftData)
  Design/      colours, fonts, sizes and the hand-drawn line art
  Fonts/       Gaegu handwriting font
  Assets.xcassets/  the 13 doodles shown on the Day screen
DESIGN.md      design brief: layout, spacing, type, behaviour
```

Built with SwiftUI, SwiftData, AVFoundation and Speech. Audio files are saved in the app's Documents folder.

## Design

`DESIGN.md` is the source of truth for how every screen should look and behave. Update it when the design changes.

## Credits

Handwriting font: [Gaegu](https://fonts.google.com/specimen/Gaegu), licensed under the SIL Open Font License.
