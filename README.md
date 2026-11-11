# murmur

A voice diary for iPhone. Tap once to talk about your day, and each recording is filed under the date it was made.

The look is a blank sheet of paper: handwriting, a few wobbly pen lines, and one red record button.

## What it does

- **Record:** open the app and tap the red button to start. Tap it again to stop and save.
- **Calendar:** swipe left, or tap "calendar", to see the month. Days with a recording have a dot, and today is circled.

Coming next: a Day screen for playing back a day's recordings, then on-device transcripts.

## Running it

1. Open `murmur.xcodeproj` in Xcode.
2. Pick a simulator or your iPhone as the run destination, then press ⌘R.
3. To run on a real iPhone, choose your team under **Signing & Capabilities** first.

The app asks for microphone access the first time you tap record.

## Project layout

```
murmur/
  Home/        record screen
  Calendar/    month view
  Audio/       recording
  Model/       saved recordings (SwiftData)
  Design/      colours, fonts, sizes and the hand-drawn line art
  Fonts/       Gaegu handwriting font
DESIGN.md      design brief: layout, spacing, type, behaviour
```

Built with SwiftUI, SwiftData and AVFoundation. Audio files are saved in the app's Documents folder.

## Design

`DESIGN.md` is the source of truth for how every screen should look and behave. Update it when the design changes.

## Credits

Handwriting font: [Gaegu](https://fonts.google.com/specimen/Gaegu), licensed under the SIL Open Font License.
