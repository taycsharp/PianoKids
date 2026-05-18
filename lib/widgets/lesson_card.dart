import 'package:flutter/material.dart';

import '../models/lesson.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isLocked;
  final int stars;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.isLocked,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLocked ? Colors.grey.shade300 : Colors.white;

    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: isLocked ? Colors.grey.shade400 : Colors.amber.shade200, width: 2),
        ),
        child: Row(
          children: [
            Text(isLocked ? '🔒' : lesson.icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    isLocked ? 'Complete the previous lesson first.' : lesson.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(stars == 0 ? 'No stars yet' : List.filled(stars, '⭐').join(' ')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
