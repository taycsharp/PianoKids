import 'package:flutter/material.dart';

import '../models/song.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final bool completed;
  final VoidCallback? onDemo;
  final VoidCallback? onPractice;
  final VoidCallback? onStop;

  const SongCard({
    super.key,
    required this.song,
    required this.completed,
    required this.onDemo,
    required this.onPractice,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎵', style: TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(child: Text(song.title, style: Theme.of(context).textTheme.titleLarge)),
              if (completed) const Text('🏅', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${song.difficulty} • ${song.description}'),
          const SizedBox(height: 8),
          Text(song.notes.join('  '), style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDemo,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Demo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPractice,
                  icon: const Icon(Icons.piano),
                  label: const Text('Practice'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
