# Happy Piano Kids - Codex Instructions

## Project Goal
Happy Piano Kids is a Flutter piano-learning app for children aged 5–10.

## Important Product Rules
- Teach real piano fundamentals, not only white notes.
- Include white keys and black keys.
- Teach the 2-black-key and 3-black-key patterns.
- Teach that C is left of the 2-black-key group.
- Teach that F is left of the 3-black-key group.
- Keep lessons simple, visual, playful, and suitable for beginners.

## Flutter Rules
- Use Provider for state management.
- Use shared_preferences for local progress.
- Keep the app offline-first.
- Do not add backend, login, ads, or cloud sync in this MVP.
- Keep code clean and easy to extend.

## Audio Rules
- Generated piano notes must never crash the app.
- If real audio samples are missing, fallback to generated piano tones.
- Keep the piano sound warm and soft for children.
- Do not claim exact Steinway or Yamaha reproduction unless using licensed samples.

## UI Rules
- Large buttons.
- Rounded colorful cards.
- Simple English.
- Kid-friendly icons.
- Not too much text on one screen.

## Before Finishing
Always run:

flutter analyze
flutter test
