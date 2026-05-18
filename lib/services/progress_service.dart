import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress.dart';

class ProgressService {
  static const _completedLessonsKey = 'completedLessonIds';
  static const _completedSongsKey = 'completedSongIds';
  static const _badgesKey = 'unlockedBadges';
  static const _bestRhythmScoreKey = 'bestRhythmScore';
  static const _practiceSecondsKey = 'practiceSeconds';
  static const _lessonStarsPrefix = 'lessonStars_';

  Future<ProgressData> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final completedLessons = prefs.getStringList(_completedLessonsKey)?.toSet() ?? <String>{};
    final completedSongs = prefs.getStringList(_completedSongsKey)?.toSet() ?? <String>{};
    final badges = prefs.getStringList(_badgesKey)?.toSet() ?? <String>{};

    final stars = <String, int>{};
    for (final lessonId in completedLessons) {
      stars[lessonId] = prefs.getInt('$_lessonStarsPrefix$lessonId') ?? 0;
    }

    return ProgressData(
      completedLessonIds: completedLessons,
      lessonStars: stars,
      completedSongIds: completedSongs,
      bestRhythmScore: prefs.getInt(_bestRhythmScoreKey) ?? 0,
      unlockedBadges: badges,
      practiceSeconds: prefs.getInt(_practiceSecondsKey) ?? 0,
    );
  }

  Future<void> saveProgress(ProgressData progress) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(_completedLessonsKey, progress.completedLessonIds.toList());
    await prefs.setStringList(_completedSongsKey, progress.completedSongIds.toList());
    await prefs.setStringList(_badgesKey, progress.unlockedBadges.toList());
    await prefs.setInt(_bestRhythmScoreKey, progress.bestRhythmScore);
    await prefs.setInt(_practiceSecondsKey, progress.practiceSeconds);

    for (final entry in progress.lessonStars.entries) {
      await prefs.setInt('$_lessonStarsPrefix${entry.key}', entry.value);
    }
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
