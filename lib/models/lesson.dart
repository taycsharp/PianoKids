class Lesson {
  final String id;
  final String title;
  final String description;
  final String icon;
  final List<String> requiredNotes;
  final LessonTaskType taskType;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredNotes,
    required this.taskType,
  });
}

enum LessonTaskType {
  tapNotes,
  highLow,
  rhythm,
  info,
  song,
  review,
}
