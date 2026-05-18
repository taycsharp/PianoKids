# Happy Piano Kids - Codex Instructions

## Project
Happy Piano Kids is a Flutter piano-learning app for children aged 5–10.

## Goals
- Keep the UI colorful, playful, and simple for young children.
- Teach real piano fundamentals: white keys, black keys, groups of 2 and 3 black keys, note recognition, rhythm, ear training, and simple songs.
- Keep code clean, modular, and easy to extend.

## Tech
- Flutter
- Provider
- shared_preferences
- audioplayers
- Local-first MVP

## Coding rules
- Use null safety.
- Keep widgets reusable.
- Avoid over-complex architecture.
- Do not break existing screens.
- Run before finishing:
  - flutter analyze
  - flutter test

## Audio rules
- Generated piano tones must not crash the app.
- Keep optional asset-based note playback supported.
- If real audio files are missing, fallback to generated tones.
- Piano sound should be warm, soft, and suitable for kids.

## UI rules
- Large buttons.
- Rounded cards.
- Soft shadows.
- Simple English.
- No ads.
- No login required in MVP.

## Review guidelines
- Flag code that can crash when audio assets are missing.
- Flag UI that is too text-heavy for children.
- Flag regressions in lesson progression, progress saving, or piano keyboard behavior.
- Flag missing tests for important state/progress logic.
