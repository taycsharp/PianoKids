import '../models/lesson.dart';

class LessonData {
  static const lessons = <Lesson>[
    Lesson(
      id: 'lesson_1',
      title: 'Meet White Keys',
      description: 'White keys are the big keys. Start with C, D, and E.',
      icon: '🎹',
      requiredNotes: ['C', 'D', 'E'],
      taskType: LessonTaskType.tapNotes,
    ),
    Lesson(
      id: 'lesson_2',
      title: 'Meet Black Keys',
      description: 'Black keys live in groups of two and three. Try C sharp and D sharp.',
      icon: '🐼',
      requiredNotes: ['C#', 'D#'],
      taskType: LessonTaskType.tapNotes,
    ),
    Lesson(
      id: 'lesson_3',
      title: 'Find C with Black Keys',
      description: 'Find the group of two black keys. C is just on the left.',
      icon: '🔎',
      requiredNotes: ['C', 'C#', 'D', 'D#', 'E'],
      taskType: LessonTaskType.tapNotes,
    ),
    Lesson(
      id: 'lesson_4',
      title: 'Learn F-G-A-B',
      description: 'After the group of three black keys, find F, G, A, and B.',
      icon: '🌈',
      requiredNotes: ['F', 'G', 'A', 'B'],
      taskType: LessonTaskType.tapNotes,
    ),
    Lesson(
      id: 'lesson_5',
      title: 'All Black Keys',
      description: 'Play the five black keys: C sharp, D sharp, F sharp, G sharp, A sharp.',
      icon: '⭐',
      requiredNotes: ['C#', 'D#', 'F#', 'G#', 'A#'],
      taskType: LessonTaskType.tapNotes,
    ),
    Lesson(
      id: 'lesson_6',
      title: 'Simple Rhythm',
      description: 'Tap with the beat. Music has a heartbeat!',
      icon: '🥁',
      requiredNotes: [],
      taskType: LessonTaskType.rhythm,
    ),
    Lesson(
      id: 'lesson_7',
      title: 'Play First Song',
      description: 'Play your first little song with C-D-E.',
      icon: '🎵',
      requiredNotes: ['C', 'D', 'E'],
      taskType: LessonTaskType.song,
    ),
    Lesson(
      id: 'lesson_8',
      title: 'Review Challenge',
      description: 'Review white keys, black keys, and high sounds.',
      icon: '🏆',
      requiredNotes: ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', 'High C'],
      taskType: LessonTaskType.review,
    ),
  ];
}
