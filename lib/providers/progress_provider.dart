import 'package:flutter/material.dart';

import '../data/lesson_data.dart';
import '../models/progress.dart';
import '../services/progress_service.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressService _progressService;
  ProgressData _progress = ProgressData.empty();
  bool _isLoaded = false;

  ProgressProvider(this._progressService);

  ProgressData get progress => _progress;
  bool get isLoaded => _isLoaded;

  int get totalStars => _progress.totalStars;
  int get completedLessonsCount => _progress.completedLessonIds.length;
  int get completedSongsCount => _progress.completedSongIds.length;
  int get bestRhythmScore => _progress.bestRhythmScore;
  Set<String> get unlockedBadges => _progress.unlockedBadges;

  Future<void> loadProgress() async {
    _progress = await _progressService.loadProgress();
    _isLoaded = true;
    notifyListeners();
  }

  bool isLessonUnlocked(int index) {
    if (index == 0) return true;
    final previousLesson = LessonData.lessons[index - 1];
    return _progress.completedLessonIds.contains(previousLesson.id);
  }

  bool isLessonCompleted(String lessonId) => _progress.completedLessonIds.contains(lessonId);

  int starsForLesson(String lessonId) => _progress.lessonStars[lessonId] ?? 0;

  Future<void> completeLesson(String lessonId, int stars) async {
    final completed = {..._progress.completedLessonIds, lessonId};
    final lessonStars = {..._progress.lessonStars};
    lessonStars[lessonId] = stars > (lessonStars[lessonId] ?? 0) ? stars : (lessonStars[lessonId] ?? 0);

    final badges = _calculateBadges(
      completedLessonIds: completed,
      completedSongIds: _progress.completedSongIds,
      bestRhythmScore: _progress.bestRhythmScore,
    );

    _progress = _progress.copyWith(
      completedLessonIds: completed,
      lessonStars: lessonStars,
      unlockedBadges: badges,
      practiceSeconds: _progress.practiceSeconds + 120,
    );

    await _progressService.saveProgress(_progress);
    notifyListeners();
  }

  Future<void> completeSong(String songId) async {
    final songs = {..._progress.completedSongIds, songId};
    final badges = _calculateBadges(
      completedLessonIds: _progress.completedLessonIds,
      completedSongIds: songs,
      bestRhythmScore: _progress.bestRhythmScore,
    );

    _progress = _progress.copyWith(
      completedSongIds: songs,
      unlockedBadges: badges,
      practiceSeconds: _progress.practiceSeconds + 180,
    );

    await _progressService.saveProgress(_progress);
    notifyListeners();
  }

  Future<void> updateRhythmScore(int score) async {
    if (score <= _progress.bestRhythmScore) return;

    final badges = _calculateBadges(
      completedLessonIds: _progress.completedLessonIds,
      completedSongIds: _progress.completedSongIds,
      bestRhythmScore: score,
    );

    _progress = _progress.copyWith(
      bestRhythmScore: score,
      unlockedBadges: badges,
      practiceSeconds: _progress.practiceSeconds + 60,
    );

    await _progressService.saveProgress(_progress);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    await _progressService.resetProgress();
    _progress = ProgressData.empty();
    notifyListeners();
  }

  Set<String> _calculateBadges({
    required Set<String> completedLessonIds,
    required Set<String> completedSongIds,
    required int bestRhythmScore,
  }) {
    final badges = <String>{};

    if (completedLessonIds.isNotEmpty) badges.add('First Note');
    if (completedLessonIds.contains('lesson_3')) badges.add('C-D-E Master');
    if (completedSongIds.isNotEmpty) badges.add('First Song');
    if (bestRhythmScore >= 2) badges.add('Rhythm Star');
    if (completedLessonIds.length >= 4) badges.add('Piano Explorer');

    return badges;
  }
}
