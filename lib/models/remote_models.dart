import '../data/two_octave_demo_songs.dart';
import 'lesson.dart';
import 'song.dart';

class RemoteMappers {
  static List<Song> mapSongs(Map<String, dynamic> json) {
    final rawItems = (json['data'] ?? json['songs']) as List<dynamic>?;
    if (rawItems == null) throw const FormatException('Missing songs data');

    return rawItems.map((item) {
      final map = item as Map<String, dynamic>;
      final stepsRaw = (map['steps'] ?? map['notes']) as List<dynamic>? ?? const [];
      final steps = stepsRaw.map((stepItem) {
        final step = stepItem as Map<String, dynamic>;
        final note = step['note'] as String?;
        final beats = (step['beats'] as num?)?.toDouble() ?? 1;
        return note == null ? SongStep.rest(beats: beats) : SongStep.note(note, beats: beats);
      }).toList();

      return Song(
        id: (map['id'] ?? map['slug'] ?? '').toString(),
        title: (map['title'] ?? '').toString(),
        difficulty: (map['difficulty'] ?? 'Easy').toString(),
        tempoBpm: (map['tempo_bpm'] as num?)?.toInt() ?? 100,
        description: (map['description'] ?? '').toString(),
        steps: steps,
      );
    }).toList();
  }

  static List<Lesson> mapLessons(Map<String, dynamic> json) {
    final rawItems = (json['data'] ?? json['lessons']) as List<dynamic>?;
    if (rawItems == null) throw const FormatException('Missing lessons data');

    return rawItems.map((item) {
      final map = item as Map<String, dynamic>;
      final taskTypeName = (map['task_type'] ?? 'tapNotes').toString();
      final taskType = LessonTaskType.values.firstWhere(
        (value) => value.name == taskTypeName,
        orElse: () => LessonTaskType.tapNotes,
      );

      return Lesson(
        id: (map['id'] ?? '').toString(),
        title: (map['title'] ?? '').toString(),
        description: (map['description'] ?? '').toString(),
        icon: (map['icon'] ?? '🎹').toString(),
        requiredNotes: ((map['required_notes'] ?? const []) as List<dynamic>)
            .map((note) => note.toString())
            .toList(),
        taskType: taskType,
      );
    }).toList();
  }

  static List<DemoSong> mapTwoOctaveSongs(Map<String, dynamic> json) {
    final rawItems = (json['data'] ?? json['songs']) as List<dynamic>?;
    if (rawItems == null) throw const FormatException('Missing two-octave songs data');

    return rawItems.map((item) {
      final map = item as Map<String, dynamic>;
      final eventsRaw = (map['events'] ?? const []) as List<dynamic>;
      final events = eventsRaw.map((eventItem) {
        final event = eventItem as Map<String, dynamic>;
        return DemoNoteEvent(
          note: (event['note'] ?? '').toString(),
          hand: (event['hand'] ?? 'right').toString() == 'left' ? DemoHand.left : DemoHand.right,
          duration: Duration(milliseconds: (event['duration_ms'] as num?)?.toInt() ?? 420),
        );
      }).toList();

      return DemoSong(
        id: (map['id'] ?? '').toString(),
        name: (map['name'] ?? '').toString(),
        events: events,
      );
    }).toList();
  }
}
