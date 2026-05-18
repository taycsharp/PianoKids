class ProgressData {
  final Set<String> completedLessonIds;
  final Map<String, int> lessonStars;
  final Set<String> completedSongIds;
  final int bestRhythmScore;
  final Set<String> unlockedBadges;
  final int practiceSeconds;

  const ProgressData({
    required this.completedLessonIds,
    required this.lessonStars,
    required this.completedSongIds,
    required this.bestRhythmScore,
    required this.unlockedBadges,
    required this.practiceSeconds,
  });

  factory ProgressData.empty() {
    return const ProgressData(
      completedLessonIds: <String>{},
      lessonStars: <String, int>{},
      completedSongIds: <String>{},
      bestRhythmScore: 0,
      unlockedBadges: <String>{},
      practiceSeconds: 0,
    );
  }

  int get totalStars {
    final lessonTotal = lessonStars.values.fold<int>(0, (sum, stars) => sum + stars);
    final songTotal = completedSongIds.length * 3;
    return lessonTotal + songTotal;
  }

  ProgressData copyWith({
    Set<String>? completedLessonIds,
    Map<String, int>? lessonStars,
    Set<String>? completedSongIds,
    int? bestRhythmScore,
    Set<String>? unlockedBadges,
    int? practiceSeconds,
  }) {
    return ProgressData(
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      lessonStars: lessonStars ?? this.lessonStars,
      completedSongIds: completedSongIds ?? this.completedSongIds,
      bestRhythmScore: bestRhythmScore ?? this.bestRhythmScore,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      practiceSeconds: practiceSeconds ?? this.practiceSeconds,
    );
  }
}
