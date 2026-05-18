import 'dart:math' as math;

/// One note in the standard 88-key acoustic piano range.
///
/// A real piano spans MIDI 21 (A0) through MIDI 108 (C8). The frequency is
/// calculated with A4 = MIDI 69 = 440 Hz so generated notes stay in tune as the
/// keyboard grows beyond the beginner one-octave screen.
class PianoNote {
  const PianoNote({
    required this.name,
    required this.midiNumber,
    required this.frequency,
    required this.isBlackKey,
  });

  final String name;
  final int midiNumber;
  final double frequency;
  final bool isBlackKey;

  bool get isWhiteKey => !isBlackKey;

  static const int lowestPianoMidi = 21;
  static const int highestPianoMidi = 108;
  static const int a4Midi = 69;
  static const double a4Frequency = 440;

  static const List<String> _pitchClasses = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  static const Set<String> _blackPitchClasses = {
    'C#',
    'D#',
    'F#',
    'G#',
    'A#',
  };

  static final List<PianoNote> standard88 = List.unmodifiable(
    Iterable<int>.generate(
      highestPianoMidi - lowestPianoMidi + 1,
      (index) => lowestPianoMidi + index,
    ).map(fromMidi),
  );

  static final Map<String, PianoNote> byName = Map.unmodifiable({
    for (final note in standard88) note.name: note,
  });

  /// Converts the short labels used by the beginner keyboard into real note
  /// names. The visible keyboard is C4 through C5.
  static PianoNote? fromKeyboardLabel(String label) {
    final fullName = switch (label) {
      'C' => 'C4',
      'C#' => 'C#4',
      'D' => 'D4',
      'D#' => 'D#4',
      'E' => 'E4',
      'F' => 'F4',
      'F#' => 'F#4',
      'G' => 'G4',
      'G#' => 'G#4',
      'A' => 'A4',
      'A#' => 'A#4',
      'B' => 'B4',
      'High C' => 'C5',
      _ => label,
    };
    return byName[fullName];
  }

  static PianoNote fromMidi(int midiNumber) {
    if (midiNumber < lowestPianoMidi || midiNumber > highestPianoMidi) {
      throw RangeError.range(
        midiNumber,
        lowestPianoMidi,
        highestPianoMidi,
        'midiNumber',
        'Piano note must be within the standard 88-key range.',
      );
    }

    final pitchClass = _pitchClasses[midiNumber % _pitchClasses.length];
    final octave = midiNumber ~/ _pitchClasses.length - 1;
    final frequency = a4Frequency * math.pow(2, (midiNumber - a4Midi) / 12);

    return PianoNote(
      name: '$pitchClass$octave',
      midiNumber: midiNumber,
      frequency: frequency.toDouble(),
      isBlackKey: _blackPitchClasses.contains(pitchClass),
    );
  }
}
