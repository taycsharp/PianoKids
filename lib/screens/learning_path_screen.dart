import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/lesson_data.dart';
import '../providers/progress_provider.dart';
import '../widgets/lesson_card.dart';
import 'lesson_detail_screen.dart';

class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Path')),
      body: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: LessonData.lessons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final lesson = LessonData.lessons[index];
          final isLocked = !progress.isLessonUnlocked(index);

          return LessonCard(
            lesson: lesson,
            isLocked: isLocked,
            stars: progress.starsForLesson(lesson.id),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LessonDetailScreen(lesson: lesson, lessonIndex: index),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
