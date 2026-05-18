import 'package:flutter_test/flutter_test.dart';
import 'package:happy_piano_kids/models/piano_note.dart';

void main() {
  group('PianoNote registry', () {
    test('contains the full standard 88-key range from A0 to C8', () {
      expect(PianoNote.standard88, hasLength(88));
      expect(PianoNote.standard88.first.name, 'A0');
      expect(PianoNote.standard88.first.midiNumber, 21);
      expect(PianoNote.standard88.last.name, 'C8');
      expect(PianoNote.standard88.last.midiNumber, 108);
    });

    test('uses A4 = MIDI 69 = 440 Hz tuning', () {
      final a4 = PianoNote.byName['A4'];

      expect(a4, isNotNull);
      expect(a4!.midiNumber, 69);
      expect(a4.frequency, closeTo(440, 0.0001));
    });

    test('maps beginner keyboard labels to C4 through C5', () {
      expect(PianoNote.fromKeyboardLabel('C')?.name, 'C4');
      expect(PianoNote.fromKeyboardLabel('C#')?.name, 'C#4');
      expect(PianoNote.fromKeyboardLabel('A')?.name, 'A4');
      expect(PianoNote.fromKeyboardLabel('High C')?.name, 'C5');
    });

    test('identifies black and white keys', () {
      expect(PianoNote.byName['C4']?.isWhiteKey, isTrue);
      expect(PianoNote.byName['C#4']?.isBlackKey, isTrue);
    });
  });
}
