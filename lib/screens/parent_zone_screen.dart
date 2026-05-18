import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/lesson_data.dart';
import '../providers/progress_provider.dart';

class ParentZoneScreen extends StatelessWidget {
  const ParentZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final nextLessonIndex = progress.completedLessonsCount.clamp(0, LessonData.lessons.length - 1);
    final nextLesson = LessonData.lessons[nextLessonIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Parent Zone')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('Child Progress Summary', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          _InfoBox(
            title: 'Progress',
            lines: [
              'Stars: ${progress.totalStars}',
              'Completed lessons: ${progress.completedLessonsCount}/${LessonData.lessons.length}',
              'Songs practiced: ${progress.completedSongsCount}',
              'Practice time: about ${(progress.progress.practiceSeconds / 60).round()} minutes',
            ],
          ),
          _InfoBox(
            title: 'Suggested Next Lesson',
            lines: [nextLesson.title, nextLesson.description],
          ),
          _InfoBox(
            title: 'Tips for Parents',
            lines: const [
              'Practice 5–10 minutes daily.',
              'Encourage, do not pressure.',
              'Repeat simple songs.',
              'Let the child enjoy sound first.',
              'Celebrate small wins with smiles and stars.',
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _InfoBox({
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 7))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $line', style: Theme.of(context).textTheme.bodyLarge),
            ),
        ],
      ),
    );
  }
}
