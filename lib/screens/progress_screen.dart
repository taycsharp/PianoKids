import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/lesson_data.dart';
import '../providers/progress_provider.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _MetricCard(label: 'Total Stars', value: '${progress.totalStars} ⭐', emoji: '🌟'),
          _MetricCard(label: 'Completed Lessons', value: '${progress.completedLessonsCount}/${LessonData.lessons.length}', emoji: '📚'),
          _MetricCard(label: 'Songs Practiced', value: '${progress.completedSongsCount}', emoji: '🎵'),
          _MetricCard(label: 'Best Rhythm Score', value: '${progress.bestRhythmScore} ⭐', emoji: '🥁'),
          const SizedBox(height: 12),
          Text('Badges', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          if (progress.unlockedBadges.isEmpty)
            const Text('No badges yet. Start a lesson to unlock your first badge!')
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: progress.unlockedBadges
                  .map((badge) => Chip(
                        label: Text(badge, style: const TextStyle(fontWeight: FontWeight.w800)),
                        avatar: const Text('🏅'),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => progress.resetProgress(),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset Progress'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 7))],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
