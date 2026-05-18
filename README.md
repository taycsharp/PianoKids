# Happy Piano Kids

A complete Flutter MVP for children aged 5–10 who are beginning piano.

## Features

- Splash screen
- Home screen with kid-friendly navigation
- Learning path with unlock logic
- Lesson detail interactions
- Virtual piano keyboard
- Songs list
- Song practice mode
- Rhythm game
- Ear training
- Progress screen
- Parent zone
- Local progress saving with `shared_preferences`
- Safe audio playback with missing-file protection
- Provider state management
- Colorful reusable widgets and theme

## Setup

```bash
flutter pub get
flutter run
```

## Add piano sound files

Put note files here:

```text
assets/audio/notes/c.mp3
assets/audio/notes/d.mp3
assets/audio/notes/e.mp3
assets/audio/notes/f.mp3
assets/audio/notes/g.mp3
assets/audio/notes/a.mp3
assets/audio/notes/b.mp3
assets/audio/notes/high_c.mp3
```

Optional effects:

```text
assets/audio/effects/success.mp3
assets/audio/effects/tap.mp3
assets/audio/effects/animal_reward.mp3
```

The app uses safe audio playback. If a file is missing, it will print a debug message and continue without crashing.

## Run on iPhone

```bash
flutter devices
open ios/Runner.xcworkspace
flutter run -d <your-ios-device-id>
```

For a real iPhone:
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select Runner > Signing & Capabilities.
3. Choose your Apple Team.
4. Connect your iPhone and trust the developer certificate if needed.
5. Run from Xcode or with `flutter run`.

## Run on Android

```bash
flutter devices
flutter run -d <your-android-device-id>
```

For a real Android phone:
1. Enable Developer Options.
2. Enable USB Debugging.
3. Connect phone by USB.
4. Run `flutter devices`.
5. Run `flutter run -d <device-id>`.

## Build release

Android APK:

```bash
flutter build apk --release
```

iOS release build:

```bash
flutter build ios --release
```


## Generated standard piano notes

The app now works even when no MP3 piano files are provided.

`lib/services/audio_service.dart` uses this order:

1. Try to play a real piano asset from `assets/audio/notes/`.
2. If the file is missing, generate a soft piano-like WAV tone in memory.
3. If audio still fails, skip safely without crashing the app.

Generated beginner note frequencies:

| Note | Frequency |
| --- | ---: |
| C4 | 261.63 Hz |
| D4 | 293.66 Hz |
| E4 | 329.63 Hz |
| F4 | 349.23 Hz |
| G4 | 392.00 Hz |
| A4 | 440.00 Hz |
| B4 | 493.88 Hz |
| C5 | 523.25 Hz |

This is good for MVP learning and note recognition. For a more realistic piano
feeling later, add real piano MP3 files using the names shown in
`assets/audio/notes/README.md`.

## Piano keyboard education update

This MVP now teaches the real beginner keyboard pattern:

- White keys: C D E F G A B C
- Black keys: C♯ D♯ F♯ G♯ A♯
- Children learn the group of 2 black keys and group of 3 black keys
- Children learn that C is just to the left of the group of two black keys
- Children learn that F is just to the left of the group of three black keys

The generated audio service includes standard equal-tempered frequencies from C4 to C5, including black keys.
