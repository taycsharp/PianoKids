class SongStep {
  final String? note;
  final List<String> notes;
  final double beats;
  final double velocity;
  final String? articulation;
  final double timingMultiplier;

  const SongStep.note(
    this.note, {
    this.beats = 1,
    this.velocity = 0.8,
    this.articulation,
    this.timingMultiplier = 1,
  })  : notes = const [],
        assert(beats > 0),
        assert(velocity >= 0 && velocity <= 1),
        assert(timingMultiplier > 0);

  const SongStep.chord(
    this.notes, {
    this.beats = 1,
    this.velocity = 0.8,
    this.articulation,
    this.timingMultiplier = 1,
  })  : note = null,
        assert(beats > 0),
        assert(velocity >= 0 && velocity <= 1),
        assert(timingMultiplier > 0);

  const SongStep.rest({this.beats = 1, this.timingMultiplier = 1})
      : note = null,
        notes = const [],
        velocity = 0,
        articulation = null,
        assert(beats > 0),
        assert(timingMultiplier > 0);

  bool get isRest => note == null && notes.isEmpty;

  List<String> get playableNotes => [if (note != null) note!, ...notes];
}

class Song {
  final String id;
  final String title;
  final String difficulty;
  final int tempoBpm;
  final int beatsPerMeasure;
  final List<SongStep> steps;
  final String description;

  const Song({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.tempoBpm,
    this.beatsPerMeasure = 4,
    required this.steps,
    required this.description,
  });

  List<String> get notes => [
        for (final step in steps)
          ...step.playableNotes,
      ];

  Duration durationForBeats(double beats, {double tempoMultiplier = 1}) {
    final effectiveTempo = tempoBpm * tempoMultiplier;
    final milliseconds = (60000 / effectiveTempo * beats).round();
    return Duration(milliseconds: milliseconds);
  }
}
