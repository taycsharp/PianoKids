class SongStep {
  final String? note;
  final double beats;

  const SongStep.note(this.note, {this.beats = 1}) : assert(beats > 0);

  const SongStep.rest({this.beats = 1})
      : note = null,
        assert(beats > 0);

  bool get isRest => note == null;
}

class Song {
  final String id;
  final String title;
  final String difficulty;
  final int tempoBpm;
  final List<SongStep> steps;
  final String description;

  const Song({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.tempoBpm,
    required this.steps,
    required this.description,
  });

  List<String> get notes => [
        for (final step in steps)
          if (step.note != null) step.note!,
      ];

  Duration durationForBeats(double beats, {double tempoMultiplier = 1}) {
    final effectiveTempo = tempoBpm * tempoMultiplier;
    final milliseconds = (60000 / effectiveTempo * beats).round();
    return Duration(milliseconds: milliseconds);
  }
}
