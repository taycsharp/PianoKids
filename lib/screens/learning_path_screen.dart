import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../providers/progress_provider.dart';
import '../services/content_repository.dart';
import '../widgets/lesson_card.dart';
import 'lesson_detail_screen.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  late final Future<List<Lesson>> _lessonsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = context.read<ContentRepository>().getLessons();
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Path')),
      body: FutureBuilder<List<Lesson>>(
        future: _lessonsFuture,
        builder: (context, snapshot) {
          final lessons = snapshot.data ?? const <Lesson>[];
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: lessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final lesson = lessons[index];
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
          );
        },
      ),
    );
  }
}
